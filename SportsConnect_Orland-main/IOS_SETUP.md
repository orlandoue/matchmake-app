# iOS — Puesta a punto y compilación (Matchmake)

Estado y pasos para dejar la app lista para **correr en dispositivo iOS** y
**compilar/subir a App Store / TestFlight**.

> ⚠️ **Restricción dura:** iOS **no se puede compilar en Windows**. Necesitas
> macOS + Xcode, o un CI con runner macOS (Codemagic / GitHub Actions
> `macos-latest` / Bitrise) o un Mac en la nube (MacStadium, MacinCloud).
> Todo lo de la sección **A** ya está hecho en el repo (Windows-friendly);
> las secciones **B–E** requieren Mac y/o tus credenciales.

---

## A. Ya configurado en el repo (hecho) ✅

- **Info.plist** (`ios/Runner/Info.plist`):
  - `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`,
    `NSLocationWhenInUseUsageDescription` (cámara/QR, galería, geolocalización).
  - `CFBundleURLTypes` con el scheme **`sportsconnect`** (deep link de retorno
    de Mercado Pago). Placeholder documentado para el reversed-client-id de
    Google Sign-In.
  - `LSApplicationQueriesSchemes` (mailto, tel, https, maps, comgooglemaps)
    para `url_launcher`.
  - `UIBackgroundModes = remote-notification` (OneSignal).
  - `ITSAppUsesNonExemptEncryption = false` (evita el prompt de export
    compliance en TestFlight).
  - `GMSApiKey = $(GOOGLE_MAPS_API_KEY)` (leído desde `Secrets.xcconfig`).
- **Google Maps key nativa**: `ios/Flutter/Secrets.xcconfig` (gitignored,
  con `.example`), inyectada vía `Debug/Release.xcconfig` → Info.plist →
  `AppDelegate.provideAPIKey`.
- **Podfile** (`ios/Podfile`): `platform :ios, '14.0'` + `post_install` que
  fuerza `IPHONEOS_DEPLOYMENT_TARGET = 14.0` en todos los pods.
- **Deployment target** del target Runner subido a **14.0** en el pbxproj
  (lo exigen `google_maps_flutter_ios` 2.15+ y OneSignal 5).
- `.env` se empaqueta como asset (funciona en iOS igual que Android).

---

## B. Requiere tus credenciales / cuentas (antes del build)

1. **Bundle Identifier real.** Hoy es `com.example.orlandSports` (inválido para
   la App Store). Cámbialo por tu dominio inverso, p. ej.
   `com.matchmake.app`, en Xcode → Runner → Signing & Capabilities (o
   `PRODUCT_BUNDLE_IDENTIFIER` en el pbxproj). Debe coincidir con el App ID de
   tu Apple Developer Portal.
2. **Apple Developer Program** (US$99/año). Sin esto no hay firma ni TestFlight.
3. **Signing (Team).** En Xcode, selecciona tu *Team*; con "Automatically
   manage signing" Xcode genera el provisioning profile.
4. **Google Sign-In en iOS:**
   - Crea un OAuth Client ID tipo **iOS** en Google Cloud (con el bundle id de
     arriba). Pon su valor en `.env` → `GOOGLE_IOS_CLIENT_ID`.
   - Añade su **REVERSED_CLIENT_ID** como segundo scheme en `CFBundleURLTypes`
     (ver el TODO en Info.plist).
   - En Supabase → Auth → Google, agrega ese client id a la lista permitida.
5. **OneSignal / APNs:** genera una **APNs Auth Key (.p8)** en el Apple
   Developer Portal y súbela al dashboard de OneSignal. Rota además la
   `ONESIGNAL_REST_API_KEY` (estuvo expuesta) y úsala **solo** desde la Edge
   Function `notify_onesignal`, nunca en la app.
6. **Mercado Pago (recordatorio):** ya está server-side; confirma que el
   webhook y las Edge Functions estén desplegados y el deep link
   `sportsconnect://payment/*` registrado en el panel de MP.

---

## C. Capabilities en Xcode (Mac)

En **Runner → Signing & Capabilities → + Capability**:
- **Push Notifications** (crea el entitlement `aps-environment`).
- **Background Modes** → *Remote notifications*.
- (Opcional, push con imágenes) *Notification Service Extension* para OneSignal.

---

## D. Build en Mac — primera vez

```bash
# En la carpeta del proyecto Flutter, en un Mac con Xcode + CocoaPods
flutter pub get
cd ios && pod install && cd ..
# Copiar el ejemplo y poner la key real de Maps
cp ios/Flutter/Secrets.xcconfig.example ios/Flutter/Secrets.xcconfig   # y editar
# Crear el .env con las credenciales (no está en git)
open ios/Runner.xcworkspace   # abrir SIEMPRE el .xcworkspace, no el .xcodeproj
```
- Selecciona un dispositivo/simulador y corre desde Xcode o `flutter run`.
- Para archivar: Xcode → Product → Archive → Distribute (App Store Connect),
  o `flutter build ipa --export-options-plist=...`.

## E. Alternativa sin Mac físico — CI (recomendado)

**Codemagic** o **GitHub Actions (`runs-on: macos-latest`)**:
- Sube los secretos (`.env`, `Secrets.xcconfig`, certificado de firma /
  API key de App Store Connect) como variables cifradas del CI.
- Pipeline: `flutter pub get` → `pod install` → `flutter build ipa` → subir a
  TestFlight con `app-store-connect` / fastlane `pilot`.
- Es la vía más barata si no tienes Mac.

---

## F. Checklist final antes de subir a la Store

- [ ] Bundle id real y único, versión/build (`version: x.y.z+n` en pubspec).
- [ ] Íconos de app iOS (`flutter_launcher_icons` ya configurado; corre
      `dart run flutter_launcher_icons`).
- [ ] LaunchScreen y nombre visible ("Matchmake") correctos.
- [ ] Todas las credenciales **rotadas** y fuera del código (ya en `.env` /
      `Secrets.xcconfig`).
- [ ] Probar en **dispositivo físico**: login Google, permisos (cámara/QR,
      ubicación, galería), push OneSignal, mapa, deep link de pago MP.
- [ ] Política de privacidad + *App Privacy* (recopila ubicación, cámara,
      email) en App Store Connect.
- [ ] `flutter analyze` limpio (0 errores) — ✔ actual.
