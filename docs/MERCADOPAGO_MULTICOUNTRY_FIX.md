# MERCADOPAGO_MULTICOUNTRY_FIX

**Objetivo:** recargas y cobros por país (`CO`/`CL`) con credenciales, moneda y webhooks aislados.  
**Alcance:** backend Payments + Wallet. Repo Flutter solo consume API.  
**Fecha:** 2026-07-19.

## Causa raíz (Chile)

El backend identifica al usuario como `CL` y puede crear montos en `CLP`, pero las **credenciales / preference / config global** siguen apuntando a vendedor **Colombia** o a un fallback `CO` cuando falta `CL`.  
La app móvil **no elige Access Token**; abre `checkoutUrl` del backend.

## Principios

1. Resolver país **solo** desde perfil autenticado (o tarjeta/wallet vinculada), nunca desde query libre del cliente.
2. Seleccionar `Payments__Countries__{CC}__AccessToken` / `PublicKey` / `WebhookSecret` / `Currency`.
3. **Prohibido** fallback silencioso `CL` → token `CO`.
4. Idempotencia por `idempotencyKey` + `intentId`: una recarga no se acredita dos veces.
5. Webhooks verifican firma/secreto del **país de la preference / payment**.

## Flujo de recarga Wallet

```
POST /api/wallet/cards/{cardId}/recharge-intents
Body: { amount, currency, idempotencyKey, description }
```

### Response `value` (contrato)

```json
{
  "paymentId": "...",
  "checkoutUrl": "https://www.mercadopago.cl/...",
  "countryCode": "CL",
  "currency": "CLP",
  "status": "pending"
}
```

Aliases aceptables: `intentId` ≡ `paymentId`; `initPoint` solo si `checkoutUrl` vacío.

### Post-pago

- `GET /api/wallet/recharge-intents/{intentId}`
- `POST /api/wallet/recharge-intents/{intentId}/sync`
- Acreditación **únicamente** tras confirmación MP + transición de estado atómica.

## Endpoints a endurecer

| Path | Cambio |
|------|--------|
| `POST /api/wallet/cards/{id}/recharge-intents` | Credenciales país del usuario; currency coherente. |
| `GET/POST .../recharge-intents/{id}` (+ `/sync`) | Estado autoritativo; sin doble crédito. |
| Webhook MP | Secreto por país; external_reference → intent. |
| `GET /api/wallet/mercadopago/config` | Marcar como **legacy CO** o devolver config del país del caller; no usarla como global. |
| `GET /api/payments/config` | Config del país del usuario autenticado. |

## Variables por país (sin valores reales)

```
Payments__Countries__CO__AccessToken=<Secret Manager>
Payments__Countries__CO__PublicKey=<Secret Manager o configuración>
Payments__Countries__CO__WebhookSecret=<Secret Manager>
Payments__Countries__CO__Currency=COP

Payments__Countries__CL__AccessToken=<Secret Manager>
Payments__Countries__CL__PublicKey=<Secret Manager o configuración>
Payments__Countries__CL__WebhookSecret=<Secret Manager>
Payments__Countries__CL__Currency=CLP
```

## Solución aplicada (especificación)

1. `IPaymentCountryResolver` → `countryCode` desde usuario.
2. `IMercadoPagoClientFactory` → cliente HTTP con Access Token del país.
3. Crear preference en moneda del país; `checkoutUrl` del sitio MP correspondiente.
4. Persistir en intent: `countryCode`, `currency`, `preferenceId`, `checkoutUrl`.
5. Webhook: detectar país (metadata / preference / payment account) → secreto correcto.
6. Acreditación: transacción DB + unique constraint / estado terminal único.
7. Tests: CL nunca usa token CO; CO sigue en COP; doble webhook no duplica saldo.

## Criterios de aceptación

- [ ] Usuario chileno crea recarga en `CLP`.
- [ ] Recarga CL usa credenciales vendedor Chile.
- [ ] Operación CL **nunca** usa token colombiano como fallback.
- [ ] Colombia continúa en `COP`.
- [ ] Webhooks con secreto correcto por país.
- [ ] Una recarga no se acredita dos veces.
- [ ] App abre únicamente `checkoutUrl` del response (validación host en cliente).
