# CIERVO Family Payment API — Tarjeta del tutor (Kids respaldo)

Contrato para pagos CIERVO Kids con tarjeta Visa/Mastercard tokenizada del padre/madre.

**Prefijo base:** `/api/family` y `/api/kids` (compatible con rutas legacy `/api/guardians`, `/api/parents/approvals`).

## Seguridad de tarjeta

- Nunca se persiste PAN, CVV ni número completo.
- Solo: `cardToken` (referencia MP), `brand`, `last4`, `status`, `providerReference`, metadata segura.

## Métodos de pago del tutor

| Método | Ruta | Auth |
|--------|------|------|
| POST | `/api/family/payment-methods/cards` | ClientOnly |
| POST | `/api/family/payment-methods/cards/{cardId}/verify` | ClientOnly |
| GET | `/api/family/payment-methods/cards` | ClientOnly |
| DELETE | `/api/family/payment-methods/cards/{cardId}` | ClientOnly |
| POST | `/api/family/payment-methods/cards/{cardId}/set-primary` | ClientOnly |
| POST | `/api/family/payment-methods/cards/{cardId}/set-backup` | ClientOnly |
| PATCH | `/api/family/payment-methods/cards/{cardId}/alias` | ClientOnly |
| POST | `/api/family/payment-methods/cards/{cardId}/freeze` | ClientOnly |
| POST | `/api/family/payment-methods/cards/{cardId}/unfreeze` | ClientOnly |

### Roles de tarjeta (vista Métodos de pago)

- **Principal** → `POST .../set-primary` (una sola por tutor; limpia primary previa).
- **Respaldo** → `POST .../set-backup` (una sola por tutor; limpia backup previa).
- **Editar alias** → `PATCH .../alias` body `{ "alias": "Tarjeta escolar" }` (máx 60; `null`/vacío limpia).
- **Congelar** → `POST .../freeze` body opcional `{ "reason": "..." }`; reactivar con `POST .../unfreeze`.

Response de list/detalle incluye `isPrimary`, `isBackup`, `alias`, `isFrozen`, `status` (`PENDINGVERIFICATION` | `ACTIVE` | `FROZEN` | `REMOVED`).

### POST cards — request

```json
{
  "cardToken": "tok_mp_xxx",
  "brand": "VISA",
  "last4": "4242",
  "expiryMonth": 12,
  "expiryYear": 2030,
  "holderName": "Maria Lopez",
  "idempotencyKey": "add-card-1"
}
```

### Response

```json
{
  "status": true,
  "value": {
    "cardId": "FPC_A1B2C3D4E5F6",
    "brand": "VISA",
    "last4": "4242",
    "status": "ACTIVE",
    "isPrimary": true,
    "isBackup": false,
    "alias": null,
    "isFrozen": false,
    "threeDsRedirectUrl": null
  }
}
```

## Configuración por menor

| Método | Ruta |
|--------|------|
| POST | `/api/family/kids/{kidId}/payment-source` |
| PUT | `/api/family/kids/{kidId}/limits` |
| PUT | `/api/family/kids/{kidId}/merchant-rules` |
| PUT | `/api/family/kids/{kidId}/schedule` |
| PUT | `/api/family/kids/{kidId}/auto-payment` |
| PUT | `/api/family/kids/{kidId}/approval-rules` |
| PUT | `/api/family/kids/{kidId}/geofence` |
| POST | `/api/kids/{kidId}/freeze` |
| POST | `/api/kids/{kidId}/unfreeze` |

### payment-source

```json
{
  "cardId": "FPC_A1B2C3D4E5F6",
  "approvalMode": "AUTO_APPROVAL",
  "perTransactionLimit": 50000,
  "dailyLimit": 100000,
  "monthlyLimit": 500000,
  "currency": "COP"
}
```

`approvalMode`: `AUTO_APPROVAL` | `MANUAL_APPROVAL`

## Flujo de pago del menor

| Método | Ruta | Auth |
|--------|------|------|
| POST | `/api/kids/payment/request` | ClientOrKid |
| POST | `/api/kids/payment/validate` | ClientOrKid |

### request

```json
{
  "kidId": 5,
  "merchantId": 12,
  "merchantName": "Cafe Central",
  "amount": 15000,
  "currency": "COP",
  "paymentMethod": "kids_card",
  "latitude": 4.65,
  "longitude": -74.05,
  "deviceId": "device-abc",
  "idempotencyKey": "pay-req-unique-1"
}
```

### Estados de pago

`REQUESTED`, `VALIDATED`, `PENDING_PARENT`, `APPROVED`, `REJECTED`, `PROCESSING`, `COMPLETED`, `DECLINED`, `CANCELLED`, `EXPIRED`, `REQUIRES_3DS`

### Fuentes de fondos

- `KidsWallet` — saldo tarjeta Kids (sin pasar por tarjeta del tutor)
- `ParentCard` — cobro directo MP; **no acredita wallet Kids**

## Aprobaciones del tutor

| Método | Ruta |
|--------|------|
| GET | `/api/family/payment-approvals` |
| POST | `/api/family/payment-approvals/{approvalId}/approve` |
| POST | `/api/family/payment-approvals/{approvalId}/reject` |

Push al tutor con tipo `payment.pending_parent` (botones Aprobar/Rechazar en app).

## Operaciones de pago

| Método | Ruta |
|--------|------|
| POST | `/api/payments/charge-parent-card` |
| GET | `/api/family/payments` |
| GET | `/api/kids/{kidId}/payments` |
| GET | `/api/payments/{paymentId}` |
| POST | `/api/payments/{paymentId}/cancel` |
| POST | `/api/webhooks/payment-authorized` |

## Eventos de notificación

`payment.requested`, `payment.pending_parent`, `payment.approved`, `payment.rejected`, `payment.authorized`, `payment.declined`, `payment.completed`, `payment.refunded`, `card.added`, `card.removed`, `limits.updated`, `rules.updated`

Persistidos en `PAYMENT_NOTIFICATION_EVENT` + FCM vía `INotificationService`.

## Idempotencia

- `KidPaymentRequest.idempotencyKey` único
- `ParentPaymentApproval.chargeIdempotencyKey` evita doble cobro
- Estados terminales no re-ejecutan cobro

## Errores comunes

| Código lógico | Mensaje |
|---------------|---------|
| INSUFFICIENT_BALANCE | Sin saldo Kids y sin tarjeta tutor |
| MERCHANT_BLOCKED | Comercio bloqueado |
| LIMIT_AMOUNT | Límite diario/mensual/transacción excedido |
| CARD_BLOCKED | Tarjeta Kids o tutor congelada |
| OUTSIDE_SCHEDULE | Fuera de horario permitido |

## Migración

Aplicar: `20260701193000_FamilyPaymentParentCardPhase`

## Compatibilidad

- Flujos existentes QR (`/api/kids/payments/scan`), wallet Kids, pay-for-me, NFC y delivery **no modificados** en contrato.
- QR confirm con saldo insuficiente intenta fallback a tarjeta del tutor si está configurada.

## Producción pendiente

- Credenciales MP producción + 3DS obligatorio según país
- Webhook MP unificado con `payment-authorized`
- Panel admin: visibilidad de `PAYMENT_AUDIT_LOG`
- Pruebas E2E con SDK MP en mobile
