# Android Sideload Build (deploy_android)

Self-signed APK for the `music_collection` app. This isolates all Android
deliverables so the Vercel web deploy (`web/`, `vercel.json`, `build.sh`)
stays untouched.

## What's here
- `build_apk.bat` — one-command build that produces **both** release APKs:
  32-bit `armeabi-v7a` and 64-bit `arm64-v8a` (see ABIs below). Each build runs
  `--analyze-size`, **fails if the APK exceeds 75 MB** (size-regression guard),
  then copies the artifact(s) to `dist/`.
- `dist/` — final sideloadable APKs (git-ignored).
- `symbols/` — Dart/Flutter debug symbols for crash symbolication (git-ignored).

## ABIs (which APK to use)
The phone's CPU architecture decides which APK it can run. A build for the
*wrong* ABI **installs but crashes instantly on open** ("app won't open"),
because the native Flutter engine can't load.

- **armeabi-v7a** (32-bit) — older/entry phones. Example: Samsung Galaxy M11
  (SM-M115F) reports `ro.product.cpu.abi = armeabi-v7a`. **Use this one if your
  phone is 32-bit.**
- **arm64-v8a** (64-bit) — virtually all modern phones (report `arm64-v8a`).

Check your phone: `adb shell getprop ro.product.cpu.abi` (or Settings → About).
Then install the matching `dist/*.apk`.

## Build
```
deploy_android\build_apk.bat
```
Produces:
- `deploy_android\dist\music-collection-armeabi-v7a-release.apk` (≈18 MiB)
- `deploy_android\dist\music-collection-arm64-v8a-release.apk` (≈20 MiB)
(both well under the 75 MB target).

Prerequisites: Flutter stable (3.41.x), JDK 17, Android SDK 36
(`platforms;android-36`, `build-tools;36.0.0`, `platform-tools`),
SDK licenses accepted. Set `flutter config --android-sdk <SDK>`.

### Clone & build with your own Supabase credentials
No real credentials live in the repo (`.env` is git-ignored, `dist/` is
git-ignored), so the app needs yours before building:

1. Copy the local `.env.example` to `.env` and fill in your project:
   ```
   SUPABASE_URL=https://<your-project-ref>.supabase.co
   SUPABASE_PUBLISHABLE_KEY=sb_publishable_<your-key>
   ```
   (`SUPABASE_PUBLISHABLE_KEY` is the "publishable" key from your Supabase
   project → API keys. The app reads **only** the publishable key; the legacy
   `anon` key is no longer consumed — if your `.env` still has
   `SUPABASE_ANON_KEY`, leave it but add the publishable one.)
   The `.env` file is bundled into the APK as an asset, so it must exist and
   hold real values **before** you run the build.
2. Run `deploy_android\build_apk.bat` (it embeds the `.env` automatically).
   Alternatively you can pass the values as compile-time defines instead of a
   `.env`: `flutter build apk ... --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_PUBLISHABLE_KEY=...`.
3. If you are the project owner, add the OAuth return path (below).
4. Sideload the APK from `dist\` (see Sideload).

Note: if the app was previously crashing on launch ("app won't open"), that was
the missing `android.permission.INTERNET` in the release manifest — now declared
in `android/app/src/main/AndroidManifest.xml` and required for any networked
release build.

## Identity & signing
- Package id: `com.sathvik.musiccollection` (set in `android/app/build.gradle.kts`
  and `AndroidManifest.xml`).
- Release builds currently sign with the auto-generated debug keystore
  (`signingConfigs.getByName("debug")`) so `flutter run --release` works.
  For a permanent sideload key, generate a release keystore and set
  `signingConfigs.release` before shipping (self-signed is fine for sideloading;
  there is no Google Play involvement).

## OAuth deep link
- Custom scheme `musicdb://` registered in `android/app/src/main/AndroidManifest.xml`
  with host `login` and path prefix `/callback`.
- `lib/core/auth/auth_provider.dart` passes
  `redirectTo: 'musicdb://login/callback'` on Android so GitHub OAuth returns
  into the app.
- **Owner step (required once):** add `musicdb://login/callback` to the
  Supabase → Authentication → URL Configuration → Redirect URLs list.

## Sideload
1. Build the APK(s) (above).
2. Pick the APK matching the device ABI (see ABIs):
   `dist\music-collection-armeabi-v7a-release.apk` (32-bit) or
   `dist\music-collection-arm64-v8a-release.apk` (64-bit).
3. Transfer it to the device and install (allow "install unknown apps" for the
   file manager / browser). Uninstall any previously broken install first.
4. Complete GitHub OAuth through the returned `musicdb://` link.
5. Verify all 5 tabs against the same Supabase project; non-owner logins are
   denied server-side ("Access denied").

## App icon
Wired in and bundled. The icon is generated from a **user-supplied source image
kept out of the repo** (`assets/icon/app_icon.png`, git-ignored via
`.gitignore`):

- Android launcher mipmaps: `android/app/src/main/res/mipmap-*/ic_launcher.png`.
- Web icons: `web/icons/Icon-{192,512}.png` + `Icon-maskable-{192,512}.png`
  (referenced by `web/manifest.json`).

To replace the icon: drop the new image at `assets/icon/app_icon.png`, rebuild
the mipmaps + web icons (see the phase 7 icons step), then rebuild the APK.
