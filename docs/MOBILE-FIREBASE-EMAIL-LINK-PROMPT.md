# Mobile — Migración legacy por correo (Flujo B.1)

> **Estado (jul 2026):** Backend desplegado (`ciervo-backend-00140-fnt`, commit `45b7a6b`). Fix `FirebaseJwtHelper.ExtractKidFromJwt` — `JwtSecurityTokenHandler.ReadJwtToken` descartaba `kid` del header Firebase. Mobile ya enviaba ID token correcto.

## Flujo Correo legacy (sin teléfono en UI)

```
1. POST /api/auth/account-lookup { email }
   → requiresFirebaseLink: true

2. POST /api/auth/user/login { user/email, password }
   → Solo validar credenciales Ciervo (NO guardar JWT como sesión final)

3. Firebase createUserWithEmailAndPassword (o signIn si email-already-in-use)
   → sendEmailVerification()

4. Usuario confirma enlace en bandeja → "Ya confirmé"

5. reloadUser() + getIdTokenResult(forceRefresh: true)
   → Log debug: [AUTH] Firebase ID token kid=... len=...

6. POST /api/auth/firebase/check-user { firebaseIdToken, email }

7. POST /api/auth/firebase/login { firebaseIdToken, email }
   → authAction: link_legacy, linkedLegacy: true

8. Guardar accessToken Ciervo → Home
```

**No enviar** `phone` ni `countryCode` en pasos 6–7 para migración por correo.

## Implementación en esta app

| Paso | Archivo |
|------|---------|
| UI tabs Correo/Teléfono | `lib/features/auth/presentation/pages/unified_auth_page.dart` |
| Flujo B.1 cubit | `lib/features/auth/presentation/cubit/firebase_auth_cubit.dart` |
| `validateLegacyCredentials` (sin save JWT) | `lib/features/auth/data/repositories/auth_repository_impl.dart` |
| Payload API | `lib/features/auth/data/datasources/auth_remote_datasource.dart` |
| `getIdTokenResult` + validación `kid` | `lib/core/firebase/firebase_auth_service.dart` |
| Decoder header JWT | `lib/core/firebase/firebase_id_token.dart` |
| Pantalla "Ya confirmé" | `lib/features/auth/presentation/widgets/email_verification_pending_screen.dart` |

## Checklist QA

- [ ] `account-lookup` con email legacy → pantalla contraseña (sin campo teléfono)
- [ ] `user/login` valida pero no deja sesión Ciervo activa hasta `firebase/login`
- [ ] Tras confirmar email, log muestra `kid=16d39caba...` (o similar)
- [ ] `check-user` → `exists: true` o coherente con lookup
- [ ] `firebase/login` → `authAction: link_legacy`
- [ ] Home carga sin 401 en `/notifications/badges`
- [ ] Tab Teléfono sigue siendo flujo aparte (SMS OTP); botón "Soy hijo/a" es login PIN hijo

## Usuario de prueba

- email: `gabrielsantiao7151@gmail.com`
- userId: 6
- `requiresFirebaseLink: true`, `hasFirebaseUid: false`

## Errores conocidos (no mobile)

| Error | Causa |
|-------|-------|
| `IDX10206` audience empty | Backend sin `ValidAudience=ciervoclub-70a3c` → ver `docs/BACKEND-FIREBASE-AUDIENCE-FIX-PROMPT.md` |
| SMS error 17010 | Firebase bloqueó el dispositivo por muchos intentos → usar tab Correo |
| 401 badges al reabrir app | JWT Ciervo viejo en storage → `logout()` al iniciar migración limpia sesión |
