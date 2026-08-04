# Prompt Flutter — Tarjetas físicas NFC (multi + editar/revocar)

## Contexto
El backend ya no limita a **1 UID Active por wallet card**. Se pueden registrar varias tarjetas físicas; cada una tiene identificador de plataforma único (`identifier`) y UID de chip único (`cardUid`). El UID **no se edita**; para quitar una tarjeta se **revoca** (libera el UID).

Base: `https://api.ciervo.club`  
Auth: Bearer client token.

## Endpoints

### Listar
`GET /api/wallet/nfc/physical-cards`  
→ `{ status, value: PhysicalNfcCard[] }` (sin paginar)

### Registrar (varias permitidas)
`POST /api/wallet/cards/{walletCardId}/physical-nfc`
```json
{ "cardUid": "KIDS-F11756B6F7D", "label": "Tarjeta escolar" }
```
- 200 OK si crea
- 409 / `status:false` si el **UID** ya está usado por otra tarjeta no revocada

### Detalle
`GET /api/wallet/physical-nfc/{physicalCardId}`

### Editar etiqueta
`PUT /api/wallet/physical-nfc/{physicalCardId}`
```json
{ "label": "Tarjeta escolar (nuevo)" }
```
No enviar `cardUid` (no se puede cambiar).

### Bloquear / desbloquear / eliminar
- `POST /api/wallet/physical-nfc/{id}/block`
- `POST /api/wallet/physical-nfc/{id}/unblock`
- `POST /api/wallet/physical-nfc/{id}/revoke` o `DELETE /api/wallet/physical-nfc/{id}`

## Modelo `PhysicalNfcCard`
```json
{
  "id": 12,
  "identifier": "NFC-00000012",
  "walletCardId": 5,
  "childProfileId": null,
  "childWalletCardId": null,
  "cardUid": "KIDS-F11756B6F7D",
  "label": "Tarjeta escolar",
  "status": "Active",
  "createdAt": "...",
  "blockedAt": null,
  "updatedAt": null,
  "canEdit": true,
  "canBlock": true,
  "canUnblock": false,
  "canRevoke": true
}
```
`status`: `Active` | `Blocked` | `Revoked` (revocadas no salen en el listado).

## Cambios UI requeridos
1. **Quitar** estados/botones “UID ya registrado” / “Tarjeta UID registrado” que bloquean el alta global.
2. Botón **“Agregar tarjeta física”** siempre visible (si el plan tiene NFC), abre flujo NFC o UID manual.
3. Lista: mostrar `label`, `identifier`, `cardUid` (enmascarado opcional), `status`.
4. Acciones por ítem según flags:
   - `canEdit` → editar nombre
   - `canBlock` → bloquear
   - `canUnblock` → desbloquear
   - `canRevoke` → eliminar/revocar (confirmación: “Se podrá volver a registrar este UID”)
5. Tras revoke, refrescar lista; el UID queda libre para un nuevo registro.
6. No filtrar ni asumir 1 sola tarjeta por wallet.

## Criterios de aceptación
- [ ] Con una tarjeta ya activa, se puede registrar otra con **otro** UID.
- [ ] Mismo UID dos veces → error claro (UID en uso).
- [ ] Editar solo cambia label.
- [ ] Bloquear/desbloquear actualiza status y botones.
- [ ] Revocar quita de la lista y permite re-registrar ese UID.
- [ ] Textos “UID ya registrado” no bloquean el alta de nuevas tarjetas.
