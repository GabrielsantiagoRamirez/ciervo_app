# Entrega final al equipo Flutter — Kids v2 + Movie/Chat v2

**Fecha de corte del contrato:** 2026-07-17  
**Rama backend auditada:** `feat/enterprise-ciervo-update`  
**Contrato fuente de verdad:** código actual del backend. Este documento no afirma que ninguna pantalla, modelo o integración Flutter ya esté implementada.

## 1. Base técnica, autenticación y formato común

### Base URL y versión

- Base pública configurada para producción: `https://api.ciervo.club` (`WebApi/appsettings.Production.json`, `AppUrls:PublicBaseUrl`).
- Desarrollo: `https://localhost:7150`.
- Los contratos nuevos usan principalmente `/api/v1/...`; siguen existiendo rutas `/api/...` y aliases explícitos indicados más abajo.
- Swagger declara versión `v1` en `WebApi/Program.cs`.

No concatenar dos veces `/api`; configurar el cliente con la raíz del host.

### Headers realmente soportados

```http
Authorization: Bearer <access-token>
Content-Type: application/json
Accept: application/json
```

Para SSE:

```http
Accept: text/event-stream
Cache-Control: no-cache
Authorization: Bearer <access-token>
```

Precisiones importantes:

- No hay lectura de un header `Idempotency-Key` en estos controladores. La idempotencia implementada se envía como campo JSON `idempotencyKey`.
- No hay soporte de `Last-Event-ID` en controladores. La reanudación se hace con query `?cursor=<último-id>` en Kids/Movie o `?sinceId=<último-id>` en notificaciones.
- El `id:` emitido por SSE Kids/Movie debe persistirse en memoria/almacenamiento de sesión y reenviarse como `cursor`.

### JWT, roles y claims

Roles numéricos (`Models/Enums/RoleType.cs`, policies en `IOC/Dependencies.cs`):

- `1`: Client, adulto/tutor.
- `2`: Business.
- `3`: Admin.
- `4`: Kid.

Policies usadas:

- `ClientOnly`: role `1`.
- `KidOnly`: role `4`.
- `ClientOrKid`: role `1` o `4`.
- `BusinessOrAdmin`: role `2`/`3` o `accountKind=BusinessUser`/`PlatformAdmin`.
- `AdminOnly`: role `3` o `accountKind=PlatformAdmin`.

Claims consumidos (`WebApi/Extensions/ClaimsPrincipalExtensions.cs`):

- `nameidentifier`: `userId`, autoridad del actor.
- `role`: rol numérico.
- `accountKind`: `Kid`, `BusinessUser` o `PlatformAdmin` cuando aplica.
- Kids: `childProfileId` y `familyId`.

El JWT Kids se emite con `nameidentifier`, `name`, role `4`, `accountKind=Kid`, `childProfileId` y `familyId` (`Business/Security/JwtTokenService.cs`). `ciervoId`, `kidId`, `userId`, `payerUserId` u otros IDs enviados por el cliente nunca reemplazan al actor JWT; el backend vuelve a comprobar propiedad/participación.

### Envoltorio de éxito/error

La mayoría de servicios devuelve:

```json
{
  "status": true,
  "value": {},
  "msg": null,
  "errorCode": null
}
```

`Models/Response.cs` define exactamente `status`, `value`, `msg`, `errorCode`. No asumir que todo error usa el mismo formato: errores de validación automática, middleware y respuestas HTTP vacías se normalizan como RFC 7807:

```json
{
  "type": "https://httpstatuses.com/400",
  "title": "Solicitud inválida",
  "status": 400,
  "detail": "Detalle seguro",
  "instance": "/api/v1/...",
  "correlationId": "..."
}
```

En validaciones de DataAnnotations, además aparece `errors: { "campo": ["mensaje"] }`. Referencias: `WebApi/Program.cs`, `WebApi/Middlewares/GlobalExceptionMiddleware.cs`.

HTTP que Flutter debe manejar:

- `200`: operación procesada; revisar también `status`, porque varios endpoints legacy responden `200` con `status=false`.
- `400`: DTO inválido, estado inválido o regla de negocio en controladores legacy.
- `401`: JWT ausente/inválido, login o refresh rechazado.
- `403`: rol, propiedad, actor o negocio no autorizado.
- `404`: recurso inexistente.
- `409`: conflicto/idempotencia/inventario/QR ya emitido o consumido.
- `410`: QR Movie expirado.
- `422`: error de pago Movie (`PAYMENT_ERROR`).
- `429`: rate limit. Login Kids: 5 solicitudes/minuto por IP; global: 120/minuto por IP.
- `500`: error interno sin detalle sensible.

Movie traduce `NOT_FOUND→404`, `FORBIDDEN→403`, `CONFLICT→409`, `GONE→410`, `PAYMENT_ERROR→422`; otros códigos (`VALIDATION`, `INVALID_STATE`) terminan en `400` (`WebApi/Controllers/MovieController.cs`).

## 2. Inventario de endpoints Kids v2

Todos requieren `Authorization` salvo los marcados públicos.

### Identidad, perfil, settings y Shield

- `POST /api/v1/kids/auth/login` — público; login PIN o Firebase.
- `POST /api/v1/kids/auth/refresh` — público; rota refresh token.
- `GET /api/v1/kids/profile` — Kid.
- `GET /api/v1/kids/settings` — Kid; horario, límites, categorías, geocercas y wallet.
- `POST /api/v1/kids/security/attempt` — Kid; registra intento Shield.
- `POST /api/v1/kids/shield/validate` — Client/Kid; valida una sesión accesible por `paymentSessionId`.
- Alias legacy vigente: `POST /api/kids/rules/validate`.
- `POST /api/v1/security/block-all` — Client; bloqueo global del menor.
- `POST /api/v1/security/unblock-all` — Client.
- Alias compatible: `POST /api/v1/security/unlock-all`.

### Commerce

- `GET /api/v1/commerce/search?name=&city=&category=` — Kid; máximo 100.
- `GET /api/v1/commerce/{commerceId}` — Kid.
- `POST /api/v1/commerce/read-qr` — Kid.
- `POST /api/v1/commerce/validate-id` — Kid.
- `GET /api/v1/commerce/{commerceId}/reservation-policy` — público.

Solo aparecen comercios habilitados, aprobados, visibles y que aceptan pagos CIERVO (`Business/Services/EnterpriseKidsV2Service.cs`).

### Solicitudes y Master

- `POST /api/v1/kids/payment-request` — Client/Kid.
- `GET /api/v1/kids/payment-request` — Client/Kid; enviadas.
- `PUT|POST /api/v1/kids/payment-request/{id}/cancel` — Client/Kid.
- Alias plural idéntico: `/api/v1/kids/payment-requests`.
- `GET /api/v1/master/payment-requests/pending` — Client.
- `POST /api/v1/master/payment-requests/{id}/approve` — Client; para solicitud Kids aprueba y emite token+PIN.
- `POST /api/v1/master/payment-requests/{id}/reject` — Client.
- Legacy compatible:
  - `POST /api/payment-requests/pay-for-me`
  - `GET /api/payment-requests/inbox`
  - `GET /api/payment-requests/sent`
  - `POST /api/payment-requests/{id}/approve|reject|cancel`
- `GET /api/v1/master/dashboard` — Client.
- `POST /api/v1/master/reservation-policy/accept` — Client.
- `POST /api/v1/master/security/reset-attempts` — Client Master.
- `GET /api/v1/kids/security/attempts/{kidId}` — Client Master.

### Token de autorización y ejecución

- `POST /api/v1/payment/token` — Client Master; emite token+PIN para solicitud ya aprobada.
- `POST /api/v1/payment/token/validate` — autenticado no-Kid; tutor emisor o personal del comercio dueño.
- `POST /api/v1/payment/execute` — autenticado no-Kid; tutor emisor o personal del comercio dueño.

El secreto se devuelve una sola vez. Repetir emisión para la misma solicitud devuelve `token:null`, `pin:null`, `secretShown:false`. TTL actual: 3 minutos. El backend guarda hashes, no los secretos.

### Dispositivos Firebase Kids

- `GET /api/v1/master/kids/{kidId}/devices` — Client Master.
- `POST /api/v1/master/kids/{kidId}/devices` — Client Master; registra/prerregistra.
- `POST /api/v1/master/kids/{kidId}/devices/{deviceRegistrationId}/approve` — Client Master.
- `POST /api/v1/master/kids/{kidId}/devices/{deviceRegistrationId}/revoke` — Client Master.

Limitación real: no existe endpoint anónimo/Kid de auto-prerregistro. En el código actual el Master crea el registro, y `firebaseUid` debe coincidir exactamente con el vínculo Firebase ya guardado en la cuenta Kids.

### Administración Master del menor

- `POST /api/v1/master/kids`
- `POST /api/v1/master/kids/{kidId}/account`
- `PUT /api/v1/master/kids/{kidId}/limits`
- `PUT /api/v1/master/kids/{kidId}/schedule`
- `PUT /api/v1/master/kids/{kidId}/categories`
- `POST /api/v1/master/kids/{kidId}/geofence`
- `POST /api/v1/master/kids/{kidId}/secondary-admin`
- `DELETE /api/v1/master/kids/{kidId}/secondary-admin/{secondaryUserId}`

Solo el tutor primario puede usar estos aliases Master.

### Reglas, ubicación, wallet y NFC

Sesión QR Kids:

- `POST /api/kids/payments/scan` — Client/Kid.
- `POST /api/kids/payments/confirm` — Client/Kid.
- `GET /api/kids/payments/{paymentSessionId}/tracking` — Client/Kid.
- `GET /api/kids/payments/{paymentSessionId}/approval` — Client/Kid.
- `POST /api/kids/approvals/request` — Client/Kid.
- `GET /api/parents/approvals` — Client.
- `GET /api/parents/approvals/history?take=50` — Client.
- `POST /api/parents/approvals/{approvalId}/approve|reject` — Client.

Reglas Client:

- `/api/kids/{kidId}/rules/merchants`: `GET`, `POST`; `DELETE /{merchantId}`.
- `/api/kids/{kidId}/rules/categories`: `GET`, `POST`.
- `/api/kids/{kidId}/rules/limits`: `GET`, `PUT`.
- `/api/kids/{kidId}/rules/schedules`: `GET`, `PUT`.
- `/api/kids/{kidId}/rules/geofences`: `GET`, `POST`; `PUT|DELETE /{geofenceId}`.
- `/api/kids/{kidId}/rules/countries`: `GET`, `POST`; `DELETE /{countryCode}`.
- `/api/kids/{kidId}/rules/blocked-merchants`: `GET`, `POST`; `DELETE /{merchantId}`.

Ubicación:

- `POST /api/kids/{kidId}/location` — Client/Kid; Kid solo para su propio claim.
- `GET /api/kids/{kidId}/location` — Client.
- `GET /api/kids/{kidId}/location/locations?take=50` — Client.

Perfil/home Kid canónico:

- `GET /api/kids/me/home`
- `GET /api/kids/me/allowed-businesses?city=&zone=&categoryId=&query=&page=&pageSize=`
- `GET /api/kids/me/wallet`
- `POST /api/kids/me/pay-for-me/request`
- `GET /api/kids/me/pay-for-me/requests`
- `POST /api/kids/me/location/share`
- `GET|PATCH /api/kids/me/profile`
- `POST /api/kids/me/photo` — multipart, máximo 5 MiB.
- `GET /api/kids/me/family-chat`

Wallet aliases Kids:

- `GET /api/v1/kids/wallet/balance` — Kid.
- `GET /api/v1/kids/wallet/history` — Kid. Limitación: hoy devuelve el mismo `KidMeWalletResponse` que `balance`, incluidos solo `lastMovements`; no es historial paginado independiente.
- Canonical previo: `GET /api/kids/me/wallet`.

NFC Kids:

- `GET /api/v1/kids/nfc/status` — Kid.
- `POST /api/v1/master/kids/{kidId}/nfc/{physicalCardId}/enable|disable` — Client.
- Legacy vigente:
  - `POST /api/guardians/children/{childId}/nfc/cards/{cardId}/public-id`
  - `POST /api/guardians/children/{childId}/nfc/associate`
  - `POST /api/guardians/children/{childId}/nfc/physical/{physicalCardId}/block|unblock`
  - `POST /api/businesses/{businessId}/kids-nfc/pay` — Business/Admin.

Wallet NFC general (no es exclusivo Kids):

- `POST /api/wallet/nfc/sessions` — Client.
- `GET /api/wallet/nfc/sessions/{sessionId}` — Client.
- `POST /api/wallet/nfc/sessions/{sessionId}/cancel` — Client.
- `POST /api/wallet/nfc/validate` — Business/Admin.
- `POST /api/wallet/nfc/charge` — Business/Admin.
- `GET /api/wallet/nfc/physical-cards` — Client.
- `POST /api/wallet/cards/{cardId}/physical-nfc` — Client (varias por wallet; UID único).
- `GET /api/wallet/physical-nfc/{physicalCardId}` — Client.
- `PUT /api/wallet/physical-nfc/{physicalCardId}` — Client (editar label).
- `POST /api/wallet/physical-nfc/{physicalCardId}/block` — Client.
- `POST /api/wallet/physical-nfc/{physicalCardId}/unblock` — Client.
- `POST|DELETE /api/wallet/physical-nfc/{physicalCardId}/revoke` o `DELETE .../{id}` — Client (libera UID).


### Auditoría

- `GET /api/v1/audit/kids?kidId=&page=1&pageSize=50` — Client Master; `pageSize≤200`.
- `GET /api/v1/audit/export?kidId=` — Client Master; CSV UTF-8, máximo 10.000 filas, `Content-Disposition` de descarga.

### Chat, notificaciones y aliases

Chat mantiene las dos bases equivalentes: `/api/chat` y `/api/v1/chat`.

- `GET /conversations` y alias `GET /list`.
- `GET /conversations/{conversationId}` y alias `GET /{conversationId}`.
- `GET /conversations/{conversationId}/messages?page=&pageSize=`.
- `POST /conversations`.
- `POST /conversations/{conversationId}/messages` y alias `POST /{conversationId}/send`.
- `POST /commerce/share` y alias `POST /payment/share-commerce`.
- `POST /qr/share` y alias `POST /payment/share-qr`.
- `POST /payment-requests/share` y alias `POST /payment/share`.
- `POST /typed/movie/share`.
- `POST /move/share`.
- `POST /conversations/{conversationId}/messages/{messageId}/forward`.
- `POST /conversations/{conversationId}/read`.
- `GET /buttons`.
- `POST /calls/sessions`, `GET /calls/sessions/{id}`, `POST /calls/sessions/{id}/end`.
- `POST /conversations/{conversationId}/messages/media` — multipart, máximo 5 MiB.

Notificaciones mantiene `/api/notifications` y `/api/v1/notifications`:

- `GET ?page=&pageSize=&isRead=&category=&type=`
- `GET /badges`
- `POST /{id}/read`
- `POST /read-all`
- `DELETE /{id}`
- `DELETE /`
- `POST /fcm/register`
- `POST /fcm/unregister`
- `DELETE /fcm/tokens`
- `GET /events?sinceId=0` — SSE.

### Realtime durable Kids

- SSE: `GET /api/kids/payments/{paymentSessionId}/events?cursor=0`.
- Poll durable: `GET /api/kids/payments/{paymentSessionId}/events/poll?cursor=0&take=100`.
- Alias poll: `GET /api/v1/kids/security/events?paymentSessionId=...&cursor=0&take=100`.
- Tracking: `GET /api/kids/payments/{paymentSessionId}/tracking`.
- Approval: `GET /api/kids/payments/{paymentSessionId}/approval`.

Los eventos históricos Kids sí están persistidos en `KID_PAYMENT_STREAM_EVENT`; polling limita `take` a 1–200. SSE primero reproduce hasta 200 eventos posteriores al cursor y luego escucha el hub en memoria. Tras reconexión, usar de nuevo cursor/polling para no perder eventos.

## 3. DTOs Kids exactos para Flutter

JSON usa camelCase. `?` significa opcional/null. Las restricciones vienen de DataAnnotations.

### Login y dispositivo

`KidLoginRequest` (`DTO/KidAccountDtos.cs`):

```json
{
  "username": "kid_demo",
  "pin": "1234",
  "firebaseIdToken": null,
  "deviceId": "install-uuid",
  "platform": "android",
  "appVersion": "2.0.0"
}
```

- Modo PIN: `username` (≤50) y `pin` (4–12) obligatorios por lógica.
- Modo Firebase: `firebaseIdToken` (≤8192) y `deviceId` (≤160) obligatorios por lógica.
- Respuesta `KidLoginResponse`: `token`, `expiresAt`, `refreshToken`, `refreshTokenExpiresAt`, `user`.
- `user`: `userId`, `kidId`, `role`, `accountKind`, `name`, `photoUrl?`, `familyId`.

Refresh:

```json
{ "refreshToken": "<secreto>", "deviceId": "install-uuid" }
```

`refreshToken` requerido, mínimo 32; `deviceId` requerido en la práctica si el token quedó ligado a un dispositivo Firebase.

Registro Master:

```json
{
  "firebaseUid": "firebase-uid-del-menor",
  "deviceId": "install-uuid",
  "platform": "android",
  "appVersion": "2.0.0"
}
```

Respuesta `KidDeviceRegistrationResponse`: `id`, `kidId`, `deviceId`, `platform?`, `appVersion?`, `approved`, `revoked`, `registeredAt`, `approvedAt?`, `lastSeenAt?`.

### Solicitud, política y token

`PayForMeRequestDto` (`DTO/ChatPaymentDtos.cs`):

```json
{
  "payerUserId": 120,
  "payerCiervoUserCode": null,
  "targetUserId": null,
  "businessId": 25,
  "amount": 28000.00,
  "currency": "COP",
  "description": "Entrada de cine",
  "purpose": "PayForMe",
  "idempotencyKey": "payforme-install-uuid-0001",
  "chatConversationId": 44,
  "chatMessageId": null,
  "bookingId": null,
  "expiresAt": null
}
```

Requeridos: `amount>0`, `currency` ≤10, `idempotencyKey` ≤100. Para resolver pagador debe enviarse un identificador válido conforme al flujo; no usarlo como autoridad local.

`PaymentRequestResponse`: `id`, `requesterUserId`, `payerUserId`, `targetUserId?`, `businessId?`, `amount`, `currency`, `description?`, `purpose`, `status`, `statusLabel`, datos del solicitante, IDs de intent/transacción/recibo opcionales, `idempotencyKey`, fechas, referencias de chat/booking, `receipt?`, `checkoutUrl?`.

Estados `PaymentRequestStatus`: `1 Pending`, `2 Approved`, `3 Rejected`, `4 Expired`, `5 Cancelled`, `6 Paid`, `7 Failed`.

`AcceptReservationPolicyRequest`:

```json
{
  "paymentRequestId": 9001,
  "commerceId": 25,
  "policyVersion": 3,
  "idempotencyKey": "policy-install-uuid-0001"
}
```

`PaymentTokenCreateRequest`:

```json
{ "paymentRequestId": 9001, "idempotencyKey": "token-install-uuid-0001" }
```

`PaymentTokenIssuedResponse`: `authorizationId`, `paymentRequestId`, `commerceId`, `amount`, `currency`, `token?`, `pin?`, `expiresAt`, `secretShown`.

Validación:

```json
{ "token": "<token-one-time>", "pin": "654321" }
```

Ejecución:

```json
{
  "token": "<token-one-time>",
  "pin": "654321",
  "idempotencyKey": "execute-terminal-0001",
  "latitude": 4.710989,
  "longitude": -74.072092
}
```

`token` requerido ≤256; `pin` requerido 6–12; ejecución requiere `idempotencyKey` ≤100. Latitud/longitud son nullable en DTO, pero si existen geocercas activas su ausencia falla cerrada; deben enviarse juntas.

Respuesta de ejecución `KidsBusinessPaymentResponse`: `id`, `guardianUserId`, `childProfileId`, `childWalletId`, `childWalletCardId`, `businessId`, `paymentIntentId`, `paymentTransactionId`, `childWalletTransactionId?`, `childReceiptId?`, `guardianReceiptId?`, `businessReceiptId?`, `amount`, `currency`, `status`, `idempotencyKey`, `description?`, `rejectionReason?`, `createdAt`.

### Commerce, Shield y reglas

- `CommerceQrReadRequest`: `{ "value": "..." }`, requerido ≤500.
- `CommerceIdValidateRequest`: `{ "commerceId": 25 }`, `>0`.
- `KidsCommerceItem`: `commerceId`, `name`, `city?`, `categoryId?`, `address?`, `acceptsCiervoPayments`, `requiresReservation`.
- `ReservationPolicyResponse`: `commerceId`, `version`, `acceptanceRequired`, `terms`.
- `KidsRulesValidateRequest`: `{ "paymentSessionId": "..." }`, requerido ≤32.
- `KidsRulesValidateResponse`: `allowed`, `requiresApproval`, `ruleMatched?`, `reason?`.
- `KidSecurityAttemptRequest`: `attemptType` (default `shield_rejection`, ≤50), `resourceId?` ≤100, `restrictive` (default `true`), `reasonCode?` ≤80.
- `KidsSecurityActionRequest`: `kidId>0`, `reason?` ≤300.
- `ChildSpendingLimitRequest`: `dailyLimit?`, `weeklyLimit?`, `monthlyLimit?`, `currency` requerido ≤10.
- `KidSpendingScheduleDto`: `timezone` (default `America/Bogota`), `scheduleJson` (string JSON), `isActive`.
- `KidGeofenceRequest`: `name` requerido ≤120, `centerLatitude`, `centerLongitude`, `radiusMeters` 50–50000.

Sesión QR:

- `KidsQrScanRequest`: `kidId` requerido, `deviceId` requerido ≤120, `merchantQr` requerido ≤120, `amount>0`, `latitude?`, `longitude?`.
- `KidsQrScanResponse`: `paymentSessionId`, `merchant`, `amount`, `currency`, `approvalRequired`, `status`, `ruleMatched?`, `reason?`, `approvalId?`.
- `KidsQrConfirmRequest`: `paymentSessionId` requerido ≤32, `paymentMethod` requerido ≤30 (default `CIERVO_BALANCE`), `pin?` ≤20, `idempotencyKey` requerido ≤100.
- `KidsQrConfirmResponse`: `paymentSessionId`, `status`, `childBusinessPaymentId?`, `receipt?`.
- `KidsApprovalActionRequest`: `biometric`, `deviceInfo?` ≤200, `latitude?`, `longitude?`, `reason?` ≤500.
- `KidLocationPostRequest`: `latitude`, `longitude`, `label?` ≤200, `paymentSessionId?`.
- Poll durable devuelve `KidsRealtimeEventPageDto`: `nextCursor`, `hasMore`, `items`; cada item contiene `cursor`, `type`, `payloadJson?`, `createdAt`.

`MasterDashboardDto`: `availableBalance`, `currency`, contadores `pendingRequests`, `approvedRequests`, `rejectedRequests`, `paymentAttempts`, `restrictiveAttempts`, `blockedAccounts`, `averageApprovalMinutes?`, `frequentBusinesses`, `authorizedLocations`, `alerts`, `spendByCategory`, `generatedAt` (`DTO/DashboardDtos.cs`).

Reglas Shield relevantes: `MERCHANT_BLOCKED`, `COUNTRY_NOT_ALLOWED`, `GEOFENCE_LOCATION_REQUIRED`, `GEOFENCE_LOCATION_INVALID`, `GEOFENCE_OUTSIDE`, `OUTSIDE_SCHEDULE`, `SUSPICIOUS_FREQUENCY`, límites/categorías y confianza del comercio (`Business/Services/KidsQr/KidsRulesEngine.cs`).

### Chat y notificaciones

`CreateInternalChatConversationRequest`: `type` requerido, `businessId?`, `reservationId?`, `orderId?`, `targetUserId?`, `title?` ≤200.

`SendInternalChatMessageRequest`: `messageType` requerido (default `Text`), `body?` ≤4000, `attachmentUrl?`, `mediaUrl?`, `thumbnailUrl?` ≤2048, `storagePath?` ≤1024, `mediaType?` ≤100, `metadataJson?`.

`ShareTypedChatMessageRequest`: `conversationId>0`, `contentType` requerido ≤40, `referenceId` requerido ≤80, `referenceKind?` ≤40, `comment?` ≤500. Los endpoints especializados sobreescriben `contentType` con su tipo canónico.

Respuesta conversación: `id`, `type`, `businessId?`, `reservationId?`, `orderId?`, `clientUserId?`, `peerUserId?`, `title?`, `status`, `lastMessageAt?`, `createdAt`, `unreadCount`; detalle agrega `participants`. Mensaje: `id`, `conversationId`, actor/remitente, `messageType`, aliases `type?`, `body?`/`text?`, URLs/media/metadata, ubicación opcional, fechas e `isOwnMessage` (`DTO/InternalChatDtos.cs`).

`RegisterFcmTokenRequest`: `fcmToken` requerido ≤500, `platform` requerido ≤20, `deviceId?` ≤120, `deviceName?` ≤120, `appVersion?` ≤30.

`NotificationQuery`: `page≥1`, `pageSize` 1–100, `isRead?`, `category?` ≤80, `type?` ≤80. La lista devuelve `PagedResponse<UserNotificationResponse>`; cada notificación contiene `id`, `userId`, `type`, `title`, `message`, referencias opcionales (`resource`, business/event/product/service/promotion/etc.), `deepLink?`, `metadataJson?`, `priority`, `icon?`, `isRead`, `createdAt`, `readAt?`. Badges: `total`, `wallet`, `chat`, `delivery`, `reservations`, `promotions`.

## 4. Flujos y estados Kids

### Solicitud → Master → token/PIN → ejecución

1. Kid crea solicitud con `idempotencyKey`.
2. Master consulta pendientes.
3. Si el comercio requiere política, obtenerla y aceptar su versión para esa solicitud.
4. Master aprueba. Para una solicitud de una cuenta Kids, approve llama `ApproveAndIssue` y puede devolver el secreto.
5. Guardar token/PIN solo en memoria protegida y mostrarlos/transferirlos una vez.
6. Actor autorizado valida opcionalmente token+PIN.
7. Ejecuta con una nueva `idempotencyKey` y ubicación confiable.
8. Backend revalida actor, expiración, consumo, Shield, política vigente y wallet; al éxito consume el token.

Geolocalización: con geocercas activas, coordenadas ausentes o inválidas son rechazo crítico. Estar fuera produce decisión `requiresApproval`, pero el flujo `execute` exige finalmente `allowed=true`; no debe asumirse que el token omite la geocerca. La app debe tratar falta de GPS como bloqueo, no como permiso.

### Firebase

1. Cuenta Kids ya debe estar vinculada a un `firebaseUid`.
2. Master registra `firebaseUid + deviceId`.
3. Master aprueba el registro.
4. Kid obtiene Firebase ID token e inicia sesión enviando también el mismo `deviceId`.
5. Backend exige coincidencia UID/dispositivo, aprobación y ausencia de revocación.
6. Refresh rota en cada uso y permanece ligado al dispositivo.
7. Revocar dispositivo revoca sus refresh tokens activos. Reutilizar un refresh ya revocado provoca revocación de todos los refresh activos de ese Kid.

### Sesiones QR Kids legacy aún vigentes

Estados `KidsPaymentSessionStatus`: `1 QrScanned`, `2 MerchantFound`, `3 RulesValidated`, `4 WaitingParent`, `5 ParentViewing`, `6 Approved`, `7 Rejected`, `8 PaymentProcessing`, `9 PaymentSuccess`, `10 PaymentFailed`, `11 Expired`, `12 Cancelled`.

Approval: `0 Pending`, `1 Approved`, `2 Rejected`, `3 Expired`. El worker de expiración persiste `Expired` y eventos durables (`WebApi/Workers/DomainExpirationWorker.cs`).

## 5. Movie/Chat v2

### Endpoints de usuario

Base Chat Movie: `/api/v1/chat/movie`, Client/Kid.

- `POST /requests` y alias singular `/request`.
- `GET /requests/{requestId}` y alias `/request/{requestId}`.
- `POST /requests/{requestId}/approve` y alias singular.
- `POST /requests/{requestId}/reject` y alias singular.
- `POST /requests/{requestId}/cancel` y alias singular.
- `POST /share`.

Base Movie: `/api/v1/movie`.

- `GET /movies?page=1&pageSize=20&maximumMinimumAge=&search=` — catálogo.
- `GET /movies/{movieId}/showtimes`.
- `GET /showtimes/{showtimeId}/seats` — cada asiento incluye `code`.
- `POST /reservations`.
- `PUT /reservations/{reservationId}/seats` — seleccionar por IDs o `codes`.
- `POST /reservations/{reservationId}/payment`.
- `POST /reservations/{reservationId}/qr`.
- `POST /qr/consume` — Business/Admin.
- `GET /history?page=1&pageSize=20`.
- `GET /events?cursor=0&take=100` — polling durable.
- `GET /events/stream?cursor=0` — SSE durable, evento `MOVIE_DOMAIN_EVENT`.

### Endpoints Movie de negocio/admin

Base `/api/v1/movie/admin`, policy Business/Admin:

- `GET|POST /movies`; `PUT|DELETE /movies/{id}`.
- `GET|POST /cinemas`; `PUT|DELETE /cinemas/{id}`.
- `GET|POST /cinemas/{cinemaId}/halls`.
- `PUT|DELETE /halls/{id}`.
- `GET|PUT /halls/{hallId}/seats`.
- `GET|POST /showtimes`; `PUT|DELETE /showtimes/{id}`.

### DTOs request exactos

`CreateMovieRequestDto`:

```json
{
  "conversationId": 44,
  "chatId": null,
  "ciervoId": null,
  "movieId": "11111111-1111-1111-1111-111111111111",
  "cinemaId": "22222222-2222-2222-2222-222222222222",
  "showtimeId": "33333333-3333-3333-3333-333333333333",
  "ticketCount": 2,
  "tickets": null,
  "seatType": 1,
  "idempotencyKey": "movie-request-install-0001"
}
```

- `conversationId` o alias `chatId`: uno debe resolver una conversación accesible.
- `showtimeId` requerido por tipo (GUID no nullable).
- `ticketCount` o alias `tickets`: 1–20.
- `seatType?`: enum 1–4.
- `idempotencyKey`: requerido, 8–100.
- `movieId?` y `cinemaId?` se validan contra la función si se envían.
- `ciervoId?` ≤40 es solo comprobación adicional de identidad; nunca autoridad.

`DecideMovieRequestDto`: `reason?` ≤500, `paymentMethod?`. Aprobar sin body usa WALLET. Rechazo requiere body en el controlador, aunque `reason` sea nullable en DTO.

`ShareMovieDto`: `conversationId?`, `chatId?`, `ciervoId?`, `movieId` GUID, `message?` ≤500.

`CreateMovieReservationDto`:

```json
{
  "showtimeId": "33333333-3333-3333-3333-333333333333",
  "movieId": "11111111-1111-1111-1111-111111111111",
  "cinemaId": "22222222-2222-2222-2222-222222222222",
  "movieRequestId": "44444444-4444-4444-4444-444444444444",
  "ticketCount": 2,
  "tickets": null,
  "seatType": 1,
  "ciervoId": null,
  "idempotencyKey": "movie-reservation-install-0001"
}
```

Para Kid, `movieRequestId` debe apuntar a una solicitud aprobada para el mismo showtime. Adulto puede reservar directamente.

Selección:

```json
{
  "showtimeSeatIds": [],
  "codes": ["A1", "A2"]
}
```

Ambas listas máximo 20. Enviar exactamente el número de asientos de la reserva; no mezclar IDs/códigos duplicados.

Pago:

```json
{
  "paymentMethod": 1,
  "walletCardId": null,
  "idempotencyKey": "movie-wallet-install-0001"
}
```

Único método implementado: `MoviePaymentMethod.Wallet = 1`. Kid no ejecuta el pago; paga el adulto autorizado. No enviar tarjeta, Mercado Pago, efectivo ni otro enum.

Consumo:

```json
{ "token": "<token-one-time-de-al-menos-20-caracteres>" }
```

### DTOs response principales

- `MovieSummaryDto`: `id`, `title`, `description?`, `minimumAge`, `durationMinutes`, `language`, `imageUrl?`.
- Catálogo: `PagedResponse<MovieSummaryDto>` con `page`, `pageSize`, `total`, `totalPages`, `items`.
- `MovieShowtimeDto`: `id`, `movieId`, `movieTitle`, `cinemaId`, `cinemaName`, `hallId`, `hallName`, `startsAt`, `endsAt`, `basePrice`, `currency`, `availableSeats`.
- `MovieShowtimeSeatDto`: `seatId`, `code`, `row`, `number`, `type`, `price`, `available`.
- `MovieRequestDto`: IDs, solicitante/aprobador y roles, `childProfileId?`, `ticketCount`, `amount`, `currency`, `status`, `decisionReason?`, `createdAt`, `expiresAt`, `reservationId?`, `paymentMethod?`.
- `MovieReservationDto`: IDs/snapshots de película-cine-sala, `showtimeStartsAt`, `movieRequestId?`, owner/payer/roles, `childProfileId?`, `ticketCount`, `totalAmount`, `currency`, `status`, `expiresAt`, `paidAt?`, `paymentMethod?`, `paymentReference?`, `seats`.
- `MovieQrDto`: `qrId`, `reservationId`, `token`, `expiresAt`, `imageBase64`, `imageDataUrl`. `imageBase64` es PNG sin prefijo; `imageDataUrl` ya contiene `data:image/png;base64,`.
- `MovieQrConsumptionDto`: `qrId`, `reservationId`, `consumedAt`.
- `MovieHistoryDto`: `reservation`, `admissionQrIssued`, `admissionConsumed`.
- `MovieEventDto`: `cursor`, `aggregateId`, `aggregateType`, `eventType`, `payloadJson`, `createdAt`. `payloadJson` es string JSON, requiere una segunda decodificación si la UI necesita sus campos.

ASP.NET serializa estos enums como números:

- `CinemaSeatType`: `1 Standard`, `2 Premium`, `3 Accessible`, `4 Companion`.
- `MovieRequestStatus`: `1 Pending`, `2 Approved`, `3 Rejected`, `4 Cancelled`, `5 Expired`, `6 Reserved`.
- `MovieReservationStatus`: `1 Draft`, `2 SeatsHeld`, `3 PendingPayment`, `4 Confirmed`, `5 Cancelled`, `6 Expired`, `7 Refunded`, `8 Completed`.
- `MovieAdmissionQrStatus`: `1 Active`, `2 Consumed`, `3 Expired`, `4 Revoked`.
- `MoviePaymentMethod`: `1 Wallet`.
- Admin: `MovieStatus` 1 Draft/2 Published/3 Archived; `CinemaStatus` 1 Active/2 Inactive; `MovieShowtimeStatus` 1 Scheduled/2 OnSale/3 SoldOut/4 Cancelled/5 Completed.

### Máquina de estado Movie

Flujo Kid:

1. Catálogo → showtimes → seats.
2. Crear request: `Pending`.
3. Adulto autorizado aprueba con WALLET: `Approved`; puede rechazar (`Rejected`). El solicitante puede cancelar Pending/Approved (`Cancelled`).
4. Kid crea reserva enlazando request: request pasa a `Reserved`, reserva `Draft`.
5. Seleccionar asientos: `SeatsHeld`; hold actual máximo 10 minutos y nunca más allá de 10 minutos antes del showtime.
6. Adulto/pagador ejecuta WALLET: `Confirmed`; asientos `Sold`.
7. Propietario emite QR una sola vez.
8. Personal del cine/Admin consume: QR `Consumed`.

Flujo adulto: request se crea directamente `Approved` con WALLET, o puede crear reserva directa; luego selección → pago → QR.

Expiraciones:

- Request vence como máximo en 24 h y al menos 15 min antes de la función.
- Reserva/hold vence en 10 min o 10 min antes de la función, lo primero.
- Worker cambia Draft/SeatsHeld/PendingPayment a `Expired` y libera asientos.
- QR vence al terminar la función. Consumir vencido devuelve `410`.

QR one-time:

- Solo se almacena hash.
- Una segunda emisión devuelve `409`; el token original no puede recuperarse.
- Un segundo consumo devuelve `409`.
- Nunca persistir el token o PNG en logs, analytics, crash reports, clipboard ni almacenamiento no cifrado.

Realtime Movie:

- Eventos están persistidos y se consultan por cursor ascendente.
- SSE consulta eventos durables cada 2 s y emite `id`, `event: MOVIE_DOMAIN_EVENT`, `data`.
- Reconectar con el último cursor mediante polling primero; luego abrir SSE con ese cursor. El backend no consume `Last-Event-ID`.

Referencias: `WebApi/Controllers/MovieController.cs`, `DTO/MovieDtos.cs`, `Business/Services/MovieService.cs`, `DataAccess/Models/MovieEntities.cs`, `WebApi/Workers/DomainExpirationWorker.cs`.

## 6. Seguridad móvil obligatoria

- Actor: siempre JWT. IDs de body/query sirven para seleccionar recursos, nunca para decidir permisos.
- No decodificar claims como única autorización local; usarlos para UX y dejar decisión final al backend.
- No loguear JWT, refresh, Firebase ID token, PIN, token de pago, token QR, FCM token ni payload NFC.
- Guardar access/refresh únicamente en almacenamiento seguro del SO; token/PIN de pago y QR one-time preferiblemente solo en memoria.
- Rotar refresh reemplazando atómicamente el anterior. Si falla el refresh, borrar sesión; no reusar el token anterior.
- Generar `idempotencyKey` estable por intención de usuario, 8–100 caracteres donde Movie exige mínimo 8. Un retry conserva la misma clave; una acción nueva usa otra.
- No reintentar automáticamente `400/403/409/410/422`. Reintentar timeout/5xx con backoff y la misma clave.
- Pedir GPS antes de ejecutar flujos con geocerca. Enviar latitud y longitud juntas, obtenidas recientemente; ubicación ausente es fail-closed cuando hay geocercas.
- Solicitar cámara solo al entrar al scanner QR, push al activar notificaciones y NFC al iniciar el flujo NFC; contemplar denegado permanente y enlace a Settings.
- SSE: cerrar al logout/background prolongado, reconectar con backoff+jitter, persistir cursor de sesión y ejecutar catch-up por polling.
- Validar que la conversación, solicitud, reserva y QR devueltos pertenecen al flujo esperado antes de renderizar deep links.

## 7. Cambios concretos solicitados en Flutter

La arquitectura es agnóstica a Bloc/Provider/Riverpod/GetX. Separar:

### Modelos

- `ApiEnvelope<T>` y `ProblemDetailsModel`.
- Kids: sesión/claims, `KidSettings`, commerce, payment request, token issued/validation, device registration, Shield decision, audit page, realtime event.
- Movie: summary, showtime, seat, request, reservation, QR, history, domain event y enums numéricos.
- Parsear fechas como UTC/ISO-8601; convertir a zona local solo en presentación.
- Conservar `payloadJson` crudo y ofrecer parser tolerante por `eventType`.

### Repositorios

- `KidsAuthRepository`: login PIN/Firebase, refresh rotatorio y logout seguro.
- `KidsRepository`: settings/profile/commerce/Shield.
- `MasterKidsRepository`: solicitudes, política, token, dispositivos, reglas, dashboard y auditoría.
- `KidsRealtimeRepository`: poll/SSE con cursor.
- `MovieRepository`: catálogo, funciones, asientos, requests, reservas, pago WALLET, QR, historia y eventos.
- `ChatRepository` y `NotificationsRepository`: usar rutas `/api/v1`; aliases legacy solo como fallback temporal.
- Interceptor Bearer; serialización de `idempotencyKey` en body, no header.

### Pantallas y navegación

Kid:

- Login PIN/Firebase con estado “dispositivo pendiente/no aprobado/revocado”.
- Inicio/settings, comercios, scanner QR, Shield, solicitud “pagar por mí”, tracking en tiempo real.
- Catálogo Movie → funciones → asientos → solicitud al tutor → espera de decisión → reserva → espera de pago → QR.

Master:

- Inbox de solicitudes, detalle de política, aprobar/rechazar, pantalla efímera token+PIN.
- Dispositivos pendientes/aprobados/revocados.
- Límites, horarios, categorías, geocercas, bloqueo global, intentos y auditoría/export.
- Solicitud Movie con approve/reject y pago WALLET.

Business/Admin móvil si aplica:

- Validación/ejecución token Kids.
- Consumo QR Movie con cámara.
- NFC validate/charge.

Deep links mínimos sugeridos, resueltos internamente sin confiar en IDs: notificación → request Kids, device, Movie request, reservation/QR, chat conversation.

### Estados UI

Todas las operaciones: `initial/loading/success/empty/error/forbidden/expired/conflict/offline`.

Adicionales:

- Request: pending/approved/rejected/cancelled/expired/reserved.
- Reserva: draft/seatsHeld/confirmed/expired.
- QR: notIssued/active/consumed/expired; no ofrecer “recuperar QR”.
- Realtime: connecting/catchingUp/live/reconnecting/pollingFallback.
- GPS/cámara/push/NFC: notDetermined/granted/denied/permanentlyDenied/unavailable.

Validaciones cliente deben reflejar DTOs, pero nunca sustituir las del servidor. Mostrar `msg`, `detail` o primer `errors[field]` seguro y conservar `correlationId` para soporte.

## 8. Breaking changes y migración

- Preferir `/api/v1/chat` frente a `/api/chat`; ambos son aliases actuales.
- Preferir `/api/v1/notifications` frente a `/api/notifications`; ambos vigentes.
- Movie Chat acepta singular y plural (`request`/`requests`); normalizar Flutter a plural.
- Payment request Kids acepta singular y plural; normalizar a `/api/v1/kids/payment-requests`.
- Aprobación Kids mediante `/api/v1/master/payment-requests/{id}/approve` puede devolver `PaymentTokenIssuedResponse`, no solo la respuesta legacy de aprobación.
- `idempotencyKey` está en JSON; cualquier implementación Flutter que lo mande solo como header no activa la idempotencia.
- Realtime usa query `cursor`/`sinceId`; `Last-Event-ID` no es suficiente.
- Movie solo soporta `WALLET=1`. Eliminar opciones UI ficticias.
- QR Movie no se puede regenerar/consultar después de emitirlo. El cliente debe presentar la respuesta de emisión sin prometer recuperación.
- En Movie, enums llegan numéricos; no esperar strings.
- `GET /api/v1/kids/wallet/history` no es historial paginado: hoy es alias del resumen wallet.
- Firebase no tiene auto-prerregistro móvil: la aprobación exige registro iniciado por Master.

Mantener aliases legacy únicamente durante migración; no implementar fallback indiscriminado ante cualquier error. Solo intentar alias cuando el canonical devuelve `404` de ruta y nunca ante `401/403/409`.

## 9. Limitaciones reales detectadas

- Movie: únicamente WALLET; sin tarjeta externa, Mercado Pago, efectivo ni reembolso expuesto en este controlador.
- QR Movie: emisión única sin endpoint de recuperación.
- Kids `wallet/history`: mismo resumen que balance.
- Firebase device: registro solo por Master; no hay endpoint público “request device approval”.
- Idempotencia: campo body, no header.
- Cursor: query, no soporte `Last-Event-ID`.
- Realtime durable existe para sesiones Kids y Movie. Notificaciones SSE usa `sinceId` y consulta las 20 notificaciones más recientes; no ofrece polling dedicado con cursor ni garantía equivalente para una brecha mayor.
- SSE Kids combina replay persistido con hub en memoria; la recuperación fiable requiere polling por cursor.
- Algunos endpoints legacy devuelven HTTP 200 con `status=false`; Flutter debe inspeccionar ambos niveles.
- `ciervoId` en Movie es validación secundaria, no identidad.
- Con geocercas activas, no hay ejecución segura sin ubicación; fuera de geocerca no equivale a autorización final en el flujo token.

## 10. Checklist de aceptación Flutter

- [ ] Base URL por flavor, sin secretos y sin `/api` duplicado.
- [ ] Bearer interceptor y logout ante refresh inválido/revocado.
- [ ] Keychain/Keystore para sesión; ningún secreto en logs.
- [ ] Roles/claims modelados; permisos finales delegados al backend.
- [ ] Parser dual `Response<T>` / `ProblemDetails`, incluidos `errorCode` y `correlationId`.
- [ ] Idempotencia en body y retry con la misma clave.
- [ ] Kids PIN y Firebase probados; dispositivo no aprobado/revocado bloquea sesión.
- [ ] Revocación de dispositivo invalida refresh en ese dispositivo.
- [ ] GPS requerido y coordenadas juntas en ejecución con geocerca.
- [ ] Política de reserva aceptada antes de aprobar cuando corresponde.
- [ ] Token+PIN se presenta una vez y no se persiste.
- [ ] Pantallas Master de requests, dispositivos, reglas, seguridad y auditoría.
- [ ] Aliases chat/notificaciones migrados a `/api/v1`.
- [ ] Movie singular/plural tolerado; cliente genera plural.
- [ ] Catálogo, showtimes, asientos por `code`, hold y expiración implementados.
- [ ] Kid no puede pagar; adulto/pagador ejecuta WALLET.
- [ ] No existe selector de método Movie distinto de WALLET.
- [ ] QR PNG renderiza `imageBase64` o `imageDataUrl`; token no se registra.
- [ ] Segundo issue/consume y QR expirado tienen UX `409/410`.
- [ ] Polling catch-up antes de SSE y reconexión con cursor.
- [ ] Permisos GPS/cámara/push/NFC con estados denegado/permanente.
- [ ] Deep links revalidan recurso con backend antes de navegar a contenido sensible.
- [ ] Pruebas de 400/401/403/404/409/410/422/429/500 y offline.
- [ ] No se presenta como disponible ninguna limitación listada en la sección 9.

## 11. Archivos fuente auditados

- `WebApi/Controllers/EnterpriseKidsV2Controller.cs`
- `WebApi/Controllers/KidsEnterpriseV1Controller.cs`
- `WebApi/Controllers/KidsQrModuleController.cs`
- `WebApi/Controllers/KidsRealtimeController.cs`
- `WebApi/Controllers/PaymentRequestsController.cs`
- `WebApi/Controllers/KidsNfcController.cs`
- `WebApi/Controllers/WalletNfcController.cs`
- `WebApi/Controllers/ChatController.cs`
- `WebApi/Controllers/NotificationsController.cs`
- `WebApi/Controllers/MovieController.cs`
- `DTO/EnterpriseKidsV2Dtos.cs`
- `DTO/KidAccountDtos.cs`
- `DTO/KidsQrDtos.cs`
- `DTO/KidsSecurityDtos.cs`
- `DTO/ChatPaymentDtos.cs`
- `DTO/InternalChatDtos.cs`
- `DTO/NotificationDtos.cs`
- `DTO/WalletNfcDtos.cs`
- `DTO/MovieDtos.cs`
- `Business/Services/EnterpriseKidsV2Service.cs`
- `Business/Services/KidAuthService.cs`
- `Business/Services/KidsQr/KidsRulesEngine.cs`
- `Business/Services/KidsQr/KidsRealtimeEventService.cs`
- `Business/Services/MovieService.cs`
- `Business/Security/JwtTokenService.cs`
- `WebApi/Workers/DomainExpirationWorker.cs`
- `WebApi/Program.cs`
- `IOC/Dependencies.cs`

## 12. Actualización MOVE Driver Onboarding v2

> Esta sección agrega el contrato MOVE v2 sin modificar Kids/Movie. Para la implementación autocontenida y ejemplos completos usar `Flutter_MOVE_Driver_Onboarding_Prompt.md`. Se debe implementar **frontend Flutter, no backend**.

### 12.1 Actor, autenticación y límites

- El conductor es un `Client` existente (`role=1`, policy `ClientOnly`), no un rol Driver.
- Login Client: `POST /api/auth/user/login`; alternativa Firebase Client: `/api/auth/firebase/login|register|sync-verification`.
- No existe `/master/login` ni login Driver. Password/OTP no forman parte del onboarding.
- SMS propio no existe; teléfono verificado usa Firebase Phone Auth.
- Autoridad: JWT. No enviar IDs para cambiar actor.
- Debe existir email o teléfono Client verificado antes de poder enviar.

### 12.2 Endpoints canónicos

Base `ClientOnly`: `/api/v1/move/driver/onboarding`.

- `GET /status`
- `PUT /identity`
- `PUT /license`
- `PUT /vehicle`
- `PUT /operations`
- `POST /submit`

Todos devuelven `Response<MoveDriverOnboardingStatusDto>`. Las cinco mutaciones requieren header `Idempotency-Key`, obligatorio y máximo 120. Esta es una excepción MOVE a la afirmación anterior de que la idempotencia solo va en JSON: en MOVE onboarding v2 va en **header**. Conservar la misma clave y payload hasta respuesta definitiva; payload distinto con la misma clave produce `409`.

Self-service compatible:

- `/api/v1/move/driver/apply` y `/registration/basic-profile`
- `/me`
- `/vehicles`, `/registration/vehicle`, `/vehicles/{vehicleId}`
- `/documents`, `/registration/driver-license`
- `/registration/review`
- `/online`, `/location`

Usar v2 para altas nuevas. Tras `Approved`, `/online` sigue aplicando gate `canGoOnline`.

### 12.3 Media privada

Antes de cada PUT, subir imágenes mediante:

```http
POST /api/media/upload
Authorization: Bearer <Client JWT>
Content-Type: multipart/form-data

ownerType=User
ownerId=<userId JWT>
mediaType=Gallery
file=<imagen>
```

Usar el `value.id` devuelto como `mediaAssetId`. Formatos efectivos: JPG/JPEG/PNG/WebP, máximo 5 MiB. MOVE comprueba ownership User, tamaño, storage relativo y tipo Gallery/ProfilePhoto.

Limitaciones reales:

- `/api/media/register` crea assets incompatibles con MOVE v2 (`SizeBytes=0`/storage externo); no usarlo.
- El DTO admite PDF para documentos, pero el upload actual no acepta PDF.
- No existe antivirus/cuarentena.
- No existe reconocimiento facial automático; selfie para revisión humana.

### 12.4 DTOs y enums

DTO exactos en `DTO/MoveOnboardingDtos.cs`:

- `MoveIdentityOnboardingRequest`: nombres, documento, CO/CL, ciudad, email/teléfono coincidente, nacimiento, selfie, aceptación, versión y hash.
- `MoveLicenseOnboardingRequest`: número/clase, vigencia, frente, reverso condicional, experiencia.
- `MoveVehicleOnboardingRequest`: tipo físico, categoría, datos, documentos y cinco fotos.
- `MoveOperationsOnboardingRequest`: Wallet/payout, emergencia, idiomas, capacidades, agenda, radios y servicios.
- Respuesta: `driverId`, `status`, `percentage`, `canSubmit`, `canGoOnline`, máscaras/last4, IDs y rowVersions, documentos, etapas, `missing`, `reasons`.

Enums:

- identidad: `1 Pending`, `2 Verified`, `3 Rejected`;
- licencia/documento: `1 Pending`, `2 Approved`, `3 Rejected`, `4 Expired`;
- etapas: `1 Identity`, `2 License`, `3 VehicleAndOperations`;
- payout: `1 Wallet`, `2 ExternalPayout`;
- tipo físico: `1 Car`, `2 Motorcycle`, `3 Suv`, `4 Van`, `5 Pickup`;
- fotos: `1 Front`, `2 Rear`, `3 Left`, `4 Right`, `5 Interior`;
- servicios: `1 Economy`, `2 Taxi`, `3 Executive`, `4 SUV`, `5 Van`, `6 Tourism`, `7 Airport`, `8 Corporate`, `9 Courier`, `10 Delivery`, `11 Errands`;
- documentos: `1 Registration`, `2 Insurance`, `3 TechnicalInspection`, `4 TaxiAuthorization`;
- perfil: `0 Draft`, `1 PendingReview`, `2 Approved`, `3 Rejected`, `4 Suspended`, `5 Blocked`.

### 12.5 Reglas y flujo

- Solo CO/CL y edad mínima 18.
- Registro y seguro en ambos países.
- Reverso de licencia: CO sí, CL no.
- Inspección técnica: antigüedad >=6 años CO, >=1 año CL.
- Taxi requiere TaxiAuthorization.
- Seguro, inspección y autorización Taxi requieren expiración futura.
- Cinco fotos exactas y distintas.
- Contacto de emergencia completo, al menos un servicio y Wallet activa.
- Wallet es default. Payout externo requiere token de proveedor + banco/tipo + last4; nunca pedir cuenta completa. El proveedor/tokenizador no está expuesto.

Flujo: registro/login Client + contacto verificado → términos → media → identity → license → vehicle/documentos/fotos → operations/Wallet → status → submit → revisión/correcciones → Approved → online.

Editar cualquier etapa reinicia a Draft y offline salvo Blocked. Renderizar siempre `percentage`, `stages`, `missing`, `reasons`, `canSubmit` y `canGoOnline`.

### 12.6 Términos y release

El backend valida términos por configuración `MoveOnboarding:Countries:CO|CL` con `CurrentTermsVersion` y `CurrentTermsContentHash`. No existe endpoint público de catálogo. Flutter debe empaquetar o recibir por configuración remota el documento exacto del país, mostrarlo y enviar:

- CO: versión `2026-07`, SHA-256 `39BA0EAB3352694DED546A61B82DDDC1240956C4C4C6BAFEA529E169937A01BB`, documento `docs/CIERVO_MOVE_DRIVER_TERMS_CO_2026-07.md`.
- CL: versión `2026-07`, SHA-256 `E189A1B2B5A552925A4A6BA093A38D4D3D4425F753064900355B4CA165658ECE`, documento `docs/CIERVO_MOVE_DRIVER_TERMS_CL_2026-07.md`.

Los hashes fueron verificados contra los archivos y están configurados en backend y `cloudrun-production.env.yaml`. Ante `409`, invalidar la aceptación y exigir aceptar la versión vigente. No inventar endpoint, texto ni hash.

La migración MOVE v2 deberá aplicarse durante despliegue. Los bindings HMAC/AES ya están preparados en `scripts/prod-cloudrun-deploy.ps1` (`ciervo-move-payout-encryption-key` y `ciervo-move-identifier-hmac-key`); los secretos se crearán en Google Secret Manager durante el despliegue. Nunca incluirlos en Flutter.

### 12.7 Pantallas, seguridad y QA

Agregar modelos/repositorios/providers o BLoC, wizard de identidad/licencia/vehículo/operations, uploads con progreso/retry, status/revisión/corrección y Approved/online. Incluir permisos cámara/galería/ubicación/push, borrador offline cifrado, deep links que refrescan status y notificaciones `move.driver.*`.

No guardar/loguear JWT, Firebase token, PII, documentos, imágenes, claves idempotentes, provider token o datos bancarios. Backend aplica HMAC a identificadores y AES-GCM a datos sensibles; no replicar secretos.

Probar DTO/enums, CO/CL/Taxi/vigencias, cinco fotos, contacto verificado, términos cambiados, upload/offline, idempotencia y `400/401/403/404/409/429/5xx`.

## 13. CIERVO Tickets (API unificada)

Contrato completo: [`docs/CIERVO_TICKETS_MOBILE.md`](docs/CIERVO_TICKETS_MOBILE.md).

Apuntar el módulo Tickets solo a:

- `GET /api/v1/events`, `/highlights`, `/nearby`, `/{eventId}`, `/{eventId}/seats` (+ reserve/release)
- `POST /api/v1/tickets/create`, `/pay`, `/validate`, `/refund`, `/cancel`
- `GET /api/v1/wallet/tickets`, `/history`, `/{ticketId}`
- `GET /api/v1/ai/recommend-events`

IDs: `movie-{guid:N}` / `event-{int}`; ticket `TK...`. Pago primario: `CIERVO_BALANCE` / `WALLET`. Legacy `/api/v1/movie` y `/api/events` no usar en la app Tickets.

## 14. Vakupli — contactos, cupos y pago visual

Contrato: [`docs/CIERVO_VAKUPLI_CONTACTS.md`](docs/CIERVO_VAKUPLI_CONTACTS.md).

- Contactos nacionales: `GET /api/vakupli/contacts`, búsqueda `GET /api/vakupli/contacts/search?q=`
- Participantes con `hasPaid` / `paymentStatus` para UI
- Solo invitados del mismo país; cupos Free=3 invitados, +4 por tier de plan del creador (`maxGuests` / `remainingSlots` en el grupo)
- Packs extra **bimensuales por usuario**: `POST /api/vakupli/groups/{groupId}/extra-slots` → +4/pack (Free US$2 / pago US$1), vigencia 2 meses; `GET /api/vakupli/extra-slots/me` antes de upgrade de plan
- **Modal obligatorio al mejorar plan** si `acknowledgeBeforePlanUpgrade`: cobro bimensual, no se pierden días, no se recobra hasta vencer; botones continuar upgrade / quedarse en plan actual (ver `docs/CIERVO_VAKUPLI_CONTACTS.md`)

