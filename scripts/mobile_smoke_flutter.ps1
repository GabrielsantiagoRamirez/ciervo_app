# CIERVO CLUB — Smoke mobile Flutter
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

Write-Host "== CIERVO Mobile Smoke ==" -ForegroundColor Cyan

Write-Host "`n[1/2] flutter analyze" -ForegroundColor Yellow
flutter analyze
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "`n[2/2] flutter test" -ForegroundColor Yellow
flutter test
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "`n== Checklist manual (ver docs/FLUTTER-MOBILE-PROMPT.md §10) ==" -ForegroundColor Green
@(
  "Login adulto -> permisos ubicacion + notificaciones",
  "Perfil CIERVO ID copiable",
  "Wallet recarga MP + poll + recibo",
  "Kids pay-for-me kid + tutor approve/reject",
  "Kid NFC / QR en comercio",
  "Envios seguros: crear, aceptar, hold, PIN, pago, recibo",
  "Vakupli crear/listar/chat/pagar",
  "Logout desregistra FCM",
  "Camara solo on-demand (QR/foto)"
) | ForEach-Object { Write-Host "  [ ] $_" }

Write-Host "`nSmoke automatizado OK." -ForegroundColor Green
