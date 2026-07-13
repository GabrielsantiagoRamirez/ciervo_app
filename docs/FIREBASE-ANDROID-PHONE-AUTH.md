# Firebase Phone Auth en Android (Play Integrity)

## Error que ves

```
This request is missing a valid app identifier, meaning that Play Integrity
checks, and reCAPTCHA checks were unsuccessful.
```

Eso **no es un bug del flujo Flutter**. Firebase no puede verificar que la app es legítima antes de enviar el SMS.

## Checklist (en orden)

### 1. Huellas SHA en Firebase Console

Proyecto: `ciervoclub-70a3c` → Configuración → Tus apps → Android `com.company.ciervoclub`

Agrega **SHA-1 y SHA-256** del keystore con el que **instalaste** la app:

**Debug** (`flutter run` / desarrollo):

```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

Huellas actuales del debug (verificar en tu máquina):

| Tipo    | Valor |
|---------|-------|
| SHA-1   | `87:E0:22:27:04:F0:DE:89:E5:2B:29:33:DD:62:00:47:AA:69:A6:EE` |
| SHA-256 | `E5:8D:D5:6B:0C:89:24:D0:8E:EB:D4:60:B0:28:5E:5D:2A:C9:18:4C:A6:48:71:48:00:FC:49:FB:2D:4C:EF:CE` |

**Release** (APK/AAB firmado con `upload-keystore.jks`):

```powershell
keytool -list -v -keystore android\upload-keystore.jks -alias ciervo
```

Si instalas un build release, **debes** registrar también esas huellas en Firebase.

Tras agregar huellas, descarga de nuevo `google-services.json` y reemplaza `android/app/google-services.json`.

### 2. Habilitar Play Integrity API

[Google Cloud Console](https://console.cloud.google.com/apis/library/playintegrity.googleapis.com?project=ciervoclub-70a3c) → proyecto `ciervoclub-70a3c` → **Play Integrity API** → **Habilitar**.

También verifica que estén habilitadas:

- Identity Toolkit API
- Token Service API

### 3. Phone Auth en Firebase

Firebase Console → Authentication → Sign-in method → **Teléfono** → **Habilitado**.

### 4. Teléfonos de prueba (desarrollo)

Authentication → Sign-in method → Teléfono → **Números de teléfono para pruebas**

Ejemplo:

| Teléfono        | Código |
|-----------------|--------|
| +56942255924    | 123456 |

Con número de prueba **no** se envía SMS real y se evita el bloqueo por Play Integrity en muchos casos de desarrollo.

### 5. App Check (si está forzado)

Si en Firebase → App Check → Authentication está en **Enforced**, la app debe integrar `firebase_app_check` con proveedor Play Integrity. Hoy el proyecto **no** lo tiene; si está forzado en consola, desactívalo en desarrollo o implementa App Check.

### 6. Dispositivo

- Google Play Services actualizado
- Evitar emuladores sin Google Play
- En Xiaomi/MIUI, asegurar que la app tenga acceso a servicios de Google

## Verificación rápida

1. Agregar SHA-256 en Firebase (si falta).
2. Habilitar Play Integrity API.
3. Registrar `+56 942255924` como teléfono de prueba con código `123456`.
4. Reinstalar la app (`flutter run` o build limpio).
5. Probar de nuevo el tab **Teléfono**.

## Email vs teléfono

El tab **Correo** no usa Play Integrity ni SMS. Si necesitas entrar ya, usa correo mientras ajustas la configuración Android.
