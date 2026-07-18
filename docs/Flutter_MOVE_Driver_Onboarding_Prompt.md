# Prompt final para Flutter — onboarding de conductor CIERVO MOVE v2

## Mandato

Implementa **exclusivamente el frontend Flutter** del onboarding de conductor CIERVO MOVE v2 contra el backend ya existente. No diseñes, cambies ni simules backend; no inventes endpoints, DTOs, estados, verificaciones ni capacidades ausentes. La fuente de verdad son los contratos descritos aquí, derivados del código implementado.

El conductor **no es un rol nuevo**: es un `Client` existente (rol numérico `1`) que adquiere un perfil MOVE. La identidad y autoridad siempre provienen del JWT (`nameidentifier`/userId) y de la policy backend `ClientOnly`. No existe login ni rol `Driver`, no existe `/master/login`, y no se debe enviar un `driverId` para suplantar al actor.

## 1. Base, autenticación y sesión

- Producción configurada: `https://api.ciervo.club`; desarrollo: `https://localhost:7150`. Configurar por flavor y no duplicar `/api`.
- Login Client con contraseña: `POST /api/auth/user/login`, body `LoginRequest`:

```json
{
  "email": "persona@example.invalid",
  "user": null,
  "password": "<secreto-introducido-por-el-usuario>"
}
```

  Debe existir `email` o `user`; `password` es obligatorio. La contraseña pertenece al login, **nunca al onboarding**.
- Login Firebase Client: `POST /api/auth/firebase/login`, body:

```json
{
  "firebaseIdToken": "<token-efimero>",
  "phone": "+573000000000",
  "email": null,
  "countryCode": "CO"
}
```

- Registro Firebase si corresponde: `POST /api/auth/firebase/register`; sincronización de contacto verificado: `POST /api/auth/firebase/sync-verification`.
- El backend no implementa SMS propio para MOVE. Para teléfono usar **Firebase Phone Auth** y luego sincronizar la verificación. No implementar una pantalla que espere OTP de MOVE ni enviar password/OTP en los DTO del onboarding.
- Refresh/logout existentes: `POST /api/auth/refresh-token` y `POST /api/auth/logout`, con `{ "refreshToken": "<secreto>" }`.
- La respuesta de autenticación moderna es `Response<AuthResponse>`; `AuthResponse`: `userId`, `fullName`, `roleId`, `accountKind`, `roleName`, `businessRoleId?`, `businessId?`, `staffId?`, `permissions[]`, `accessToken`, `accessTokenExpiresAt`, `refreshToken`, `refreshTokenExpiresAt`, `authAction?`, `linkedLegacy`.
- Aceptar el flujo solo si el actor es Client. Guardar tokens en Keychain/Keystore, nunca en logs, analytics, breadcrumbs ni almacenamiento plano.
- Antes de poder enviar el onboarding debe existir al menos un contacto Client verificado: `EmailVerifiedAt` o `PhoneVerifiedAt` backend. El status lo reporta indirectamente como `verified_contact` faltante.

Headers comunes:

```http
Authorization: Bearer <access-token>
Accept: application/json
Content-Type: application/json
```

Todas las mutaciones v2 de onboarding (`identity`, `license`, `vehicle`, `operations`, `submit`) requieren además:

```http
Idempotency-Key: <clave-estable-de-la-intencion>
```

La clave es un **header**, obligatoria, no vacía y de máximo 120 caracteres. Generar una clave por intención, persistirla de forma segura junto al borrador hasta recibir respuesta definitiva y reutilizarla en timeout, desconexión o 5xx. Una acción/payload nuevo usa otra clave. Reusar una clave con payload distinto devuelve `409`.

## 2. Envoltorios y errores

Los endpoints MOVE devuelven `Response<T>`:

```json
{
  "status": true,
  "value": {},
  "msg": "OK",
  "errorCode": null
}
```

En error de dominio:

```json
{
  "status": false,
  "value": null,
  "msg": "Mensaje seguro",
  "errorCode": "VALIDATION"
}
```

Modelar `status`, `value`, `msg`, `errorCode`; evaluar HTTP y también `status`. La validación automática/middleware puede devolver Problem Details. Manejar:

- `400`: DataAnnotations, regla o transición inválida; corregir y no reintentar automáticamente.
- `401`: JWT ausente/vencido; refresh una vez y, si falla, cerrar sesión.
- `403`: no es Client/propietario; no alterar IDs ni reintentar.
- `404`: Client/perfil/recurso no existe.
- `409`: términos cambiaron, duplicado, idempotencia o concurrencia; refrescar status/configuración.
- `429`: rate limit; respetar espera y backoff.
- `5xx`/timeout: reintento acotado con backoff+jitter y la misma `Idempotency-Key`.

## 3. Inventario exacto de endpoints

### 3.1 Canónicos de onboarding v2 — `ClientOnly`

- `GET /api/v1/move/driver/onboarding/status`
- `PUT /api/v1/move/driver/onboarding/identity`
- `PUT /api/v1/move/driver/onboarding/license`
- `PUT /api/v1/move/driver/onboarding/vehicle`
- `PUT /api/v1/move/driver/onboarding/operations`
- `POST /api/v1/move/driver/onboarding/submit` — sin body

Todos devuelven `Response<MoveDriverOnboardingStatusDto>`.

### 3.2 Self-service y compatibilidad legacy MOVE

Estas rutas siguen existiendo, pero no sustituyen los DTO ni gates v2:

- `POST /api/v1/move/driver/apply`
- alias `POST /api/v1/move/driver/registration/basic-profile`
- `GET /api/v1/move/driver/me` — si aún no hay perfil devuelve éxito con `value:null`; el DTO incluye `onboarding`.
- `POST /api/v1/move/driver/vehicles`
- alias `POST /api/v1/move/driver/registration/vehicle`
- `PUT /api/v1/move/driver/vehicles/{vehicleId}`
- `POST /api/v1/move/driver/documents`
- alias de licencia legacy `POST /api/v1/move/driver/registration/driver-license`
- `POST /api/v1/move/driver/registration/review`
- `POST /api/v1/move/driver/online`
- `POST /api/v1/move/driver/location`

Para onboarding nuevo usar las rutas v2. No ejecutar simultáneamente altas legacy y v2 ni convertir `fileUrl` legacy en `mediaAssetId`. Tras aprobación, `POST /api/v1/move/driver/online` recibe:

```json
{
  "isOnline": true,
  "latitude": 4.710989,
  "longitude": -74.072092
}
```

Solo permite online si perfil `Approved`, vehículo activo y, cuando existe identidad v2, `canGoOnline=true`.

### 3.3 Media real requerida antes de enviar DTO v2

El onboarding recibe IDs de `MediaAsset`, no bytes ni URLs. Flujo implementable:

```http
POST /api/media/upload
Authorization: Bearer <Client JWT>
Content-Type: multipart/form-data

ownerType=User
ownerId=<userId del Client autenticado>
mediaType=Gallery
file=<imagen>
```

También se acepta técnicamente `mediaType=ProfilePhoto`, pero usar `Gallery` para documentos/fotos evita cambiar la foto principal. La respuesta `Response<MediaAssetResponse>` contiene `id`; usar ese `id` como `selfieMediaAssetId`, media de licencia, documentos o fotos.

Contrato efectivo de upload actual:

- ownership `User` del mismo Client;
- imágenes `.jpg`, `.jpeg`, `.png`, `.webp`;
- MIME `image/jpeg`, `image/jpg`, `image/png`, `image/webp`;
- máximo **5 MiB** por archivo;
- MOVE vuelve a validar ownership, no eliminado, `StoragePath` relativo, `SizeBytes>0`, tamaño máximo interno 10 MiB y tipo `ProfilePhoto|Gallery`.

Rutas media existentes:

- `GET /api/media/{id}` — metadata, solo owner o Admin.
- `GET /api/media/{id}/download` — descarga privada; `Cache-Control: private, max-age=300`.
- `GET /api/media/{id}/thumbnail` — hoy delega en download, no garantiza miniatura distinta.
- `DELETE /api/media/{id}` — no borrar un asset ya referenciado por un borrador enviado.
- `POST /api/media/register?ownerType=User&ownerId=...&mediaType=Gallery`.

**No usar `/api/media/register` para MOVE v2**: el registro externo actual guarda `SizeBytes=0` y normalmente un `StoragePath` absoluto, y `ValidMedia` de onboarding lo rechaza. Aunque `MoveLicenseOnboardingRequest`/documentos permiten PDF por validación interna, el `MediaService.Upload` actual solo acepta imágenes; PDF no es subible por esta API. Capturar/convertir a imagen permitida sin degradar legibilidad. No subir directo a bucket y no inventar presigned upload.

No existe antivirus, escaneo antimalware ni cuarentena de media. No afirmar que un archivo fue escaneado. Comprimir/redimensionar localmente, validar firma/extensión/MIME en UX y advertir errores del servidor.

## 4. DTOs exactos de `DTO/MoveOnboardingDtos.cs`

JSON usa camelCase; fechas ISO-8601 con offset o `Z`.

### `MoveIdentityOnboardingRequest`

```json
{
  "firstNames": "Ana María",
  "lastNames": "Pérez Soto",
  "documentType": "CC",
  "documentNumber": "DEMO0001",
  "countryCode": "CO",
  "city": "Bogotá",
  "email": "persona@example.invalid",
  "phone": null,
  "birthDate": "1990-05-20",
  "selfieMediaAssetId": 101,
  "acceptMoveTerms": true,
  "termsVersion": "valor-entregado-por-release",
  "termsContentHash": "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
}
```

- `firstNames`, `lastNames`: 2..80.
- `documentType`: 2..20, regex `^[A-Za-z0-9_-]+$`.
- `documentNumber`: 4..40.
- `countryCode`: exactamente 2; servicio solo admite `CO|CL`.
- `city`: 2..80.
- `email?`: email, máximo 254; `phone?`: teléfono, máximo 30. Al menos uno debe enviarse y coincidir normalizado con la cuenta Client.
- `birthDate`: mayoría de edad cumplida, mínimo 18.
- `selfieMediaAssetId>0`.
- `acceptMoveTerms=true`.
- `termsVersion`: requerido, máximo 40.
- `termsContentHash`: SHA-256 hexadecimal de exactamente 64 caracteres.

### `MoveLicenseOnboardingRequest`

```json
{
  "number": "LIC-DEMO-0001",
  "class": "B1",
  "expiresAt": "2030-12-31T23:59:59Z",
  "frontMediaAssetId": 102,
  "backMediaAssetId": 103,
  "experienceYears": 5
}
```

- `number`: 4..40; `class`: 1..20.
- `expiresAt` debe ser futuro.
- `frontMediaAssetId>0`; `backMediaAssetId?`.
- `experienceYears?`: 0..80.
- CO exige reverso; CL no.

### `MoveVehicleDocumentInputV2`

```json
{
  "type": 1,
  "mediaAssetId": 104,
  "expiresAt": null
}
```

`type` 1..4; `mediaAssetId>0`; `expiresAt?`.

### `MoveVehiclePhotoInput`

```json
{
  "type": 1,
  "mediaAssetId": 108
}
```

`type` 1..5; `mediaAssetId>0`.

### `MoveVehicleOnboardingRequest`

```json
{
  "physicalType": 1,
  "serviceCategory": 1,
  "brand": "Marca demo",
  "model": "Modelo demo",
  "year": 2024,
  "color": "Blanco",
  "plate": "ABC123",
  "passengerCapacity": 4,
  "vin": "1HGCM82633A000001",
  "documents": [
    { "type": 1, "mediaAssetId": 104, "expiresAt": null },
    { "type": 2, "mediaAssetId": 105, "expiresAt": "2027-12-31T23:59:59Z" }
  ],
  "photos": [
    { "type": 1, "mediaAssetId": 108 },
    { "type": 2, "mediaAssetId": 109 },
    { "type": 3, "mediaAssetId": 110 },
    { "type": 4, "mediaAssetId": 111 },
    { "type": 5, "mediaAssetId": 112 }
  ]
}
```

- `physicalType` 1..5; `serviceCategory` 1..4.
- `brand`, `model`: requeridos, máximo 60; `color`: requerido, máximo 40.
- `year`: 1950..2100 y no mayor al año UTC actual + 1.
- `plate`: requerida, máximo 16; `passengerCapacity`: 1..20.
- `vin?`: exactamente 17, regex `^[A-HJ-NPR-Za-hj-npr-z0-9]{17}$`.
- `documents`: 2..4 por atributo; el backend exige los requeridos del país. No duplicar tipo.
- `photos`: exactamente cinco tipos diferentes con cinco assets diferentes.

### `MoveOperationsOnboardingRequest`

```json
{
  "payoutMethod": 1,
  "externalProviderToken": null,
  "bank": null,
  "accountType": null,
  "accountLast4": null,
  "emergencyName": "Contacto Demo",
  "emergencyPhone": "+573000000001",
  "emergencyRelationship": "Familiar",
  "languages": ["es"],
  "accessible": false,
  "pets": true,
  "airConditioning": true,
  "luggage": true,
  "isAvailableNow": false,
  "scheduleJson": "{\"timezone\":\"America/Bogota\",\"windows\":[]}",
  "radiusKm": 20.0,
  "maxDistanceKm": 100.0,
  "services": [1, 7]
}
```

- `payoutMethod`: `1|2`, default `1`.
- `externalProviderToken?` máximo 1000; `bank?` 2..80; `accountType?` 2..40; `accountLast4?` exactamente cuatro dígitos.
- contacto de emergencia completo obligatorio: nombre 2..120, teléfono regex `^\+?[1-9]\d{7,14}$`, relación 2..60.
- `languages`: máximo 10; servicio exige cada valor no vacío, 1..30, sin coma.
- `scheduleJson?`: **string que contiene un objeto JSON**, máximo 2000, profundidad máxima 8; no hay esquema de horario adicional implementado.
- `radiusKm?`: 0.1..200; `maxDistanceKm?`: 0.1..1000; radio no puede superar distancia máxima.
- `services`: 1..11 elementos y al menos un valor válido; eliminar duplicados en UI.
- Wallet (`1`) es el default. Payout externo (`2`) requiere token de un proveedor externo, banco, tipo y last4. El backend no expone aquí el proveedor/tokenizador: no pedir ni enviar número de cuenta completo y no implementar captura bancaria directa. Ocultar payout externo hasta que exista integración real de proveedor.
- El usuario necesita una Wallet activa backend; si falta, status devuelve `active_wallet`.

### Respuesta `MoveDriverOnboardingStatusDto`

```json
{
  "driverId": 25,
  "status": "Draft",
  "percentage": 67,
  "canSubmit": false,
  "canGoOnline": false,
  "maskedDocument": "***0001",
  "maskedLicense": "***0001",
  "maskedPlate": "AB***3",
  "vinLast4": "0001",
  "payoutLast4": null,
  "currentLicenseId": 8,
  "vehicleId": 15,
  "profileRowVersion": "AAAAAAAAAAE=",
  "identityRowVersion": "AAAAAAAAAAI=",
  "licenseRowVersion": "AAAAAAAAAAM=",
  "vehicleRowVersion": "AAAAAAAAAAQ=",
  "vehicleDocuments": [
    {
      "id": 31,
      "type": 1,
      "status": 1,
      "expiresAt": null,
      "rowVersion": "AAAAAAAAAAU="
    }
  ],
  "stages": [
    {
      "stage": 1,
      "name": "Identity",
      "complete": true,
      "percentage": 100,
      "missing": [],
      "reasons": []
    }
  ],
  "missing": ["active_wallet"],
  "reasons": []
}
```

`MoveOnboardingStageDto`: `stage`, `name`, `complete`, `percentage`, `missing[]`, `reasons[]`.  
`MoveOnboardingReviewItemDto`: `id`, `type`, `status`, `expiresAt?`, `rowVersion?`.

## 5. Enums y estados exactos

De `MoveOnboardingEnums.cs`:

- `MoveIdentityVerificationStatus`: `1 Pending`, `2 Verified`, `3 Rejected`.
- `MoveLicenseStatus`: `1 Pending`, `2 Approved`, `3 Rejected`, `4 Expired`.
- `MoveOnboardingStage`: `1 Identity`, `2 License`, `3 VehicleAndOperations`.
- `MovePayoutMethod`: `1 Wallet`, `2 ExternalPayout`.
- `MovePhysicalVehicleType`: `1 Car`, `2 Motorcycle`, `3 Suv`, `4 Van`, `5 Pickup`.
- `MoveVehiclePhotoType`: `1 Front`, `2 Rear`, `3 Left`, `4 Right`, `5 Interior`.
- `MoveServiceType`: `1 Economy`, `2 Taxi`, `3 Executive`, `4 SUV`, `5 Van`, `6 Tourism`, `7 Airport`, `8 Corporate`, `9 Courier`, `10 Delivery`, `11 Errands`.
- `MoveVehicleDocumentType`: `1 Registration`, `2 Insurance`, `3 TechnicalInspection`, `4 TaxiAuthorization`.
- `MoveReviewSubjectType`: `1 Identity`, `2 License`, `3 VehicleDocument`, `4 Vehicle`, `5 Profile`, `6 KidsEligibility`.

Estados relacionados de `MoveEnums.cs`:

- `MoveDriverStatus`: `0 Draft`, `1 PendingReview`, `2 Approved`, `3 Rejected`, `4 Suspended`, `5 Blocked`. El status v2 lo serializa como **nombre string**.
- `MoveDocumentStatus`: `1 Pending`, `2 Approved`, `3 Rejected`, `4 Expired`.
- `MoveVehicleStatus`: `1 PendingReview`, `2 Active`, `3 Rejected`, `4 Inactive`.
- `MoveVehicleCategory` usado por `serviceCategory`: `1 Economy`, `2 Standard`, `3 Premium`, `4 Corporate`. No confundirlo con `MoveServiceType`.

Máquina móvil:

`sin perfil -> Draft -> PendingReview -> Approved`; corrección/rechazo deja `Rejected` y permite editar/re-enviar; administración puede llevar `Approved -> Suspended -> Approved`, y existe `Blocked`. Cualquier edición de identidad/licencia/vehículo/operaciones reinicia a `Draft` salvo perfil bloqueado y fuerza offline.

## 6. Términos vigentes y reglas CO/CL

El backend toma términos desde `MoveOnboarding:Countries:{CO|CL}`:

- `CurrentTermsVersion`
- `CurrentTermsContentHash` (SHA-256 hex de 64)

**No existe endpoint público de catálogo/términos en el código actual.** Los valores del `appsettings.json` versionado están vacíos y deben suministrarse como configuración/secretos del entorno desplegado. Por tanto:

1. no inventar `GET /terms`;
2. la app debe recibir texto legal, versión y hash mediante configuración remota confiable o artefacto de release coordinado con la configuración backend;
3. enviar exactamente versión/hash que corresponden al país y al contenido mostrado;
4. ante `409` “versión cambió”, invalidar aceptación, recargar la configuración remota/release disponible y exigir nueva aceptación;
5. si no hay valores confiables, bloquear identidad con mensaje de configuración, no fabricar hash ni hashear un texto diferente.

Reglas actuales:

- solo `CO` y `CL`;
- edad mínima 18 años cumplidos;
- registro y seguro obligatorios en ambos;
- CO exige reverso de licencia; CL no;
- inspección técnica desde antigüedad `>=6` años en CO y `>=1` año en CL, calculada con año UTC actual menos año del vehículo;
- `Insurance`, `TechnicalInspection` y `TaxiAuthorization` requieren expiración futura; `Registration` no;
- seleccionar servicio `Taxi=2` hace obligatorio `TaxiAuthorization=4`;
- el PUT de vehículo se valida antes de guardar operations y calcula inicialmente requeridos sin servicios; después `status` aplica TaxiAuthorization según los servicios seleccionados. La UI debe anticiparlo y adjuntarlo si Taxi está seleccionado para evitar un status incompleto;
- cinco fotos exactas: Front, Rear, Left, Right, Interior;
- contacto de emergencia completo obligatorio;
- al menos un servicio válido y Wallet activa.

## 7. Flujo Flutter a implementar

1. Prerregistro/registro y login como **Client**; nunca “crear Driver”.
2. Verificar email o teléfono; para teléfono usar Firebase Phone Auth y sync.
3. `GET status`; si no hay perfil muestra alta.
4. Resolver términos CO/CL desde configuración de release/remota coordinada.
5. Capturar/subir media privada, conservando cada `mediaAssetId`.
6. Guardar identidad y aceptación.
7. Guardar licencia vigente.
8. Configurar vehículo, documentos exigidos y cinco fotos.
9. Configurar operations: Wallet por defecto, emergencia, servicios, capacidades y límites.
10. Volver a `GET status`; renderizar progreso, `missing` y `reasons`.
11. Habilitar submit solo si `canSubmit=true`; `POST submit` con clave propia.
12. En `PendingReview`, bloquear edición accidental o advertir que editar reinicia a Draft.
13. En `Rejected`, mostrar motivos/campos, permitir corrección y reenviar.
14. En `Approved`, solo habilitar online cuando `canGoOnline=true`; pedir ubicación justo al activar online.
15. En `Suspended|Blocked` forzar offline y mostrar razón segura sin ofrecer bypass.

No hay biometría/reconocimiento facial automático. La selfie se captura para revisión humana; no mostrar porcentaje de match ni “identidad verificada automáticamente”.

## 8. Arquitectura Flutter solicitada

Implementar, adaptando nombres al proyecto:

- Modelos: `ApiEnvelope<T>`, `ProblemDetailsModel`, cinco requests v2, `MoveOnboardingStatus`, `MoveOnboardingStage`, `MoveReviewItem`, todos los enums con fallback desconocido.
- Repositorios:
  - `ClientAuthRepository`;
  - `MoveOnboardingRepository` para status/PUT/submit;
  - `MoveMediaRepository` para multipart, metadata, descarga privada y delete de borradores no referenciados;
  - `MoveDriverRepository` para `me`, online y ubicación;
  - `TermsConfigurationRepository` remoto/release, explícitamente no backend REST.
- Providers/BLoC/Riverpod/equivalente:
  - sesión Client;
  - coordinador de wizard y borrador;
  - cola de uploads con progreso/cancelación/retry;
  - status/revisión;
  - permisos y conectividad.
- Interceptores:
  - Bearer;
  - refresh single-flight;
  - `Idempotency-Key` solo en mutaciones MOVE v2;
  - redacción de logs.
- Persistencia segura:
  - tokens en secure storage;
  - claves de idempotencia y IDs de assets en almacenamiento local cifrado;
  - PII de formularios solo el mínimo y borrarla al completar/logout;
  - jamás persistir imágenes/documentos en caché pública.

Pantallas/widgets:

- acceso/registro Client y verificación de contacto;
- resumen de elegibilidad y país;
- términos con versión visible y checkbox no premarcado;
- captura selfie con guía, sin biometría;
- identidad;
- licencia frente/reverso condicional;
- vehículo;
- checklist de documentos dinámico CO/CL/Taxi;
- captura de las cinco vistas del vehículo;
- operations, Wallet, contacto de emergencia, idiomas, capacidades, agenda/radio/distancia y servicios;
- resumen, status/progreso, faltantes y razones;
- envío/espera de revisión;
- correcciones;
- aprobado/online, suspendido y bloqueado.

Navegación/deep links:

- rutas internas sugeridas: `/move/driver/onboarding`, `/identity`, `/license`, `/vehicle`, `/operations`, `/review`, `/status`;
- notificaciones backend usan eventos como `move.driver.submitted`, `move.driver.approve`, `move.driver.reject`, `move.driver.request-correction`, `move.driver.suspend`, `move.driver.reactivate`, `move.driver.requirement.expired`;
- al abrir deep link/notificación, ignorar IDs como autoridad y volver a consultar `status`/`me` antes de mostrar contenido;
- registrar FCM mediante APIs generales existentes del proyecto, sin inventar endpoint MOVE.

## 9. Validaciones, permisos, offline y UX

- Replicar DataAnnotations para feedback inmediato, pero backend manda.
- Cámara: solicitar al capturar; galería: solo al elegir; ubicación: al activar online/compartir; push: al activar avisos. Manejar denied/permanentlyDenied y enlace a Settings.
- No se requiere permiso de ubicación para completar identidad/documentos.
- Sanitizar nombre de archivo y eliminar EXIF/GPS si la librería lo permite.
- Upload secuencial o con concurrencia baja, progreso por archivo, compresión controlada, checksum local opcional solo para deduplicación; no confundirlo con hash de términos.
- Offline: permitir borrador local cifrado, pero no marcar etapa guardada hasta respuesta exitosa. Mostrar `localPending/serverSaved`.
- Reintentar uploads solo si no hubo respuesta; una respuesta exitosa entrega `id` y no debe duplicarse. Las mutaciones usan la misma clave hasta resultado definitivo.
- Considerar definitivas `2xx`, `400`, `401` tras refresh fallido, `403`, `404`, `409` y `429` después de mostrar su política; no mantener spinner infinito.
- Al volver del background, refrescar status y validar que archivos temporales siguen disponibles.
- Mostrar `missing` como claves traducidas y `reasons` escapadas como texto; nunca ejecutar HTML.

## 10. Seguridad y privacidad obligatorias

- Documento/licencia/placa solo enmascarados al resumir; no guardar ni loguear números completos.
- Backend protege identificadores con HMAC-SHA256 y payout/emergencia con AES-GCM; frontend no debe intentar reproducir esas claves ni enviar secretos backend.
- Nunca solicitar contraseña, OTP, cuenta bancaria completa, claves, CVV ni PIN dentro del onboarding.
- Payout externo: solo token de proveedor + banco/tipo + last4; depende de proveedor no expuesto. Wallet es default.
- Toda media debe pertenecer al `User` Client autenticado. No aceptar IDs pegados, URLs externas ni media de otro owner.
- Vista/descarga mediante endpoint autenticado; no asumir que `publicUrl` es seguro para documentos.
- No reconocimiento facial automático real, no SMS propio, no antivirus/cuarentena.
- No capturar PII/media en Sentry, Crashlytics, analytics, Redux/Riverpod observers o logs HTTP. Redactar `Authorization`, refresh, Firebase token, body de identidad, números, provider token y media.
- TLS obligatorio en producción; bloquear cleartext.

## 11. Pruebas

Unitarias:

- serialización exacta de DTO/enums/fechas;
- validaciones de todos los rangos/regex;
- reglas CO/CL, antigüedad, TaxiAuthorization y cinco fotos;
- parser `Response<T>`/Problem Details;
- estado e idempotency key conservada en reintento;
- redacción de datos sensibles.

Widgets/BLoC:

- progreso/missing/reasons;
- contacto no verificado;
- términos ausentes/cambiados;
- permisos denegados;
- upload parcial/offline/reanudación;
- `Draft`, `PendingReview`, `Rejected`, `Approved`, `Suspended`, `Blocked`;
- `canSubmit` y `canGoOnline`.

Integración/contract:

- login Client contraseña y Firebase;
- media multipart privada;
- flujo completo CO y CL;
- Taxi con autorización;
- corrección y reenvío;
- `409` por clave con payload distinto y por términos;
- `400/401/403/404/409/429/5xx`;
- expiry de licencia/documento fuerza offline;
- deep link refresca servidor.

No usar datos reales en fixtures, screenshots ni ejemplos.

## 12. Limitaciones de release que la UI debe declarar

- Migración `EnterpriseMoveDriverOnboardingV2` y secretos/configuración aún no están desplegados por esta entrega.
- Deben configurarse claves backend HMAC/AES de 32 bytes base64 y términos CO/CL antes de habilitar el feature flag. No incluirlas en Flutter.
- No hay catálogo público de términos; requiere coordinación remota/release.
- No hay SMS propio: Firebase Phone Auth.
- No hay biometría automática.
- No hay antivirus/cuarentena de media.
- Upload real no acepta PDF y `register` externo no sirve para assets MOVE v2.
- Payout externo depende de proveedor/tokenizador no expuesto; dejar Wallet.
- El status no entrega todo el borrador en claro. No prometer restauración completa en otro dispositivo; solo status, máscaras, IDs/resumen disponible.

## 13. Checklist de aceptación

- [ ] Se implementó frontend Flutter, sin cambios backend.
- [ ] Actor Client y JWT; no existe rol/login Driver ni `/master/login`.
- [ ] Login Client/password o Firebase; OTP/password fuera del onboarding.
- [ ] Contacto verificado antes de submit.
- [ ] Todos los endpoints v2 y aliases legacy están modelados sin mezclarlos.
- [ ] `Authorization` e `Idempotency-Key` header correctos.
- [ ] Clave estable hasta respuesta definitiva.
- [ ] DTOs, enums, nombres, rangos y estados coinciden exactamente.
- [ ] Términos por config remota/release; no endpoint inventado.
- [ ] Reglas CO/CL, edad, vigencias, Taxi y cinco fotos.
- [ ] Media `User` privada con IDs; no register externo/PDF ficticio.
- [ ] Wallet default y payout externo oculto sin proveedor.
- [ ] Progreso, missing y reasons visibles y accesibles.
- [ ] Correcciones/review/Approved/online funcionan con refresh server-side.
- [ ] Cámara/galería/ubicación/push y offline tienen UX completa.
- [ ] PII/tokens/media nunca aparecen en logs o analytics.
- [ ] Pruebas cubren `400/401/403/404/409/429`, timeout y 5xx.
- [ ] Ninguna limitación real se presenta como disponible.

## Fuentes contractuales auditadas

- `WebApi/Controllers/MoveDriverOnboardingController.cs`
- `WebApi/Controllers/MoveDriversController.cs`
- `WebApi/Controllers/MediaController.cs`
- `WebApi/Controllers/AuthController.cs`
- `DTO/MoveOnboardingDtos.cs`
- `DTO/MoveDtos.cs`
- `DTO/MediaDtos.cs`
- `DTO/AuthDtos.cs`
- `Models/Enums/MoveOnboardingEnums.cs`
- `Models/Enums/MoveEnums.cs`
- `Models/Enums/MediaEnums.cs`
- `Models/MoveOnboardingSettings.cs`
- `Business/Services/MoveDriverOnboardingService.cs`
- `Business/Services/MoveDriverService.cs`
- `Business/Services/MediaService.cs`
- `WebApi/appsettings.json`

