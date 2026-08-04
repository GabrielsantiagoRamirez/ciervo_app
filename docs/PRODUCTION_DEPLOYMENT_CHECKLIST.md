# PRODUCTION_DEPLOYMENT_CHECKLIST

**Fecha:** 2026-07-19  
**Repos:** Flutter mobile (`ciervo_clud`) + backend Ciervo (repo separado).

## Pre-despliegue

- [ ] Backup de base de datos.
- [ ] Secretos cargados en Secret Manager (no en Git).
- [ ] Variables de producción revisadas (lista abajo).
- [ ] Migraciones SQL workers / unique credits preparadas.
- [ ] Credenciales Mercado Pago **CO** y **CL** validadas en cuenta vendedor correcta.
- [ ] App Password Gmail generada y rotada si la anterior filtró.
- [ ] Webhooks MP apuntan a URL prod y secretos por país.
- [ ] Documentación: `SMTP_FIX`, `MERCADOPAGO_MULTICOUNTRY_FIX`, `SQL_WORKERS_FIX`, `ADMIN_INTEGRATIONS_DIAGNOSTICS`, `MOBILE_CHANGES_REQUIRED`.

## Variables de producción esperadas (sin valores reales)

```
Email__Host=smtp.gmail.com
Email__Port=587
Email__Username=<correo>
Email__Password=<Secret Manager>
Email__From=<correo>
Email__DisplayName=Ciervo Club
Email__EnableSsl=true

Payments__Countries__CO__AccessToken=<Secret Manager>
Payments__Countries__CO__PublicKey=<Secret Manager o configuración>
Payments__Countries__CO__WebhookSecret=<Secret Manager>
Payments__Countries__CO__Currency=COP

Payments__Countries__CL__AccessToken=<Secret Manager>
Payments__Countries__CL__PublicKey=<Secret Manager o configuración>
Payments__Countries__CL__WebhookSecret=<Secret Manager>
Payments__Countries__CL__Currency=CLP
```

### Prohibido guardar secretos reales en

- `appsettings.json`
- Git
- archivos `.env` versionados
- documentación
- capturas
- logs
- respuestas de API

## Pasos de despliegue (backend)

1. Desplegar migraciones (outbox lease + unique credit).
2. Publicar nueva revisión Cloud Run / API con config multi-país + SMTP.
3. Verificar `GET /api/admin/integrations/diagnostics` (sin secretos).
4. Smoke SMTP: recovery real a casilla de prueba.
5. Smoke pago CO (COP) sandbox/prod controlado.
6. Smoke pago CL (CLP) → preferencia en `mercadopago.cl`.
7. Disparar webhook duplicado en staging → una sola acreditación.
8. Observar logs: ausencia SQL 650; workers con claim único.

## Pasos de despliegue (móvil)

1. Esta fase **no** requiere release móvil obligatorio si el backend ya entrega `checkoutUrl` correcto.
2. Release móvil posterior según `MOBILE_CHANGES_REQUIRED.md` (DTO `paymentId`/`countryCode`/`currency`, SMTP sanitize).
3. Build: `flutter build appbundle --release` / iOS cuando credenciales Apple estén listas.

## Pruebas de aceptación

| # | Caso | Resultado esperado |
|---|------|--------------------|
| 1 | Recovery password | Correo llega; sin error SMTP en UI |
| 2 | Recarga usuario CL | `CLP` + checkout `.cl` + vendedor CL |
| 3 | Recarga usuario CO | `COP` + checkout Colombia |
| 4 | Sin token CL | Error controlado; **no** fallback CO |
| 5 | Webhook x2 | Un solo crédito |
| 6 | 2 workers mismo evento | Un solo process |
| 7 | Admin diagnostics | Estado OK, secretos ocultos |
| 8 | Compilar + tests | Verde |

## Rollback

1. Revertir revisión Cloud Run a la anterior estable.
2. **No** borrar secretos nuevos hasta confirmar rollback OK.
3. Si migraciones no son backward-compatible: restore DB desde backup **solo** con aprobación.
4. Deshabilitar workers nuevos vía flag / scale a 0 si hay corrupción de cola.
5. Comunicar a móvil: usuarios con checkout pendiente deben reintentar tras estabilizar.
6. Verificar diagnostics y smoke CO (mínimo) post-rollback.

## Riesgos pendientes

- Credenciales CL no provisionadas en Secret Manager.
- Preferences antiguas CO cacheadas en clientes (mitigado en app con clear de sesión de recarga).
- Panel admin aún sin endpoint diagnostics.
- Repo Flutter no incluye código backend: fixes deben aplicarse en el repositorio API.
- iOS signing / Firebase iOS config pueden bloquear release Apple.

## Contactos / ownership

| Área | Owner |
|------|-------|
| SMTP | Backend + Ops |
| MP multi-país | Backend Payments |
| Workers SQL | Backend + DBA |
| Admin panel | Web Admin |
| App móvil | Flutter (`MOBILE_CHANGES_REQUIRED.md`) |
