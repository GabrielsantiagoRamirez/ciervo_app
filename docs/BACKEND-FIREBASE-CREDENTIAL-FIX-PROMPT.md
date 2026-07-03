# Backend — Fix `Credential must be set` en firebase/check-user

## Error actual

```
POST /api/auth/firebase/check-user
{ "firebaseIdToken": "<JWT Firebase válido>", "email": "gabrielsantiao7151@gmail.com" }

HTTP 200
{
  "status": false,
  "msg": "Value cannot be null. (Parameter 'Credential must be set')"
}
```

## Mobile confirma token correcto

```
[AUTH] Firebase ID token kid=16d39caba861f5c602b7b64899b7aa7a1f1fc86e len=949
```

Payload JWT:

```json
{
  "iss": "https://securetoken.google.com/ciervoclub-70a3c",
  "aud": "ciervoclub-70a3c",
  "email_verified": true,
  "email": "gabrielsantiao7151@gmail.com"
}
```

**No es bug de Flutter.** El backend falla al verificar el token o al obtener claves públicas de Google.

---

## Causa probable

Tras los fixes de `kid` y `ValidAudience`, el verificador intenta:

1. Resolver `IssuerSigningKey` con el `kid` del JWT, **o**
2. Usar `FirebaseAuth.DefaultInstance` / `GoogleCredential` **sin credenciales inicializadas** en Cloud Run

`Credential must be set` es típico de:

- `GoogleCredential` / `Google.Apis.Auth` sin `GOOGLE_APPLICATION_CREDENTIALS`
- `FirebaseApp.Create()` sin `AppOptions` con credencial
- Cliente HTTP de Google APIs creado sin credential al descargar certificados

---

## Fix recomendado (C# / Cloud Run)

### Opción A — Verificar JWT con claves públicas (sin service account para verify)

```csharp
// Descargar y cachear:
// https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com

var validationParameters = new TokenValidationParameters
{
    ValidateIssuer = true,
    ValidIssuer = $"https://securetoken.google.com/{projectId}",
    ValidateAudience = true,
    ValidAudience = projectId,
    ValidateLifetime = true,
    ValidateIssuerSigningKey = true,
    IssuerSigningKeyResolver = (token, securityToken, kid, parameters) =>
    {
        var keyId = FirebaseJwtHelper.ExtractKidFromJwt(token); // fix raw header
        return ResolveGoogleSigningKeys(keyId); // HttpClient público, SIN GoogleCredential
    },
};
```

`ResolveGoogleSigningKeys` debe usar `HttpClient` normal a la URL de certificados de Google — **no requiere** service account solo para leer claves públicas.

### Opción B — Firebase Admin SDK

```csharp
if (FirebaseApp.DefaultInstance == null)
{
    FirebaseApp.Create(new AppOptions
    {
        Credential = GoogleCredential.GetApplicationDefault(),
        ProjectId = "ciervoclub-70a3c",
    });
}

// Verificar:
await FirebaseAuth.DefaultInstance.VerifyIdTokenAsync(firebaseIdToken);
```

En **Cloud Run**, asegurar que la service account del servicio tenga permisos y que `GOOGLE_APPLICATION_CREDENTIALS` o ADC estén disponibles.

---

## Checklist

- [ ] `ValidAudience = "ciervoclub-70a3c"`
- [ ] `ValidIssuer = "https://securetoken.google.com/ciervoclub-70a3c"`
- [ ] `kid` leído del segmento raw del JWT
- [ ] Resolver de signing keys **no** depende de `GoogleCredential` vacío
- [ ] O `FirebaseApp` inicializado en startup con ADC
- [ ] Test: `firebase/check-user` + `firebase/login` → `link_legacy` userId 6

---

## Historial errores backend (misma ruta)

| Deploy | Error | Estado |
|--------|-------|--------|
| pre-00140 | `propertyName` / falta kid | Fix raw header |
| 00140+ | `IDX10206` audience empty | Fix ValidAudience |
| actual | `Credential must be set` | Fix signing keys o FirebaseApp init |

Mobile **no requiere cambios** de contrato.
