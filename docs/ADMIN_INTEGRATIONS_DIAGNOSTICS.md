# ADMIN_INTEGRATIONS_DIAGNOSTICS

**Objetivo:** panel administrativo muestra salud de integraciones **sin exponer secretos**.  
**Alcance:** API Admin + Panel Web.  
**Fecha:** 2026-07-19.

## Qué mostrar (seguro)

| Integración | Señales visibles |
|-------------|------------------|
| SMTP / Email | `configured: true/false`, `host` (solo hostname), último envío OK/fail (timestamp), sin user/password. |
| Mercado Pago CO | `configured`, `currency=COP`, `publicKeyConfigured` (bool), `webhookSecretConfigured` (bool), último webhook OK. |
| Mercado Pago CL | Igual para CL / CLP. |
| Workers / Outbox | cola pendiente, processing, failed, edad del evento más viejo, instancias activas. |
| Firebase Admin | `projectId` (no service account JSON), `initialized`. |

## Qué nunca devolver

- Access tokens MP
- Webhook secrets
- App passwords SMTP
- Connection strings
- Service account JSON / private keys
- OTP / códigos de recovery
- URLs de checkout con tokens sensibles en query (si aplica, enmascarar)

## Endpoint sugerido

```
GET /api/admin/integrations/diagnostics
```

Autorización: rol SuperAdmin / OwnerOps.

### Ejemplo de response (ilustrativo)

```json
{
  "email": {
    "configured": true,
    "host": "smtp.gmail.com",
    "port": 587,
    "enableSsl": true,
    "lastSuccessAt": "2026-07-19T12:00:00Z",
    "lastErrorCode": null
  },
  "payments": {
    "CO": {
      "accessTokenConfigured": true,
      "publicKeyConfigured": true,
      "webhookSecretConfigured": true,
      "currency": "COP"
    },
    "CL": {
      "accessTokenConfigured": true,
      "publicKeyConfigured": true,
      "webhookSecretConfigured": true,
      "currency": "CLP"
    }
  },
  "workers": {
    "pending": 3,
    "processing": 1,
    "failed": 0,
    "oldestPendingAgeSeconds": 12
  }
}
```

## Criterios de aceptación

- [ ] El panel muestra estado de integraciones.
- [ ] La respuesta **no** incluye secretos ni valores de tokens.
- [ ] Un admin puede ver si Chile/Colombia están configurados sin ver las keys.
