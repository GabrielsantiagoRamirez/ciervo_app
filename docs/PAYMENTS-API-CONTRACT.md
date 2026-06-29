# Contrato API Pagos CIERVO — Single Source of Truth

> **Este documento es la fuente oficial del módulo de pagos.** Flutter Mobile y Panel Web deben implementarse consultando únicamente este contrato. Cualquier cambio backend no reflejado aquí se considera implementación incompleta.

**Estado:** Contrato **listo para implementación** en Flutter Mobile y Panel Web (membresías multi-país, conversión automática, pagos MP, admin tasas).

**Base URL prod:** `https://ciervo-backend-613568140358.southamerica-east1.run.app`  
**Proveedor activo:** Mercado Pago (Checkout Preferences) — por país según config  
**Moneda base membresías:** USD (fuente de verdad comercial)  
**Moneda de cobro membresías:** local por país (CO→COP, CL→CLP, MX→MXN, PE→PEN, US→USD)

---

## Índice

1. [PaymentIntent unificado](#1-paymentintent-unificado)
2. [Mobile — Cliente](#2-mobile--cliente)
3. [Membresías (USD base + cobro local por país)](#3-membresías-usd-base--cobro-local-por-país)
4. [Webhooks Mercado Pago](#4-webhooks-mercadopago)
5. [Rutas de retorno post-pago](#5-rutas-de-retorno-post-pago)
6. [Panel dueño/staff](#6-panel-dueñostaff)
7. [Panel SuperAdmin](#7-panel-superadmin)
8. [Wallet / Delivery / Reservas / Eventos](#8-otros-flujos-de-pago)
9. [Recibos, facturación, comisiones, liquidaciones](#9-recibos-facturación-comisiones-liquidaciones)
10. [Seguridad](#10-seguridad)
11. [Errores comunes](#11-errores-comunes)
12. [Migraciones requeridas](#12-migraciones-requeridas)
13. [Variables de entorno](#13-variables-de-entorno)
14. [Mapa Flutter vs Panel](#14-mapa-flutter-vs-panel)

---

## 1. PaymentIntent unificado

Todos los flujos MP convergen en `PAYMENT_INTENT`.

| Campo API | Origen DB | Notas |
|-----------|-----------|-------|
| `paymentIntentId` | `ID` | |
| `type` | `TYPE` | slug string |
| `userId` | `USER_ID` | |
| `amount` | `AMOUNT` | **Siempre calculado en backend** para membership/delivery/booking |
| `currency` | `CURRENCY` | Moneda local de cobro (según país del usuario/comercio) |
| `status` | `STATUS` | slug (ver estados) |
| `providerPreferenceId` | `MetadataJson.preferenceId` | |
| `providerPaymentId` | `PAYMENT_TRANSACTION.PROVIDER_TRANSACTION_ID` | |
| `checkoutUrl` | `MetadataJson.checkoutUrl` | |
| `externalReference` | `EXTERNAL_REFERENCE` | clave webhook |
| `membershipPricing` | `MetadataJson` | solo membership (USD base + moneda local + tasa + país) |
| `paidAt` | `SUCCEEDED_AT` | |

### Tipos (`type`)

| Slug | Enum | Uso |
|------|------|-----|
| `wallet_recharge` | 6 | Recarga wallet |
| `membership_subscription` | 8 | Membresía cliente o comercio |
| `delivery_order` | 7 | Pago pedido delivery |
| `booking` | 1 | Reserva conectada |
| `event_ticket` | 2 | Ticket evento |

### Estados (`status`)

| Slug | Significado |
|------|-------------|
| `pending` | Pending / RequiresExternalAction |
| `processing` | Processing |
| `approved` | Succeeded / MP `approved` |
| `rejected` | Failed |
| `cancelled` | Cancelled / refunded |
| `expired` | Expired |

### External references (webhook)

| Tipo | Patrón |
|------|--------|
| Wallet | `wallet-recharge-{intentId}` |
| Membership | `membership-subscribe-{intentId}` |
| Delivery | `delivery-order-{orderId}-intent-{intentId}` |
| Booking | `booking-pay-{intentId}` |

### Transiciones de estado

```
pending → processing → approved
pending → rejected
pending → cancelled
pending → expired
approved → (idempotente, no re-acredita)
```

---

## 2. Mobile — Cliente

**Auth:** `Authorization: Bearer {token}` — policy `ClientOnly` salvo endpoints públicos.

### Config MP

```http
GET /api/payments/config
```

```json
{
  "status": true,
  "value": {
    "provider": "MercadoPago",
    "enabled": true,
    "isSandbox": false,
    "publicKey": "APP_USR-...",
    "currency": "COP",
    "successUrl": "https://ciervo-backend-.../api/payments/return/success",
    "failureUrl": "https://ciervo-backend-.../api/payments/return/failure",
    "pendingUrl": "https://ciervo-backend-.../api/payments/return/pending"
  }
}
```

### Recarga wallet

```http
POST /api/payments/intents
```

```json
{
  "type": "wallet_recharge",
  "amount": 5000,
  "currency": "COP",
  "walletCardId": 7,
  "idempotencyKey": "uuid-v4"
}
```

> Mobile **sí** envía `amount` para recargas. **No** envía amount para membresías.

### Delivery / Booking

```json
{ "type": "delivery_order", "deliveryOrderId": 34, "idempotencyKey": "uuid-v4" }
{ "type": "booking", "bookingId": 10, "businessId": 2, "idempotencyKey": "uuid-v4" }
```

### Response intent (común)

```json
{
  "status": true,
  "value": {
    "paymentIntentId": 80,
    "type": "wallet_recharge",
    "status": "pending",
    "checkoutUrl": "https://www.mercadopago.com.co/checkout/...",
    "providerPreferenceId": "...",
    "externalReference": "wallet-recharge-80",
    "amount": 5000,
    "currency": "COP",
    "createdAt": "2026-06-29T..."
  }
}
```

### Consultar / historial

```http
GET /api/payments/intents/{id}
GET /api/payments/me?type=wallet_recharge&status=approved&page=1&pageSize=20
GET /api/payments/me/{id}
```

### Post-pago mobile

1. Abrir `checkoutUrl` en WebView/browser.
2. Tras pagar, polling: `GET /api/payments/intents/{id}` hasta `status=approved`.
3. Refrescar wallet: `GET /api/wallet/cards`.
4. Las URLs de retorno HTML son válidas (backend Cloud Run).

---

## 3. Membresías (USD base + cobro local por país)

### Regla de negocio principal

| Concepto | Regla |
|----------|-------|
| Precio oficial del plan | **USD** (fuente de verdad comercial, siempre) |
| Moneda de cobro | **Local por país** — calculada en backend |
| Proveedor de cobro | Configurado por país (`Payments:Countries:{CC}:Provider`) |
| Mobile / Panel | Solo envían `membershipPlanId` + `idempotencyKey`. **Nunca** `amount`, moneda ni tasa |
| Activación | Solo tras webhook `approved` |
| Plan gratis | `POST /api/memberships/subscribe` (sin MP) |
| Plan pago | `POST /api/memberships/subscribe-intents` |
| CORPORATIVO | Cotización manual — **sin checkout automático** |
| USA (Stripe) | Checkout pendiente de integración — backend rechaza si provider=Stripe |

### País, moneda y proveedor

El backend resuelve el país en checkout así:

1. `Client.CountryCode` del usuario autenticado (cliente).
2. País del club/negocio del owner (comercio).
3. Fallback: `Memberships:DefaultCountryCode` (default `CO`).

Para **estimación de precios** en listado de planes, opcional: `?countryCode=CL`.

| País | Moneda local | Proveedor (config) |
|------|--------------|-------------------|
| CO | COP | MercadoPago |
| CL | CLP | MercadoPago |
| MX | MXN | MercadoPago |
| PE | PEN | MercadoPago |
| US | USD | Stripe (pendiente) |

### Precios oficiales USD

| Código | Nombre | USD/mes | Audience | Checkout |
|--------|--------|---------|----------|----------|
| `FREE` | CIERVO FREE | 0.00 | client | No |
| `PLUS` | CIERVO Plus | 4.99 | client | Sí |
| `GOLD` | CIERVO GOLD | 9.99 | client | Sí |
| `PLATINUM` | CIERVO PLATINUM | 19.99 | client | Sí |
| `FAMILY` | CIERVO FAMILY | 24.99 | client | Sí |
| `BUSINESS` | CIERVO BUSINESS | 29.99 | business | Sí |
| `EMPRESARIAL` | CIERVO EMPRESARIAL | 99.99 | enterprise | Sí |
| `CORPORATIVO` | CIERVO CORPORATIVO | Cotización | enterprise | No |

> Códigos internos DB: `free`, `silver`→PLUS, `black`→PLATINUM, etc. La API expone códigos públicos en MAYÚSCULAS.

### Audience (visibilidad)

| Valor | Quién lo ve | Planes |
|-------|-------------|--------|
| `client` | App mobile cliente | FREE, PLUS, GOLD, PLATINUM, FAMILY |
| `business` | Panel dueño/comercio | BUSINESS |
| `enterprise` | Panel B2B / admin | EMPRESARIAL, CORPORATIVO |

```http
GET /api/memberships/plans?audience=client
GET /api/memberships/plans?audience=client&countryCode=CO
GET /api/memberships/plans?audience=client&countryCode=CL
GET /api/memberships/plans?audience=business
GET /api/memberships/plans?audience=enterprise
```

- **Mobile cliente:** `audience=client` (precio local según país del usuario; opcional `countryCode` para preview).
- **Panel dueño:** `audience=business` (país del comercio).
- **SuperAdmin:** sin filtro o cualquier audience → ve todos.

### Response plan

```json
{
  "status": true,
  "value": [
    {
      "id": 2,
      "code": "PLUS",
      "name": "CIERVO Plus",
      "audience": "client",
      "priceUsd": 4.99,
      "baseCurrency": "USD",
      "billingCurrency": "USD",
      "countryCode": "CO",
      "estimatedLocalPrice": 19960,
      "estimatedLocalCurrency": "COP",
      "paymentProvider": "MercadoPago",
      "description": "Plan Plus con mas PINs y beneficios",
      "benefits": [
        "PINs ilimitados",
        "Tarjeta fisica + NFC",
        "Cashback 1%"
      ],
      "limits": {
        "dailyPinLimit": null,
        "virtualCards": 1,
        "physicalCard": true,
        "nfc": true,
        "secondaryUsers": 2,
        "kidsLimit": 0,
        "cashbackPercent": 1,
        "prioritySupport": true,
        "deliveryPreferential": true
      },
      "requiresCustomQuote": false,
      "supportsCheckout": true,
      "billingPeriod": "Monthly"
    }
  ]
}
```

> `estimatedLocalPrice = round(priceUsd × exchangeRateUsed)`. La tasa proviene de `CurrencyConversionService` (API + cache + BD). **El frontend solo muestra lo que devuelve el backend.**

### Conversión de moneda (`CurrencyConversionService`)

**Principio:** USD es la moneda oficial del negocio. El backend convierte automáticamente a la moneda local del país de cobro. **Flutter Mobile y Panel Web nunca calculan tasas, moneda, conversiones ni montos finales.**

| Prioridad | Fuente | `exchangeRateSource` |
|-----------|--------|------------------------|
| 1 | API externa (`open.er-api.com`, configurable) | `open_er_api` |
| 2 | Cache en memoria (TTL default **6 h**, `Memberships:ExchangeRateCacheMinutes`) | (interno; no se expone en intent) |
| 3 | Última tasa persistida en tabla `EXCHANGE_RATE` | `database_stale` |
| 4 | Contingencia extrema (constantes de emergencia en código) | `emergency_static` |
| — | USD → USD | `identity` |

**No usar variables de entorno como fuente principal de tasas.** Las tasas se actualizan automáticamente vía API y se persisten en `EXCHANGE_RATE` para reutilización y auditoría.

#### Tabla `EXCHANGE_RATE`

| Columna | Descripción |
|---------|-------------|
| `BASE_CURRENCY` | Siempre `USD` |
| `TARGET_CURRENCY` | COP, CLP, MXN, PEN, etc. |
| `EXCHANGE_RATE` | Tasa vigente al momento de la sync |
| `SOURCE` | Proveedor (`open_er_api`, `migration_seed`, etc.) |
| `RETRIEVED_AT` | Fecha/hora de la tasa obtenida |
| `UPDATED_AT` | Última escritura en BD |

#### Metadata en cada `PaymentIntent` de membresía

Obligatorio guardar: `priceUsd`, `baseCurrency`, `countryCode`, `localChargeAmount`, `localChargeCurrency`, `exchangeRateUsed`, `exchangeRateSource`, `exchangeRateDate`.

Los intents existentes **no** se recalculan si cambia la tasa después del checkout.

### Tabla de límites por plan (`limits`)

| Plan | Límites clave (backend aplica) |
|------|--------------------------------|
| **FREE** | dailyPinLimit: 3, virtualCards: 1, kidsLimit: 0, cashback: 0%, historyDays: 30 |
| **PLUS** | dailyPinLimit: ∞, physicalCard, nfc, secondaryUsers: 2, cashback: 1% |
| **GOLD** | kidsLimit: 5, parentalControl, geoFences, kidsCards, doubleAdmin |
| **PLATINUM** | cashback: 2%, premiumTravel, concierge, unlimitedCards |
| **FAMILY** | familyMembersLimit: 10, kidsLimit: ∞, sharedWallet, familyBudget, approvals |
| **BUSINESS** | qrPayments, delivery, marketplace, dashboard, apiAccess, cashiers |
| **EMPRESARIAL** | employeesLimit: 100, payroll, corporateCards, erpApi |
| **CORPORATIVO** | customQuote, employeesLimit: ∞, sla247, accountManager |

**Regla:** Mobile/panel muestran `benefits` y `limits`. **Backend bloquea** acciones que excedan límites → HTTP **400/403** con mensaje claro (ej. `"Limite diario de PINs alcanzado para tu plan."`).

### Suscribir plan gratis (cliente)

```http
POST /api/memberships/subscribe
Authorization: Bearer {clientToken}
```

```json
{ "planId": 1 }
```

Activa inmediatamente. Planes con `priceUsd > 0` → error: *"Use POST /api/memberships/subscribe-intents"*.

### Suscribir plan pago — Mobile cliente

```http
POST /api/memberships/subscribe-intents
Authorization: Bearer {clientToken}
```

```json
{
  "membershipPlanId": 2,
  "idempotencyKey": "uuid-v4"
}
```

> Alias legacy: `"planId": 2` también aceptado.

**Backend hace (mobile NO calcula nada):**

1. Resuelve país del usuario/comercio → moneda local y proveedor.
2. Busca plan → `priceUsd` (ej. PLUS = 4.99 USD).
3. Convierte USD → moneda local vía `CurrencyConversionService` (cache + fallback).
4. Crea `PaymentIntent` type=`membership_subscription`, `amount` = monto local.
5. Guarda metadata de auditoría:

```json
{
  "membershipPlanId": 2,
  "planCode": "PLUS",
  "priceUsd": 4.99,
  "baseCurrency": "USD",
  "billingCurrency": "USD",
  "countryCode": "CO",
  "localChargeCurrency": "COP",
  "localChargeAmount": 19960,
  "exchangeRateUsed": 3912.5,
  "exchangeRateSource": "open_er_api",
  "exchangeRateDate": "2026-06-29",
  "paymentProvider": "MercadoPago",
  "checkoutUrl": "https://www.mercadopago.com.co/checkout/...",
  "preferenceId": "..."
}
```

6. Si proveedor = MercadoPago → crea preferencia en **moneda local** (COP, CLP, etc.).
7. Si proveedor = Stripe (US) → error hasta integración.
8. Devuelve `checkoutUrl`.

**Response (Colombia):**

```json
{
  "status": true,
  "value": {
    "paymentIntentId": 81,
    "type": "membership_subscription",
    "status": "pending",
    "checkoutUrl": "https://www.mercadopago.com.co/checkout/...",
    "amount": 19960,
    "currency": "COP",
    "membershipPlanId": 2,
    "membershipPricing": {
      "membershipPlanId": 2,
      "planCode": "PLUS",
      "priceUsd": 4.99,
      "baseCurrency": "USD",
      "billingCurrency": "USD",
      "countryCode": "CO",
      "localChargeCurrency": "COP",
      "localChargeAmount": 19960,
      "exchangeRateUsed": 3912.5,
      "exchangeRateSource": "open_er_api",
      "exchangeRateDate": "2026-06-29T00:00:00Z",
      "paymentProvider": "MercadoPago"
    }
  }
}
```

### Suscribir plan pago — Panel dueño/comercio

```http
POST /api/business-memberships/subscribe-intents
Authorization: Bearer {businessToken}
```

Mismo body que mobile. Solo planes `audience=business|enterprise` según rol.

Alias: `POST /api/business-memberships/checkout` (mismo comportamiento).

### Reglas de seguridad membresías

| Regla | Implementación |
|-------|----------------|
| No aceptar amount/moneda/tasa desde mobile | Rechaza `amount` en `membership_subscription` |
| No activar hasta webhook approved | `CompleteMembershipPayment` en webhook |
| Guardar tasa usada | `MetadataJson` inmutable por intent |
| Tasa cambia después | Intents existentes **no** se recalculan |
| Plan gratis | Sin Mercado Pago |
| CORPORATIVO | `requiresCustomQuote=true` → 400 |
| Idempotencia webhook | No doble activación si webhook llega N veces |
| Cliente vs comercio | `audience=client` → `USER_MEMBERSHIP`; `business/enterprise` → `OWNER_MEMBERSHIP` |

### Endpoints membresía adicionales

| Endpoint | Rol | Uso |
|----------|-----|-----|
| `GET /api/memberships/me` | Auth | Membresía activa cliente |
| `GET /api/memberships/benefits` | Client | Beneficios + limits |
| `GET /api/memberships/invoices` | Client | Facturas |
| `POST /api/memberships/cancel` | Client | Cancelar |
| `GET /api/business-memberships/me` | Business | Membresía comercio |
| `GET /api/business-memberships/me/limits` | Business | Límites técnicos |
| `GET /api/business-memberships/me/usage` | Business | Uso vs límites |

---

## 4. Webhooks Mercado Pago

```http
POST /api/payments/webhooks/mercadopago?data.id={paymentId}&type=payment
```

**Flujo:**

1. Valida firma (`WebhookSecret` + `x-signature`, `x-request-id`).
2. Persiste evento en `PAYMENT_WEBHOOK_EVENT`.
3. Consulta `GET /v1/payments/{id}` en MP.
4. Resuelve intent por `externalReference`.
5. Ejecuta acción idempotente según tipo.
6. Error → registra en evento (reprocesable por admin).

**Acciones al aprobar:**

| Tipo | Acción |
|------|--------|
| `wallet_recharge` | Acredita wallet + `WALLET_TRANSACTION` + receipt |
| `membership_subscription` | Activa membresía + invoice Paid + receipt |
| `delivery_order` | Marca pedido Paid |
| `booking` | Confirma reserva + receipt |

---

## 5. Rutas de retorno post-pago

Públicas (`AllowAnonymous`), HTML responsive:

| Ruta | Mensaje |
|------|---------|
| `GET /api/payments/return/success` | Pago aprobado / validando recarga |
| `GET /api/payments/return/failure` | Pago rechazado |
| `GET /api/payments/return/pending` | Pago pendiente |

Query params MP: `payment_id`, `external_reference`. Success/pending intentan reconciliar idempotentemente.

---

## 6. Panel dueño/staff

**Auth:** `BusinessOrAdmin` + permiso `payments.view`.

```http
GET /api/businesses/{businessId}/payments
GET /api/businesses/{businessId}/payments/{paymentIntentId}
GET /api/businesses/{businessId}/payments/summary
POST /api/business-memberships/subscribe-intents
GET /api/memberships/plans?audience=business
```

---

## 7. Panel SuperAdmin

**Auth:** `AdminOnly` — `Authorization: Bearer {adminToken}`.

### Pagos y conciliación

```http
GET /api/admin/payments
GET /api/admin/payments/{paymentIntentId}
GET /api/admin/payments/summary
GET /api/admin/payments/webhook-events
POST /api/admin/payments/{id}/sync-provider?providerPaymentId=
POST /api/admin/payments/{id}/reconcile?providerPaymentId=
POST /api/admin/payments/webhook-events/{eventId}/reprocess
```

### Membresías

```http
GET /api/memberships/plans
GET /api/admin/membership-plans
```

### Tasas de cambio (admin)

Consulta y refresh manual de tasas USD → moneda local. **Solo SuperAdmin.** Mobile y Panel comercio **no** usan estos endpoints.

```http
GET /api/admin/exchange-rates
POST /api/admin/exchange-rates/refresh
```

#### `GET /api/admin/exchange-rates`

Devuelve tasas persistidas en `EXCHANGE_RATE` y metadatos del servicio de conversión.

**Response:**

```json
{
  "status": true,
  "value": {
    "baseCurrency": "USD",
    "cacheMinutes": 360,
    "apiUrl": "https://open.er-api.com/v6/latest/USD",
    "supportedCountryCodes": ["CO", "CL", "MX", "PE", "US"],
    "rates": [
      {
        "baseCurrency": "USD",
        "targetCurrency": "COP",
        "exchangeRate": 3912.5,
        "source": "open_er_api",
        "retrievedAt": "2026-06-29T12:00:01Z",
        "updatedAt": "2026-06-29T12:00:05Z"
      },
      {
        "baseCurrency": "USD",
        "targetCurrency": "CLP",
        "exchangeRate": 921.3,
        "source": "open_er_api",
        "retrievedAt": "2026-06-29T12:00:01Z",
        "updatedAt": "2026-06-29T12:00:05Z"
      }
    ]
  }
}
```

> No ejecuta llamada al proveedor externo; lee lo almacenado en BD (última sync automática o refresh manual).

#### `POST /api/admin/exchange-rates/refresh`

Fuerza invalidación de cache en memoria, consulta al proveedor externo y persiste tasas en `EXCHANGE_RATE`.

**Body:** vacío.

**Response (éxito con proveedor):**

```json
{
  "status": true,
  "value": {
    "refreshedFromProvider": true,
    "source": "open_er_api",
    "retrievedAt": "2026-06-29T15:30:00Z",
    "message": null,
    "rates": [
      {
        "baseCurrency": "USD",
        "targetCurrency": "COP",
        "exchangeRate": 3920.1,
        "source": "open_er_api",
        "retrievedAt": "2026-06-29T15:30:00Z",
        "updatedAt": "2026-06-29T15:30:02Z"
      }
    ]
  }
}
```

**Response (proveedor caído):**

```json
{
  "status": true,
  "value": {
    "refreshedFromProvider": false,
    "source": "open_er_api",
    "retrievedAt": "2026-06-29T12:00:01Z",
    "message": "No se pudo obtener tasas del proveedor externo. Se devuelven las ultimas tasas almacenadas.",
    "rates": []
  }
}
```

**Uso panel:** pantalla de configuración financiera / monitoreo de tasas antes de campañas o tras incidentes del proveedor.

---

## 8. Otros flujos de pago

| Flujo | Endpoint | Monto |
|-------|----------|-------|
| Wallet recarga | `POST /api/payments/intents` | Mobile envía COP |
| Delivery MP | `POST /api/payments/intents` | Backend calcula |
| Booking MP | `POST /api/payments/intents` | Backend calcula |
| PIN comercio | `POST /api/payments/pin` | Interno |
| Kids business | `POST /api/kids/payments/business` | Interno |
| Transfer wallet | `POST /api/wallet/transfers` | Interno |

---

## 9. Recibos, facturación, comisiones, liquidaciones

| Concepto | Tabla / endpoint |
|----------|------------------|
| Recibos | `PAYMENT_RECEIPT`, `GET /api/receipts` |
| Factura membresía cliente | `USER_MEMBERSHIP_INVOICE` |
| Comisiones plataforma | `PLATFORM_COMMISSION` |
| Liquidaciones delivery | `DELIVERY_SETTLEMENT` |
| Auditoría financiera | `FINANCIAL_AUDIT_LOG` |
| Auditoría proveedor | `PAYMENT_PROVIDER_AUDIT_LOG` |

Membresía pagada genera receipt con monto **local cobrado**; metadata USD + tasa + país queda en `PaymentIntent.MetadataJson`.

---

## 10. Seguridad

| Regla | Implementación |
|-------|----------------|
| Cliente solo ve sus pagos | Filtro `userId` en `/payments/me` |
| Staff solo ve su negocio | `CanManageBusiness` + `payments.view` |
| Membresía paga sin MP | `subscribe` rechaza `priceUsd > 0` |
| Monto membership | **Nunca** desde mobile/panel |
| Tasas / conversiones | **Nunca** desde frontend; solo backend |
| Webhook idempotente | Check transacción Succeeded existente |
| Firma webhook | Obligatoria en prod |
| Límites plan | Backend enforce, no Flutter |

---

## 11. Errores comunes

| HTTP | Mensaje | Causa |
|------|---------|-------|
| 400 | Firma webhook invalida | Secret incorrecto |
| 400 | Plan no encontrado | membershipPlanId inválido |
| 400 | Use subscribe-intents | Plan pago vía subscribe directo |
| 400 | No enviar amount para membership | Mobile envió amount |
| 400 | Este plan requiere cotizacion comercial | CORPORATIVO |
| 400 | Este plan no esta disponible para tu tipo de cuenta | Audience incorrecto |
| 403 | Limite diario de PINs alcanzado | Plan FREE |
| 403 | PLAN_LIMIT_REACHED | Límite técnico business |

---

## 12. Migraciones requeridas

Ejecutar en prod (orden):

1. `DataAccess/Migrations/_pending_prod_payment_webhook_events.sql`
2. `DataAccess/Migrations/_pending_prod_membership_usd.sql`
3. `DataAccess/Migrations/_pending_prod_exchange_rate.sql`

La tercera crea `EXCHANGE_RATE` con índice único `(BASE_CURRENCY, TARGET_CURRENCY)` y seed inicial opcional hasta la primera sincronización con la API.

---

## 13. Variables de entorno

### Mercado Pago

```yaml
Payments__MercadoPago__Enabled: "true"
Payments__MercadoPago__AccessToken: "APP_USR-..."
Payments__MercadoPago__PublicKey: "APP_USR-..."
Payments__MercadoPago__WebhookSecret: "..."
Payments__MercadoPago__NotificationUrl: "https://.../api/payments/webhooks/mercadopago"
Payments__MercadoPago__SuccessUrl: "https://.../api/payments/return/success"
Payments__MercadoPago__FailureUrl: "https://.../api/payments/return/failure"
Payments__MercadoPago__PendingUrl: "https://.../api/payments/return/pending"
```

### Membresías / países / conversión

```yaml
Memberships__BaseCurrency: "USD"
Memberships__DefaultCountryCode: "CO"
Memberships__ExchangeRateCacheMinutes: "360"
Memberships__ExchangeRateApiUrl: "https://open.er-api.com/v6/latest/USD"

Payments__Countries__CO__LocalCurrency: "COP"
Payments__Countries__CO__Provider: "MercadoPago"
Payments__Countries__CL__LocalCurrency: "CLP"
Payments__Countries__CL__Provider: "MercadoPago"
# ... demás países según expansión
```

> **No configurar tasas de cambio en variables de entorno.** Las tasas viven en `EXCHANGE_RATE` (actualizadas por `CurrencyConversionService`) y en cache en memoria.

---

## 14. Mapa Flutter vs Panel

| Pantalla | Consumidor | Endpoint |
|----------|------------|----------|
| Planes cliente | Flutter Mobile | `GET /api/memberships/plans?audience=client` (opc. `countryCode`) |
| Suscribir PLUS/GOLD/... | Flutter Mobile | `POST /api/memberships/subscribe-intents` |
| Plan FREE | Flutter Mobile | `POST /api/memberships/subscribe` |
| Planes comercio | Panel Web | `GET /api/memberships/plans?audience=business` |
| Checkout BUSINESS | Panel Web | `POST /api/business-memberships/subscribe-intents` |
| Config MP | Ambos | `GET /api/payments/config` |
| Recargar wallet | Flutter | `POST /api/payments/intents` type=wallet_recharge |
| Pagar delivery | Flutter | `POST /api/payments/intents` type=delivery_order |
| Historial pagos | Flutter | `GET /api/payments/me` |
| Recibos | Ambos | `GET /api/receipts` |
| Pagos negocio | Panel | `GET /api/businesses/{id}/payments` |
| Conciliación | SuperAdmin | `GET /api/admin/payments/webhook-events` |
| Tasas de cambio | SuperAdmin | `GET /api/admin/exchange-rates` |
| Refresh tasas | SuperAdmin | `POST /api/admin/exchange-rates/refresh` |

---

## Changelog

| Fecha | Cambio |
|-------|--------|
| 2026-06-29 | Endpoints admin tasas: `GET/POST /api/admin/exchange-rates`; contrato listo para Mobile y Panel |
| 2026-06-29 | Tasas automáticas vía API + tabla EXCHANGE_RATE; sin ExchangeRates en env; cache 6h |
| 2026-06-29 | Membresías USD base + cobro local multi-país; CurrencyConversionService; audience; limitsJson; rutas retorno HTML; contrato SSOT |
