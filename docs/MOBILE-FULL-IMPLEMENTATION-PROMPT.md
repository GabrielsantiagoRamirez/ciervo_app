# Prompt único Mobile Flutter — Membresías, Imágenes, Wallet/Loyalty, Chat

**Copiar este archivo al repo Flutter** (`docs/MOBILE-FULL-IMPLEMENTATION-PROMPT.md`).  
Sustituye/amplía `docs/MOBILE-PRODUCTION-BACKEND-CLOSURE.md` para los temas de membresía, imágenes y loyalty.

**Backend prod:** `https://ciervo-backend-613568140358.southamerica-east1.run.app`  
**Revisión:** `ciervo-backend-00133-bmc`  
**Fecha auditoría:** 2026-07-01

---

## 0. Resumen de auditoría (estado actual Flutter)

| # | Tema | Estado | Archivos actuales |
|---|------|--------|-------------------|
| 1 | Refresh `/memberships/me` post-pago | **Parcial** — solo en `MembershipPage`, no global | `membership_page.dart` L44-48, L131-136, L173-179 |
| 2 | Planes desde API | **OK** | `memberships_repository.dart`, `membership_page.dart` |
| 3 | Gating `private_chat` | **No** | `chat_inbox_page.dart` L83-105 |
| 4 | Gating `favorites.max` | **No** | `place_detail_page.dart` L1109-1115 |
| 5 | Gating `kids.profiles.max` | **No** | `kids_cubit.dart` L61-68 |
| 6 | Upgrade `PLAN_LIMIT_REACHED` | **No** (código muerto en `user_error_message.dart`) | Solo NFC en `nfc_navigation.dart` |
| 7 | Foto Firebase + `/photo/register` | **No** — usa multipart `/photo` | `profile_remote_datasource.dart` L107-112 |
| 8 | Chat imagen `mediaUrl` | **Parcial** — `attachmentMediaId`, no `mediaUrl` | `chat_dtos.dart` L33-35 |
| 9 | Wallet loyalty summary | **Parcial** — usa `/rewards/me/points`, no `/wallet/loyalty/summary` | `qr_wallet_repository.dart`, `cashback_page.dart` |
| 10 | `process-purchase` post-pago comercio | **No** | Sin referencias en `lib/` |

**Objetivo de este prompt:** cerrar todos los ítems anteriores sin inventar endpoints ni campos que el backend no expone.

---

## 1. Arquitectura obligatoria — `MembershipCubit` global

### Problema
Hoy el plan solo se refresca dentro de `MembershipPage`. El resto de la app no sabe si el usuario es Free, Silver, Gold, etc.

### Implementar

```
lib/features/memberships/
  domain/membership_state.dart
  data/memberships_repository.dart      ← ampliar
  presentation/cubit/membership_cubit.dart   ← NUEVO
```

**Cuándo cargar** (siempre los tres en paralelo o en cadena):

```
GET /api/memberships/me
GET /api/memberships/benefits
GET /api/memberships/me/limits
```

Opcional: `GET /api/memberships/me/features` si prefieren lista plana de features habilitadas.

**Disparadores de refresh:**

| Evento | Acción |
|--------|--------|
| Login exitoso (`app.dart` / auth bloc) | `membershipCubit.load()` |
| Return Mercado Pago membresía | `membershipCubit.load()` |
| `POST /memberships/subscribe` gratis OK | `membershipCubit.load()` |
| Push `membership.*` o SSE | `membershipCubit.load()` |
| Logout | `membershipCubit.clear()` |

**Proveer en `MaterialApp`:**

```dart
BlocProvider<MembershipCubit>(create: (_) => sl<MembershipCubit>()..load(), ...)
```

**API del cubit (mínimo):**

```dart
class MembershipState {
  MembershipMe? me;
  MembershipBenefits? benefits;
  Map<String, PlanLimit>? limits;  // de /me/limits
  bool isLoading;
  String? error;
}

bool isFeatureEnabled(String key) =>
  limits?[key]?.isEnabled == true;

int? limitValue(String key) => limits?[key]?.limitValue;

bool canUsePrivateChat() => isFeatureEnabled('private_chat');

bool canAddFavorite(int currentCount) {
  final max = limitValue('favorites.max');
  return max == null || currentCount < max;
}

bool canAddKidProfile(int currentCount) {
  final max = limitValue('kids.profiles.max');
  return max == null || currentCount < max;
}
```

**Tras pago membresía** en `membership_page.dart`: además de `setState(_load)`, llamar `context.read<MembershipCubit>().load()` y `Navigator.pop` si venía de upgrade dialog.

---

## 2. Gating de UI por membresía

### 2.1 Chat privado (`private_chat`)

**Archivo:** `lib/features/chat/presentation/pages/chat_inbox_page.dart`

**Hoy:** FAB "Nuevo" / "Buscar personas" siempre visible (L83-105).

**Cambiar:**

```dart
final canPrivateChat = context.watch<MembershipCubit>().state.canUsePrivateChat();
// Si false:
// - Ocultar FAB o mostrarlo deshabilitado con tooltip
// - Al tap: showUpgradeDialog(context, feature: 'Chat privado')
// - No navegar a UserSearchPage
```

Si `private_chat.isEnabled == false` en `/me/limits`, el usuario **no debe** poder iniciar chat directo con desconocidos.

### 2.2 Favoritos (`favorites.max`)

**Archivos:** `place_detail_page.dart` (`_FavoriteButton`), `favorites_repository_impl.dart`

**Antes de** `FavoritesRepository.add()`:

1. Obtener conteo actual: `GET /api/users/me/favorites` (o contar lista en caché).
2. `membershipCubit.canAddFavorite(currentCount)` → si false, mostrar upgrade dialog, **no** llamar POST.
3. Si POST falla con `PLAN_LIMIT_REACHED` en body/msg → mismo upgrade dialog (defensa en profundidad).

### 2.3 Perfiles Kids (`kids.profiles.max`)

**Archivos:** `kids_cubit.dart` L61-68, pantalla crear hijo

**Antes de** `createChild()`:

1. Contar hijos activos del tutor.
2. `membershipCubit.canAddKidProfile(count)` → si false, upgrade dialog.
3. Backend puede no bloquear 100% — la app es la UX principal.

### 2.4 Diálogo upgrade genérico

**Archivo:** `lib/core/errors/user_error_message.dart` (arreglar código muerto L60-67)

**Crear:** `lib/core/widgets/membership_upgrade_dialog.dart`

```dart
void showMembershipUpgradeDialog(BuildContext context, {
  required String featureLabel,
  String? requiredPlan,
}) {
  // Título: "Mejora tu plan CIERVO"
  // Cuerpo: "Tu plan actual no incluye $featureLabel."
  // CTA primario: "Ver planes" → MembershipPage
  // CTA secundario: Cerrar
}
```

**Interceptar errores API** en el cliente HTTP o en `UserErrorMessage`:

```
Si msg contiene "PLAN_LIMIT_REACHED" o code == PLAN_LIMIT_REACHED:
  parsear feature=, requiredPlan= del mensaje
  mostrar showMembershipUpgradeDialog(...)
  NO mostrar SnackBar genérico
```

Reordenar `user_error_message.dart`: evaluar `PLAN_LIMIT_REACHED` **antes** del handler genérico 403 (L31-37).

Reutilizar patrón de `nfc_navigation.dart` L33-58 pero **global**, no solo NFC.

### 2.5 Humanizar límites (no mostrar keys)

Ya existe `DisplayLabels.membershipLimitLabel` — extender:

| Key | Texto usuario |
|-----|---------------|
| `private_chat` | "Chat privado con cualquier usuario CIERVO" |
| `favorites.max` = 20 | "Hasta 20 comercios favoritos" |
| `kids.profiles.max` = 3 | "Hasta 3 perfiles Kids" |
| `points.multiplier` = 2 | "Ganas el doble de puntos" |

**Nunca** mostrar: `cashbackPercent`, `kidsLimit`, `prioritySupport` como keys crudas.

---

## 3. Pantalla membresía (ya OK — pequeños ajustes)

**Archivos:** `membership_page.dart`, `memberships_repository.dart`

Mantener:
- `GET /plans`, `/me`, `/benefits`, `/invoices`
- Checkout MP vía `POST /memberships/subscribe-intents`
- Plan gratis vía `POST /memberships/subscribe`

**Añadir:**
- Tras éxito: `context.read<MembershipCubit>().load()` (global)
- Mostrar beneficios desde `/benefits` usando `DisplayLabels`, no keys
- Badge plan actual en drawer/perfil desde `MembershipCubit.state.me.planName`

---

## 4. Imágenes — Firebase Storage + cache bust

**Contrato completo:** sección imágenes en backend `docs/MOBILE-IMAGES-LOYALTY-CLOSURE.md`

### 4.1 Foto de perfil

**Archivo a cambiar:** `profile_remote_datasource.dart` L107-112

**Dejar de usar** como flujo principal: `POST /api/users/me/photo` multipart.

**Nuevo flujo:**

```
1. image_picker → File
2. FirebaseStorage.ref('users/{uid}/profile_{timestamp}.jpg').putFile(...)
3. downloadUrl + fullPath (storagePath)
4. POST /api/users/me/photo/register
   { imageUrl, storagePath, mediaType: 'image/jpeg' }
5. Actualizar UserState local con respuesta (photoUrl, photoUpdatedAt)
6. GET /api/users/me para confirmar
```

**Widget imagen perfil:**

```dart
CachedNetworkImage(
  imageUrl: user.imageUrl ?? user.photoUrl!,
  cacheKey: '${user.storagePath ?? user.photoUrl}_${user.photoUpdatedAt?.millisecondsSinceEpoch}',
  placeholder: ...,
  errorWidget: ...,
)
```

Dependencia: `cached_network_image` (si no está, agregar).

### 4.2 Chat — imágenes

**Archivo:** `chat_dtos.dart` L33-35

**Ampliar parser** (orden de prioridad):

```dart
final mediaUrl = json['mediaUrl'] ?? json['imageUrl'] ?? json['attachmentUrl'];
final thumbnailUrl = json['thumbnailUrl'];
final storagePath = json['storagePath'];
final updatedAt = json['updatedAt'] ?? json['createdAt'];
```

**Enviar imagen:**

```
1. Subir a Firebase: chat/{conversationId}/{messageId}.jpg
2. POST mensaje:
   messageType: "Image"
   mediaUrl: downloadUrl
   storagePath, thumbnailUrl?, mediaType
```

**Render burbuja:**

- Si `mediaUrl` empieza con `http` → `CachedNetworkImage` con cacheKey versionado
- Si solo hay `attachmentMediaId` / `mediaId` → mantener `AuthenticatedMediaImage` (legacy)
- Loading + error state obligatorios

**Family chat:** misma barra de acciones que chat normal (`GET /api/chat/buttons`). Pay-for-me kid:

```
POST /api/payment-requests/pay-for-me
{ amount, currency, description, chatConversationId, idempotencyKey }
// Sin payerUserId — backend asigna tutor principal
```

### 4.3 Comercios, favoritos, ads

Usar campos normalizados del API:

- `imageUrl`, `thumbnailUrl`, `storagePath`, `logoUpdatedAt` / `updatedAt`
- Cache key: `url + updatedAt`
- No asumir URLs relativas

---

## 5. Wallet, puntos, cashback, loyalty

### 5.1 Endpoints a usar (migrar desde rewards legacy)

| Antes (parcial) | Contrato actual |
|-----------------|-----------------|
| Solo `/api/rewards/me/points` | `GET /api/wallet/loyalty/summary` |
| Historial disperso | `GET /api/wallet/history` |
| — | `GET /api/wallet/transactions` |
| Canje | `POST /api/wallet/points/redeem` |

**Archivos a actualizar:**

- `qr_wallet_repository.dart`
- `cashback_repository.dart`
- `cashback_page.dart`, `qr_wallet_page.dart`

### 5.2 UI wallet (`PremiumWalletDashboard`)

Mostrar desde `/wallet/loyalty/summary`:

- `pointsAvailable` / `cashbackAvailable`
- `level` (Bronce, Plata, Oro, Platino, Diamante)
- `nextLevelAt`, `progressPercent`
- Historial desde `/wallet/history`
- Estados vacíos diseñados, loading, retry, modo día/noche

**No mostrar** textos técnicos ni variables debug.

### 5.3 `process-purchase` tras pago en comercio

**Crear:** `lib/features/loyalty/data/loyalty_repository.dart`

Tras pago exitoso (PIN, NFC, QR, wallet transfer a comercio):

```
POST /api/loyalty/process-purchase
{
  "idempotencyKey": "pay-{paymentIntentId o walletTxId}",
  "amount": <monto pagado>,
  "currency": "COP",
  "businessId": <id comercio>,
  "paymentIntentId": <si existe>,
  "eventType": "wallet_payment"
}
```

Mostrar toast/banner si `pointsGenerated > 0` o `cashbackGenerated > 0`.  
Idempotente — seguro llamar una vez por transacción.

### 5.4 Monedas

Usar endpoints existentes (ver `MOBILE-PRODUCTION-BACKEND-CLOSURE.md`):

- `GET /api/exchange-rates/convert`
- `GET /api/catalogs/currencies`

Siempre mostrar moneda local (COP/CLP) + equivalencia opcional.

---

## 6. Chat familiar — botonera y pay-for-me (ya en backend)

Backend listo en `ciervo-backend-00133-bmc`:

- `GET /api/chat/buttons` en `FamilyConversationPage`
- `POST /api/payment-requests/pay-for-me` con JWT Kid + `chatConversationId`
- Mensaje `Payment` en el hilo

**Verificar en Flutter:**

- Kid puede llamar pay-for-me sin `payerUserId`
- Tras enviar, refrescar mensajes del hilo
- Tutor ve tarjeta + `GET /api/payment-requests/inbox`

---

## 7. Repositorio — métodos a agregar

```dart
// memberships_repository.dart
Future<MembershipMe> myMembership();
Future<MembershipBenefits> benefits();
Future<Map<String, PlanLimit>> limits();  // GET /api/memberships/me/limits

// profile_remote_datasource.dart
Future<UserPhotoResult> registerPhotoFromFirebase({...});  // POST /photo/register

// loyalty_repository.dart (nuevo)
Future<LoyaltySummary> summary();  // GET /api/wallet/loyalty/summary
Future<LoyaltyPurchaseResult> processPurchase(...);

// chat_dtos.dart
// campos: mediaUrl, thumbnailUrl, storagePath, updatedAt, messageType
```

---

## 8. Checklist de aceptación (marcar al terminar)

### Membresías
- [ ] `MembershipCubit` global carga en login
- [ ] Post-checkout MP refresca cubit sin cerrar sesión
- [ ] Chat privado oculto/bloqueado si `private_chat` deshabilitado
- [ ] Favoritos validan `favorites.max` antes de POST
- [ ] Kids validan `kids.profiles.max` antes de crear
- [ ] `PLAN_LIMIT_REACHED` → diálogo upgrade (no SnackBar genérico)
- [ ] Beneficios en lenguaje humano (sin feature keys visibles)

### Imágenes
- [ ] Perfil: Firebase → `/photo/register` → cache con `photoUpdatedAt`
- [ ] Chat envía/recibe `mediaUrl` + burbuja con loading/error
- [ ] Comercios/ads usan `imageUrl` + cache bust

### Wallet / Loyalty
- [ ] Dashboard usa `/wallet/loyalty/summary`
- [ ] Historial `/wallet/history`
- [ ] `process-purchase` tras pagos en comercio
- [ ] Sin textos debug en pantallas wallet

### Chat familiar
- [ ] Barra botones desde `/api/chat/buttons`
- [ ] Kid pay-for-me sin payerUserId
- [ ] Refresh mensajes tras solicitud

---

## 9. Orden de implementación sugerido (sprints)

| Sprint | Entregable | Impacto |
|--------|------------|---------|
| **S1** | `MembershipCubit` + refresh login/post-pago + upgrade dialog | Base para todo gating |
| **S2** | Gating chat privado + favoritos + kids | UX membresía visible |
| **S3** | Foto Firebase + chat `mediaUrl` | Imágenes corregidas |
| **S4** | Wallet loyalty summary + process-purchase | Puntos/cashback reales |
| **S5** | Pulido family chat pay-for-me + QA dispositivo | Flujo hijo→tutor |

---

## 10. Cómo probar (QA mobile)

### Membresía
1. Usuario Free → no debe poder abrir "Buscar personas" en chat (o ve upgrade).
2. Usuario Free con 20 favoritos → el 21º muestra upgrade, no POST.
3. Simular 403 con `PLAN_LIMIT_REACHED|feature=favorites.max` → diálogo upgrade.
4. Pagar plan Silver → sin cerrar app, chat privado se habilita tras refresh.

### Imágenes
1. Cambiar foto → se ve nueva sin logout (`photoUpdatedAt` cambió).
2. Enviar imagen chat → burbuja carga desde `mediaUrl` HTTP.

### Loyalty
1. Pagar en comercio → `process-purchase` → puntos en summary.
2. `GET /wallet/loyalty/summary` muestra nivel y progreso.

### Family pay-for-me
1. Login kid → chat familiar → Paga por mí → mensaje en hilo.
2. Tutor → inbox → aprobar.

---

## 11. Referencias backend (no inventar más)

| Doc backend | Tema |
|-------------|------|
| `docs/MOBILE-MEMBERSHIP-GATING-PROMPT.md` | Membresías detalle |
| `docs/MOBILE-IMAGES-LOYALTY-CLOSURE.md` | Imágenes + wallet endpoints |
| `docs/MOBILE-PRODUCTION-BACKEND-CLOSURE.md` | Geo, FX, auth, SSE |
| `docs/CHAT-CIERVO-API-CONTRACT.md` | Chat botones y mensajes |

**No crear endpoints nuevos en mobile.** Si falta algo en backend, reportar como pendiente backend.

---

## 12. Mensaje para el agente Flutter (copiar/pegar)

```
Implementa el cierre mobile según docs/MOBILE-FULL-IMPLEMENTATION-PROMPT.md (repo backend Ciervo-backend/docs/).

Prioridad:
1. MembershipCubit global (GET /memberships/me + /benefits + /me/limits) con refresh en login y post-checkout MP.
2. Gating: private_chat en chat_inbox_page, favorites.max en _FavoriteButton, kids.profiles.max en kids_cubit.
3. MembershipUpgradeDialog global para PLAN_LIMIT_REACHED (arreglar user_error_message.dart).
4. Foto perfil: Firebase Storage → POST /api/users/me/photo/register → CachedNetworkImage con photoUpdatedAt.
5. Chat: parser mediaUrl/thumbnailUrl en chat_dtos; envío imagen vía Firebase + messageType Image.
6. Wallet: migrar a GET /api/wallet/loyalty/summary y /wallet/history; POST /api/loyalty/process-purchase tras pagos.
7. Verificar family chat pay-for-me kid (chatConversationId, sin payerUserId).

Backend prod: https://ciervo-backend-613568140358.southamerica-east1.run.app
No hardcodear planes ni límites. No mostrar feature keys al usuario.
```
