# Transferir dinero CIERVO — contrato mobile + admin

Fecha: 2026-08-02  
Revisión prod objetivo: endpoints bajo `/api/wallet/*` y búsqueda `/api/users/search`.

## Resumen

El backend soporta el bottom sheet **Transferir dinero** del ecosistema cerrado CIERVO:

| Botón / sección UI | Backend | Estado |
|--------------------|---------|--------|
| Buscar usuario (CIERVO ID / @usuario) | `GET /api/users/search?q=` + `GET /api/wallet/resolve-user/{lookup}` | Listo |
| CIERVO ID | `GET /api/wallet/resolve-user/CIERVO-########` → preview → transfer | Listo |
| @Usuario | `resolve-user/@carlos` o `?q=@carlos` + `targetUsername` en transfer | Listo |
| Contactos CIERVO | `GET /api/wallet/transfer/contacts` | Listo |
| Favoritos ⭐ | `GET/POST/DELETE /api/wallet/transfer/favorites` | Listo |
| Escanear QR | `POST /api/qr/resolve` → `ciervo://user/CIERVO-…` → resolve-user | Listo |
| Transferencias recientes | `GET /api/wallet/transfer/recent` | Listo |
| Transferencia internacional | `POST /api/wallet/transfer/preview` + `TargetCurrency` en transfer | Listo (FX vía tasas) |
| Continuar / Confirmar | `POST /api/wallet/transfer/preview` → `POST /api/wallet/transfer` | Listo |

**No usar** `POST /api/users/search/by-phones` para este flujo (el spec prohíbe agenda telefónica).

---

## Endpoints (auth `ClientOnly`)

### Resolve destinatario
- `GET /api/wallet/resolve-user/{lookup}`
- `GET /api/wallet/resolve-user?q={lookup}`

`lookup` acepta: `CIERVO-81935499`, `@carlos`, `carlos`, `ciervo://user/CIERVO-…`.

Response (`value`):
```json
{
  "userId": 20,
  "ciervoUserCode": "CIERVO-81935499",
  "username": "carlos",
  "displayName": "Carlos Nossa",
  "photoUrl": "https://...",
  "countryCode": "CL",
  "localCurrency": "CLP",
  "isVerified": true,
  "isBusiness": false,
  "isFavorite": false
}
```

### Buscar usuarios (filtros)
`GET /api/users/search?q=@carlos&country=CL&includeOtherCountries=true&type=person&verifiedOnly=true`

| Query | Uso |
|-------|-----|
| `q` | Texto (≥2). Soporta `@`, CIERVO ID, nombre |
| `country` | `CL` / `CO` / … |
| `includeOtherCountries` | `true` = búsqueda internacional |
| `type` | `person` \| `business` (comercio/empresa) |
| `verifiedOnly` | solo email/teléfono verificado |

Items incluyen `isVerified`, `isBusiness`, `accountType`.

> Online / Premium / Kids / Fundación: aún no hay flags dedicados en `CLIENT`. Mobile puede ocultar esos chips o tratarlos como no disponibles.

### Contactos / Favoritos / Recientes
| Método | Ruta |
|--------|------|
| GET | `/api/wallet/transfer/contacts?take=50` |
| GET | `/api/wallet/transfer/favorites` |
| POST | `/api/wallet/transfer/favorites` body `{ "targetUserId" \| "targetCiervoUserCode" \| "targetUsername" }` |
| DELETE | `/api/wallet/transfer/favorites/{favoriteUserId}` |
| GET | `/api/wallet/transfer/recent?take=20` |

Cada item: foto, nombre, `@username`, CIERVO ID, país, moneda local, última transferencia (si aplica), `isFavorite`.

### Preview (nacional / internacional)
`POST /api/wallet/transfer/preview`
```json
{
  "targetUsername": "carlos",
  "amount": 50000,
  "currency": "CLP",
  "targetCurrency": null,
  "message": "Para el almuerzo"
}
```

Si el destinatario tiene otra moneda local (ej. CO → COP), el preview convierte automáticamente.

Response clave: `isInternational`, `sendAmount/sendCurrency`, `fee`, `totalDebit`, `receiveAmount/receiveCurrency`, `exchangeRate`, `estimatedTime` (`Instantáneo`), `sufficientFunds`.

### Ejecutar transferencia
`POST /api/wallet/transfer`
```json
{
  "targetUsername": "carlos",
  "amount": 50000,
  "currency": "CLP",
  "targetCurrency": "COP",
  "idempotencyKey": "xfer-unique-1",
  "message": "Hola"
}
```

También acepta `targetUserId` / `targetCiervoUserCode`.  
Debita wallet origen (subtotal + fee 1%) y acredita monto convertido en wallet destino.

Quote simple (sin FX): `POST /api/wallet/transfer/quote` (existente).

### QR propio
`GET /api/wallet/me/ciervo-id` → `qrPayload = ciervo://user/CIERVO-…`

---

## Seguridad (responsabilidad por capa)

| Control | Backend hoy | Mobile |
|---------|-------------|--------|
| Solo usuarios CIERVO | Sí (lookup en `CLIENT`) | — |
| Biometría | Challenge/verify device existen; **no gate obligatorio** en transfer | Solicitar antes de confirmar |
| PIN wallet | PIN durable P2P existe (`/api/pins/*`); transfer wallet no lo exige aún | Pedir PIN local / biometric |
| 2FA montos altos | No cableado a transfer | Mostrar Authenticator cuando monto > umbral (configurable en app hasta existir config server) |
| Trust score destinatario | Fraud score admin existe; no bloquea P2P aún | Banner “cuenta nueva” con `isVerified` / antigüedad si se agrega |

---

## Panel administrativo

**No requiere pantallas nuevas para este MVP.** Ya hay:

- `GET /api/admin/wallet/transactions`
- `GET /api/admin/financial-audit/logs` (`wallet_transfer_succeeded`)
- `GET/POST /api/admin/exchange-rates` (tasas FX)

Útil más adelante (no bloqueante): umbrales 2FA/PIN configurables, vista filtrada “P2P transfers”, moderación de abuse en favoritos.

---

## Flujo mobile recomendado

1. Bottom sheet → buscar / contactos / favoritos / recientes / escanear QR.  
2. Resolve destinatario.  
3. Formulario monto + moneda (+ mensaje).  
4. `transfer/preview` → pantalla confirmar (nacional o FX).  
5. Biometría / PIN en device.  
6. `transfer` con `idempotencyKey` único.  
7. Estrella → `POST transfer/favorites`.
