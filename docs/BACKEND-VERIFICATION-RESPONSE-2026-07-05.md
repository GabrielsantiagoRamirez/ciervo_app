# Respuesta Backend — Verificación contratos Mobile (2026-07-05)

Fuente: equipo backend CIERVO.  
Base prod: `https://ciervo-backend-613568140358.southamerica-east1.run.app`

## Estado P0

| Área | Backend | Ajuste mobile aplicado |
|------|---------|------------------------|
| User search | `value.items[]` paginado | Ya parseaba `items` |
| By-phones | Máx 100/lote | Batches de 100 en `ContactsMatcher` |
| Media upload | Requiere `ownerType`, `ownerId`, `mediaType` | `MediaRepository` envía los 4 campos |
| KYC `/me` | `documentNumberMasked` | Parser acepta masked |
| Wallet block | `blockedAt` + `statusId=0` | DTO corregido (ya no usa `statusId===2`) |
| Family card | Plana: `cardId`, `threeDsRedirectUrl` | Mobile envía `brand+last4+holder` y parsea respuesta plana |
| Promociones | 404 | Fallback local en mobile |

## Estado P1 — Promociones Gold (2026-07-05)

Endpoints implementados en backend:

- `GET /api/promotions/current`
- `POST /api/promotions/gold-trial/claim` (con `idempotencyKey`)

Mobile integrado con API real (sin fallback local en 404). Tras claim refresca `MembershipCubit`.
