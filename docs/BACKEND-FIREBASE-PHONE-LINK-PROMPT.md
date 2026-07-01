# Prompt Backend — Vincular cuentas antiguas con Firebase Phone Auth

**Para:** repo `Back/Ciervo-backend`  
**Solicitado por:** Mobile Flutter (`ciervo_clud`)  
**Backend prod:** `https://ciervo-backend-613568140358.southamerica-east1.run.app`  
**Fecha:** 2026-07-01

---

## 0. Problema reportado (QA real)

Flujo teléfono en app móvil:

1. Usuario ingresa `+57 321 4291986` → `POST /api/auth/account-lookup` responde que **el teléfono ya tiene cuenta** → modal “Número ya registrado / Iniciar sesión”.
2. Usuario confirma SMS Firebase (6 dígitos) → `POST /api/auth/firebase/check-user` responde **`exists: false`** → app muestra “Cuenta no encontrada / ¿Crear cuenta nueva?”.

**Resultado:** contradicción UX; usuarios con **cuenta legacy** (sin `FirebaseUid`, teléfono en formato viejo) no pueden iniciar sesión por SMS aunque el número sea el suyo.

**Causa raíz (código actual):** `account-lookup` y `firebase/check-user` no resuelven el mismo usuario con la misma lógica de teléfono.

---

## 1. Contexto técnico

| Sistema | Rol |
|---------|-----|
| **Firebase Auth** | Prueba propiedad del teléfono vía SMS (`firebaseIdToken` con `phone_number`) |
| **CIERVO `Client`** | Cuenta real (wallet, perfil, membresía) |
| **Vínculo** | `Client.FirebaseUid` + `Client.AuthProvider` |

Cuentas antiguas típicas:

- `Phone` = `3214291986` o `573214291986` (sin `+`)
- `AuthProvider` = `Legacy` o registro email/contraseña
- `FirebaseUid` = `NULL`
- Usuario nuevo en Firebase Phone crea **UID distinto** al de un eventual Firebase email previo

**Vinculación automática ya existe parcialmente** en `LoginFirebase` → `ApplyFirebaseVerification` (asigna `FirebaseUid` si está vacío). **No se ejecuta** porque `FindClientByFirebase` no encuentra al cliente.

---

## 2. Archivos backend a revisar

| Archivo | Qué hace hoy |
|---------|----------------|
| `Business/Services/AuthService.cs` | `CheckFirebaseUser`, `LoginFirebase`, `RegisterFirebase`, `LookupAccount`, `FindClientByFirebase`, `ApplyFirebaseVerification` |
| `Business/Helpers/PhoneCatalog.cs` | `Normalize(phone, countryCode?)` |
| `DTO/AuthDtos.cs` | `FirebaseCheckUserRequest`, `FirebaseLoginRequest`, `AccountLookupResponse` |
| `WebApi/Controllers/AuthController.cs` | Rutas `/api/auth/*` |

### Código problemático actual

`FindClientByFirebase` (aprox. L605-613):

```csharp
private async Task<Client?> FindClientByFirebase(FirebaseVerifiedToken verified)
{
    var byUid = await _clientRepository.GetAsync(x => x.FirebaseUid == verified.Uid);
    if (byUid != null) return byUid;
    var phone = PhoneCatalog.Normalize(verified.Phone);
    if (!string.IsNullOrWhiteSpace(phone))
        return await _clientRepository.GetAsync(x => x.Phone == phone);
    return null;
}
```

**Problemas:**

1. **Ignora** `request.Phone` en `CheckFirebaseUser` / `LoginFirebase` si el token trae teléfono vacío o distinto.
2. **Match exacto** `x.Phone == phone` — falla si BD tiene `3214291986` y lookup normaliza a `+573214291986`.
3. `LookupAccount` usa la misma normalización pero **no comparte** helper de búsqueda con `FindClientByFirebase` → resultados inconsistentes.

`CheckFirebaseUser` (aprox. L424-449): calcula `phone` desde `request.Phone ?? verified.Phone` para la **respuesta**, pero **no** lo usa para buscar el `Client`.

---

## 3. Comportamiento esperado (definición de producto)

### 3.1 Tras SMS Firebase verificado

Si existe **exactamente un** `Client` cuyo teléfono corresponde al número autenticado (en cualquier formato legacy o E.164):

| Escenario | Acción backend |
|-----------|----------------|
| `FirebaseUid` vacío | **Vincular automáticamente** en `firebase/login` (`ApplyFirebaseVerification`) |
| `FirebaseUid` distinto al del token | Error claro: teléfono ya asociado a otra cuenta Firebase |
| Sin `Client` | `exists: false` → registro nuevo |
| Más de un `Client` con mismo teléfono (datos sucios) | Error operativo + log; no auto-vincular |

### 3.2 `account-lookup` y `firebase/check-user` deben ser coherentes

Si `account-lookup` con teléfono T devuelve `exists: true`, entonces `firebase/check-user` con el mismo T (post-SMS, mismo token) **debe** devolver `exists: true` salvo que el SMS sea de otro número.

### 3.3 Cuentas legacy con contraseña (`suggestedFlow: legacy_password`)

- SMS Firebase **no** reemplaza la contraseña por sí solo.
- Opciones (elegir una):
  - **A (recomendada MVP):** si teléfono coincide + SMS OK + sin `FirebaseUid` → permitir `firebase/login` y vincular UID (sin pedir password).
  - **B (más estricta):** nuevo endpoint `firebase/link` que exige además `email + password` o OTP email antes de asignar `FirebaseUid`.

**Mobile está preparado para A** si `firebase/login` encuentra y vincula la cuenta existente.

---

## 4. Cambios requeridos en backend

### 4.1 Helper unificado de búsqueda por teléfono

Crear p.ej. `ClientPhoneResolver` o métodos en `PhoneCatalog` + `AuthService`:

```csharp
// Pseudocódigo
Task<Client?> FindClientByPhoneAsync(string? rawPhone, string? countryCode = null)
```

Debe:

1. Normalizar con `PhoneCatalog.Normalize(rawPhone, countryCode)`.
2. Generar **variantes de búsqueda** y probar en orden hasta un único match:
   - E.164: `+573214291986`
   - Sin `+`: `573214291986`
   - Nacional CO (10 dígitos): `3214291986`
   - Nacional CL (9 dígitos): `912345678`
3. Comparar en SQL con `Replace(Phone, '+', '')` o tabla normalizada — **no** solo igualdad literal.
4. Si hay 0 → `null`; si hay >1 → excepción controlada.

Usar este helper en:

- `LookupAccount`
- `FindClientByFirebase` (ver 4.2)
- `RegisterFirebase` (validar teléfono no duplicado con mismas variantes)

### 4.2 Ampliar `FindClientByFirebase`

Firma sugerida:

```csharp
private async Task<Client?> FindClientByFirebase(
    FirebaseVerifiedToken verified,
    string? phoneOverride = null,
    string? countryCode = null)
```

Orden de búsqueda:

1. `FirebaseUid == verified.Uid`
2. `FindClientByPhoneAsync(verified.Phone, countryCode)`
3. Si sigue null → `FindClientByPhoneAsync(phoneOverride, countryCode)` ← **teléfono que manda la app**

Actualizar llamadas:

- `CheckFirebaseUser(request)` → pasar `request.Phone`
- `LoginFirebase(request)` → pasar `request.Phone`
- `SyncFirebaseVerification` → opcional phone del token

### 4.3 `CheckFirebaseUser` — respuesta enriquecida (opcional pero útil para mobile)

Además de `exists`, considerar exponer (sin romper contrato actual):

```json
{
  "exists": true,
  "userId": 123,
  "canLinkFirebase": true,
  "authProvider": "Legacy",
  "suggestedFlow": "firebase_phone",
  "phone": "+573214291986",
  "phoneVerified": true
}
```

Campos nuevos opcionales:

| Campo | Significado |
|-------|-------------|
| `canLinkFirebase` | `true` si existe client sin UID o UID coincide |
| `authProvider` | `Legacy` \| `Firebase` |
| `suggestedFlow` | `firebase_phone` \| `firebase_password` \| `legacy_password` \| `register` |

Si no se agregan campos nuevos, **al menos** `exists` debe ser correcto con la búsqueda flexible.

### 4.4 `RegisterFirebase` — evitar duplicados

Antes de crear `Client`, buscar con el mismo `FindClientByPhoneAsync`. Si existe:

- Si `FirebaseUid` vacío → **no crear**; devolver error `409` con código `PHONE_ACCOUNT_EXISTS_LINK_REQUIRED` o redirigir lógica a login/link.
- Mensaje humano: “Ya tienes cuenta con este teléfono. Inicia sesión para vincular.”

### 4.5 (Opcional) `POST /api/auth/firebase/link`

Solo si se elige flujo **B** (legacy + password):

```http
POST /api/auth/firebase/link
{
  "firebaseIdToken": "...",
  "phone": "+573214291986",
  "email": "user@mail.com",
  "password": "..."   // solo legacy
}
```

Respuesta: mismo `AuthResponse` que login.

---

## 5. Migración de datos (recomendada)

Script one-off o job:

```sql
-- Pseudocódigo: normalizar Client.Phone a E.164 usando CountryCode
-- CO: 10 dígitos empezando en 3 → +57XXXXXXXXXX
-- CL: 9 dígitos empezando en 9 → +56XXXXXXXXX
```

Reglas:

- No duplicar: si dos filas colapsan al mismo E.164, reportar para revisión manual.
- Backup antes de migrar.
- Log de filas actualizadas.

Sin migración, el helper de variantes (4.1) es **obligatorio**; con migración, reduce deuda técnica.

---

## 6. Contrato API — resumen para mobile

Endpoints existentes (sin cambiar rutas):

| Método | Ruta | Cambio esperado |
|--------|------|-----------------|
| POST | `/api/auth/account-lookup` | Misma forma; búsqueda teléfono flexible |
| POST | `/api/auth/firebase/check-user` | `exists` coherente; usar `phone` del body en búsqueda |
| POST | `/api/auth/firebase/login` | Encuentra legacy por teléfono → vincula `FirebaseUid` automático |
| POST | `/api/auth/firebase/register` | Rechaza si teléfono ya existe (variantes) |

**Mobile envía hoy:**

- `account-lookup`: `{ "phone": "+573214291986" }`
- `firebase/check-user`: `{ "firebaseIdToken": "...", "phone": "+573214291986" }`
- `firebase/login`: `{ "firebaseIdToken": "...", "phone": "+573214291986" }`

No requiere cambios en mobile si backend corrige búsqueda y vinculación.

---

## 7. Códigos de error sugeridos

| Código | HTTP | Cuándo |
|--------|------|--------|
| `PHONE_ACCOUNT_EXISTS_LINK_REQUIRED` | 409 | Registro Firebase pero teléfono ya tiene cuenta |
| `FIREBASE_UID_CONFLICT` | 409 | Teléfono de otro usuario ya vinculado a otro UID |
| `AMBIGUOUS_PHONE_MATCH` | 409 | Más de un client con variantes del mismo número |

Mobile mapeará estos a mensajes humanos (sin feature keys visibles).

---

## 8. Plan de pruebas (checklist)

### Caso 1 — Legacy sin prefijo

- BD: `Phone = "3214291986"`, `FirebaseUid = NULL`, `AuthProvider = Legacy`
- Lookup `+573214291986` → `exists: true`, `phoneAvailable: false`
- SMS Firebase → `check-user` → `exists: true`
- `firebase/login` → 200, `FirebaseUid` guardado, `Phone` = `+573214291986`

### Caso 2 — Ya E.164 en BD

- BD: `Phone = "+573214291986"`, `FirebaseUid = NULL`
- Mismo flujo → login OK

### Caso 3 — Teléfono libre

- Lookup → `exists: false`, `phoneAvailable: true`
- SMS → `check-user` → `exists: false`
- `firebase/register` → crea client nuevo

### Caso 4 — Firebase ya vinculado

- BD: `FirebaseUid` = UID del token
- `check-user` → `exists: true`
- `firebase/login` → 200 sin duplicar

### Caso 5 — UID distinto, mismo teléfono

- BD: `FirebaseUid` = otro UID, mismo teléfono
- `firebase/login` → 409 `FIREBASE_UID_CONFLICT`

### Caso 6 — Coherencia lookup vs check-user

- Para todos los formatos de entrada: `3214291986`, `573214291986`, `+573214291986`
- `account-lookup.exists` debe igualar `firebase/check-user.exists` (mismo número, post-SMS)

---

## 9. Coordinación con mobile (post-backend)

Cuando backend esté desplegado, mobile ajustará:

1. Guardar resultado de `account-lookup` antes del SMS.
2. Si `lookup.exists == true` y `check-user.exists == false` (no debería ocurrir tras fix) → modal **“Vincular cuenta”** en lugar de “Crear cuenta”.
3. Llamar `firebase/login` directamente tras SMS cuando `check-user.exists == true`.
4. Si `suggestedFlow == legacy_password` y login falla → ofrecer pestaña correo/contraseña.

**Mobile no bloquea este trabajo; el fix crítico es backend.**

---

## 10. Prioridad y entregable

| Prioridad | Entregable |
|-----------|------------|
| **P0** | `FindClientByPhoneAsync` + usar en `LookupAccount`, `FindClientByFirebase`, `LoginFirebase`, `CheckFirebaseUser` |
| **P0** | `RegisterFirebase` anti-duplicado por teléfono |
| **P1** | Migración `Client.Phone` → E.164 |
| **P2** | Campos extra en `FirebaseCheckUserResponse` o endpoint `firebase/link` |

**Definición de hecho:** Casos 1–6 del checklist pasan en staging/prod contra la app Flutter actual sin crear cuentas duplicadas.

---

## 11. Referencias en repo Flutter

- Flujo UI: `lib/features/auth/presentation/pages/unified_auth_page.dart` (`_startPhoneSmsFlow`, `_handlePhoneVerified`)
- Cliente API: `lib/features/auth/data/datasources/auth_remote_datasource.dart`
- DTO lookup: `lib/features/auth/data/dtos/account_lookup_dto.dart`

Copiar este archivo a `Back/Ciervo-backend/docs/BACKEND-FIREBASE-PHONE-LINK-PROMPT.md` si se desea versionarlo junto al API.
