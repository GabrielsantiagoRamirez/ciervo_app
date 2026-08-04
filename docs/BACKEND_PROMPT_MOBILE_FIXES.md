# Prompt para Backend — Correcciones móviles Ciervo (CL / chats / wallet / reservas)

Copia y pega este prompt al equipo de backend:

---

## Contexto
Estamos ajustando la app Flutter (Ciervo Club / Ciervo Move). Varios flujos ya tienen UI lista, pero faltan datos o reglas del API. Usuario de prueba en **Chile (CL / CLP)**; hoy varios endpoints responden como si fuera **Colombia (CO / COP)**.

## 1) Búsqueda de personas (`GET /api/users/search?q=`)
La app envía `q` crudo (nombre, `@usuario` o `CIERVO-XXXXXXXX`).
Confirmar y documentar qué matchea el backend:
- ¿CIERVO ID exacto / parcial?
- ¿username con y sin `@`?
- ¿nombre?
- ¿teléfono solo vía `POST /api/users/search/by-phones`?

Si `CIERVO-XXXX` no busca por ID hoy, implementar búsqueda por `ciervoUserCode` (case-insensitive, con o sin prefijo).

## 2) ID operativo de sesión (día / noche / 24h)
Hoy el perfil solo expone `nightOperationalId` tipo `CIERVO-20260723-NOCHE-0001` y la UI quedaba “pegada” en noche.
Necesitamos:
- Generar la franja según el **modo de experiencia** del usuario o la hora local del país: `DIA` | `NOCHE` | `24H`.
- Campos sugeridos en `GET /api/users/me` (o equivalente):
  - `operationalSessionId` (canónico)
  - `operationalBand`: `day` | `night` | `24h`
  - Mantener `nightOperationalId` solo por compatibilidad, o deprecarlo.
- Regenerar/actualizar el ID cuando cambie la franja (no dejar `NOCHE` fijo de madrugada/tarde).

## 3) Wallet / moneda por país (crítico)
Error visto en app: *"La wallet (COP) no corresponde a la configuracion de CL (CLP)."*
Si el usuario tiene `countryCode=CL`, al crear wallet/card debe nacer en **CLP**, no COP.
Revisar:
- creación de wallet al registrar / primer login
- `GET /api/wallet/cards`
- recargas Mercado Pago (país + moneda alineados a CL)
- membresías: `GET .../client-plans?countryCode=CL` debe devolver `estimatedLocalCurrency=CLP` (no COP por defecto)

## 4) Favoritos
`POST/DELETE/GET /api/users/me/favorite-businesses`
Al dar like desde detalle o card, el negocio debe aparecer en “Mis favoritos” **sin filtrar por radio 25 km** a menos que el cliente lo pida.
Confirmar persistencia y que `GET .../check/{businessId}` coincida con el listado.

## 5) Chats de negocio
Al crear/listar conversaciones business, devolver:
- `businessId`
- `businessName` (nombre comercial real, no “Nuevo negocio en CIERVO…”)
- `businessLogoUrl` / `logoUrl` / mediaId
- `type: business`

El título del inbox debe poder mostrar nombre + logo. Hoy a veces llega “Consulta Nuevo negocio…”.

## 6) UID tarjeta física NFC
`POST /api/wallet/cards/{cardId}/physical-nfc`
Regla: **un UID activo por wallet card**. Si ya existe UID no bloqueado:
- responder `409` / código `PHYSICAL_NFC_ALREADY_REGISTERED`
- no permitir regenerar ni sobrescribir
La app ya bloquea en UI; hace falta la validación en back.

## 7) Consulta de reservas ampliada
Hoy solo: `GET /api/bookings/by-code/{code}` (RSV-…).
Necesitamos búsqueda unificada, por ejemplo:
`GET /api/bookings/lookup?q=`
aceptando:
- código `RSV-XXXXXXXX`
- `@username` del titular
- número de documento usado en la reserva
- payload/token de QR guardado en favoritos

## 8) MOVE Driver — rol 1
Mensaje: *"MOVE Driver requiere una sesión Client explícita (rol 1)."*
Es gate del JWT (`role == "1"`). Confirmar que el token de clientes emite `role: "1"` (string) y no otro formato. Si el usuario es solo driver/staff, documentar el flujo de “sesión Client explícita”.

## 9) Breakdown de tarifas MOVE
Si `breakdown` llega como map camelCase (`baseFare`, `nightSurcharge`…), la app ya traduce a español. Ideal: enviar también `label` legible en español desde el API.

## 10) Pago Pinduck / aprobaciones
Aceptar moneda del país del pagador (CLP en Chile). Evitar defaults COP hardcodeados en back.
Opcional: campo `preferredPaymentMethod` (`digital_card` | `physical_card` | `pin` | `at_handle`).

## Respuesta esperada
Para cada punto: estado actual, cambio a hacer, contrato JSON de ejemplo, y ETA.

---

*Generado desde el repo Flutter `ciervo_clud` tras auditoría FE/BE.*
