# CIERVO MOVE — Guía de adaptación para la app Flutter

> Documento de traspaso técnico para integrar el módulo **CIERVO MOVE** (movilidad / ride‑hailing con
> negociación de tarifa) en la app móvil. Cubre contratos de API, flujos de pasajero y conductor,
> pagos con wallet, tiempo real (SSE) y notificaciones. Todos los endpoints requieren `Authorization: Bearer <accessToken>`
> (el mismo JWT que ya usa el resto de la app).

## 1. Conceptos clave

- **No hay rol "Driver" separado.** Un conductor es un usuario Client (rol=1) que además creó un
  `MoveDriverProfile` y fue **aprobado** por un admin. La app decide qué UI mostrar según
  `GET /api/v1/move/driver/me` (si devuelve perfil y `status = Approved`, habilita el modo conductor).
- **Moneda por país.** COP (Colombia) y CLP (Chile). Los importes son enteros en la moneda local
  (sin decimales). El backend redondea con `roundingUnit` (p. ej. 50).
- **Negociación de tarifa.** El backend calcula una tarifa **sugerida** y un rango `[minOffer, maxOffer]`.
  Conductores ofertan dentro del rango; el pasajero puede aceptar o contraofertar.
- **Pago con wallet.** Al aceptar una oferta se **retiene (hold)** el importe en la wallet del pasajero;
  al finalizar se **captura** y se liquida al conductor (neto = tarifa − comisión) más cashback al pasajero.
- **Envelope de respuesta.** Todas las respuestas siguen `{ status, value, msg, errorCode }`.
  `status=true` → éxito y `value` trae el dato. En error, `errorCode` es legible por máquina
  (`VALIDATION`, `NOT_FOUND`, `FORBIDDEN`, `INSUFFICIENT_BALANCE`, `NO_WALLET`, `CURRENCY_MISMATCH`,
  `CONCURRENCY`, `PAYMENT_ERROR`).

## 2. Máquina de estados del viaje (`MoveTripStatus`)

```
Draft(1) → Searching(2) → Offered(3) → DriverAssigned(4)
        → DriverArriving(7) → DriverArrived(8) → InProgress(9) → Completed(10)
Cancelaciones: CancelledByUser(11), CancelledByDriver(12), CancelledBySystem(13), Expired(14)
```

`paymentStatus` (`MovePaymentStatus`): `None=0, Pending=1, Held=2, Captured=3, Released=4, Failed=5, Refunded=6`.
`paymentMethod` (`MovePaymentMethod`): `Wallet=1, Cash=2, Card=3, Pin=4, Qr=5, Points=6`.
`vehicleCategory` (`MoveVehicleCategory`): `Economy=1, Standard=2, Premium=3, Corporate=4`.

## 3. Flujo del PASAJERO

### 3.1 Estimar tarifa (opcional, previo a solicitar)
`POST /api/v1/move/fare/calculate`
```json
{
  "countryCode": "CO", "city": null, "vehicleCategory": 2,
  "distanceKm": 8.0, "durationMin": 20, "waitMinutes": 0,
  "isNight": false, "isRaining": false, "highDemandPct": 0, "isAirport": false, "tolls": 0,
  "promoAmount": 0, "cashbackToApply": 0
}
```
Respuesta (`value`): `suggestedFare`, `minOffer`, `maxOffer`, `currency`, `breakdown` (desglose por bandas y recargos).

### 3.2 Solicitar viaje
`POST /api/v1/move/trips`
```json
{
  "countryCode": "CO", "city": "Bogota", "vehicleCategory": 2,
  "originLat": 4.65, "originLng": -74.05, "originAddress": "Cra 1 #2-3",
  "destLat": 4.70, "destLng": -74.10, "destAddress": "Cll 80 #10-20",
  "distanceKm": 8.0, "durationMin": 20, "waitMinutes": 0,
  "isNight": false, "isRaining": false, "highDemandPct": 0, "isAirport": false, "tolls": 0,
  "paymentMethod": 1, "offeredFare": 0
}
```
- `offeredFare = 0` → usa la tarifa sugerida como referencia; si envías un valor se acota a `[minOffer, maxOffer]`.
- Devuelve el `MoveTripDto` en estado `Searching`. Guarda `trip.id` y `trip.publicCode`.
- Error `"Ya tienes un viaje en curso."` si hay un viaje activo del usuario.

### 3.3 Escuchar ofertas en vivo (SSE) — recomendado
`GET /api/v1/move/trips/{tripId}/events` (respuesta `text/event-stream`).
- El primer evento es `trip.snapshot` con el viaje completo.
- Luego llegan: `offer.created`, `offer.countered`, `trip.assigned`, `trip.status`, `trip.location`,
  `trip.completed`, `trip.cancelled`.
- En Flutter usa un cliente SSE (p. ej. paquete `http` con stream, o `flutter_client_sse`). Enviar el header `Authorization`.
- **Fallback sin SSE:** polling a `GET /api/v1/move/trips/{tripId}/offers` cada 2–3 s.

### 3.4 Aceptar o contraofertar
- Aceptar: `POST /api/v1/move/trips/{tripId}/accept/{offerId}`
  - Con `paymentMethod = Wallet`, el backend hace el **hold**. Posibles errores: `INSUFFICIENT_BALANCE`,
    `NO_WALLET`, `CURRENCY_MISMATCH`. Maneja esos casos con CTA a "Recargar wallet".
  - Éxito → viaje en `DriverAssigned`, `value.driverId`, `value.agreedFare`.
- Contraofertar: `POST /api/v1/move/trips/counter-offer`
```json
{ "tripId": 123, "offerId": 456, "amount": 12000 }
```
  - `amount` debe estar en `[minOffer, maxOffer]`; limitado por `maxCounterOffers`.

### 3.5 Seguimiento del viaje
- Ubicación del conductor: por SSE (`trip.location`) o `GET /api/v1/move/trips/{tripId}/location`.
- Detalle/estado: `GET /api/v1/move/trips/{tripId}`.

### 3.6 Cancelar / Calificar
- Cancelar: `POST /api/v1/move/trips/{tripId}/cancel` con `{ "reason": "..." }` (libera el hold).
- Calificar (solo `Completed`): `POST /api/v1/move/trips/{tripId}/rate` con `{ "rating": 5, "comment": "..." }`.

### 3.7 Historial
`GET /api/v1/move/trips?status=Completed&page=1&pageSize=20` → `PagedResponse<MoveTripDto>`.

## 4. Flujo del CONDUCTOR

### 4.1 Onboarding
1. `POST /api/v1/move/driver/apply` → `{ fullName, phone, countryCode, city }` (idempotente).
2. `POST /api/v1/move/driver/vehicles` → `{ category, plate, brand, model, year, color, seats, isDefault }`.
3. `POST /api/v1/move/driver/documents` → `{ documentType, fileUrl, documentNumber, expiresAt }`
   (sube el archivo a tu storage y envía la URL).
4. Espera aprobación admin. Consulta estado con `GET /api/v1/move/driver/me`.
   - `MoveDriverStatus`: `PendingReview=1, Approved=2, Rejected=3, Suspended=4, Blocked=5`.
   - `MoveDocumentStatus` / `MoveVehicleStatus` traen su propio estado.

### 4.2 Disponibilidad y ubicación
- Ponerse en línea: `POST /api/v1/move/driver/online` → `{ isOnline: true, latitude, longitude }`.
  - Requiere `status = Approved` **y** al menos un vehículo `Active` (si no, error de validación).
- Enviar ubicación (cada pocos segundos): `POST /api/v1/move/driver/location`
```json
{ "latitude": 4.66, "longitude": -74.06, "heading": 90, "speed": 30, "tripId": 123 }
```
  - Si envías `tripId` de un viaje activo, la ubicación se propaga por SSE al pasajero.
  - El backend hace **throttling** (~1s); enviar más seguido no falla, solo se ignora la escritura.

### 4.3 Tomar viajes
- Ver disponibles: `GET /api/v1/move/driver/trips/available?maxDistanceKm=15`
  (filtra por país, categoría de tus vehículos activos y cercanía a tu ubicación).
- Ofertar / re‑ofertar (responder contraoferta): `POST /api/v1/move/driver/trips/offer`
```json
{ "tripId": 123, "amount": 12000, "vehicleId": 10, "etaMinutes": 5, "message": "Voy en 5 min" }
```
  - `amount` en `[minOffer, maxOffer]`; el vehículo debe estar `Active` y coincidir en categoría.

### 4.4 Ejecutar el viaje (máquina de estados)
En orden, con el conductor asignado:
1. `POST /api/v1/move/driver/trips/{tripId}/arriving`
2. `POST /api/v1/move/driver/trips/{tripId}/arrived`
3. `POST /api/v1/move/driver/trips/{tripId}/start`
4. `POST /api/v1/move/driver/trips/{tripId}/finish` (captura pago y liquida)
- Cancelar: `POST /api/v1/move/driver/trips/{tripId}/cancel` con `{ reason }`.
- Calificar al pasajero: `POST /api/v1/move/driver/trips/{tripId}/rate` con `{ rating, comment }`.
- Historial del conductor: `GET /api/v1/move/driver/trips?status=&page=&pageSize=`.

## 5. Notificaciones push (FCM)
El backend envía push + in‑app automáticamente en los eventos del viaje
(`move.offer.received`, `move.offer.accepted`, `move.offer.countered`, `move.trip.driverarriving`,
`move.trip.driverarrived`, `move.trip.inprogress`, `move.trip.completed`, `move.trip.cancelled`).
- Registra el token FCM con el endpoint existente `POST /api/notifications/fcm/register`.
- Cada notificación trae `resourceType = "move_trip"` y `resourceId = tripId` para navegar (deep link).

## 6. Buenas prácticas de integración Flutter
- Centraliza el parseo del envelope `Response<T>` y mapea `errorCode` a mensajes/acciones de UI.
- Modela los enums en Dart con los valores enteros de arriba (no dependas de los nombres).
- Para SSE, reconecta con backoff y reenvía el último `trip.snapshot` como estado base.
- Los importes son enteros; formatea con separador de miles según país (`es_CO`, `es_CL`).
- Verifica siempre `paymentStatus` tras aceptar: si el hold falló, no muestres "conductor asignado".

## 7. Índice rápido de endpoints MOVE
| Actor | Método | Ruta |
|---|---|---|
| Público | POST | `/api/v1/move/fare/calculate` |
| Público | GET | `/api/v1/move/fares` |
| Pasajero | POST | `/api/v1/move/trips` |
| Pasajero | GET | `/api/v1/move/trips` |
| Pasajero | GET | `/api/v1/move/trips/{id}` |
| Pasajero | GET | `/api/v1/move/trips/{id}/offers` |
| Pasajero | POST | `/api/v1/move/trips/{id}/accept/{offerId}` |
| Pasajero | POST | `/api/v1/move/trips/counter-offer` |
| Pasajero | POST | `/api/v1/move/trips/{id}/cancel` |
| Pasajero | POST | `/api/v1/move/trips/{id}/rate` |
| Pasajero | GET | `/api/v1/move/trips/{id}/location` |
| Ambos | GET (SSE) | `/api/v1/move/trips/{id}/events` |
| Conductor | POST | `/api/v1/move/driver/apply` |
| Conductor | GET | `/api/v1/move/driver/me` |
| Conductor | POST | `/api/v1/move/driver/vehicles` |
| Conductor | PUT | `/api/v1/move/driver/vehicles/{id}` |
| Conductor | POST | `/api/v1/move/driver/documents` |
| Conductor | POST | `/api/v1/move/driver/online` |
| Conductor | POST | `/api/v1/move/driver/location` |
| Conductor | GET | `/api/v1/move/driver/trips/available` |
| Conductor | POST | `/api/v1/move/driver/trips/offer` |
| Conductor | GET | `/api/v1/move/driver/trips` |
| Conductor | POST | `/api/v1/move/driver/trips/{id}/arriving` |
| Conductor | POST | `/api/v1/move/driver/trips/{id}/arrived` |
| Conductor | POST | `/api/v1/move/driver/trips/{id}/start` |
| Conductor | POST | `/api/v1/move/driver/trips/{id}/finish` |
| Conductor | POST | `/api/v1/move/driver/trips/{id}/cancel` |
| Conductor | POST | `/api/v1/move/driver/trips/{id}/rate` |
