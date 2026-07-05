# Fix backend — `firebase/login` con cuenta email + teléfono

**Fecha:** 2026-07-05  
**Estado:** Implementado en `Business/Services/AuthService.cs` (pendiente deploy Cloud Run)

---

## Problema

Usuario `+57 3214291986` (userId **6**, email `gabrielsantiao7151@gmail.com`):

1. SMS Firebase OK → UID token: `cXZ9Cnel9IYpWypbKEhzwiDuvm33`
2. `firebase/check-user` → `exists: true`, `suggestedFlow: firebase_login`
3. `firebase/login` fallaba:
   - Solo token → `"Usuario no registrado…"`
   - Con teléfono → `"Esta cuenta ya esta vinculada a otro usuario Firebase."`

**Causa:** `Client.FirebaseUid` en BD podía ser distinto al UID del token SMS aunque el teléfono/correo coincidieran. `EnsureFirebaseUidLinkable` rechazaba en lugar de reconciliar.

---

## Fix aplicado

1. **`EnsureFirebaseUidLinkable`**: si teléfono o email del token coinciden con el cliente, actualiza el UID stale en lugar de error.
2. **`FindClientByContact`**: búsqueda flexible de teléfono (E.164, nacional, variantes CO/CL).
3. **`BuildFirebaseCheckUserResponse`**: devuelve `client.FirebaseUid` real (no siempre el del token).
4. **Tests:** `AuthFirebaseLinkTests` — reconciliación UID stale, check-user con UID almacenado.

---

## Mobile (complemento)

- Login post-SMS intenta: token-only → E.164 → nacional → **email del check-user**
- Guarda `checkUserEmail` del backend para reintentos

---

## Deploy y prueba

1. Desplegar backend a Cloud Run
2. En Android: logout → login SMS `+573214291986`
3. Verificar logs `[AUTH] firebase/login intento` → respuesta 200 con JWT
4. Repetir login por **correo** (misma cuenta Firebase)

---

## Checklist

- [x] Tests backend `AuthFirebaseLinkTests` (10/10)
- [x] Tests mobile `firebase_login_attempts_test.dart`
- [ ] Deploy backend prod
- [ ] QA userId 6 SMS + email
