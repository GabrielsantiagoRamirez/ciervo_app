# Google Maps API Key (Android + iOS)

Configuración para `google_maps_flutter` en la geocerca de **Ciervo Kids** (`KidGeofencePage`).

La key de **Firebase** (`google-services.json` / `GoogleService-Info.plist`) es independiente. No la modifiques aquí.

## APIs requeridas en Google Cloud

- Maps SDK for Android
- Maps SDK for iOS
- Geocoding API (backend / futuras features)
- Places API / Directions API (si aplica)

Restringe la key por app (package name + SHA-1 en Android, bundle ID en iOS).

---

## Android

1. Copia `android/local.properties.example` → `android/local.properties` (si aún no existe).
2. Añade tu key:

```properties
GOOGLE_MAPS_API_KEY=TU_API_KEY
```

3. `AndroidManifest.xml` ya incluye:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="${GOOGLE_MAPS_API_KEY}" />
```

4. `android/app/build.gradle.kts` resuelve la key en este orden:
   - `android/local.properties` (desarrollo local, **no versionado**)
   - `android/gradle.properties` o `-PGOOGLE_MAPS_API_KEY=...` (CI/CD)

**CI/CD:** inyecta la variable en `gradle.properties` o pásala al build:

```bash
./gradlew assembleRelease -PGOOGLE_MAPS_API_KEY=$GOOGLE_MAPS_API_KEY
```

---

## iOS

1. Copia `ios/Flutter/Secrets.xcconfig.example` → `ios/Flutter/Secrets.xcconfig`.
2. Define:

```
GOOGLE_MAPS_API_KEY=TU_API_KEY
```

3. `Debug.xcconfig` / `Release.xcconfig` incluyen `#include? "Secrets.xcconfig"`.
4. `Info.plist` expone `GMSApiKey` → `$(GOOGLE_MAPS_API_KEY)`.
5. `AppDelegate.swift` lee `GMSApiKey` del bundle y llama `GMSServices.provideAPIKey` (sin hardcode en Swift).

`ios/Flutter/Secrets.xcconfig` está en `.gitignore`.

**CI/CD:** genera `Secrets.xcconfig` en el pipeline antes de `flutter build ios`.

---

## Validación local

```bash
flutter clean
flutter pub get
flutter run
```

Abre **Ciervo Kids → Reglas parentales → Geocerca** y confirma que el mapa carga (no pantalla gris/en blanco).

### Android: verificar que Gradle inyectó la key

```bash
cd android
./gradlew :app:processDebugMainManifest
```

En `android/app/build/intermediates/merged_manifest/debug/processDebugMainManifest/AndroidManifest.xml` debe aparecer `com.google.android.geo.API_KEY` con tu key (no `${GOOGLE_MAPS_API_KEY}` literal).

---

## Seguridad

- No subas keys reales en Dart ni en archivos versionados.
- Usa restricciones de API key en Google Cloud Console.
- Rota la key si se expone accidentalmente en un commit.
