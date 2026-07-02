# Prompt Flutter — Migración obligatoria legacy → Firebase (producción)

**Backend prod:** `https://ciervo-backend-613568140358.southamerica-east1.run.app`  
**Sin cambios de backend requeridos.** El contrato ya está desplegado.  
**Documentos relacionados:** `docs/MOBILE-FIREBASE-PHONE-LINK-PROMPT.md`, `docs/MOBILE-PRODUCTION-BACKEND-CLOSURE.md`

---

## Objetivo

Refactorizar el flujo de login/registro para **mantener teléfono y email**, pero **eliminar el login por contraseña legacy en la UI principal**.

Los usuarios legacy (cuentas creadas antes de Firebase, `authProvider: "Legacy"`, `hasFirebaseUid: false`) **deben pasar obligatoriamente** por verificación Firebase (OTP). La app orquesta todo internamente; el usuario solo ve:

1. Ingresar teléfono o email
2. Pantalla de espera (“verificando tu cuenta…”)
3. Pantalla de código OTP
4. Entrada a la app

**No mostrar** términos técnicos (“Firebase”, “legacy”, “vinculación”). Usar copy de “verificación de seguridad” o “activación de cuenta”.

---

## Problema actual (bug en producción)

La app llama `FirebaseAuth.signInWithEmailAndPassword` para usuarios que tienen contraseña solo en Ciervo, no en Firebase. Eso produce:

> `The supplied auth credential is incorrect, malformed or has expired.`

Esto ocurre **antes** de llamar al backend. La contraseña legacy de Ciervo **nunca** funcionará en Firebase hasta que el usuario complete la migración OTP.

---

## Regla de oro

1. **Siempre** llamar `POST /api/auth/account-lookup` **antes** de cualquier operación Firebase.
2. **Siempre** enviar `phone` y/o `email` + `countryCode` en `check-user`, `login` y `register` (no confiar solo en el token Firebase).
3. Para usuarios con `requiresFirebaseLink: true` → usar **`firebase/login`**, nunca `signInWithEmailAndPassword` con contraseña legacy.
4. Persistir **JWT Ciervo** (`accessToken` + `refreshToken`), no el token Firebase.

---

## Máquina de estados (AuthStateMachine)

```
                    ┌─────────────────┐
                    │  AuthEntry      │
                    │  (tabs Tel/Email)│
                    └────────┬────────┘
                             │ usuario ingresa contacto
                             ▼
                    ┌─────────────────┐
                    │  AccountLookup  │  POST account-lookup
                    └────────┬────────┘
                             │
          ┌──────────────────┼──────────────────┐
          │                  │                  │
          ▼                  ▼                  ▼
   !exists            exists +            exists +
   (nuevo)         requiresFirebaseLink   hasFirebaseUid
          │           (MIGRACIÓN)              │
          │                  │                  │
          ▼                  ▼                  ▼
   Firebase OTP      MigrationSplash     Firebase OTP
          │           + Firebase OTP           │
          ▼                  │                  ▼
   firebase/register         ▼            firebase/login
          │           firebase/login             │
          └──────────────────┴──────────────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │  AuthSuccess    │  guardar JWT → Home
                    └─────────────────┘
```

---

## Endpoints

| Método | Ruta | Cuándo |
|--------|------|--------|
| POST | `/api/auth/account-lookup` | **Siempre primero** (teléfono o email) |
| POST | `/api/auth/firebase/check-user` | Tras OTP Firebase, antes de login/register |
| POST | `/api/auth/firebase/login` | Usuario existente + migración legacy |
| POST | `/api/auth/firebase/register` | Solo usuario nuevo (`!exists`) |
| POST | `/api/auth/firebase/sync-verification` | Opcional post-login |

**NO usar en flujo principal:**
- `POST /api/auth/user/login` (login clásico con contraseña)
- `FirebaseAuth.signInWithEmailAndPassword` para usuarios con `requiresFirebaseLink: true`

---

## Flujo A — Teléfono (método principal, prioridad P0)

### Paso 1: Usuario ingresa teléfono + país (CL / CO)

```http
POST /api/auth/account-lookup
Content-Type: application/json

{
  "phone": "3214291986",
  "countryCode": "CO"
}
```

### Paso 2: Decidir según respuesta

| `exists` | `requiresFirebaseLink` | `hasFirebaseUid` | Acción app |
|----------|------------------------|------------------|------------|
| `false` | — | — | OTP → `firebase/register` |
| `true` | `true` | `false` | **MigrationSplash** → OTP → `firebase/login` |
| `true` | `false` | `true` | OTP → `firebase/login` |

### Paso 3: Firebase OTP

```dart
await FirebaseAuth.instance.verifyPhoneNumber(
  phoneNumber: '+573214291986', // E.164 completo
  verificationCompleted: (credential) async { /* auto-verify si aplica */ },
  verificationFailed: (e) { /* mostrar error */ },
  codeSent: (verificationId, resendToken) {
    // navegar a OtpCodeScreen
  },
  codeAutoRetrievalTimeout: (verificationId) {},
);
```

### Paso 4: Usuario ingresa código (OtpCodeScreen)

```dart
final credential = PhoneAuthProvider.credential(
  verificationId: verificationId,
  smsCode: userEnteredCode,
);
final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
final idToken = await userCredential.user!.getIdToken();
```

### Paso 5: Check-user

```http
POST /api/auth/firebase/check-user

{
  "firebaseIdToken": "<token>",
  "phone": "3214291986",
  "countryCode": "CO"
}
```

### Paso 6: Login o register

**Si `exists == true` OR `requiresFirebaseLink == true`:**

```http
POST /api/auth/firebase/login

{
  "firebaseIdToken": "<token>",
  "phone": "3214291986",
  "countryCode": "CO"
}
```

**Si `exists == false`:**

```http
POST /api/auth/firebase/register

{
  "firebaseIdToken": "<token>",
  "phone": "3214291986",
  "countryCode": "CO",
  "name": "Nombre",
  "lastname": "Apellido",
  "countryCode": "CO"
}
```

### Paso 7: Respuesta exitosa

```json
{
  "status": true,
  "value": {
    "userId": 6,
    "accessToken": "...",
    "refreshToken": "...",
    "authAction": "link_legacy",
    "linkedLegacy": true
  }
}
```

| `authAction` | UI |
|--------------|-----|
| `link_legacy` | Toast: “¡Tu cuenta está activa!” → Home |
| `login` | Home directo |
| `register` | Onboarding → Home |

---

## Flujo B — Email (método secundario, prioridad P1)

### Paso 1: Usuario ingresa email

```http
POST /api/auth/account-lookup
{ "email": "usuario@ejemplo.com" }
```

### Paso 2: Decidir según respuesta

| Condición | Acción app |
|-----------|------------|
| `!exists` | Firebase email OTP o magic link → `firebase/register` |
| `exists && requiresFirebaseLink` | **NO pedir contraseña.** Redirigir a verificación por **teléfono** si el usuario tiene teléfono en Ciervo, o email OTP Firebase |
| `exists && hasFirebaseUid` | Firebase email OTP/password → `firebase/login` |

### Importante para legacy con email

Si `account-lookup` devuelve:

```json
{
  "exists": true,
  "authProvider": "Legacy",
  "hasFirebaseUid": false,
  "requiresFirebaseLink": true,
  "suggestedFlow": "firebase_password"
}
```

**Ignorar `suggestedFlow: firebase_password` para la UI.** Ese valor no implica que exista contraseña en Firebase. Tratar como migración obligatoria:

1. Mostrar MigrationSplash
2. Si el usuario tiene teléfono registrado → pedir teléfono y seguir **Flujo A** (recomendado)
3. Si solo tiene email → usar verificación email Firebase (`sendSignInLinkToEmail` o email OTP si está habilitado en Firebase Console)
4. Tras obtener `idToken` → `firebase/login` con `{ firebaseIdToken, email }`

**Nunca** llamar `signInWithEmailAndPassword` con la contraseña antigua de Ciervo.

---

## Pantallas nuevas / modificadas

### 1. AuthEntryScreen (modificar)

- Tabs: **Teléfono** | **Correo**
- Botón continuar → `account-lookup` (no Firebase directo)
- **Eliminar** campo contraseña en tab Correo para flujo principal
- **Eliminar** texto “Cuenta verificada con Firebase” hasta completar migración real

### 2. MigrationSplashScreen (nueva)

Mostrar **solo** cuando `requiresFirebaseLink == true`.

**Copy sugerido (español):**

- Título: *Verificando tu cuenta*
- Subtítulo: *Por tu seguridad, necesitamos confirmar tu identidad. Esto puede tardar uno o dos minutos.*
- Loader animado
- La app dispara `verifyPhoneNumber` (o email) en background mientras muestra esta pantalla
- Timeout UI: 90s → botón “Reintentar”

### 3. OtpCodeScreen (nueva o refactor)

- Título: *Ingresa el código*
- Subtítulo: *Enviamos un código de 6 dígitos a +57 *** *** **86* (enmascarar)*
- Input 6 dígitos con auto-avance
- Botón “Reenviar código” (cooldown 60s)
- Al validar → continuar secuencia check-user → login/register

### 4. AuthSuccessScreen / toast

- `link_legacy`: *¡Listo! Tu cuenta Ciervo Club está activa.*
- `register`: *¡Bienvenido a Ciervo Club!*
- `login`: navegar directo a Home

---

## Modelos Dart

```dart
enum AuthFlow {
  registerNew,
  firebaseLogin,
  legacyMigration,
}

class AccountLookupResult {
  final bool exists;
  final int? userId;
  final String? authProvider;
  final bool hasFirebaseUid;
  final bool requiresFirebaseLink;
  final String suggestedFlow;

  AuthFlow get resolvedFlow {
    if (!exists) return AuthFlow.registerNew;
    if (requiresFirebaseLink && !hasFirebaseUid) return AuthFlow.legacyMigration;
    return AuthFlow.firebaseLogin;
  }
}

class CiervoAuthResult {
  final int userId;
  final String accessToken;
  final String refreshToken;
  final String? authAction; // login | register | link_legacy
  final bool linkedLegacy;
}
```

---

## Repositorio sugerido (pseudocódigo)

```dart
class AuthRepository {
  final ApiClient _api;
  final FirebaseAuth _firebase;

  Future<AccountLookupResult> lookupByPhone(String phone, String countryCode) async {
    final res = await _api.post('/api/auth/account-lookup', {
      'phone': phone,
      'countryCode': countryCode,
    });
    return AccountLookupResult.fromJson(res['value']);
  }

  Future<AccountLookupResult> lookupByEmail(String email) async {
    final res = await _api.post('/api/auth/account-lookup', {
      'email': email.trim().toLowerCase(),
    });
    return AccountLookupResult.fromJson(res['value']);
  }

  Future<CiervoAuthResult> completeFirebaseAuth({
    required String idToken,
    required AccountLookupResult lookup,
    String? phone,
    String? email,
    String? countryCode,
    String? name,
    String? lastname,
  }) async {
    // Siempre check-user primero
    await _api.post('/api/auth/firebase/check-user', {
      'firebaseIdToken': idToken,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (countryCode != null) 'countryCode': countryCode,
    });

    final endpoint = (lookup.exists || lookup.requiresFirebaseLink)
        ? '/api/auth/firebase/login'
        : '/api/auth/firebase/register';

    final body = {
      'firebaseIdToken': idToken,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (countryCode != null) 'countryCode': countryCode,
      if (endpoint.contains('register')) ...{
        'name': name ?? '',
        'lastname': lastname ?? '',
      },
    };

    final res = await _api.post(endpoint, body);
    if (res['status'] != true) throw AuthException(res['msg']);
    return CiervoAuthResult.fromJson(res['value']);
  }
}
```

---

## Errores Firebase (cliente) — mapeo UI

| Error Firebase | Causa | Acción UI |
|----------------|-------|-----------|
| `invalid-verification-code` | Código OTP incorrecto | “Código incorrecto, intenta de nuevo” |
| `session-expired` | OTP expiró | Volver a enviar código |
| `too-many-requests` | Rate limit Firebase | “Demasiados intentos, espera unos minutos” |
| `invalid-phone-number` | Formato mal | Validar E.164 antes de enviar |
| `auth credential is incorrect` | signInWithEmailAndPassword con legacy | **No debería ocurrir** si se sigue este prompt |

## Errores backend — mapeo UI

| `msg` backend | Acción UI |
|---------------|-----------|
| `Usuario no registrado. Completa el registro Firebase.` | Cambiar a `firebase/register` |
| `Telefono ya registrado. Usa firebase/login.` | Reintentar con `firebase/login` |
| `Esta cuenta ya esta registrada. Usa firebase/login.` | `firebase/login` |
| `Esta cuenta Firebase ya esta vinculada a otro usuario.` | Pantalla soporte |
| `Usuario inactivo` | Bloquear acceso, contactar soporte |
| `Firebase Auth no esta configurado.` | Error técnico, reintentar más tarde |

---

## Casos de prueba manuales (obligatorios antes de prod)

### Caso 1 — Legacy con teléfono (Colombia)

- Email: `gabrielsantiao7151@gmail.com`
- Teléfono: `+57 321 429 1986`
- `account-lookup` debe devolver `userId` igual para ambos, `requiresFirebaseLink: true`
- Flujo: tab Teléfono → MigrationSplash → OTP → `firebase/login`
- Esperado: `authAction: link_legacy`, `linkedLegacy: true`

### Caso 2 — Usuario nuevo

- Teléfono no registrado
- `exists: false` → OTP → `firebase/register`
- Esperado: `authAction: register`

### Caso 3 — Usuario ya vinculado

- Tras Caso 1, repetir login
- `hasFirebaseUid: true`, `requiresFirebaseLink: false`
- Esperado: `authAction: login`, sin MigrationSplash

### Caso 4 — Legacy intenta email + contraseña (regresión)

- Tab Correo, email legacy, contraseña cualquiera
- **No debe** llamar `signInWithEmailAndPassword`
- Debe redirigir a migración OTP

### Caso 5 — Chile (+56)

- Repetir Caso 1 con `countryCode: "CL"` y número chileno

---

## Checklist implementación

- [ ] `account-lookup` antes de cualquier auth Firebase
- [ ] Eliminar login por contraseña legacy de UI principal
- [ ] MigrationSplash solo si `requiresFirebaseLink == true`
- [ ] OtpCodeScreen con reenvío y máscara de teléfono
- [ ] `firebase/login` para existentes y migración (no register)
- [ ] Siempre pasar `phone`/`email` + `countryCode` en check-user, login, register
- [ ] Guardar JWT Ciervo (`accessToken`, `refreshToken`)
- [ ] Leer `authAction` y `linkedLegacy` para UX post-login
- [ ] Manejar errores Firebase y backend según tablas
- [ ] Tests manuales Casos 1–5 en dispositivo real (SMS)
- [ ] No mostrar “Cuenta verificada con Firebase” si `requiresFirebaseLink == true`

---

## Secuencia rápida (teléfono — copiar en implementación)

```
1. Usuario ingresa teléfono + país
2. POST account-lookup { phone, countryCode }
3. if requiresFirebaseLink → MigrationSplash
4. Firebase verifyPhoneNumber(E.164)
5. Usuario ingresa código en OtpCodeScreen
6. signInWithCredential → getIdToken()
7. POST firebase/check-user { firebaseIdToken, phone, countryCode }
8. if exists || requiresFirebaseLink → POST firebase/login
   else → POST firebase/register (+ name, lastname)
9. Guardar accessToken + refreshToken
10. if authAction == link_legacy → toast éxito → Home
```

---

## Fuera de alcance (no implementar ahora)

- Cambios en backend
- Login clásico `POST /api/auth/user/login` en flujo principal
- Recuperación de contraseña legacy en UI (usar solo flujo OTP migración)
- Crear usuarios Firebase con contraseña generada en background

---

## Referencia backend

Contrato completo vinculación legacy: `docs/BACKEND-FIREBASE-PHONE-LINK-PROMPT.md`  
Cierre producción: `docs/MOBILE-PRODUCTION-BACKEND-CLOSURE.md` (sección 5)
