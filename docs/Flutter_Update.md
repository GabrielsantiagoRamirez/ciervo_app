# Actualización Flutter contra el backend final de CIERVO

## 1. Alcance y reglas de integración

Este documento describe únicamente contratos presentes en el backend actual: controladores de `WebApi`, DTO de `DTO`, políticas JWT y enums de `Models`. No propone endpoints nuevos ni presupone WebSocket/SignalR. Cuando el backend devuelve un estado como texto además de un entero, Flutter debe conservar ambos; el entero es el contrato estable para los enums explícitos y el texto es útil para presentación y compatibilidad.

Convenciones de tipos Dart:

- C# `int`/`long` → Dart `int`.
- C# `decimal`/`double` → Dart `double`; para dinero, conservar además el texto JSON original o usar una librería decimal en la capa de dominio. Nunca hacer cálculos financieros con redondeo binario en UI.
- C# `Guid` → Dart `String`, validado como UUID.
- C# `DateTime` → Dart `DateTime`, parseado en UTC y convertido a local solo al renderizar.
- C# `T?` → Dart `T?`.
- C# `List<T>`/`IReadOnlyList<T>` → Dart `List<T>`.
- Los nombres JSON son `camelCase` por defecto en ASP.NET Core.

Contrato de éxito predominante:

```json
{
  "status": true,
  "value": {},
  "msg": null,
  "errorCode": null
}
```

No basta con HTTP 200: varios servicios devuelven `status: false` dentro de 200. El cliente debe evaluar primero HTTP y luego `status == true`.

Modelo base sugerido:

```dart
sealed class ApiResult<T> {
  const ApiResult();
}
final class ApiSuccess<T> extends ApiResult<T> {
  final T value;
  final String? message;
}
final class ApiFailure<T> extends ApiResult<T> {
  final int httpStatus;
  final String? code;
  final String message;
  final String? correlationId;
  final Map<String, List<String>> fieldErrors;
}
```

**Criterio de aceptación:** una prueba de contrato deserializa respuestas con `status/value/msg/errorCode`, Problem Details y Validation Problem Details sin `dynamic` fuera de la capa de transporte.

## 2. Cambio crítico de autenticación y sesiones

### 2.1 JWT

El backend ahora emite y valida:

- firma HMAC-SHA256;
- `issuer` obligatorio;
- `audience` obligatorio;
- expiración con `ClockSkew = 0`;
- rol en el claim estándar de rol;
- `accountKind`;
- en Kid: `childProfileId` y `familyId`.

Políticas reales:

- `ClientOnly`: rol `1`.
- `BusinessOnly`: rol `2` o `accountKind=BusinessUser`.
- `AdminOnly`: rol `3` o `accountKind=PlatformAdmin`.
- `KidOnly`: rol `4`.
- `ClientOrKid`: rol `1` o `4`.
- `BusinessOrAdmin`: rol `2`/`3` o account kind equivalente.

**Breaking change:** cualquier access token emitido antes de activar/cambiar `issuer` o `audience` será inválido. La actualización móvil debe forzar re-login una vez. No intentar “reparar” un JWT local ni mantener sesión tras un 401 si el refresh también falla.

### 2.2 Endpoints de autenticación reales

| Método | Ruta | Auth | Request / respuesta principal |
|---|---|---|---|
| POST | `/api/auth/user/register` | Pública | `RegisterUserRequest` → `Response<AuthResponse>` |
| POST | `/api/auth/user/login` | Pública, 5/min/IP | `LoginRequest` → `Response<AuthResponse>` |
| POST | `/api/auth/login` | Pública, 5/min/IP | login general; 401 credenciales, 403 cuenta inactiva |
| POST | `/api/auth/business/login` | Pública, 5/min/IP | login negocio; 401/403 |
| POST | `/api/auth/admin/login` | Pública, 5/min/IP | login admin |
| POST | `/api/auth/staff/login` | Pública, 5/min/IP | login staff |
| POST | `/api/auth/refresh-token` | Pública | `{refreshToken:string}` → `Response<AuthResponse>` |
| POST | `/api/auth/logout` | Pública | `{refreshToken:string}` |
| POST | `/api/auth/account-lookup` | Pública, 3/min/IP | correo/teléfono → flujo sugerido |
| POST | `/api/auth/firebase/check-user` | Pública | Firebase ID token → existencia/vinculación |
| POST | `/api/auth/firebase/login` | Pública, 5/min/IP | Firebase ID token → sesión |
| POST | `/api/auth/firebase/register` | Pública, 5/min/IP | Firebase ID token + perfil → sesión |
| POST | `/api/auth/firebase/sync-verification` | Pública, 5/min/IP | sincroniza verificaciones |
| POST | `/api/auth/send-verification-code` | Pública, 3/min/IP | `{user,purpose,channel}` |
| POST | `/api/auth/verify-code` | Pública, 3/min/IP | `{user,code,purpose}` |
| POST | `/api/auth/request-password-recovery` | Pública, 2/min/IP | `{email}` |
| POST | `/api/auth/recover-password` | Pública, 2/min/IP | `{user,code,newPassword}` |
| POST | `/api/auth/change-password` | Pública en el controlador | `{user,currentPassword,newPassword}` |
| POST | `/api/auth/kid-login` | Pública, 5/min/IP | alias Kid legacy |
| POST | `/api/v1/kids/auth/login` | Pública | `KidLoginRequest` |
| POST | `/api/v1/kids/auth/refresh` | Pública, 5/min/IP | `KidRefreshTokenRequest`; rota refresh |
| POST | `/api/auth/kid/verify-guardian` | Pública, 5/min/IP | verifica tutor |
| POST | `/api/auth/kid/register` | Pública, 5/min/IP | autorregistro Kid |

`AuthResponse`: `userId:int`, `fullName:string`, `roleId:int`, `accountKind:string`, `roleName:string`, `businessRoleId:int?`, `businessId:int?`, `staffId:int?`, `permissions:List<String>`, `accessToken:string`, `accessTokenExpiresAt:DateTime`, `refreshToken:string`, `refreshTokenExpiresAt:DateTime`, `authAction:string?`, `linkedLegacy:bool`.

`LoginRequest`: `user:string?`, `email:string?`, `password:string`; uno de `user/email` es obligatorio.

Firebase:

- entrada común: `firebaseIdToken:string`, `phone:string?`, `email:string?`, `countryCode:string?`;
- check/lookup devuelve `exists`, `userId?`, `authProvider?`, `hasFirebaseUid`, `requiresFirebaseLink`, `suggestedFlow`;
- valores implementados/documentados de `suggestedFlow`: `register`, `legacy_password`, `firebase_phone`, `firebase_password`, `firebase_login`;
- `authAction`: `login`, `register`, `link_legacy`.

### 2.3 Refresh Kid y almacenamiento

`KidLoginRequest`: `username:string` (máx. 50), `pin:string` (4–12).

`KidLoginResponse`: `token:string`, `expiresAt:DateTime`, `refreshToken:string`, `refreshTokenExpiresAt:DateTime`, `user:{userId:int,kidId:int,role:"Kid",accountKind:"Kid",name:string,photoUrl:string?,familyId:int}`.

El refresh Kid:

1. recibe un token de al menos 32 caracteres;
2. invalida el refresh usado;
3. devuelve access y refresh nuevos;
4. si detecta reutilización, revoca todos los refresh activos del Kid;
5. rechaza cuenta deshabilitada/bloqueada, perfil inactivo o Kid sin tutor.

Implementación móvil:

- guardar access/refresh en almacenamiento seguro, separados por perfil adulto/Kid;
- serializar refresh con un mutex para impedir dos renovaciones simultáneas;
- reemplazar atómicamente ambos tokens;
- ante 401, refrescar una sola vez y repetir una sola vez la petición original;
- si refresh falla o se reutilizó, borrar credenciales, FCM local asociado y abrir login;
- bloquear 15 minutos la UX tras indicación de cuenta temporalmente bloqueada; el servidor bloquea después de 5 PIN incorrectos.

**Criterio de aceptación:** dos requests concurrentes con access expirado generan un solo refresh; el segundo consume la sesión renovada. Una respuesta 401 del refresh limpia la sesión y no entra en bucle. La primera ejecución de esta versión invalida explícitamente sesiones pre-issuer/audience y muestra “Vuelve a iniciar sesión”.

## 3. Errores, validación, correlación y reintentos

El backend acepta y devuelve `X-Correlation-ID`. Solo acepta `[A-Za-z0-9._:-]{1,64}`; si falta o es inválido genera uno. Flutter debe crear un UUID sin guiones o UUID estándar por request, enviarlo y guardar el valor de la respuesta.

Problem Details real:

```json
{
  "type": "https://httpstatuses.com/400",
  "title": "Solicitud inválida",
  "status": 400,
  "detail": "detalle",
  "instance": "/api/...",
  "correlationId": "..."
}
```

Validation Problem Details agrega:

```json
{
  "errors": {
    "Amount": ["The field Amount must be between ..."]
  }
}
```

Tratamiento:

- 400: error de campo/regla; no reintentar automáticamente.
- 401: refresh una vez; luego login.
- 403: sesión válida sin permiso; ocultar acción y mostrar rechazo.
- 404: estado vacío/recurso eliminado; refrescar lista.
- 409: concurrencia/idempotencia; consultar recurso antes de repetir.
- 410: Movie expirado/eliminado; cerrar flujo.
- 422: error de pago Movie; conservar reserva y ofrecer otro medio.
- 429: respetar espera; auth tiene límites específicos y global 120/min/IP.
- 500/503: reintento exponencial solo en GET/idempotentes, con jitter.

**Criterio de aceptación:** toda pantalla de error permite copiar el correlation ID en modo soporte; los errores de validación se asignan al campo correcto y ninguna mutación no idempotente se reintenta sin clave.

## 4. Arquitectura Flutter neutral

Capas propuestas, compatibles con Provider, Bloc/Cubit, Riverpod o GetX:

1. `transport`: cliente HTTP, interceptor JWT/refresh, Problem Details, SSE.
2. `data`: DTO JSON y datasources por módulo.
3. `domain`: entidades, enums tolerantes, repositorios, casos de uso y máquinas de estado.
4. `presentation`: estado de pantalla (`initial/loading/content/empty/submitting/error`) sin conocer HTTP.
5. `navigation`: guards por `accountKind`, rol, permiso y deep link.

Repositorios sugeridos: `AuthRepository`, `KidsRepository`, `ShieldRepository`, `MovieRepository`, `MoveRepository`, `ChatRepository`, `WalletRepository`, `CommerceRepository`, `NotificationRepository`, `QrRepository`, `NfcRepository`.

Todos los enums deben tener caso `unknown(int raw)` o almacenar `rawValue`; el servidor puede ampliar estados sin obligar a bloquear la app.

**Criterio de aceptación:** cambiar Bloc por Provider/GetX no afecta transport/data/domain; una prueba por repositorio usa un datasource fake y no importa widgets.

## 5. Pantallas y navegación

Rutas sugeridas (son rutas Flutter, no endpoints):

- `/auth/login`, `/auth/firebase`, `/auth/recovery`, `/auth/kid`, `/auth/kid-register`.
- `/home`, `/notifications`, `/chat`, `/chat/:conversationId`.
- `/kids`, `/kids/:kidId`, `/kids/:kidId/rules`, `/kids/:kidId/shield`, `/kids/:kidId/wallet`, `/kids/:kidId/location`, `/kids/approvals`.
- `/kid/home`, `/kid/wallet`, `/kid/businesses`, `/kid/pay-for-me`, `/kid/profile`.
- `/movies`, `/movies/:movieId`, `/movies/reservations/:reservationId`, `/movies/requests/:requestId`, `/movies/qr/:reservationId`.
- `/move/request`, `/move/trips`, `/move/trips/:tripId`, `/move/driver`, `/move/driver/onboarding`.
- `/wallet`, `/wallet/cards/:cardId`, `/wallet/transfer`, `/wallet/recharge/:intentId`, `/wallet/nfc/:sessionId`.
- `/commerce/businesses`, `/commerce/businesses/:id`, `/commerce/orders`, `/commerce/orders/:id`, `/bookings/:id`.
- `/qr/scan`, `/qr/kids/:paymentSessionId`, `/qr/payment/:token`.
- `/safety/report`, `/safety/blocks`.

Guards:

- Kid solo ve rutas Kid y rutas `ClientOrKid`; nunca pantallas de tutor.
- Client ve Wallet, tutor, comercio y pagos.
- Business/Admin muestra acciones solo si la política y, cuando aplique, `permissions` lo permiten.
- Un deep link protegido se guarda como destino pendiente, se autentica y luego se revalida; nunca se navega solo por confiar en el payload push.

Pantallas nuevas/modificadas:

- selector de login adulto/Kid y migración de sesión;
- panel tutor con aprobaciones y Shield;
- home Kid con saldo, comercios permitidos, pay-for-me, ubicación y chat familiar;
- escaneo/seguimiento Kids QR;
- catálogo/reserva/asientos/pago/QR Movie;
- solicitud y seguimiento Move + onboarding conductor;
- chat tipado con tarjetas Movie/Move/Commerce/QR/PaymentRequest;
- Wallet con saldo disponible vs retenido, transferencias, QR/NFC y recarga Mercado Pago;
- bandeja de notificaciones con badges y deep links;
- comercio con quote delivery/pickup y órdenes;
- seguridad: reportar y bloquear contenido.

**Criterio de aceptación:** pruebas de navegación verifican que cada rol rechaza rutas ajenas, que un deep link requiere revalidación del recurso y que back no vuelve a una pantalla con datos de otra sesión.

## 6. Kids, tutor y Shield

### 6.1 Endpoints reales

Todos requieren Bearer salvo los dos auth Kid y registro/verificación indicados antes.

**Tutor (`ClientOnly`)**

- `GET/POST/PUT /api/kids/{kidId}/allowed-businesses`; `DELETE /api/kids/{kidId}/allowed-businesses/{businessId}`.
- `GET/PUT /api/kids/{kidId}/allowed-categories`.
- `GET /api/kids/{kidId}/category-candidates`.
- `GET /api/kids/{kidId}/business-candidates?query&city&categoryId&page&pageSize`.
- `GET /api/guardians/children`; `POST /api/guardians/children`; `POST /api/guardians/children/link`.
- `GET/PUT/DELETE /api/guardians/children/{childId}`.
- `POST /api/guardians/children/{childId}/photo` multipart, máximo 5 MB.
- `GET/POST /api/guardians/children/{childId}/permissions`.
- `GET /api/guardians/children/{childId}/wallet`, `/wallet/cards`, `/wallet/history`.
- `POST /api/guardians/children/{childId}/wallet/cards`.
- `POST /api/guardians/children/{childId}/wallet/cards/{cardId}/recharge`.
- `GET /api/guardians/children/{childId}/payment-methods`; `POST .../payment-sources`.
- `GET /api/guardians/children/{childId}/payments`, `/receipts`, `/financial-permissions`, `/spending-limits`.
- `POST .../financial-permissions`; `PUT .../spending-limits`.
- `POST /api/guardians/children/{kidId}/account`; `PATCH .../account/status`; `PUT .../account/pin`.
- `GET /api/guardians/children/{kidId}/last-location`.
- `GET /api/guardians/pay-for-me/requests`; `POST .../{requestId}/approve|reject`.
- `POST /api/v1/security/block-all`; `POST /api/v1/security/unblock-all` (alias `/unlock-all`).
- reglas: `GET/POST/DELETE /api/kids/{kidId}/rules/merchants`, `categories`, `countries`, `blocked-merchants`;
  `GET/PUT .../limits`, `schedules`; `GET/POST/PUT/DELETE .../geofences`.
- tarjeta Kid: `GET /api/kids/{kidId}/card/status`; `POST .../block|unblock|enable|disable`.
- ubicación: `GET /api/kids/{kidId}/location`; `GET /api/kids/{kidId}/location/locations?take`.

**Kid (`KidOnly`)**

- `GET /api/kids/me/home`, `/wallet`, `/profile`, `/family-chat`.
- `GET /api/kids/me/allowed-businesses?city&zone&categoryId&query&page&pageSize`.
- `PATCH /api/kids/me/profile` con `displayName`; `POST /api/kids/me/photo` multipart, máximo 5 MB.
- `POST /api/kids/me/pay-for-me/request`; `GET /api/kids/me/pay-for-me/requests`.
- `POST /api/kids/me/location/share`.
- alias de perfil: `GET /api/v1/kids/profile`.

**Client o Kid**

- `POST /api/kids/{kidId}/location` (un Kid solo puede publicar su propio `kidId`).
- `POST /api/v1/kids/shield/validate`.
- `GET /api/v1/kids/security/events?paymentSessionId&cursor&take`.

Modelos Dart prioritarios:

- `KidHome`: `kidId`, `name`, `photoUrl?`, `wallet{balance,currency}`, `allowedBusinessesCount`, `unreadFamilyMessages`, `canRequestPayForMe`, `canShareLocation`.
- `KidWallet`: `balance`, `heldBalance`, `currency`, `lastMovements`; movimiento: `id,type,amount,description?,createdAt,status?`.
- `KidProfile`: campos de identidad, `age`, `familyName`, `kidsPublicId?`, `guardians`.
- `KidsSecurityStatus`: `kidId,status,loginLocked,walletLocked,cardsLocked,nfcInstrumentsLocked,tokensRevoked,changedAt?`.
- `KidPayForMeRequest`: `businessId?`, `amount`, `currency`, `description?`, `location?`, `requestedToTutorId?`, `shareInFamilyChat`, `idempotencyKey`.

Shield es un bloqueo coordinado de login, Wallet, tarjetas, NFC y refresh tokens. Estado móvil mínimo: `unlocked → locking → locked → unlocking → unlocked`; cualquier fallo obliga a leer eventos/estado relacionado antes de asumir desbloqueo. Eventos implementados: `shield.lock_all` y `shield.unlock_all`.

**Criterio de aceptación:** bloquear Shield actualiza UI solo con `status:true`; se refleja `tokensRevoked`; una sesión Kid revocada vuelve a login; un tutor no puede consultar un `kidId` ajeno y la UI trata 403 sin revelar datos.

## 7. Kids QR, aprobaciones, QR y NFC

### 7.1 Kids QR

| Método | Ruta | Auth |
|---|---|---|
| POST | `/api/kids/payments/scan` | ClientOrKid |
| POST | `/api/kids/rules/validate` | ClientOrKid |
| POST | `/api/v1/kids/shield/validate` | ClientOrKid |
| POST | `/api/kids/approvals/request` | ClientOrKid |
| GET | `/api/parents/approvals` | ClientOnly |
| GET | `/api/parents/approvals/history?take` | ClientOnly |
| POST | `/api/parents/approvals/{approvalId}/approve` | ClientOnly |
| POST | `/api/parents/approvals/{approvalId}/reject` | ClientOnly |
| GET | `/api/kids/payments/{paymentSessionId}/approval` | ClientOrKid |
| POST | `/api/kids/payments/confirm` | ClientOrKid |
| GET | `/api/kids/payments/{paymentSessionId}/tracking` | ClientOrKid |
| GET | `/api/kids/payments/{paymentSessionId}/events?cursor` | ClientOrKid, SSE |
| GET | `/api/kids/payments/{paymentSessionId}/events/poll?cursor&take` | ClientOrKid |

`KidsQrScanRequest`: `kidId:int`, `deviceId:string`, `merchantQr:string`, `amount:decimal`, `latitude:decimal?`, `longitude:decimal?`.

`KidsQrScanResponse`: `paymentSessionId`, `merchant{merchantId,businessId,name,category?,city?,country?,logo?}`, `amount`, `currency`, `approvalRequired`, `status`, `ruleMatched?`, `reason?`, `approvalId?`.

`KidsQrConfirmRequest`: `paymentSessionId`, `paymentMethod` (default `CIERVO_BALANCE`), `pin?`, `idempotencyKey`.

Estados de sesión reales: `QrScanned(1) → MerchantFound(2) → RulesValidated(3) → WaitingParent(4) → ParentViewing(5) → Approved(6) → PaymentProcessing(8) → PaymentSuccess(9)`; terminales alternos `Rejected(7)`, `PaymentFailed(10)`, `Expired(11)`, `Cancelled(12)`.

Aprobación: `Pending(0)`, `Approved(1)`, `Rejected(2)`, `Expired(3)`. Severidad de regla: `Pass(0)`, `RequiresApproval(1)`, `Critical(2)`.

### 7.2 QR de comercio

- `POST /api/businesses/{businessId}/payment-qrs`, BusinessOrAdmin.
- `GET /api/payments/qr/{token}`, anónimo.
- `POST /api/payments/qr/{token}/pay`, ClientOnly.

Crear QR: `amount`, `currency`, `description?`, `expirationMinutes?`. Pagar: `paymentMethod` (default `wallet`), `walletCardId?`, `idempotencyKey`. La resolución devuelve `status`, `expiresAt`, `isExpired`.

### 7.3 NFC

- Kids: `POST /api/guardians/children/{childId}/nfc/cards/{cardId}/public-id`, `/associate`, `/physical/{physicalCardId}/block|unblock` (ClientOnly); `POST /api/businesses/{businessId}/kids-nfc/pay` (BusinessOrAdmin).
- Wallet: `POST /api/wallet/nfc/sessions`, `GET /sessions/{sessionId}`, `POST /sessions/{sessionId}/cancel` (ClientOnly).
- `POST /api/wallet/nfc/validate`, `/charge` (BusinessOrAdmin).
- `GET /api/wallet/nfc/physical-cards`, `POST /api/wallet/cards/{cardId}/physical-nfc`, `POST /api/wallet/physical-nfc/{physicalCardId}/block` (ClientOnly).

Sesión Wallet NFC: `Active(1)`, `Used(2)`, `Expired(3)`, `Cancelled(4)`. Tarjeta física: `Active(1)`, `Blocked(2)`, `Revoked(3)`. Pago: `Succeeded(1)`, `Failed(2)`.

`CreateWalletNfcSessionRequest`: `idempotencyKey`, `walletCardId?`, `businessId?`, `amount`, `currency`, `expirationSeconds` (default 60), `description?`, `referenceType?`, `referenceId?`.

Permisos móviles: cámara para QR; ubicación solo cuando el usuario comparte/valida contexto; NFC solo en dispositivos compatibles. Solicitar cada permiso al entrar en la función, no al arrancar. Si NFC no existe, mantener QR/Wallet como alternativas.

**Criterio de aceptación:** cerrar/reabrir la app durante `WaitingParent` recupera tracking por `paymentSessionId`; una confirmación repetida conserva la misma idempotency key; expiración deshabilita pagar; denegar cámara/ubicación/NFC deja una alternativa utilizable.

## 8. Eventos, polling y SSE

No existe SignalR en los contratos revisados. Canales reales:

- Kids QR SSE: historial con `id:` para eventos persistidos y `data: {"type":...,"payload":...}`; luego eventos vivos.
- Kids QR polling: página `{nextCursor,hasMore,items:[{cursor,type,payloadJson,createdAt}]}`.
- Kids security polling: `/api/v1/kids/security/events` con el mismo cursor.
- Movie polling: `GET /api/v1/movie/events?cursor&take`; item `{cursor,aggregateId,aggregateType,eventType,payloadJson,createdAt}`.
- Move SSE: `GET /api/v1/move/trips/{tripId}/events`; primer evento `trip.snapshot`, después estado/ofertas/ubicación. No implementa cursor persistente.
- Notifications SSE: `GET /api/notifications/events?sinceId`; consulta cada 2 s y emite `type:"notification"`, heartbeat cada 30 s.

Estrategia:

1. preferir SSE en foreground;
2. reconectar con backoff 1, 2, 5, 10, 30 s;
3. Kids: persistir cursor por `paymentSessionId` y usar poll para rellenar huecos;
4. Movie: persistir cursor por usuario;
5. Notifications: persistir mayor `notification.id` como `sinceId`;
6. Move: al reconectar aceptar `trip.snapshot` como fuente de verdad;
7. en background, cerrar SSE y depender de FCM; al volver, reconciliar por GET/poll.

**Criterio de aceptación:** una prueba desconecta después de recibir N eventos, reconecta y no pierde ni duplica efectos; los reducers son idempotentes por cursor/id de notificación; Move reemplaza estado con snapshot.

## 9. Movie

Endpoints cliente autenticado:

- `GET /api/v1/movie/movies?page&pageSize&maximumMinimumAge&search`.
- `GET /api/v1/movie/movies/{movieId}/showtimes`.
- `POST /api/v1/chat/movie/requests`.
- `GET /api/v1/chat/movie/requests/{requestId}`.
- `POST .../{requestId}/approve|reject|cancel`.
- `POST /api/v1/chat/movie/share`.
- `POST /api/v1/movie/reservations`.
- `PUT /api/v1/movie/reservations/{reservationId}/seats`.
- `POST /api/v1/movie/reservations/{reservationId}/payment`.
- `POST /api/v1/movie/reservations/{reservationId}/qr`.
- `GET /api/v1/movie/history?page&pageSize`.
- `GET /api/v1/movie/events?cursor&take`.
- BusinessOrAdmin: `POST /api/v1/movie/qr/consume`.

DTO esenciales:

- catálogo: `MovieSummary{id,title,description?,minimumAge,durationMinutes,language,imageUrl?}`.
- función: `id,movieId,movieTitle,cinemaId,cinemaName,hallId,hallName,startsAt,endsAt,basePrice,currency,availableSeats`.
- request compartida: `conversationId,showtimeId,ticketCount,idempotencyKey`.
- reserva: `showtimeId,movieRequestId?,ticketCount,idempotencyKey`.
- asientos: `showtimeSeatIds:List<String>`.
- pago: `walletCardId?`, `idempotencyKey`.
- QR: `qrId,reservationId,token,expiresAt`.

Estados:

- solicitud: `Pending(1), Approved(2), Rejected(3), Cancelled(4), Expired(5), Reserved(6)`;
- reserva: `Draft(1), SeatsHeld(2), PendingPayment(3), Confirmed(4), Cancelled(5), Expired(6), Refunded(7), Completed(8)`;
- función: `Scheduled(1), OnSale(2), SoldOut(3), Cancelled(4), Completed(5)`;
- asiento: `Available(1), Held(2), Sold(3), Blocked(4)`;
- QR admisión: `Active(1), Consumed(2), Expired(3), Revoked(4)`.

Máquina UI: catálogo → función → reserva Draft → SeatsHeld → PendingPayment → Confirmed → QR Active → Consumed/Expired. Un 409 exige recargar asientos/reserva; 410 cierra la acción expirada; 422 conserva contexto para cambiar pago.

**Criterio de aceptación:** dos taps en reservar/pagar reutilizan una clave por operación lógica; la pantalla de asientos recarga ante 409; no se muestra QR antes de `Confirmed`; un evento posterior actualiza historial sin duplicar reserva.

## 10. Move

Pasajero autenticado:

- `POST /api/v1/move/trips`.
- `GET /api/v1/move/trips?status&page&pageSize`.
- `GET /api/v1/move/trips/kids/approvals`.
- `POST /api/v1/move/trips/{tripId}/parent-approve|parent-reject`.
- `POST /api/v1/move/trips/{tripId}/sos`.
- `GET /api/v1/move/trips/{tripId}`, `/offers`, `/location`, `/events`.
- `POST /api/v1/move/trips/{tripId}/accept/{offerId}`, `/cancel`, `/rate`.
- `POST /api/v1/move/trips/counter-offer`.

Conductor autenticado:

- `POST /api/v1/move/driver/apply` (alias `/registration/basic-profile`).
- `GET /api/v1/move/driver/me` devuelve `value:null` con 200 si aún no es conductor.
- `POST /api/v1/move/driver/vehicles` (alias `/registration/vehicle`), `PUT /vehicles/{id}`.
- `POST /api/v1/move/driver/documents`, `/registration/driver-license`, `/registration/review`.
- `POST /api/v1/move/driver/online`, `/location`.
- `GET /api/v1/move/driver/trips/available`, `GET /api/v1/move/driver/trips`.
- `POST /api/v1/move/driver/trips/offer`.
- `POST /api/v1/move/driver/trips/{tripId}/arriving|arrived|start|finish|cancel|rate`.

`MoveTripRequest` incluye país/ciudad/categoría, origen/destino y direcciones, distancia/duración/espera, recargos (`isNight,isRaining,highDemandPct,isAirport,tolls`), `paymentMethod`, `offeredFare`, `childProfileId?`.

Estados viaje: `Draft(1), Searching(2), Offered(3), DriverAssigned(4), PaymentPending(5), PaymentHeld(6), DriverArriving(7), DriverArrived(8), InProgress(9), Completed(10), CancelledByUser(11), CancelledByDriver(12), CancelledBySystem(13), Expired(14), Disputed(15), PendingParent(16)`.

Pago: `None(0), Pending(1), Held(2), Captured(3), Released(4), Failed(5), Refunded(6)`. Oferta: `Pending(1), Accepted(2), Rejected(3), Expired(4), CounterOffered(5), CancelledByDriver(6), SupersededByOtherOffer(7)`.

Permisos: ubicación precisa durante viaje/online; ubicación en background solo para modo conductor activo y con explicación previa; cámara/archivos para documentos. SOS debe pedir confirmación corta, enviar ubicación si está disponible y no bloquearse si se deniega.

**Criterio de aceptación:** el conductor no puede activar online hasta perfil aprobado según respuesta; cada transición habilita solo la siguiente acción válida; un 409 recarga viaje; matar/reabrir durante `InProgress` restaura detalle y SSE.

## 11. Chat

Rutas equivalentes base `/api/chat` y `/api/v1/chat`, todas autenticadas:

- `GET /conversations`, `GET /conversations/{id}`, `GET /conversations/{id}/messages?page&pageSize`.
- `POST /conversations`.
- `POST /conversations/{id}/messages`.
- `POST /conversations/{id}/messages/media` multipart, máximo 5 MB; tipo `Image` o `File`.
- `POST /conversations/{id}/messages/{messageId}/forward`.
- `POST /conversations/{id}/read`.
- `GET /buttons`.
- `POST /commerce/share`, `/qr/share`, `/payment-requests/share`, `/typed/movie/share`, `/move/share`.
- `POST /calls/sessions`, `GET /calls/sessions/{id}`, `POST /calls/sessions/{id}/end`.

Conversación: `id,type,businessId?,reservationId?,orderId?,clientUserId?,peerUserId?,title?,status,lastMessageAt?,createdAt,unreadCount`.

Mensaje: `id,conversationId,senderUserId,senderName?,senderRole,messageType,type?,body?,text?,attachmentUrl?,mediaUrl?,imageUrl?,thumbnailUrl?,storagePath?,mediaType?,metadataJson?,latitude?,longitude?,address?,mapsUrl?,staticMapUrl?,createdAt,updatedAt?,isOwnMessage`.

Tipos forzados por endpoints tipados: `CommerceShare`, `QrShare`, `PaymentRequest`, `MovieShare`, `MoveTrip`. El request comparte `conversationId`, `referenceId`, `referenceKind?`, `comment?`; no confiar en `contentType` recibido, pues el controlador lo reemplaza.

No hay stream de chat implementado en este controlador. Actualizar mediante retorno de envío, refresh paginado al volver al foreground y notificaciones.

**Criterio de aceptación:** `metadataJson` se parsea de forma tolerante por tipo y conserva el raw; archivos >5 MB se rechazan antes de subir; los mensajes paginados se deduplican por `id`.

## 12. Wallet, pagos e idempotencia

Wallet (`ClientOnly`):

- `GET /api/wallet/cards`, `/cards/{id}`, `/cards/{id}/balance`, `/cards/{id}/transactions`.
- `POST /api/wallet/cards/{id}/recharge-intents`; `GET /recharge-intents/{id}`; `POST /recharge-intents/{id}/sync`.
- `GET /api/wallet/mercadopago/config`.
- `POST /api/wallet/cards/{id}/set-primary|block|unblock`; `DELETE /cards/{id}`.
- `GET /api/wallet/me/ciervo-id`, `/resolve-user/{ciervoUserCode}`.
- `POST /api/wallet/recharge-by-ciervo-id`.
- `POST /api/wallet/transfer/quote`, `/transfer`.

Tarjeta: `id,userId,userWalletId,cardTemplateId,templateCode,displayName,balance,heldBalance,availableBalance,currency,statusId,isPrimary,visualColor?,styleKey?,blockedAt?,blockedReason?,createdAt,updatedAt?,deletedAt?`.

Recarga: `{amount,currency,idempotencyKey,description?}` → intent + `checkoutUrl`, `initPoint`, `preferenceId?`, `receipt?`. Tras volver de Mercado Pago, no asumir éxito por URL: llamar `sync` y leer estado.

Generación de claves: UUID v4 por intención lógica, persistido antes del POST. Reutilizar al reintentar la misma operación; generar otro si usuario cambia importe, destino, tarjeta o reserva. Aplica explícitamente a intents, transferencias/pagos que lo exigen, pay-for-me, Movie, Kids QR, Wallet NFC, QR comercio, delivery payment/tip y promociones.

**Criterio de aceptación:** modo avión después de enviar y antes de recibir permite reintentar con la misma clave; no se crean dos movimientos; la UI siempre muestra `availableBalance`, diferenciando `heldBalance`.

## 13. Commerce, bookings y órdenes

Descubrimiento autenticado:

- `GET /api/businesses` con ciudad/categoría/búsqueda/ubicación/radio y filtros smart.
- `GET /api/businesses/by-city`, `/nearby`, `/by-category`, `/search`; aceptan `kidId?` y filtran por tutor autorizado.
- `GET /api/businesses/{id}/public-detail` es anónimo.
- `GET /api/businesses/{id}/events?onlyUpcoming`.

Filtros implementados: `experienceMode,minRating,openNow,acceptsCiervoPayments,hasDelivery,requiresReservation,hasPromotions,familyFriendly,petFriendly,accessible,hasParking`, además de ubicación/categoría/texto.

Bookings:

- `POST /api/bookings` ClientOnly.
- `GET /api/bookings/{id}` autenticado.
- `GET /api/bookings/by-user/{userId}` ClientOnly.
- `GET /api/bookings/by-business/{businessId}` y `PUT /api/bookings/{id}/status` BusinessOrAdmin.
- `POST /api/bookings/{id}/cancel` ClientOnly.

Delivery/orden cliente:

- `GET /api/businesses/{businessId}/delivery-availability` (alias `/delivery/availability`), ClientOnly.
- `POST /api/businesses/{businessId}/order-quote`, ClientOnly.
- `POST /api/businesses/{businessId}/delivery-orders`, ClientOnly.
- `GET /api/orders?page&pageSize`, `GET /api/orders/{orderId}`, ClientOnly.

Quote: `fulfillmentType?`, `items[{productId,quantity}]`, `latitude?`, `longitude?`, flags de pico/lluvia/festivo. Respuesta contiene opciones `pickup` y `delivery`, cada una con `available,reason?,productSubtotal,deliveryFee,total,currency,countryCode,estimatedMinutes?,pricing?,items`.

Crear orden: `fulfillmentType` (`delivery`/`pickup`), dirección/lat/lng opcionales según tipo, `items`, `notes?`, `childProfileId?`, flags de recargo.

Estados Delivery reales: `PendingAssignment(1), Assigned(2), Accepted(3), ArrivedAtBusiness(4), PickedUp(5), OnTheWay(6), ArrivedAtCustomer(7), Delivered(8), Cancelled(9), Rejected(10), Preparing(11), ReadyForPickup(12), PendingBusinessApproval(13), RejectedByBusiness(14), PendingCourierAcceptance(15), CourierAssigned(16), AcceptedByCourier(17), CourierNotFound(18)`.

Pago orden: `Pending(1), Processing(2), Paid(3), CashPending(4), CollectOnDelivery(5), Failed(6), Refunded(7), NfcPrepared(8)`. Fulfillment: `Delivery(1)`, `Pickup(2)`.

**Criterio de aceptación:** checkout siempre obtiene quote inmediatamente antes de crear; bloquea opción con `available:false` mostrando `reason`; una orden Kid muestra estado de aprobación; detalle tolera cualquiera de los 18 estados sin pantalla en blanco.

## 14. Notificaciones, FCM y deep links

Endpoints autenticados:

- `GET /api/notifications` paginado/filtrado.
- `GET /api/notifications/badges`.
- `POST /api/notifications/{id}/read`, `/read-all`.
- `DELETE /api/notifications/{id}`, `DELETE /api/notifications`.
- `POST /api/notifications/fcm/register`, `/fcm/unregister`; `DELETE /fcm/tokens`.
- `GET /api/notifications/events?sinceId` SSE.
- `POST /api/devices/register`; `DELETE /api/devices/{deviceId}` para ClientOrKid.

FCM register: `fcmToken`, `platform` (`android` por defecto), `deviceId?`, `deviceName?`, `appVersion?`. Re-registrar al cambiar token, login, rol/perfil o versión relevante; desregistrar al logout antes de borrar sesión.

Badges: `total,wallet,chat,delivery,reservations,promotions`.

El backend almacena `deepLink` y `metadataJson`, pero no define en los DTO revisados un catálogo móvil cerrado. Flutter debe implementar un resolver allowlist local:

- parsear URI;
- mapear únicamente host/esquema oficial y rutas conocidas;
- extraer IDs tipados;
- abrir primero el GET autorizado del recurso;
- ante ruta desconocida, abrir bandeja de notificaciones;
- nunca ejecutar pagos, aprobaciones o mutaciones desde el deep link.

**Criterio de aceptación:** un push con deep link malformado/externo no navega; uno válido con sesión expirada autentica y revalida; logout desregistra token; badges coinciden tras `read-all`.

## 15. Safety

ClientOnly:

- `POST /api/reports`; `GET /api/reports/me`.
- `POST /api/content-blocks`; `DELETE /api/content-blocks/{targetType}/{targetId}`; `GET /api/content-blocks/me`.

Reporte: `targetType`, `targetId?`, `reportedUserId?`, `reason`, `description?` (máx. 1000). Respuesta: `id`, objetivo, usuario reportado, motivo, descripción, `status`, `createdAt`, `reviewedAt?`, `adminNotes?`.

Bloqueo: `targetType`, `targetId`; respuesta `id,targetType,targetId,createdAt`.

**Criterio de aceptación:** el contenido bloqueado desaparece de listas locales al confirmar `status:true`; un fallo revierte el cambio optimista; reportar nunca expone notas administrativas de terceros.

## 16. Modelos Dart mínimos

Crear, con generación JSON y tests de round-trip:

- `ApiEnvelope<T>`, `ProblemDetails`, `ValidationProblemDetails`, `PagedResponse<T>`.
- `AuthSession`, `AuthUser`, `KidSession`, `FirebaseAccountLookup`.
- `KidHome`, `KidProfile`, `KidWallet`, `KidMovement`, `KidsSecurityStatus`, `KidsRealtimeEventPage`.
- `KidsQrSession`, `KidsApproval`, `MerchantKidsContext`.
- `Movie`, `MovieShowtime`, `MovieRequest`, `MovieReservation`, `MovieSeat`, `MovieQr`, `MovieEvent`.
- `MoveTrip`, `MoveOffer`, `MoveLocation`, `MoveDriverProfile`, `MoveVehicle`, `MoveDocument`.
- `ChatConversation`, `ChatMessage`, `TypedChatReference`.
- `WalletCard`, `WalletTransaction`, `PaymentIntent`, `PaymentReceipt`, `WalletNfcSession`.
- `BusinessSummary`, `DeliveryQuote`, `DeliveryOrder`, `Booking`.
- `AppNotification`, `NotificationBadges`, `FcmRegistration`.

Reglas:

- dinero y currency siempre juntos;
- IDs `Guid` como value object String;
- `payloadJson`/`metadataJson` se guardan raw y se decodifican opcionalmente;
- fechas se normalizan a UTC;
- enums desconocidos no lanzan excepción.

**Criterio de aceptación:** fixtures cubren nullables, enum desconocido, decimal, UUID, fecha UTC, payload JSON inválido y respuesta con `value:null`.

## 17. Migración por fases

### Fase 0 — compatibilidad

Implementar envelope, Problem Details, correlation ID, secure storage versionado y cierre de sesión por cambio issuer/audience.

**Aceptación:** build migrado inicia con sesión antigua, la elimina una vez, lleva a login y no repite el aviso en siguientes arranques.

### Fase 1 — auth y navegación

Integrar login adulto/Firebase/Kid, refresh mutex, guards por rol/account kind/permissions, FCM por sesión.

**Aceptación:** suites E2E cubren Client, Kid, Business y Admin; access expirado se recupera; refresh inválido sale de sesión.

### Fase 2 — Kids y Shield

Integrar perfiles, permisos, reglas, Wallet Kid, ubicación, pay-for-me, Shield y aprobaciones.

**Aceptación:** tutor administra solo hijos propios; Kid solo accede a su perfil; bloqueo revoca sesión Kid y se refleja en eventos.

### Fase 3 — QR/NFC/Wallet

Integrar escaneo, tracking, polling/SSE, pagos idempotentes, recarga y fallback por capacidades.

**Aceptación:** pruebas con red intermitente no duplican cargos; cursor se recupera; dispositivo sin NFC completa por QR/Wallet.

### Fase 4 — Movie/Move/Chat/Commerce

Activar máquinas de estados y tarjetas tipadas, delivery/pickup y órdenes.

**Aceptación:** pruebas de transición cubren todos los estados enumerados; 409/410/422 muestran recuperación correcta; chat deduplica mensajes.

### Fase 5 — observabilidad y endurecimiento

Instrumentar métricas por endpoint, errorCode, HTTP status, correlation ID, reconexión SSE y latencia; nunca registrar JWT, refresh, PIN, token QR/NFC ni FCM completo.

**Aceptación:** un incidente de QA puede rastrearse con correlation ID; revisión de logs confirma ausencia de secretos.

## 18. Matriz QA final

1. **Contrato:** generar fixtures desde respuestas reales para cada modelo prioritario. Aceptación: 100 % deserializa sin `dynamic` en presentation.
2. **Auth:** JWT vencido, issuer/audience viejo, refresh rotado/reutilizado, PIN errado cinco veces. Aceptación: no hay loops ni sesión fantasma.
3. **Roles:** ejecutar cada endpoint móvil con rol correcto e incorrecto. Aceptación: 403 no filtra datos y la acción está oculta.
4. **Idempotencia:** cortar red después de cada POST financiero. Aceptación: reintento usa la misma key y produce un único resultado.
5. **Eventos:** desconectar/reconectar Kids/Movie/Move/Notifications. Aceptación: sin pérdidas ni efectos duplicados.
6. **Estados:** fixture por cada estado Kids QR, Movie, Move, Wallet NFC y Delivery. Aceptación: todos tienen texto/acción/terminalidad definidos.
7. **Permisos del SO:** cámara, ubicación foreground/background, notificaciones y NFC: concedido, denegado y denegado permanente. Aceptación: hay explicación y fallback.
8. **Deep links:** válido, desconocido, malicioso, recurso inexistente y sesión expirada. Aceptación: nunca muta y siempre revalida.
9. **Accesibilidad:** lector de pantalla, tamaño de fuente, contraste y confirmaciones financieras. Aceptación: acciones críticas tienen etiqueta, importe y moneda legibles.
10. **Fechas/moneda:** UTC, cambio de zona, COP y currency inesperada. Aceptación: no cambia el día indebidamente ni mezcla monedas.
11. **Archivos:** foto/chat exactamente 5 MB y superior, tipo inválido. Aceptación: validación local coincide con backend y conserva correlation ID.
12. **Regresión:** bootstrap anónimo `GET /api/app/bootstrap`, health no usado como auth, logout y borrado FCM. Aceptación: cold start funciona con/sin sesión y sin llamadas protegidas prematuras.

## 19. Decisiones que la app no debe asumir

- No asumir que HTTP 200 significa éxito.
- No asumir que chat tiene streaming.
- No asumir que Move SSE puede reanudarse por cursor.
- No asumir que un retorno de Mercado Pago implica pago exitoso.
- No asumir que `deepLink` es confiable o pertenece a un catálogo cerrado.
- No asumir que todos los estados textuales usan la misma capitalización.
- No asumir que `GET /api/v1/move/driver/me` con `value:null` es error.
- No asumir que el rol visual sustituye las políticas/permissions del backend.
- No reintentar una mutación financiera con una idempotency key nueva.
- No conservar tokens previos al cambio obligatorio de issuer/audience.
