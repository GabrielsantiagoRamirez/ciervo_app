# Prompt Flutter Mobile — Cierre auditoría Kids/Familia + pagos + perfil adulto

**Backend:** `Ciervo-backend` (este repo)  
**Contrato SSOT:** `docs/BACKEND-AUDIT-EF-KIDS-FIX.md`, `docs/KIDS-API-CONTRACT.md`, `docs/FAMILY-PAYMENT-API-CONTRACT.md`  
**Migración DB requerida:** `20260706120000_UserUsernameNightOperationalIdAndDeliveryCommission`

---

## Objetivo

Integrar en la app mobile los cambios de backend ya implementados tras la auditoría Kids/Familia. Prioridad P0: perfil Kids sin crash, solicitudes de pago enriquecidas, aprobación con tarjeta de respaldo, búsqueda por @username y saldos wallet correctos.

---

## 1. Perfil Kids — `GET /api/kids/me/profile` (P0)

### Problema resuelto en backend
EF Core fallaba al ordenar tutores con concatenación de nombre en SQL. El endpoint ahora devuelve campos **siempre como string** (nunca `null` en JSON para strings de presentación).

### Response `value` — campos obligatorios en UI

| Campo | Uso en UI |
|-------|-----------|
| `firstName` | Nombre legal |
| `lastName` | Apellido |
| `displayName` | Apodo visible (nickname o nombre completo) |
| `nickname` | Alias editable |
| `username` | @usuario Kids |
| `ciervoUserCode` | CIERVO ID del menor (`kidsPublicId`) |
| `role` | `"Kid"` |
| `roleLabel` | `"Menor"` |
| `photoUrl` | Avatar |
| `familyName` | "Familia {apellido tutor}" |
| `guardians[]` | Lista tutores |

### Acciones Flutter
- Mapear el DTO con defaults: `?? ''` para todos los strings de presentación.
- Pantalla perfil Kids: mostrar `@username`, CIERVO ID y apodo desde los campos nuevos (no inferir solo desde `name`).
- Si `status: false`, mostrar `msg` amigable — **nunca** mostrar stacktrace ni texto técnico de EF/SQL al usuario.

---

## 2. Solicitudes de pago — `GET /api/payment-requests/inbox|sent` (P0)

### Campos nuevos en cada item

| Campo | Ejemplo | UI |
|-------|---------|-----|
| `statusLabel` | `"Pendiente"`, `"Pagada"` | Badge de estado (usar esto, no mapear `status` int manualmente) |
| `requesterUsername` | `"ana.perez"` | @usuario emisor |
| `requesterName` | `"Ana Pérez"` | Nombre completo |
| `requesterCiervoUserCode` | `"KIDS-12345678"` | CIERVO ID |
| `description` | Concepto | Siempre string (vacío si no hay) |
| `amount` + `currency` | Monto | Formato moneda |

### Aprobar con tarjeta de respaldo — `POST /api/payment-requests/{id}/approve`

Body **opcional**:

```json
{
  "useBackupCard": true,
  "familyPaymentCardId": "uuid-public-card-id-opcional"
}
```

| Caso | Body |
|------|------|
| Pago con wallet (default) | `{}` o sin body |
| Tarjeta familia explícita | `{ "useBackupCard": true, "familyPaymentCardId": "..." }` |
| Tarjeta familia por defecto | `{ "useBackupCard": true }` |

**UI sugerida:** si wallet insuficiente, ofrecer toggle "Usar tarjeta de respaldo" que envía `useBackupCard: true`. Listar tarjetas desde `GET /api/family-payment/cards` y pasar `publicCardId` en `familyPaymentCardId`.

---

## 3. Perfil adulto — @username e ID nocturno (P1)

### `GET /api/users/me` — campos nuevos

```json
{
  "username": "gabriel",
  "nightOperationalId": "CIERVO-20260706-NOCHE-0001",
  "ciervoUserCode": "CIERVO-12345678"
}
```

- `username`: único, min 3 chars, sin `@` en almacenamiento (la UI puede mostrar `@gabriel`).
- `nightOperationalId`: secuencial por turno nocturno (18:00–05:59 Colombia). Se genera automáticamente en cada `GET /me`.

### Configurar username — `PUT /api/users/me`

```json
{
  "name": "Gabriel",
  "lastname": "López",
  "username": "gabriel"
}
```

Errores típicos: `"Username no disponible."`, `"El username debe tener al menos 3 caracteres."`

### Búsqueda global — `GET /api/users/search?q=@gabriel`

- Acepta `@` al inicio (backend lo normaliza).
- Items incluyen `username` además de `displayName` y `ciervoUserCode`.
- Usar en: chat, solicitudes de pago, vacas, reservas, transferencias.

---

## 4. Wallet — saldos COP (P0)

### `GET /api/wallet/cards`

Cada tarjeta devuelve:

| Campo | Significado |
|-------|-------------|
| `balance` | Saldo total |
| `heldBalance` | Retenido (pendientes) |
| `availableBalance` | **Usar este para "disponible"** (`balance - heldBalance`) |

**Regla UI:** nunca mostrar `balance` como disponible si hay `heldBalance > 0`. Si `availableBalance == 0` y `balance > 0`, explicar "saldo retenido".

---

## 5. Delivery — comisión 1% (P1, solo visualización)

El backend guarda internamente comisión Ciervo al **1%** del fee de domicilio (`platformCommissionPercentApplied`, `platformFee`, `courierEarning`). **No calcular comisión en el cliente.**

Para el usuario mobile mostrar solo:
- `deliveryFee` / `totalAmount` del pedido
- ETA: `estimatedDeliveryMinutes` en availability
- PIN: `pickupPin` / `deliveryPin` según rol y estado

No mostrar desglose `platformFee` al cliente final (solo courier/business si aplica su app).

---

## 6. Vakupli — máximo 5 personas (P1)

Al unirse o invitar a una vaca, si el grupo ya tiene 5 participantes aceptados:

```
"El grupo ya alcanzo el maximo de 5 participantes."
```

Mostrar contador `participantCount / 5` en detalle de vaca.

---

## 7. Chat comercial desde reserva (ya en backend)

Al crear reserva conectada, el backend crea conversación + mensaje sistema con recibo. Mobile debe:
- Navegar al chat si `conversationId` viene en la respuesta de booking.
- Renderizar mensajes `type: booking_receipt` en metadata.

---

## 8. Errores globales

El middleware devuelve mensajes amigables:

```json
{ "status": false, "msg": "Ocurrio un error interno procesando la solicitud." }
```

**Nunca** parsear ni mostrar excepciones .NET/SQL al usuario.

---

## Checklist de implementación

- [ ] DTO `KidMeProfileResponse` con todos los campos string non-null
- [ ] Perfil Kids sin crash al cargar tutores
- [ ] Inbox/sent payment requests con `statusLabel` y datos del emisor
- [ ] Approve con body opcional `useBackupCard`
- [ ] Wallet UI usa `availableBalance`
- [ ] Perfil adulto muestra `@username` y `nightOperationalId`
- [ ] Búsqueda usuarios con `@` prefix
- [ ] Vakupli: límite 5 + mensaje de error
- [ ] Aplicar migración DB antes de deploy backend

---

## Deploy backend (ops)

```bash
dotnet ef database update --project DataAccess --startup-project WebApi
```

O aplicar migración `20260706120000_UserUsernameNightOperationalIdAndDeliveryCommission` en el entorno correspondiente.

---

## Pendiente (requiere credenciales / servicios externos)

| Módulo | Dependencia |
|--------|-------------|
| Kids tutor/aprobaciones push | Firebase FCM configurado |
| Delivery mapa/ETA en tiempo real | Google Maps API key en mobile |
| Cobro tarjeta respaldo real | Mercado Pago prod + tarjetas tokenizadas |
