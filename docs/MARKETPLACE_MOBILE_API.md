# CIERVO Marketplace — Contrato App Mobile

**Base URL prod:** `https://ciervo-backend-613568140358.southamerica-east1.run.app`  
**Alias:** `https://api.ciervo.club`  
**Fecha:** 2026-07-27 (v2 fidelización + QR)  
**Auth:** envelope `{ status, value, msg }` · JSON camelCase  
**JWT:** `Authorization: Bearer {accessToken}` donde se indique

> Base real: `/api/...` (no `/api/v1`).

---

## Changelog v2

| Cambio | Tipo |
|--------|------|
| Scan QR + CIERVO ID + perfil de comercio | Nuevo |
| Beneficios (cashback/puntos) + calculate-benefits | Nuevo |
| Reservas marketplace | Nuevo |
| Order + payment separados | Nuevo |
| Feeds cashback/points | Nuevo |
| Visitas QR / historial wallet aliases | Nuevo |
| Campos loyalty en cards de promo | Extensión |

---

## 1) Feed y descubrimiento

| Método | Ruta | Auth |
|--------|------|------|
| GET | `/api/marketplace` | Opcional |
| GET | `/api/marketplace/highlights` | Opcional |
| GET | `/api/marketplace/popular` | Opcional |
| GET/POST | `/api/marketplace/nearby` | Opcional |
| GET | `/api/marketplace/search?q=` | Opcional |
| GET | `/api/marketplace/filters` | Público |
| GET | `/api/marketplace/promotions/{id}` | Opcional |
| GET | `/api/marketplace/promotion/{id}` | Opcional (alias) |
| GET | `/api/marketplace/promotions/cashback` | Opcional |
| GET | `/api/marketplace/promotions/points` | Opcional |
| GET | `/api/marketplace/business/{businessId}/promotions` | Opcional |

Query feed: `page`, `limit`, `categoria`/`categoryId`, `subcategoria`, `ciudad`, `dia`/`noche`/`horas24`, `delivery`, `cashback`/`onlyCashback`, `onlyPoints`, `precioMin`/`precioMax`, `buscar`/`q`, `order=popular`.

Cada item ahora incluye: `cashbackType`, `cashbackValue`, `cashbackAmount`, `points`, `pointsEnabled`, `membershipOnly`, `premiumOnly`, `reservationEnabled`, `conditions`, `discountPercent`, `paymentMethods`.

---

## 2) Acceso inteligente QR / CIERVO ID

| Método | Ruta | Auth |
|--------|------|------|
| POST | `/api/marketplace/store/scan-qr` | Opcional |
| GET | `/api/marketplace/store/by-ciervo/{ciervoId}` | Opcional |
| GET | `/api/marketplace/store/{ciervoIdOrStoreId}` | Opcional |
| GET | `/api/marketplace/store/{storeId}/profile` | Opcional |
| GET | `/api/marketplace/store/{storeId}/promotions` | Opcional |
| GET | `/api/marketplace/store/{storeId}/events` | Opcional |
| GET | `/api/marketplace/store/{storeId}/featured-products` | Opcional |
| POST | `/api/marketplace/store/visit` | Opcional |

### Scan QR body

```json
{ "qrCode": "ciervo://business/22", "latitude": 4.71, "longitude": -74.07 }
```

Resuelve por: `Club.QrCode`, `Club.CiervoId`, payload de sucursal, o `ciervo://business/{id}`. Registra visita automáticamente.

### Perfil (`value`)

Incluye: nombre, `ciervoId`, categoría, logo/cover/galería, rating, followers, distancia, open, delivery, ciervoPay, cashback/points enabled, horarios, redes, pagos, promociones activas + listas de events/products/services en `/profile`.

---

## 3) Beneficios antes del pago

| Método | Ruta | Auth |
|--------|------|------|
| POST | `/api/marketplace/promotion/calculate-benefits` | Opcional (mejor con JWT) |

```json
{ "promotionId": 55, "quantity": 2, "paymentMethod": "CIERVO" }
```

Respuesta: `subtotal`, `discount`, `cashback`, `points`, `membershipBonus`, `totalPoints`, `totalPay`, `eligible`, `eligibilityMessage`, `conditions`.

---

## 4) Engagement

| Método | Ruta |
|--------|------|
| POST | `/api/promotions/{id}/view` · `/click` · `/share` |
| POST | `/api/marketplace/promotion/view` · `/click` · `/share` (body `{ "promotionId": 55 }`) |

---

## 5) Favoritos

| Método | Ruta |
|--------|------|
| POST/GET/DELETE | `/api/marketplace/favorites` |
| Alias | `/api/users/promotion-favorites` |

> No usar `/api/users/favorites` (es de comercios).

---

## 6) Reservas

| Método | Ruta | Auth |
|--------|------|------|
| POST | `/api/marketplace/reservation` | JWT |
| PUT | `/api/marketplace/reservation/{id}/confirm` | JWT |
| DELETE | `/api/marketplace/reservation/{id}` | JWT |

```json
{
  "promotionId": 55,
  "date": "2026-08-20",
  "time": "20:30",
  "people": 4,
  "comments": "Mesa terraza"
}
```

Requiere `reservationEnabled` en la promo (o tipo event/service/reservation).

---

## 7) Compra / pago

### Flujo rápido (1 paso)

| Método | Ruta |
|--------|------|
| POST | `/api/marketplace/checkout` o `/api/checkout` |

```json
{ "promotionId": 55, "cantidad": 2, "metodoPago": "CIERVO" }
```

- `CIERVO`/`WALLET`: debita wallet + otorga cashback/puntos → `paid`
- `CONTACT`: orden `pending`
- `PENDING`: orden `pending_payment` (luego pagar)

### Flujo 2 pasos (doc v1)

| Método | Ruta |
|--------|------|
| POST | `/api/marketplace/order` | crea `pending_payment` |
| POST | `/api/marketplace/payment` | `{ "orderId": 1, "wallet": "CIERVO", "pin": "optional" }` |

Historial: `GET /api/marketplace/orders` · detalle · `PATCH .../cancel`.

---

## 8) Wallet loyalty (aliases)

| Método | Ruta |
|--------|------|
| GET | `/api/wallet/cashback` · `/api/wallet/points` |
| GET | `/api/wallet/cashback/history` · `/api/wallet/points/history` |
| GET | `/api/wallet/history` |

---

## 9) Categorías

`GET /api/categories` · `GET /api/categories/{id}/subcategories`

---

## 10) Smoke mobile v2

1. `POST /api/marketplace/store/scan-qr` con `ciervo://business/22`
2. `GET /api/marketplace/store/22/profile`
3. `POST /api/marketplace/promotion/calculate-benefits`
4. `GET /api/marketplace/promotions/cashback`
5. Login → favorites / reservation / order+payment
