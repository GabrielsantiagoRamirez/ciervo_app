# CIERVO CLUB — Smoke mobile Flutter
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

Write-Host "== CIERVO Mobile Smoke ==" -ForegroundColor Cyan

Write-Host "`n[1/3] dart format --set-exit-if-changed" -ForegroundColor Yellow
dart format --output=none --set-exit-if-changed lib test
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "`n[2/3] flutter analyze" -ForegroundColor Yellow
flutter analyze --no-fatal-infos
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "`n[3/3] flutter test" -ForegroundColor Yellow
flutter test
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "`n== Checklist manual (ver docs/FLUTTER-MOBILE-PROMPT.md §10) ==" -ForegroundColor Green
@(
  "Login adulto -> permisos ubicacion + notificaciones",
  "Perfil CIERVO ID copiable",
  "Wallet recarga MP + poll + recibo",
  "Kids pay-for-me kid + tutor approve/reject",
  "Kid NFC / QR en comercio",
  "Kids Shield: permitido, requiere aprobacion y rechazo",
  "Kids QR: catch-up, SSE, background/resume y polling fallback",
  "Movie: catalogo, funciones, asientos, request, Wallet, QR e historial",
  "Movie compartida en chat abre request o funciones",
  "MOVE Driver v2: feature bloqueado sin terminos release",
  "MOVE Driver v2 CO/CL: identidad, licencia, documentos y cinco fotos",
  "MOVE Driver v2: retry conserva Idempotency-Key y reanuda borrador",
  "MOVE Driver v2: review, correccion, suspendido/bloqueado y canGoOnline",
  "Business/Admin: token Kids, consumo QR Movie y NFC validate/charge",
  "Deep links revalidan chat, request Kids, device y Movie",
  "Envios seguros: crear, aceptar, hold, PIN, pago, recibo",
  "Vakupli crear/listar/chat/pagar",
  "Logout desregistra FCM",
  "Camara solo on-demand (QR/foto)"
) | ForEach-Object { Write-Host "  [ ] $_" }

Write-Host "`nSmoke automatizado OK." -ForegroundColor Green
