# Prompt para Backend — Migración legacy por **correo** (sin teléfono)

> **Estado (jul 2026):** **Resuelto.** Deploy `ciervo-backend-00140-fnt` (commit `45b7a6b`). `FirebaseJwtHelper.ExtractKidFromJwt` lee `kid` del segmento raw del JWT. Mobile usa `getIdTokenResult(forceRefresh: true)` — ver `docs/MOBILE-FIREBASE-EMAIL-LINK-PROMPT.md`.

## Contexto

La app móvil separa dos flujos de autenticación:

| Tab app | Método Firebase | Payload backend |
|---------|-----------------|-----------------|
| **Teléfono** | SMS OTP (`sign_in_provider: phone`) | `{ firebaseIdToken, phone, countryCode? }` |
| **Correo** | Email + contraseña + verificación email Firebase | `{ firebaseIdToken, email }` |

Usuario de prueba legacy:

- `userId`: 6
- `email`: gabrielsantiao7151@gmail.com
- `phone` en BD: +573214291986
- `authProvider`: Legacy
- `hasFirebaseUid`: false
- `requiresFirebaseLink`: true

---

## Preguntas para el equipo backend

### 1. ¿`firebase/login` acepta solo email para vincular legacy?

Tras que el usuario:

1. Valida contraseña legacy con `POST /api/auth/user/login` (sin guardar JWT en app)
2. Crea cuenta Firebase con `createUserWithEmailAndPassword`
3. Confirma email en Firebase (`emailVerified: true`)
4. Obtiene `firebaseIdToken` con `sign_in_provider: password`

¿El backend vincula correctamente con este body?

```json
POST /api/auth/firebase/check-user
{
  "firebaseIdToken": "<JWT con email_verified>",
  "email": "gabrielsantiao7151@gmail.com"
}

POST /api/auth/firebase/login
{
  "firebaseIdToken": "<JWT con email_verified>",
  "email": "gabrielsantiao7151@gmail.com"
}
```

**Sin** enviar `phone` ni `countryCode`.

Respuesta esperada en `login`:

```json
{
  "status": true,
  "value": {
    "accessToken": "...",
    "refreshToken": "...",
    "authAction": "link_legacy",
    "linkedLegacy": true
  }
}
```

### 2. Error actual `propertyName` null

Con payload teléfono (flujo SMS), la app recibía:

```json
{
  "status": false,
  "msg": "Value cannot be null. (Parameter 'propertyName')"
}
```

En:

- `POST /api/auth/firebase/check-user`
- `POST /api/auth/firebase/login`

Con body:

```json
{
  "firebaseIdToken": "<JWT válido phone auth>",
  "phone": "3214291986",
  "countryCode": "CO"
}
```

¿Cuál es el campo faltante? ¿El DTO espera PascalCase (`FirebaseIdToken`, `Phone`, `CountryCode`)? ¿O hay un bug en la búsqueda/vinculación por teléfono?

### 3. Coherencia `account-lookup` vs `check-user`

`account-lookup` con `{ phone: "3214291986", countryCode: "CO" }` devuelve:

```json
{
  "exists": true,
  "userId": 6,
  "requiresFirebaseLink": true,
  "suggestedFlow": "firebase_phone"
}
```

Tras SMS Firebase exitoso, ¿`firebase/check-user` debe devolver `exists: true` con el mismo criterio de búsqueda de teléfono?

### 4. ¿`user/login` devuelve el teléfono del usuario?

La app usa `POST /api/auth/user/login` solo para validar credenciales legacy (email + password) **sin** persistir sesión.

¿La respuesta incluye `phone` / `phoneNumber` del usuario? Si sí, ¿en qué campo exacto del JSON?

---

## Contrato deseado (mobile)

### Flujo correo (tab Correo)

```
account-lookup(email)
  → requiresFirebaseLink → pedir solo contraseña legacy
  → user/login (validar, no guardar JWT)
  → Firebase createUser + sendEmailVerification
  → usuario confirma email en bandeja
  → firebase/check-user { firebaseIdToken, email }
  → firebase/login { firebaseIdToken, email }
  → authAction: link_legacy → Home
```

**No pedir teléfono en UI del tab Correo.**

### Flujo teléfono (tab Teléfono)

```
account-lookup(phone, countryCode)
  → requiresFirebaseLink → SMS Firebase
  → firebase/check-user { firebaseIdToken, phone, countryCode }
  → firebase/login { firebaseIdToken, phone, countryCode }
  → authAction: link_legacy → Home
```

---

## Casos de prueba que necesitamos pasar

| # | Flujo | Resultado |
|---|-------|-----------|
| 1 | Email legacy → verificar correo Firebase → login | 200, `link_legacy`, JWT Ciervo |
| 2 | Teléfono legacy → SMS → login | 200, `link_legacy`, `FirebaseUid` guardado |
| 3 | Email ya vinculado (`hasFirebaseUid: true`) | `firebase/login` directo |
| 4 | Teléfono no registrado | `exists: false` → register |

---

## Nota Firebase (no backend)

En desarrollo aparece bloqueo SMS:

```
error 17010: We have blocked all requests from this device due to unusual activity
```

Esto es rate-limit de Firebase Phone Auth por muchos intentos de prueba. No afecta el flujo por correo.
