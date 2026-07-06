# Mobile — Pedidos con retiro en local o delivery

Contrato para la app mobile: el cliente elige **cómo recibir** el pedido y ve el **total real** antes de pagar.

**Auth:** JWT cliente (`POST /api/auth/user/login` o Firebase).

**Migración requerida:** `20260706143000_OrderFulfillmentType` (columna `DELIVERY_ORDER.FULFILLMENT_TYPE`).

---

## Resumen del flujo en pantalla

```
1. Usuario agrega productos al carrito
2. App llama POST /order-quote → muestra dos tarjetas:
   - Retiro en local: subtotal (sin envío)
   - Delivery: subtotal + deliveryFee
3. Usuario elige fulfillmentType
4. App crea pedido POST /delivery-orders
5. App paga (wallet / MercadoPago) — flujo existente
6. Comercio acepta y prepara
7a. pickup → ready_for_pickup → cliente muestra pickupCode o CIERVO ID → comercio entrega
7b. delivery → flujo domiciliario existente
```

---

## 1. Cotizar (mostrar precios antes de comprar)

**POST** `/api/businesses/{businessId}/order-quote`

**Body:**

```json
{
  "items": [
    { "productId": 12, "quantity": 2 },
    { "productId": 15, "quantity": 1 }
  ],
  "latitude": -33.4378,
  "longitude": -70.6505,
  "applyPeakHour": false,
  "applyRain": false,
  "applyHoliday": false
}
```

- `latitude` / `longitude`: requeridos para calcular delivery (usar ubicación del cliente o del mapa).
- `fulfillmentType` es opcional en quote; si no se envía, la respuesta trae **ambas** opciones.

**Response 200:**

```json
{
  "status": true,
  "value": {
    "businessId": 42,
    "businessName": "Empanadas Doña Carmen QA",
    "pickup": {
      "fulfillmentType": "pickup",
      "available": true,
      "productSubtotal": 17480,
      "deliveryFee": 0,
      "total": 17480,
      "currency": "CLP",
      "countryCode": "CL",
      "estimatedMinutes": 20,
      "items": [
        { "productId": 12, "productName": "Empanada de Pino", "quantity": 2, "unitPrice": 2500, "totalPrice": 5000 }
      ]
    },
    "delivery": {
      "fulfillmentType": "delivery",
      "available": true,
      "productSubtotal": 17480,
      "deliveryFee": 3500,
      "total": 20980,
      "currency": "CLP",
      "countryCode": "CL",
      "estimatedMinutes": 35,
      "pricing": { "distanceKm": 2.4, "deliveryFee": 3500, "currency": "CLP" },
      "items": [ "... mismo detalle ..." ]
    }
  }
}
```

Si una opción no aplica:

```json
"pickup": { "fulfillmentType": "pickup", "available": false, "reason": "Uno o mas productos no estan disponibles para retiro en local." }
```

**UI sugerida:**

| Opción | Mostrar |
|--------|---------|
| Retiro | `pickup.total` + texto "Sin costo de envío" |
| Delivery | `delivery.total` + desglose `productSubtotal` + `deliveryFee` |

Solo mostrar la opción si `available === true` y el producto tiene `allowsPickup` / `allowsDelivery` en catálogo.

---

## 2. Crear pedido

**POST** `/api/businesses/{businessId}/delivery-orders`

**Body — retiro en local:**

```json
{
  "fulfillmentType": "pickup",
  "items": [
    { "productId": 12, "quantity": 2 }
  ],
  "notes": "Sin cebolla"
}
```

**Body — delivery:**

```json
{
  "fulfillmentType": "delivery",
  "deliveryAddress": "Av. Providencia 2000, Santiago",
  "latitude": -33.4378,
  "longitude": -70.6505,
  "items": [
    { "productId": 12, "quantity": 2 }
  ]
}
```

| Campo | pickup | delivery |
|-------|--------|----------|
| `fulfillmentType` | `"pickup"` | `"delivery"` (default si se omite) |
| `deliveryAddress` | No requerido | **Requerido** |
| `latitude` / `longitude` | Opcional | Requerido para tarifa |

**Response:** `DeliveryOrderResponse` con:

- `fulfillmentType`: `"pickup"` | `"delivery"`
- `totalAmount`, `productSubtotal`, `deliveryFee`
- `reference` / `confirmationCode`: código de pedido
- `status`: `pending_business_approval`

---

## 3. Pagar (sin cambios)

Usar el flujo existente de pagos delivery:

- `POST /api/delivery/orders/{orderId}/pay` (wallet / MP / etc.)
- Ver `docs/PAYMENTS-API-CONTRACT.md`

El monto a cobrar es siempre `order.totalAmount` devuelto por el backend.

---

## 4. Seguimiento — cliente

**GET** `/api/delivery/orders/{orderId}`

Campos nuevos / relevantes:

| Campo | Cuándo |
|-------|--------|
| `fulfillmentType` | Siempre |
| `pickupCode` | Solo pickup + status `ready_for_pickup` (PIN 6 dígitos para mostrar en mostrador) |
| `customerCiervoCode` | Siempre (ID CIERVO del comprador) |

**Estados pickup (retiro en local):**

```
pending_business_approval
  → accepted (comercio acepta, sin domiciliario)
  → preparing
  → ready_for_pickup  ← mostrar pickupCode al cliente
  → delivered         ← comercio confirma entrega
```

**Estados delivery:** sin cambios (domiciliario, PIN courier, etc.).

---

## 5. Panel comercio — retiro en local

Al ver el pedido (`GET /api/businesses/{id}/delivery-orders/{orderId}`):

- `fulfillmentType === "pickup"`
- `customerCiervoCode`, `customerName`, `customerPhone`
- Items y `paymentStatus`

**Cambiar estado:**

`PUT /api/businesses/{businessId}/delivery-orders/{orderId}/status`

```json
{ "status": "accepted" }
```

Secuencia pickup: `accepted` → `preparing` → `ready_for_pickup` → entregar.

**Confirmar entrega al cliente (mostrador):**

`POST /api/businesses/{businessId}/delivery-orders/{orderId}/handover`

Opción A — PIN que ve el cliente en la app:

```json
{ "pin": "482910" }
```

Opción B — CIERVO ID del cliente:

```json
{ "ciervoCode": "CIERVO-QA-12345" }
```

Requisitos: pedido `pickup`, status `ready_for_pickup`, pago completado.

---

## Valores `fulfillmentType`

| Valor API | Significado |
|-----------|-------------|
| `pickup` | Retiro en el local del comercio |
| `delivery` | Domicilio con courier |

Alias aceptados al crear: `retiro` → pickup, `domicilio` → delivery.

---

## Errores comunes

| Mensaje | Causa |
|---------|-------|
| `Debes enviar la direccion de entrega para domicilio` | `fulfillmentType=delivery` sin `deliveryAddress` |
| `Uno o mas productos no estan disponibles para retiro en local` | Producto con `allowsPickup=false` |
| `Domicilio no disponible` / sin couriers | Delivery no disponible en zona; ofrecer solo pickup |
| `Codigo de retiro o CIERVO ID invalido` | Handover con PIN/código incorrecto |

---

## Checklist implementación Flutter

- [ ] Pantalla carrito: toggle **Retiro** / **Delivery**
- [ ] Llamar `order-quote` al cambiar items, ubicación u opción
- [ ] Mostrar totales distintos según opción seleccionada
- [ ] Crear pedido con `fulfillmentType` correcto
- [ ] Ocultar mapa/dirección si elige retiro
- [ ] En detalle de pedido pickup: mostrar `pickupCode` cuando `status == ready_for_pickup`
- [ ] Mostrar `customerCiervoCode` como alternativa en mostrador
