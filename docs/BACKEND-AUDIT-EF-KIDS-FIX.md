# Backend: corrección EF Core Kids/Familia y DTOs de presentación

## Error visible en app (Kids perfil)

```
OrderByDescending(ti => ti.Outer.IsPrimaryGuardian)
.ThenBy(ti => string.Format(...)) could not be translated
```

### Causa

`string.Format`, interpolación o concatenación dentro de `OrderBy` / `ThenBy` en consultas EF Core no se traduce a SQL.

### Corrección requerida (.NET)

```csharp
// ❌ Incorrecto
var tutors = await _context.GuardianLinks
    .Where(...)
    .OrderByDescending(x => x.IsPrimaryGuardian)
    .ThenBy(x => string.Format("{0} {1}", x.User.Name, x.User.Lastname))
    .ToListAsync();

// ✅ Opción A: ordenar en memoria
var tutors = (await _context.GuardianLinks
    .Where(...)
    .Include(x => x.User)
    .ToListAsync())
    .OrderByDescending(x => x.IsPrimaryGuardian)
    .ThenBy(x => $"{x.User.Name} {x.User.Lastname}".Trim())
    .ToList();

// ✅ Opción B: campos simples traducibles
var tutors = await _context.GuardianLinks
    .Where(...)
    .OrderByDescending(x => x.IsPrimaryGuardian)
    .ThenBy(x => x.User.Name)
    .ThenBy(x => x.User.Lastname)
    .ToListAsync();
```

### Regla global

- Auditar: `string.Format`, `$"..."`, `.Trim()` complejo, métodos custom en `OrderBy`/`Where`.
- Nunca devolver stacktrace al cliente mobile.
- Usar middleware de errores → mensaje amigable + log técnico.

## DTO `/api/kids/me/profile`

Debe incluir siempre (nunca null en JSON como string):

| Campo | Uso |
|-------|-----|
| `firstName` | Nombre |
| `lastName` | Apellido |
| `displayName` | Apodo visible |
| `nickname` | Alias |
| `username` | @usuario Kids |
| `ciervoUserCode` | CIERVO ID |
| `role` / `roleLabel` | Menor, Tutor, etc. |

## DTO `/api/payment-requests/*`

| Campo | Uso |
|-------|-----|
| `statusLabel` | Pendiente, Aprobada, etc. |
| `requesterUsername` | @usuario emisor |
| `requesterName` | Nombre completo |
| `requesterCiervoUserCode` | CIERVO ID |
| `description` | Concepto |
| `amount` + `currency` | Monto |

## Approve con tarjeta de respaldo

`POST /api/payment-requests/{id}/approve` aceptar body opcional:

```json
{
  "useBackupCard": true,
  "familyPaymentCardId": "uuid-opcional"
}
```

## Delivery – comisión 1%

Guardar en backend, no exponer al cliente:

- `subtotalDelivery`
- `ciervoFeePercent = 1`
- `ciervoFeeAmount`
- `totalCharged`
- `courierAmount`

## Username adulto

Endpoints sugeridos:

- `GET /api/users/search?q=@gabriel`
- Campo `username` único en perfil
- Incluir en chat, solicitudes, vacas, reservas

## ID operativo nocturno

Modelo sugerido: `CIERVO-YYYYMMDD-NOCHE-0001` con secuencia por turno y relación interna al usuario.
