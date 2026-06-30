# CIERVO CLUB — Flutter Mobile MVP Prompt

Documento operativo para implementar y validar la app móvil Flutter contra el backend de producción. Usar **íntegramente** como checklist de agentes y desarrolladores.

**Backend prod:** `https://ciervo-backend-613568140358.southamerica-east1.run.app`  
**Referencias:** `docs/MVP-API-FINAL-BACKEND.md`, `docs/CIERVO-KIDS-MOBILE-MASTER-IMPLEMENTATION.md`, `docs/PAYMENTS-API-CONTRACT.md`

---

## 1. Bootstrap y permisos

### 1.1 Orden de arranque

1. `main.dart` → `configureDependencies()` → `CiervoApp`
2. `CiervoPushService.initialize()` — canales locales + Firebase (si `flutterfire configure` está hecho)
3. Tras **login/autenticación**, una sola vez por sesión: `AppPermissionService.requestRequiredEntryPermissions()`

### 1.2 Permisos al inicio (post-auth)

| Permiso | Cuándo | Implementación |
|---------|--------|----------------|
| **Ubicación** | Tras autenticación adulto/kid | `LocationService` vía `AppPermissionService` |
| **Notificaciones** | Tras autenticación | `Permission.notification` vía `AppPermissionService` |
| **Cámara** | **On-demand** antes de escanear QR, foto perfil, chat imagen | `AppPermissionService.requestCameraIfNeeded()` |

**Reglas:**

- No pedir cámara en cold start.
- No duplicar diálogo de notificaciones: FCM **no** llama `requestPermission`; lo hace `AppPermissionService` y luego `CiervoPushService.syncTokenIfAuthenticated()`.
- En logout: `CiervoPushService.unregisterAllTokens()` antes de limpiar sesión.

**Archivos:** `lib/app.dart`, `lib/core/permissions/app_permission_service.dart`, `lib/core/notifications/ciervo_push_service.dart`, `lib/features/auth/data/repositories/auth_repository_impl.dart`

---

## 2. QR Wallet y Mercado Pago

### 2.1 QR Wallet (pagar/recibir)

- Feature: `lib/features/qr_wallet/`
- Endpoints: contrato wallet/QR en MVP (`/api/wallet/...`, QR dinámico)
- Flujo: generar QR → escaneo comercio → confirmación → **recibo premium** (`CiervoPaymentReceipt`)

### 2.2 Recarga Mercado Pago

- `RechargePage` → intent MP → browser/app MP → volver → **poll** `GET /api/wallet/recharge-intents/{id}`
- Botón manual: "Ya pagué, consultar estado"
- Al aprobar: refresh wallet + recibo con `CIERVO-XXXXXXXX` copiable

**Archivos:** `lib/features/wallet/`, `lib/shared/widgets/ciervo_payment_receipt.dart`

---

## 3. Ciervo Kids + aprobación tutor

### 3.1 Modos

| Modo | Auth | Shell |
|------|------|-------|
| Tutor (adulto) | JWT adulto | `KidsPage`, gestión menores |
| Menor | JWT kid | `KidShellPage` (Inicio, Comercios, Familia, Yo) |

### 3.2 Pay-for-me (kid → tutor)

**Kid:**

```http
POST /api/kids/me/pay-for-me/request
GET  /api/kids/me/pay-for-me/requests
```

**Tutor:**

```http
GET  /api/guardians/pay-for-me/requests
POST /api/guardians/pay-for-me/requests/{id}/approve
POST /api/guardians/pay-for-me/requests/{id}/reject
```

**UI kid:** formulario desde comercio (monto + remitente/descripción, ubicación opcional) → "Solicitud enviada a tu familia" → lista con estados.

**UI tutor:** bandeja en Ciervo Kids → aprobar/rechazar → refresh.

**Estados UI:**

| Backend | Etiqueta |
|---------|----------|
| PendingGuardianApproval / Pending | Esperando aprobación |
| Approved | Aprobado |
| Rejected | Rechazado |
| Expired | Expirado |
| Cancelled | Cancelado |

**Archivos:** `lib/features/kid_me/`, `lib/features/kid_pay_for_me/`, `lib/features/kids/presentation/pages/guardian_pay_for_me_page.dart`

---

## 4. NFC

### 4.1 Adulto

- Setup: `nfc_pay_setup_page.dart` → sesión backend → `nfc_pay_session_page.dart`
- QR fallback en iOS si terminal no lee NFC
- Sin HCE en MVP

### 4.2 Kids

- Endpoint esperado: `POST /api/kids/me/nfc/sessions`, `GET /api/kids/me/nfc/sessions/{id}`
- Si saldo insuficiente → redirigir a pay-for-me
- Mostrar QR de sesión al comercio (mismo patrón que adulto iOS)

**Archivos:** `lib/features/kid_nfc/`, `lib/features/wallet/presentation/pages/nfc_pay_session_page.dart` (referencia adulto)

---

## 5. Vakupli (planes sociales)

Estilo: superficies dark premium, oro activo, acentos esmeralda. **Sin mocks en producción.**

Endpoints objetivo:

```http
GET  /api/vakupli/plans
POST /api/vakupli/plans
POST /api/vakupli/plans/{id}/invites
GET  /api/vakupli/plans/{id}/messages
POST /api/vakupli/plans/{id}/messages
POST /api/vakupli/plans/{id}/pay
```

Flujos:

1. **Crear** plan (título, monto, split equitativo/custom)
2. **Link/invitar** amigos (búsqueda usuarios existente)
3. **Chat temporal** por plan
4. **Pagar** split desde wallet

Si backend responde 404: empty state honesto, no datos hardcodeados.

**Archivos:** `lib/features/vakupli/data/vakupli_repository.dart`, `lib/features/vakupli/presentation/pages/vakupli_page.dart`

---

## 6. Notificaciones

- FCM + locales: `CiervoPushService`
- Badges: `NotificationBadgesCubit`
- Deep links: `notification_deep_link.dart` (wallet, kids, vakupli, chat, etc.)
- Registrar token tras permisos + auth; desregistrar en logout
- Prod: ejecutar `flutterfire configure` (reemplazar placeholders en `firebase_options.dart`)

---

## 7. Servicios core (DI)

Registrar en `lib/core/di/service_locator.dart`:

| Servicio | Rol |
|----------|-----|
| `NetworkClient` | Dio + refresh token |
| `SessionManager` | JWT secure storage |
| `AppPermissionService` | Permisos dispositivo |
| `LocationService` | GPS + permisos |
| `CiervoPushService` | FCM |
| `KidMeRepository` | API kid autenticado |
| `KidsRepository` | API tutor |
| `WalletRepository` | Wallet, NFC, MP |
| `VakupliRepository` | Planes sociales |

---

## 8. Errores y envelope API

Envelope estándar:

```json
{ "status": true|false, "value": ..., "msg": "..." }
```

- Desenvolver con `unwrapApiResponse` / `unwrapApiMap` / `unwrapApiList`
- Mapear a `AppException` → `UserErrorMessage.from()` para UI
- Dio 401 → refresh; fallo → logout
- Mostrar `msg` del backend cuando exista; fallback amigable en español

**Archivos:** `lib/core/network/api_response_unwrapper.dart`, `lib/core/errors/`

---

## 9. Recibo premium e ID global

- Tras pagos/reservas/recargas/NFC/Kids: `showCiervoPaymentReceipt` o `ActionConfirmationPage`
- Modo día/noche automático
- `CiervoUserIdOverlay` en `app.dart` — badge copiable `CIERVO-XXXXXXXX`
- Resolver ID: `GET /api/users/me` (`ciervoUserCode`) o `GET /api/wallet/me/ciervo-id`

---

## 10. Smoke mobile (manual + automatizado)

### 10.1 Script

```powershell
.\scripts\mobile_smoke_flutter.ps1
```

Ejecuta: `flutter analyze`, `flutter test`, checklist impreso.

### 10.2 Checklist manual (release candidate)

- [ ] Login adulto → permisos ubicación + notificaciones (una vez)
- [ ] Perfil muestra CIERVO ID copiable
- [ ] Wallet: saldo, recarga MP, poll estado, recibo
- [ ] **Envíos seguros:** crear → aceptar → hold → PIN dual → sync → execute-payment → recibo
- [ ] Push `secure_*` abre detalle por `publicId`
- [ ] QR wallet generar/validar
- [ ] NFC adulto: crear sesión, QR fallback
- [ ] Kids tutor: crear menor, comercios, límites
- [ ] Kid login: comercios, pay-for-me, lista solicitudes
- [ ] Tutor: aprobar/rechazar pay-for-me
- [ ] Kid NFC o pay-for-me si sin saldo
- [ ] Vakupli: listar/crear (o empty si API pendiente)
- [ ] Push: token registrado; logout limpia token
- [ ] Cámara solo al escanear/foto
- [ ] Modo día/noche en recibo y pantallas principales

### 10.3 Tests unitarios mínimos

- `test/core/network/api_response_unwrapper_test.dart`
- Tests existentes chat/experience deben seguir en verde

---

## 11. Convenciones de código

- Feature-first: `lib/features/{feature}/data|domain|presentation`
- Result pattern: `Success` / `Failure`
- Sin datos mock en flujos productivos
- Español en copy UI; acentos correctos UTF-8
- Commits atómicos; no incluir `.dart_tool/` ni `build/`

---

## 12. Orden de implementación sugerido (agente)

1. Permisos + FCM + logout
2. Kids pay-for-me / NFC Kids
3. **Envíos seguros** → `MOBILE-SECURE-SHIPMENT-IMPLEMENTATION.md` (backend docs)
4. Vakupli API real (graceful 404)
5. Smoke + analyze + test
6. Recibo/ID en cualquier flujo de pago nuevo

**Docs envío seguro (backend SSOT):**
- `Back/Ciervo-backend/docs/MOBILE-SECURE-SHIPMENT-IMPLEMENTATION.md`
- `Back/Ciervo-backend/docs/SECURE-SHIPMENTS-API-CONTRACT.md`
- `Back/Ciervo-backend/docs/NOTIFICATIONS-CONTRACT.md`
