# Prompt Mobile — Cierre producción backend (2026-07-01)

**Backend prod:** `https://ciervo-backend-613568140358.southamerica-east1.run.app`  
**Revisión desplegada:** `ciervo-backend-00131-5k2`  
**Migración BD:** `20260701191052_MobileProductionClosure`

---

## Resumen para el agente Flutter

Integra los siguientes contratos. El backend ya está en producción. No hardcodees tasas ni direcciones: todo viene del API.

---

## 1. Mapas y geocoding

```
GET  /api/geo/reverse?lat={lat}&lng={lng}
GET  /api/geo/geocode?address={urlEncoded}
POST /api/geo/resolve   { address? | latitude? + longitude? }
```

- Auth: Bearer obligatorio.
- Respuesta `GeocodeResponse`: `formattedAddress`, `street`, `city`, `region`, `country`, `latitude`, `longitude`, `mapsUrl`, `provider` (`GoogleMaps` si hay API key en servidor, si no `OpenStreetMap`).
- En mapa: usar `mapsUrl` o `latitude`/`longitude` con Google Maps Flutter / url_launcher.
- Configurar en Cloud Run `GoogleMaps__ApiKey` cuando tengas key de Google (Geocoding API).

---

## 2. Contactos del teléfono → usuarios CIERVO

```
GET  /api/users/search?q={texto}&country=CO&page=1&pageSize=20
POST /api/users/search/by-phones
     { "phones": ["+57300...", "300..."], "country": "CO" }
```

- La búsqueda por `q` ahora incluye **teléfono** (E.164 o sufijo).
- Batch: matchea contactos del dispositivo contra usuarios registrados.
- Item: `userId`, `ciervoUserCode`, `displayName`, `phoneMasked`, `matchedByPhone`, `canStartConversation`.
- Permisos: pedir `READ_CONTACTS` en Android/iOS; normalizar números antes del POST.
- No existe endpoint de “subir agenda completa” fuera de este batch (privacidad).

---

## 3. Tipo de cambio y conversión

```
GET /api/exchange-rates
GET /api/exchange-rates/convert?amount=100000&from=COP&to=CLP
GET /api/catalogs/currencies
```

- `exchange-rates`: `baseCurrency` (USD), `rates[]` con `targetCurrency`, `exchangeRate`, `source`, `retrievedAt`.
- `convert`: devuelve `convertedAmount` y `exchangeRate` entre dos monedas.
- `catalogs/currencies`: países soportados + tasa desde USD.
- Cache servidor: 6 h. Refrescar al abrir wallet/pagos; no calcular FX en cliente.
- Mostrar COP→CLP/USD usando estos endpoints, no valores fijos.

---

## 4. Registro Firebase sin email obligatorio

```
POST /api/auth/firebase/register
{
  "firebaseIdToken": "...",
  "phone": "+57300...",        // opcional si el token Firebase ya trae teléfono verificado
  "name": "...",
  "lastname": "...",
  "email": null,               // opcional
  "countryCode": "CO",
  "latitude": 4.71,
  "longitude": -74.07,
  "city": "Bogotá"
}
```

- `email` puede omitirse o ir vacío.
- Teléfono sigue siendo obligatorio a nivel de negocio (token Firebase verificado o body).

---

## 5. Verificación de teléfono único ANTES del SMS

```
POST /api/auth/account-lookup
{ "phone": "+57300..." }
```

Respuesta ampliada:

```json
{
  "exists": false,
  "phoneAvailable": true,
  "emailAvailable": null,
  "suggestedFlow": "register"
}
```

- **Flujo mobile:** llamar `account-lookup` con el teléfono **antes** de `verifyPhoneNumber` de Firebase.
- Si `phoneAvailable == false` → mostrar “Este número ya está registrado” y sugerir login.
- Si `phoneAvailable == true` → continuar con OTP Firebase.

---

## 6. KYC con foto de documento

Flujo en dos pasos:

1. `POST /api/media/upload` (multipart) — imagen/PDF del documento y selfie.
2. `POST /api/kyc/submit`

```json
{
  "documentType": "CC",
  "documentNumber": "1234567890",
  "country": "CO",
  "frontDocumentMediaId": 101,
  "backDocumentMediaId": 102,
  "selfieMediaId": 103
}
```

- `frontDocumentMediaId` es **obligatorio**.
- El backend valida que los media pertenezcan al usuario y sean imagen/PDF.
- `GET /api/kyc/me` para estado.

---

## 7. Cashback / puntos / rewards

```
GET  /api/rewards/catalog
GET  /api/rewards/me/balance
GET  /api/rewards/me/points
GET  /api/rewards/me/history      // redemptions
GET  /api/rewards/me/transactions // ledger de puntos
POST /api/rewards/{id}/redeem
GET  /api/cashback/rules
```

- Usar rutas `/me/*` (no las legacy `/rewards/points`).
- Si `transactions` viene vacío, mostrar empty state; el catálogo y balance son la fuente de verdad.

---

## 8. Multi-moneda en transferencias y pagos

- Enviar `currency` explícita en body (no asumir solo COP):
  - `POST /api/wallet/transfer` → `{ currency: "CLP", ... }`
  - `POST /api/chat-payments/pay`
  - `POST /api/payment-requests/pay-for-me`
- El backend crea/obtiene wallet card por moneda según país del usuario.
- Consultar monedas soportadas: `GET /api/catalogs/currencies`.

---

## 9. Tiempo casi real (notificaciones / contenido dueño)

**Push FCM (recomendado):**

```
POST /api/notifications/fcm/register
{ "fcmToken": "...", "platform": "android|ios" }
```

- Prod: `Firebase__PushEnabled=true` (ya configurado en deploy).

**SSE notificaciones (alternativa/complemento):**

```
GET /api/notifications/events?sinceId=0
Accept: text/event-stream
```

- Eventos cada ~2 s con nuevas notificaciones.
- Sustituir o complementar el polling de 45 s en pantallas críticas (contenido dueño, inbox pagos).

---

## 10. Compartir pago de reserva en chat

```
POST /api/payment-requests/pay-for-me
{
  "payerUserId": 12,
  "amount": 50000,
  "currency": "COP",
  "bookingId": 45,
  "chatConversationId": 13,
  "description": "¿Me ayudas con esta reserva?",
  "idempotencyKey": "pfm-reserva-{uuid}"
}
```

- Con `chatConversationId`, el backend publica mensaje tipo **Payment** en el chat con metadata (`paymentRequestId`, `bookingId`, `status: Pending`).
- `purpose` automático: `ReservationPayment` si hay `bookingId`.
- El pagador aprueba con flujo existente: inbox → approve.

---

## 11. QR beneficios reales

```
GET  /api/businesses/{businessId}/benefits/public
POST /api/qr/validate   { "token": "..." }
POST /api/qr/redeem     { "token": "..." }
```

- Beneficios activos del negocio incluyen `qrToken` cuando el dueño los publica.
- `validate` devuelve `benefit: { id, title, description, businessId }` para `ownerType=BusinessBenefit`.
- Dejar de usar datos QA hardcodeados en pantalla de escaneo.

---

## 12. Botones de chat dinámicos

```
GET /api/chat/buttons
```

- Mostrar barra en **todos** los tipos de chat (Internal, Family, Business, Direct, Vakupli).
- Filtrar `showOnMobile == true` y `productionStatus == ProductionReady`.
- Si la lista viene vacía o falla, mostrar barra mínima con Pagar / Paga por mí / Regalo (fallback UX).

---

## Checklist de implementación Flutter

- [ ] `GeoRepository` → reverse/geocode para mapa con calles
- [ ] `ContactsMatcher` → permisos + `search/by-phones`
- [ ] `ExchangeRateRepository` → rates + convert + mostrar en wallet
- [ ] Registro: `account-lookup` antes de OTP; register sin email
- [ ] KYC: upload media → submit con IDs
- [ ] Rewards: pantallas con `/me/transactions` y catálogo
- [ ] Transferencias/pagos: selector de moneda desde `/catalogs/currencies`
- [ ] FCM register + opcional SSE `/notifications/events`
- [ ] Reserva → compartir pay-for-me en chat con `bookingId`
- [ ] QR beneficios → `benefits/public` + validate
- [ ] `ChatActionBar` desde `/api/chat/buttons` en todos los chats

---

## Variables de entorno app

```dart
const apiBaseUrl = 'https://ciervo-backend-613568140358.southamerica-east1.run.app';
```

Firebase proyecto: `ciervoclub-70a3c` (mismo que backend).

---

## Notas

- WebSocket chat completo: **no** en backend; usar polling de mensajes + SSE/push para eventos.
- Google Maps API key: opcional en servidor; sin key funciona geocoding vía OpenStreetMap (menos preciso en calles).
- Para E2E pay-for-me en chat hace falta segundo usuario QA en prod (`scripts/prod-prepare-e2e-qa.ps1`).
