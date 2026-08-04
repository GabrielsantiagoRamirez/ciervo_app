# SQL_WORKERS_FIX

**Objetivo:** eliminar error SQL **650** en workers y garantizar que dos instancias no procesen el mismo evento.  
**Alcance:** backend workers / background jobs (Cloud Run, Hangfire, hosted services, queues).  
**Fecha:** 2026-07-19.

## Causa raíz esperada

SQL Server **error 650** suele asociarse a:

- Consultas con aislamiento incompatible (`READ COMMITTED SNAPSHOT` / snapshot) frente a hints o cursores.
- Lecturas inconsistentes bajo concurrencia entre réplicas de worker.
- Falta de **lease / locking** al reclamar mensajes de cola o filas de outbox.

Síntoma: dos instancias del mismo worker procesan el mismo `PaymentWebhookEvent` / outbox row → doble intento de acreditación o fallos en cascada.

## Solución aplicada (especificación)

1. **Outbox / inbox idempotente**
   - Tabla de eventos con `Id`, `Status` (`Pending`/`Processing`/`Done`/`Failed`), `LockedUntil`, `LockedBy`, `ProcessedAt`.
   - Claim atómico:

```sql
UPDATE OutboxEvents
SET Status = 'Processing', LockedBy = @instanceId, LockedUntil = DATEADD(second, 30, SYSUTCDATETIME())
WHERE Id = @id AND Status = 'Pending' AND (LockedUntil IS NULL OR LockedUntil < SYSUTCDATETIME());
```

   - Solo `@@ROWCOUNT = 1` procesa.

2. **Idempotencia de negocio**
   - Unique index en `ProviderPaymentId` / `ExternalReference` para acreditaciones.
   - Transición de intent `pending → approved` una sola vez.

3. **Aislamiento**
   - Evitar hints que disparen 650; preferir `READ COMMITTED` + claim atómico.
   - Si se usa snapshot, no mezclar con queries incompatibles en la misma transacción.

4. **Multi-instancia**
   - Heartbeat de lease; requeue si `LockedUntil` expiró.
   - Métricas: eventos reclamados vs procesados vs conflictos.

## Migraciones (esperadas)

| Migración | Descripción |
|-----------|-------------|
| `AddOutboxLeaseColumns` | `LockedBy`, `LockedUntil`, índices. |
| `AddPaymentCreditUniqueIndex` | Unique en id de pago proveedor / external ref. |
| (opcional) `EnableRCSI` | Si el DBA aprueba RCSI en la BD. |

> Ejecutar migraciones en ventana controlada; backup previo.

## Pruebas

1. Dos workers en paralelo sobre el mismo evento → un solo procesado.
2. Webhook duplicado MP → una sola acreditación.
3. Lease expirado → segundo worker puede reclamar.
4. No aparece SQL 650 en logs de carga.

## Criterios de aceptación

- [ ] Workers dejan de producir error SQL 650.
- [ ] Dos instancias no procesan el mismo evento.
- [ ] Una recarga no puede acreditarse dos veces.
- [ ] Solución compila y pruebas pasan.
