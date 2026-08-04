# Alineación mobile ↔ contrato backend

Fuente: `Ciervo-backend/docs/MOBILE_BACKEND_FIXES_CONTRACT.md` (2026-07-27)

| # | Tema | App Flutter |
|---|------|-------------|
| 1 | User search | Hint actualizado; `q` crudo (sin cambios de API) |
| 2 | Operational session | Lee `operationalSessionId` + `operationalBand` (+ legacy `nightOperationalId`) |
| 3 | Wallet moneda | Moneda desde perfil/card; transfer/Pinduck sin asumir COP |
| 4 | Favoritos | Sin radio 25 km por defecto |
| 5 | Chat business | `businessName` / `businessLogoUrl` / URL o mediaId |
| 6 | NFC UID | UI bloquea + manejo `409` / `PHYSICAL_NFC_ALREADY_REGISTERED` |
| 7 | Bookings lookup | `GET /api/bookings/lookup?q=` |
| 8 | MOVE role | Ya valida claim `role == "1"` |
| 9 | Fare labels | Usa `*Label` y `bandCharges` del API |
| 10 | Pinduck | Envía `preferredPaymentMethod` + moneda del país |
