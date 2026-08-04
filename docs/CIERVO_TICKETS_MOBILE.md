# CIERVO Tickets — contrato mobile (Flutter)

Base: `https://api.ciervo.club`  
Auth: `Authorization: Bearer <JWT>` (salvo catálogo público).  
Respuesta: `Response<T>` → `{ status, value, msg, errorCode }`.

## IDs

| Tipo | Formato | Ejemplo |
|------|---------|---------|
| Evento cine (showtime) | `movie-{guid:N}` | `movie-a1b2...` |
| Evento club | `event-{int}` | `event-50` |
| Ticket público | `TKyyMMdd####` | `TK2608020042` |

Categorías: `movies | concerts | sports | theater | events`.

## Flujo de compra

1. `GET /api/v1/events?city=Bogota&category=movies&page=1&pageSize=20`
2. `GET /api/v1/events/{eventId}`
3. Cine: `GET /api/v1/events/{eventId}/seats` → `POST .../seats/reserve` → `DELETE .../seats/release`
4. `POST /api/v1/tickets/create`
5. `POST /api/v1/tickets/pay` con `paymentMethod: "CIERVO_BALANCE"` (o `WALLET`)
6. Guardar en wallet local: `GET /api/v1/wallet/tickets`

## Endpoints

### Catálogo (público)

```http
GET /api/v1/events?city=&category=&date=&page=&pageSize=&precioMin=&precioMax=&organizer=&latitude=&longitude=&radiusKm=
GET /api/v1/events/highlights?limit=20
GET /api/v1/events/nearby?lat=&lng=&radiusKm=25&limit=20
GET /api/v1/events/{eventId}
```

Aliases de query: `ciudad`/`city`, `categoria`/`category`, `fecha`/`date`, `pagina`/`page`.

### Asientos (auth)

```http
GET    /api/v1/events/{eventId}/seats
POST   /api/v1/events/{eventId}/seats/reserve   { "seats": ["A1","A2"] }
DELETE /api/v1/events/{eventId}/seats/release?holdId=
```

Eventos sin plano: seats vacíos / tipos en detalle (`ticketTypes`).

### Tickets (auth)

```http
POST /api/v1/tickets/create
{
  "eventId": "movie-...|event-50",
  "tickets": 2,
  "seatIds": ["A1"],
  "holdId": "<reservationGuid>",
  "ticketTypeId": "501",
  "idempotencyKey": "unique-key"
}

POST /api/v1/tickets/pay
{
  "ticketId": "TK...",
  "paymentMethod": "CIERVO_BALANCE",
  "idempotencyKey": "pay-key"
}
```

Métodos soportados hoy: `CIERVO_BALANCE`, `WALLET`, `POINTS` (si hay saldo).  
`CARD` / `BANK` → error claro (no simular éxito).

```http
POST /api/v1/tickets/validate  { "qr": "CIERVO-TICKET-TK...|token" }  // BusinessOrAdmin
POST /api/v1/tickets/refund    { "ticketId": "TK..." }
POST /api/v1/tickets/cancel    { "ticketId": "TK..." }
```

### Wallet entradas (auth)

```http
GET /api/v1/wallet/tickets
GET /api/v1/wallet/tickets/history
GET /api/v1/wallet/tickets/{ticketId}
```

### Recomendaciones (auth)

```http
GET /api/v1/ai/recommend-events?lat=&lng=&limit=20
```

Heurística (cercanos + categoría frecuente + highlights), sin LLM.

## Mapping de categorías

| UI Flutter | Query `category` | Source |
|------------|------------------|--------|
| Cine | `movies` | Movie showtimes OnSale |
| Conciertos | `concerts` | Events (heurística título/desc) |
| Deportes | `sports` | Events |
| Teatro | `theater` | Events |
| Otros | `events` | Events |

## Degradaciones (no romper UI)

- NFC entrada: no implementado.
- Video promo / combos delivery-merch: null/hooks.
- Move sugerido: no se crea viaje desde Tickets.

## Compatibilidad

Legacy `/api/v1/movie` y `/api/events` siguen vivos. Flutter Tickets debe usar solo `/api/v1/events*`, `/api/v1/tickets*`, `/api/v1/wallet/tickets*`.
