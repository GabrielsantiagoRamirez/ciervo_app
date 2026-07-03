# Backend — Fix `IDX10206: Unable to validate audience`

## Error en prod (post-deploy kid fix)

```
POST /api/auth/firebase/check-user
POST /api/auth/firebase/login

HTTP 200
{
  "status": false,
  "msg": "IDX10206: Unable to validate audience. The 'audiences' parameter is empty."
}
```

## Causa

`TokenValidationParameters` de `JwtSecurityTokenHandler.ValidateToken` **no tiene `ValidAudience`** (o `ValidAudiences` está vacío).

Los ID tokens de Firebase **sí traen** `aud` en el payload:

```json
{
  "iss": "https://securetoken.google.com/ciervoclub-70a3c",
  "aud": "ciervoclub-70a3c",
  "sub": "fxSZGfFdoMOahQUAhnmQ4JeszDK2",
  "email": "gabrielsantiao7151@gmail.com",
  "email_verified": true
}
```

Mobile confirma en log:

```
[AUTH] Firebase ID token kid=16d39caba861f5c602b7b64899b7aa7a1f1fc86e len=949
```

**No es bug de Flutter.** Es configuración incompleta del verificador JWT en backend.

---

## Fix requerido (C#)

En `FirebaseTokenVerifier` / `FirebaseJwtHelper` (donde se valida el ID token):

```csharp
private const string FirebaseProjectId = "ciervoclub-70a3c";

var validationParameters = new TokenValidationParameters
{
    ValidateIssuer = true,
    ValidIssuer = $"https://securetoken.google.com/{FirebaseProjectId}",

    ValidateAudience = true,
    ValidAudience = FirebaseProjectId,  // ← OBLIGATORIO. Sin esto → IDX10206

    ValidateLifetime = true,
    ValidateIssuerSigningKey = true,
    IssuerSigningKeyResolver = (token, securityToken, kid, parameters) =>
    {
        // resolver claves públicas Google con kid del header raw (ya corregido)
        ...
    },
};
```

**Alternativa:** leer `FirebaseProjectId` de `IConfiguration` / env `FIREBASE_PROJECT_ID`, pero **nunca** dejar `ValidAudience` null ni lista vacía.

---

## Test unitario sugerido

```csharp
[Fact]
public void VerifyFirebaseIdToken_AcceptsCiervoClubAudience()
{
    var token = "<JWT real o mock con aud=ciervoclub-70a3c>";
    var result = _verifier.Verify(token);
    Assert.True(result.IsValid);
}
```

Reproducir fallo actual: `ValidAudience = null` + token con `aud` → `IDX10206`.

---

## Checklist deploy

- [ ] `ValidAudience = "ciervoclub-70a3c"` en verificación Firebase
- [ ] `ValidIssuer = "https://securetoken.google.com/ciervoclub-70a3c"`
- [ ] `kid` sigue leyéndose del segmento raw del JWT (fix 00140)
- [ ] `firebase/check-user` + `firebase/login` con `{ firebaseIdToken, email }` → `link_legacy` para userId 6

---

## Payload mobile (sin cambios)

```json
{
  "firebaseIdToken": "<ID token Firebase>",
  "email": "gabrielsantiao7151@gmail.com"
}
```

Proyecto Firebase app + backend: **`ciervoclub-70a3c`**
