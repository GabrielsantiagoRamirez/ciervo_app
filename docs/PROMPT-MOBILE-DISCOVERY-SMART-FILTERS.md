# Prompt — App mobile CIERVO: home discovery día/noche/24h + filtros smart

## Contexto

Backend listo para discovery inteligente. La app mobile debe:

1. Cambiar la home según la hora local del usuario (día / noche).
2. Ofrecer toggle Día / Noche / 24h.
3. Exponer filtros smart (cercanía, rating, CIERVO, delivery, reserva, promos, familia, pet, accesible, parking).
4. Consumir el catálogo de categorías por bucket.

Contrato: `docs/DISCOVERY-SMART-FILTERS.md`.

## Comportamiento de home

### Auto mode por hora local del dispositivo

| Hora local | `experienceMode` | Prioridad de UI |
|---|---|---|
| 06:00–17:59 | `day` | Servicios cotidianos |
| 18:00–05:59 | `night` | Bares, entretenimiento, nocturno |

El usuario puede override manual con segmented control: **Día | Noche | 24h**.

### Carga

1. `GET /api/business-categories?experienceMode={mode}` → chips/categorías de la franja.
2. `GET /api/businesses/nearby?latitude={lat}&longitude={lng}&radiusKm={r}&experienceMode={mode}&page=1&pageSize=20` (+ filtros activos).
3. Opcional: mantener ads feed / activity feed existentes.

Al cambiar el toggle, recargar categorías + nearby.

## Filtros smart (bottom sheet / modal)

| UI | Query param | Tipo |
|---|---|---|
| Radio / distancia | `radiusKm` (+ lat/lng ya usados) | number |
| Calificación mínima | `minRating` | number (ej. 3.5, 4, 4.5) |
| Solo abiertos ahora | `openNow=true` | bool |
| Acepta pagos CIERVO | `acceptsCiervoPayments=true` | bool |
| Tiene delivery | `hasDelivery=true` | bool |
| Requiere reserva | `requiresReservation=true` | bool |
| Tiene promociones | `hasPromotions=true` | bool |
| Apto familias | `familyFriendly=true` | bool |
| Pet friendly | `petFriendly=true` | bool |
| Accesible | `accessible=true` | bool |
| Estacionamiento | `hasParking=true` | bool |

Aplican también en `search`, `by-city`, `by-category`.

## Modelos a actualizar

### Categoría

```dart
class BusinessCategory {
  final int id;
  final String code;
  final String name;
  final bool active;
  final String experienceBucket; // day | night | allday
}
```

### Nearby / card

Parsear campos nuevos:

- `experienceBucket`
- `open24Hours`
- `acceptsCiervoPayments`
- `hasDelivery`
- `requiresReservation`
- `isFamilyFriendly`
- `isPetFriendly`
- `isAccessible`
- `hasParking`
- `hasActivePromotions`
- `isOpen` / `estado`
- `rating` / `distanceKm`
- `promocionesActivas` (ya existía)

### Public detail

Mismos amenities para chips en ficha del comercio.

## UX

- Home: header con toggle Día/Noche/24h + botón Filtros.
- Chips de categoría horizontales según bucket.
- Cards: mostrar distancia, rating, badge “Abierto/Cerrado”, iconos pequeños de amenities activos (máx 3–4), badge “Promo” si `hasActivePromotions`.
- Empty state si no hay resultados en la franja: CTA “Ver 24h” o “Ampliar radio”.
- Kids mode: seguir pasando `kidId` cuando aplique (sin cambios).

## Reglas de negocio (cliente)

- No inventar amenities: solo mostrar las que vengan `true` del API.
- `experienceMode=24h` lista solo comercios 24h; day/night incluyen también 24h (lo resuelve el backend).
- Cercanía sigue siendo el sort principal del nearby.

## Criterios de aceptación

- [ ] A las 20:00 la home entra en modo noche automáticamente (categorías night).
- [ ] Toggle manual cambia categorías + listado.
- [ ] Filtros smart se envían como query params y reflejan resultados.
- [ ] Cards y detalle muestran amenities/promos/open state.
- [ ] Sin romper nearby/search/kids existentes.

## Fuera de alcance

- No implementar mapa nuevo salvo que ya exista.
- No backfill de amenities: comercios viejos tendrán flags en false hasta que el dueño los configure en admin.
