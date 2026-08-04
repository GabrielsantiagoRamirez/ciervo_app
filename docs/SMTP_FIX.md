# SMTP_FIX

**Objetivo:** recuperación de contraseña envía correo vía Gmail (contraseña de aplicación) sin filtrar errores SMTP a la app.  
**Alcance:** backend (.NET / Cloud Run). Este repo Flutter **no** contiene el servicio SMTP.  
**Fecha:** 2026-07-19.

## Causa raíz esperada

1. Credenciales SMTP ausentes, incorrectas o usando contraseña de cuenta Gmail en lugar de **App Password**.
2. `Email__EnableSsl` / puerto incorrectos (`587` + STARTTLS).
3. Excepciones SMTP (`535`, `Authentication unsuccessful`, stack traces) propagadas en `msg` / Problem Details hacia clientes.

## Solución aplicada (especificación backend)

1. Configurar envío con opciones `Email__*` (ver variables abajo).
2. Autenticar Gmail **solo** con contraseña de aplicación (2FA habilitado en la cuenta).
3. En `request-password-recovery`:
   - Generar OTP / token como hoy.
   - Enviar correo; **no** devolver detalle SMTP al cliente.
   - Respuesta homogénea ante éxito o fallo de proveedor (evitar enumeración de cuentas si el producto lo requiere; si ya se distingue “usuario no encontrado”, mantener contrato actual).
4. Mapear fallos SMTP a código estable, p. ej. `EMAIL_PROVIDER_UNAVAILABLE`, mensaje genérico.
5. Loguear en servidor: host, puerto, resultado, **sin** password ni cuerpo completo del mail con OTP en claro en logs de producción si es posible redactar.

## Endpoint

| Método | Path |
|--------|------|
| `POST` | `/api/auth/request-password-recovery` |

## Variables (sin valores reales)

```
Email__Host=smtp.gmail.com
Email__Port=587
Email__Username=<correo>
Email__Password=<Secret Manager>
Email__From=<correo>
Email__DisplayName=Ciervo Club
Email__EnableSsl=true
```

## Secretos

| Secreto | Ubicación |
|---------|-----------|
| `Email__Password` | Google Secret Manager / Cloud Run secrets |
| Cuenta Gmail + App Password | Solo Secret Manager; rotación documentada |

**Prohibido:** `appsettings.json`, Git, `.env` versionado, docs, capturas, logs de API responses.

## Impacto en app móvil

La app ya traduce parcialmente mensajes con “proveedor de correo” / “email provider”.  
Si el backend envía texto SMTP crudo, aún puede filtrarse → ver `MOBILE_CHANGES_REQUIRED.md` (sanitización adicional).

## Pruebas

1. Solicitar recovery con correo válido → correo llega en &lt; 2 min.
2. Credencial SMTP inválida → HTTP controlado + mensaje genérico; **sin** `535` en body.
3. Rate limit → 429 / mensaje de espera.
4. Compilación y test de integración de mail (sandbox o mock `IEmailSender`).

## Criterios de aceptación

- [ ] Recuperar contraseña envía el correo correctamente.
- [ ] Backend autentica Gmail con App Password.
- [ ] Errores SMTP no se muestran directamente en la app.
- [ ] Secretos solo en Secret Manager.
