# MOBILE_CHANGES_REQUIRED

**Fase:** auditoría (sin modificar código móvil en esta entrega).  
**Repo auditado:** `ciervo_clud` (Flutter).  
**Fecha:** 2026-07-19.

## Veredicto de participación móvil en Chile

La app **no elige Access Token** de Mercado Pago y **no acredita saldo localmente**.  
La causa raíz del cobro/checkout en dominio o vendedor incorrecto es **backend** (credenciales por país / webhook / preference).

Aun así, la app **sí participa parcialmente** y hay **gaps de contrato** a cerrar en una fase móvil posterior.

| Pregunta | Hallazgo actual | ¿Participa en el bug Chile? |
|----------|-----------------|-----------------------------|
| ¿Qué país envía en la recarga? | **No envía `countryCode`** en el body. Lee `profile.countryCode` solo para derivar moneda y validar host. | Indirecto: el país lo debe resolver el backend desde el perfil autenticado. |
| ¿Envía moneda? | **Sí.** `CL`→`CLP`, `CO`→`COP` en `POST .../recharge-intents`. | Bajo: si el perfil es `CL`, ya pide `CLP`. |
| ¿Usa Public Key fija de Colombia? | **No en recarga Wallet** (abre URL del backend). **Sí riesgo** en tokenización de tarjetas familia vía `/api/payments/config` → fallback `/api/wallet/mercadopago/config` (config global CO). | No en recarga; sí en otro flujo. |
| ¿Abre la URL del backend? | **Sí.** Prioriza `checkoutUrl`, fallback `initPoint`. Valida host (`mercadopago.cl` / `mercadopago.com.co`). | Solo si el backend entrega URL mala; la app la abre. |
| ¿Acredita saldo localmente? | **No.** Tras GET/sync, si status terminal exitoso, llama `load()` y muestra saldo del API. | No. |
| ¿Muestra errores técnicos sin traducir? | Parcial. Hay sanitización SMTP genérica; faltan patrones `535`, `Authentication unsuccessful`, stack SMTP crudo. | UX, no causa del cobro Chile. |
| ¿Permite elegir país distinto al registrado? | **No en recarga Wallet.** Sí hay selectores de país en NFC físico / kids / discovery (otros flujos). | No en recarga. |

## Respuesta esperada del backend (contrato objetivo)

```json
{
  "paymentId": "...",
  "checkoutUrl": "...",
  "countryCode": "CL",
  "currency": "CLP",
  "status": "pending"
}
```

Hoy el DTO móvil parsea principalmente: `intentId`/`id`, `preferenceId`, `checkoutUrl`/`initPoint`, `status`.  
**No consume** `paymentId`, `countryCode` ni `currency` de la respuesta.

## Archivos a modificar (fase móvil posterior)

| Archivo | Cambio |
|---------|--------|
| `lib/features/wallet/data/dtos/wallet_operation_dtos.dart` | Mapear `paymentId`, `countryCode`, `currency` desde `value`. |
| `lib/features/wallet/domain/entities/recharge_intent.dart` | Campos `paymentId`, `countryCode`, `currency`; validar host con **país de respuesta**. |
| `lib/features/wallet/data/models/wallet_recharge_session.dart` | Persistir también `paymentId` y `countryCode`/`currency` del backend. |
| `lib/features/wallet/data/repositories/wallet_repository_impl.dart` | Preferir `countryCode`/`currency` del response; no inventar país; seguir sin Access Token. |
| `lib/features/wallet/presentation/pages/recharge_page.dart` | Abrir solo URL validada del intent recién creado; UI de moneda según response/perfil. |
| `lib/features/wallet/presentation/cubit/wallet_cubit.dart` | Éxito solo tras status backend; mensajes de usuario. |
| `lib/core/errors/user_error_message.dart` | Códigos SMTP / pagos multi-país amigables. |
| `lib/core/utils/display_labels.dart` | Ampliar `sanitizeBackendMessage` para SMTP (`535`, `Authentication`, `SmtpException`). |
| `lib/features/family_payments/presentation/pages/add_family_card_page.dart` | Public Key **por país del perfil**, nunca config global CO. |
| `lib/features/payments/data/datasources/payments_remote_datasource.dart` | Config por país; no fallback silencioso a config Colombia. |
| `test/features/wallet/wallet_recharge_flow_test.dart` | Extender cobertura contractual. |

## Endpoints involucrados

| Método | Path | Uso móvil |
|--------|------|-----------|
| `GET` | `/api/profile/me` (o equivalente `getMe`) | Origen de `countryCode` del usuario. |
| `POST` | `/api/wallet/cards/{cardId}/recharge-intents` | Crear recarga (`amount`, `currency`, `idempotencyKey`, `description`). |
| `GET` | `/api/wallet/recharge-intents/{intentId}` | Estado post-checkout. |
| `POST` | `/api/wallet/recharge-intents/{intentId}/sync` | Forzar sync. |
| `GET` | `/api/wallet/cards` | Refresco de saldo **solo tras confirmación**. |
| `GET` | `/api/payments/config` / `/api/wallet/mercadopago/config` | **No usar** para decidir país/enlace de recarga. Solo tokenización tarjetas (revisar). |
| `POST` | `/api/auth/request-password-recovery` | Recuperación; errores SMTP deben llegar genéricos. |

## Modelos

### Actual (`RechargeIntent`)

- `id`, `preferenceId`, `checkoutUrl`, `status`

### Objetivo

- `paymentId` (o alias de `id`/`intentId`)
- `checkoutUrl`
- `countryCode` (`CL` | `CO`)
- `currency` (`CLP` | `COP`)
- `status` (`pending` | …)
- `preferenceId` (opcional, persistencia)

### Sesión segura (`WalletRechargeSession`)

Persistir juntos: `intentId`/`paymentId`, `preferenceId`, `checkoutUrl`, `currency`, `countryCode`, `idempotencyKey`, `amount`, `cardId`.  
Invalidar si cambian país, moneda, monto o tarjeta.

## Mensajes de error (móvil)

| Condición | Mensaje usuario |
|-----------|-----------------|
| Host checkout ≠ país | `El checkout recibido no es válido para tu país.` |
| País perfil no CL/CO | `El país del perfil no admite recargas Wallet.` |
| SMTP / correo no configurado | `No pudimos enviar el correo ahora. Intenta más tarde o contacta soporte.` |
| SMTP técnico (`535`, auth) | **Nunca** mostrar texto SMTP; mismo mensaje genérico de correo. |
| Recarga pendiente | `Recarga creada. Completa el pago en Mercado Pago.` |
| Acreditación | Solo si backend `approved`/`succeeded`: `Recarga acreditada correctamente.` |
| Cross-border MP | Mensaje ya existente `CROSS_BORDER_NOT_SUPPORTED` / wallet. |

## Pruebas a añadir (fase móvil)

1. Perfil `CL` → body con `currency: CLP` y UUID nuevo.
2. Response con `countryCode: CL` y `checkoutUrl` `www.mercadopago.cl` → abre URL.
3. Response con host CO para perfil CL → error, no abre, no persiste.
4. Cambio de monto → nueva `idempotencyKey`.
5. Reinicio app → no reabre checkout incompatible.
6. Saldo no cambia hasta GET/sync terminal exitoso.
7. Error SMTP crudo → mensaje genérico (widget/unit).
8. Tokenización familia con perfil CL no usa public key CO (cuando backend exponga config por país).

## Criterios de aceptación (móvil)

- [ ] Un perfil `CL` solicita recarga en `CLP`.
- [ ] La URL abierta pertenece a `mercadopago.cl` (o subdominio).
- [ ] No se construye URL MP manualmente.
- [ ] No se usa Access Token en la app.
- [ ] No se usa `/api/wallet/mercadopago/config` para decidir país ni checkout de recarga.
- [ ] El saldo solo se actualiza tras confirmación del backend.
- [ ] Errores SMTP no se muestran en crudo.
- [ ] No hay selector de país en el flujo de recarga Wallet.
- [ ] Modelos aceptan `paymentId` + `countryCode` + `currency` del backend.
- [ ] Suite de pruebas de recarga en verde.

## Fuera de alcance de esta fase

- No se modificó código Flutter en esta entrega (pedido explícito).
- Fixes SMTP, workers SQL 650, webhooks y panel admin son **backend**; ver docs en `docs/`.
