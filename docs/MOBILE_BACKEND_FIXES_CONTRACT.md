# Mobile Backend Fixes — Contrato App Flutter (CL / chats / wallet / reservas)

**Base URL prod:** `https://ciervo-backend-613568140358.southamerica-east1.run.app`  
**Alias:** `https://api.ciervo.club`  
**Fecha:** 2026-07-27  
**Origen:** `docs/BACKEND_PROMPT_MOBILE_FIXES.md`  
**Auth:** Bearer · envelope `{ status, value, msg }` · camelCase

---

## Resumen por punto

| # | Tema | Estado | Cambio |
|---|------|--------|--------|
| 1 | User search CIERVO ID | **Hecho** | Match `@user`, nombre, `CIERVO-…` o sufijo |
| 2 | Operational session día/noche/24h | **Hecho** | `operationalSessionId` + `operationalBand` en `/users/me` |
| 3 | Wallet moneda por país | **Hecho** | Cards nuevas en CLP si `countryCode=CL`; repair saldo 0 |
| 4 | Favoritos sin radio 25 km | **Confirmado** | Radio solo si cliente envía near+radius; alias check |
| 5 | Chat business name/logo | **Hecho** | `businessName`, `businessLogoUrl`, `logoUrl` |
| 6 | NFC 1 UID por card | **Hecho** | `409` + `PHYSICAL_NFC_ALREADY_REGISTERED` |
| 7 | Bookings lookup | **Hecho** | `GET /api/bookings/lookup?q=` |
| 8 | MOVE Driver role claim | **Hecho** | JWT claim `role` = `"1"` (string) |
| 9 | MOVE fare labels | **Hecho** | Labels ES en breakdown + bandas |
| 10 | Pinduck/familia moneda | **Hecho** | Default moneda del país del pagador; `preferredPaymentMethod` opcional |

---

## 1) Búsqueda de personas

```http
GET /api/users/search?q=
```

Matchea (mín. 2 caracteres):

- Nombre / apellido
- Username con o sin `@`
- `ciervoUserCode` case-insensitive, con o sin prefijo `CIERVO-`
- Email
- Teléfono (normalizado o sufijo)

Teléfonos en lote: `POST /api/users/search/by-phones`.

```json
{
  "status": true,
  "value": {
    "items": [
      {
        "userId": 33,
        "ciervoUserCode": "CIERVO-XXXX",
        "username": "sebas",
        "displayName": "Sebastian Guerrero",
        "country": "CL"
      }
    ]
  }
}
```

---

## 2) ID operativo de sesión

```http
GET /api/users/me
```

Campos nuevos:

```json
{
  "operationalSessionId": "CIERVO-20260727-DIA-0001",
  "operationalBand": "day",
  "nightOperationalId": "CIERVO-20260727-DIA-0001"
}
```

| Band | Código en ID | Horario local |
|------|--------------|---------------|
| `day` | `DIA` | 06:00–17:59 |
| `night` | `NOCHE` | 18:00–05:59 |
| `24h` | `24H` | (reservado; forzar vía preferencia futura) |

TZ: `CL` → Pacific SA / Santiago; `CO` → SA Pacific (UTC-5).  
`nightOperationalId` se mantiene por compatibilidad (= `operationalSessionId` de la franja actual).

---

## 3) Wallet / moneda por país

Al crear/asegurar wallet cards:

- `countryCode=CL` → `currency=CLP`
- `CO` → `COP`
- `MX` → `MXN`, etc. (`SettlementCountryCatalog`)

Si una card existente tiene saldo `0` y moneda incorrecta, se repara al ensure wallet.

La app debe dejar de asumir COP cuando el usuario es CL.

Membresías: `estimatedLocalCurrency` ya viene del quote por país en catálogo.

---

## 4) Favoritos

```http
GET    /api/users/me/favorite-businesses
POST   /api/users/me/favorite-businesses/{businessId}
DELETE /api/users/me/favorite-businesses/{businessId}
GET    /api/users/me/favorite-businesses/check/{businessId}
GET    /api/users/me/favorite-businesses/{businessId}/check   # alias
```

**No** se filtra por radio 25 km a menos que el cliente envíe `nearLat`, `nearLng` y `radiusKm`.

---

## 5) Chats de negocio

En listado/detalle de conversaciones, si `businessId` está set:

```json
{
  "id": 10,
  "type": "Business",
  "businessId": 22,
  "businessName": "JRASERVICIOS…",
  "businessLogoUrl": "https://…",
  "logoUrl": "https://…",
  "title": "JRASERVICIOS…"
}
```

Si el título legacy era “Consulta Nuevo negocio…”, el backend lo reemplaza por el nombre comercial cuando hay club.

---

## 6) UID tarjeta física NFC

```http
POST /api/wallet/cards/{cardId}/physical-nfc
```

Si ya hay un UID **Active** en esa wallet card:

- HTTP **409 Conflict**
- Body: `{ "status": false, "msg": "PHYSICAL_NFC_ALREADY_REGISTERED" }`

No se sobrescribe ni regenera.

---

## 7) Lookup de reservas

```http
GET /api/bookings/lookup?q=
```

Acepta:

- Código `RSV-XXXXXXXX`
- `@username` del titular
- Documento de identidad del cliente
- Token/payload QR de la reserva

Auth: dueño de la reserva, staff con `bookings.view`, o admin.

Sigue existiendo: `GET /api/bookings/by-code/{code}`.

---

## 8) MOVE Driver — rol 1

JWT de cliente incluye:

- `http://schemas.microsoft.com/ws/2008/06/identity/claims/role` = `"1"`
- Claim corto **`role`** = `"1"` (string)

`RoleType.Client = 1`. La app puede validar `role == "1"`.

Si el usuario solo tiene sesión Business/Driver sin claim Client, debe hacer login Client explícito.

---

## 9) Breakdown tarifas MOVE

`breakdown` ahora incluye labels ES:

```json
{
  "baseFare": 2500,
  "baseFareLabel": "Tarifa base",
  "distanceAmount": 1800,
  "distanceAmountLabel": "Distancia",
  "nightSurcharge": 200,
  "nightSurchargeLabel": "Recargo nocturno",
  "rainSurchargeLabel": "Recargo lluvia",
  "highDemandSurchargeLabel": "Alta demanda",
  "airportSurchargeLabel": "Recargo aeropuerto",
  "promoDiscountLabel": "Descuento promo",
  "cashbackDiscountLabel": "Cashback aplicado",
  "subtotalLabel": "Subtotal",
  "bandCharges": [
    { "fromKm": 0, "toKm": 5, "amount": 900, "label": "Tramo 0-5 km" }
  ]
}
```

La app puede mostrar `*Label` o seguir mapeando camelCase.

---

## 10) Pago Pinduck / familia

- Límites kid payment: si no envían `currency`, se usa la del **país del guardian** (CL→CLP).
- Request opcional:

```json
{
  "cardId": "...",
  "approvalMode": "AUTO_APPROVAL",
  "currency": "CLP",
  "preferredPaymentMethod": "digital_card"
}
```

Valores sugeridos: `digital_card` | `physical_card` | `pin` | `at_handle`.

---

## Smoke mobile (prod)

Deploy: revisión **`ciervo-backend-00188-ttb`**.

```bash
# /users/me operational band
curl -s -H "Authorization: Bearer $CLIENT_TOKEN" "$BASE/api/users/me" \
  | jq '{band:.value.operationalBand, session:.value.operationalSessionId, country:.value.countryCode}'

# search CIERVO
curl -s -H "Authorization: Bearer $CLIENT_TOKEN" "$BASE/api/users/search?q=CIERVO-" | jq .status

# bookings lookup
curl -s -H "Authorization: Bearer $CLIENT_TOKEN" "$BASE/api/bookings/lookup?q=RSV-TEST" | jq .

# system (sanity)
curl -s "$BASE/api/system/status" | jq .
```

Smoke admin panel (mismo deploy): `orders-unified`, `delivery/metrics`, `wallet`, `customers`, `loyalty/settings`, `insights/recommendations`, `settings`, `system/status` → **OK**.

---

## Breaking / non-breaking

| Cambio | Tipo |
|--------|------|
| Campos nuevos en `/users/me` y chat | Non-breaking |
| Claim JWT `role` adicional | Non-breaking |
| Labels MOVE | Non-breaking |
| NFC 409 | Comportamiento más estricto (esperado por UI) |
| Wallet currency repair (saldo 0) | Non-breaking / corrección datos |
