# Vakupli — contactos nacionales, cupos y pago visual

## Contactos

```http
GET /api/vakupli/contacts?take=50
GET /api/vakupli/contacts/search?q=@usuario|CIERVO-...|nombre&take=20
```

Auth: `ClientOnly`. Solo usuarios del mismo `CountryCode` que el actor.  
Si el perfil no tiene país → `errorCode: COUNTRY_REQUIRED`.

Respuesta item: `userId`, `ciervoUserCode`, `username`, `displayName`, `photoUrl`, `countryCode`, `isFavorite`.

## Quién pagó (UI)

```http
GET /api/vakupli/groups/{groupId}/participants
```

Campos nuevos: `displayName`, `username`, `photoUrl`, `countryCode`, `paymentStatus` (`paid|pending|none`), `hasPaid`, `amount`, `currency`, `contributionId`.

## Invitaciones nacionales

`POST .../invite` y join validan mismo país que el **creador** del grupo.  
Mismatch → `errorCode: COUNTRY_MISMATCH`.

## Cupos por plan (creador)

| Plan | Invitados máx. | Total con creador |
|------|----------------|-------------------|
| Free | 3 | 4 |
| Plus (`silver`) | 7 | 8 |
| Gold | 11 | 12 |
| Platinum (`black`) | 15 | 16 |

Cuentan `Accepted` + `PendingInvite`.  
Grupo responde `maxGuests`, `maxTotal` (=1+maxGuests), `planGuests`, `purchasedExtraGuests`, `usedSlots`, `remainingSlots`, `planCode`, `extraSlotPackSize` (4), `nextPackPriceUsd`, `extraSlotsPeriodEndsAt`, `extraSlotsPeriodActive`.  
Cupo lleno → `errorCode: CAPACITY_EXCEEDED`.  
**Importante UI:** `maxGuests` = invitados; `maxTotal` = con creador. Free=3 / total 4; Free+1 pack=7 / total **8**.

La membresía vencida (`EndsAt` pasado) **no** cuenta: se usa Free aunque quede un trial Gold con Status Active.

## Moneda por ubicación

Contribuciones del grupo usan la moneda del **país del creador** (CL→CLP, CO→COP, etc.).  
Mismatch → `errorCode: CURRENCY_MISMATCH`.  
Packs extra: cobro wallet prioriza tarjeta en esa moneda local (precio base USD convertido).

## Packs de cupos extra (bimensual por usuario)

Cada pack suma **+4 invitados**. El cobro es **por usuario** (creador del grupo) y dura **2 meses**.

| Plan creador | Precio / pack / ciclo |
|--------------|----------------------|
| Free | US$ 2 |
| Plus / Gold / Platinum | US$ 1 |

Reglas:

- Al comprar se registra en wallet/historial (`ReferenceType: VakupliExtraSlotPack`) + recibo.
- Si el periodo sigue vigente: se pueden sumar más packs (se cobra el pack nuevo) **sin reiniciar** la fecha de fin.
- Si el periodo venció: hay que volver a pagar; arranca un ciclo nuevo de 2 meses.
- **Mejorar el plan de membresía no cancela ni recobra** los cupos extra: se conservan los días restantes. El próximo cobro (al vencer o al renovar) usa el precio del plan actual.

```http
POST /api/vakupli/groups/{groupId}/extra-slots
```

```json
{ "packs": 1, "walletCardId": null, "idempotencyKey": "uuid-unico" }
```

Respuesta: `guestsAdded`, `purchasedExtraGuests`, `maxGuests`, `remainingSlots`, `amountCharged`, `currency`, `priceUsd`, `periodStartsAt`, `periodEndsAt`, `billingPeriodMonths` (2), `periodPreservedOnPlanUpgrade`, `paymentIntentId`, `walletTransactionId`, `receipt`.

### Estado del usuario (modal app)

```http
GET /api/vakupli/extra-slots/me
```

Usar **antes de mejorar el plan** de membresía.

Campos clave: `isActive`, `extraGuests`, `periodEndsAt`, `billingPeriodMonths`, `nextRenewalPriceUsd`, `nextPackPriceUsd`, `planUpgradePreservesDays`, `acknowledgeBeforePlanUpgrade`, `upgradeModal` (`title`, `body`, `continueUpgradeLabel`, `cancelLabel`).

## Editar / cancelar / eliminar grupo

Si el Vakupli no se completa:

```http
PUT    /api/vakupli/groups/{groupId}          # name, description, isPrivate, joinType (creator/admin)
POST   /api/vakupli/groups/{groupId}/cancel   # status=Cancelled
DELETE /api/vakupli/groups/{groupId}          # soft-delete (solo creador)
```

También existe `POST .../leave` para salir como miembro.


Cada grupo responde:
- `createdAt` (UTC)
- `expiresAt` (UTC) — al crear = `createdAt + 24h`; si el registro no tenía valor, el API calcula lo mismo
- `remainingSeconds` — listo para countdown (`0` si ya venció)

La UI no debe mostrar el `code` como “tiempo restante”: usar `remainingSeconds` / `expiresAt`.

## Flutter — modal obligatorio al mejorar plan

Cuando el usuario vaya a mejorar su plan (`/api/memberships/subscribe-intents` u pantallas de upgrade):

1. Llamar `GET /api/vakupli/extra-slots/me`.
2. Si `acknowledgeBeforePlanUpgrade == true` (tiene cupos extra activos), mostrar un **modal de lectura** (no dismiss accidental) con `upgradeModal.title` / `body`.
3. Mensaje a cubrir:
   - El cobro de cupos extra es **bimensual**.
   - Si mejora el plan **no pierde los días** del periodo actual.
   - **No se cobra de nuevo** el pack hasta que venza el periodo.
4. Botones:
   - Primario: `continueUpgradeLabel` → continúa el upgrade de membresía.
   - Secundario: `cancelLabel` → se queda en el plan actual.
5. Solo continuar el upgrade tras acknowledge explícito del botón primario.
