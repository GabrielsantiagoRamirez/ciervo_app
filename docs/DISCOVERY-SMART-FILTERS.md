# Discovery smart filters — contrato mobile

Documento de apoyo al prompt `PROMPT-MOBILE-DISCOVERY-SMART-FILTERS.md`.

## Experience mode

| UI | `experienceMode` API |
|---|---|
| Día | `day` |
| Noche | `night` |
| 24h | `24h` |

Auto local: `06:00–17:59` → day · `18:00–05:59` → night.

## Endpoints

- `GET /api/business-categories?experienceMode={mode}`
- `GET /api/businesses/nearby?...&experienceMode={mode}&radiusKm={r}&page=1&pageSize=20`
- Mismos filtros en `search`, `by-city`, `by-category`

## Query params smart

| Param | Tipo |
|---|---|
| `radiusKm` | number |
| `minRating` | number |
| `openNow` | bool |
| `acceptsCiervoPayments` | bool |
| `hasDelivery` | bool |
| `requiresReservation` | bool |
| `hasPromotions` | bool |
| `familyFriendly` | bool |
| `petFriendly` | bool |
| `accessible` | bool |
| `hasParking` | bool |

## Response amenities (solo mostrar si `true`)

`experienceBucket`, `open24Hours`, `acceptsCiervoPayments`, `hasDelivery`, `requiresReservation`, `isFamilyFriendly`, `isPetFriendly`, `isAccessible`, `hasParking`, `hasActivePromotions`, `isOpen`/`estado`, `rating`, `distanceKm`.
