# Rashan Survey App — Household Survey + GPS + Camera + PIN Lock

## What's in this step

A working Flutter app with:
- A PIN lock on app startup (first launch: set a 4-6 digit PIN; every launch
  after that: enter it to get in). The PIN is stored as a SHA-256 hash, never
  as plain text. This is a real protection against casual access if a phone
  is lost or picked up — it is **not** full database encryption yet (the
  SQLite file itself isn't encrypted). That, plus individual surveyor
  logins, is a good next step once we build cloud sync.
- A home screen listing every household surveyed so far, with a photo
  thumbnail and GPS status per entry.
- A "New Survey" form covering:
  - **Section 1: Identification & Composition** (surveyor name, head of
    household, CNIC, phone, address, family size, children under 18,
    elderly 60+, notes).
  - **Section 2: Location & Photo** — a real GPS capture button (using the
    phone's actual location hardware, with proper permission handling) and
    a real camera capture button that saves the photo permanently on-device.
- Form validation (required fields, valid 13-digit CNIC).
- A duplicate-CNIC check that warns you before saving a second entry for
  the same household.
- Everything is saved **locally on the device** in a SQLite database, so it
  works fully offline in the field. No server, no account, no subscription
  needed for this step.

## What's next (future steps — just ask, one at a time or in a batch)

- Livelihood questions (income sources, skills, existing assets).
- Voice-interview recording.
- The auto + manual scoring engine (score out of 100).
- The delivery-confirmation screen (photo, GPS, timestamp captured
  invisibly; signature/thumbprint).
- Full database encryption at rest, and individual surveyor accounts once
  we add server sync.
- Syncing the local database to a shared server so multiple surveyors' and
  the executive committee's phones stay in sync.

## Project structure

```
rashan_app/
  pubspec.yaml
  codemagic.yaml                        # Codemagic build config (Android only)
  .github/workflows/build.yml           # GitHub Actions build config (Android only)
  android/                              # native Android project (Gradle, manifest, icons)
  lib/
    main.dart                           # app entry point + PIN-lock startup gate
    models/household.dart               # the Household data model
    db/database_helper.dart             # SQLite read/write logic + schema migrations
    services/auth_service.dart          # PIN hashing/storage/verification
    screens/pin_setup_screen.dart       # first-run: choose a PIN
    screens/pin_entry_screen.dart       # every other run: enter the PIN
    screens/survey_screen.dart          # the survey form (with GPS + camera)
    screens/household_list_screen.dart  # home screen / list of households
```

## A note on testing

I don't have the Flutter SDK available in the environment I write code in, so
I couldn't compile-test this myself. I've written it carefully against
standard Flutter/Dart syntax, but if `flutter pub get` or `flutter run` throws
an error on your machine, paste it back to me and I'll fix it right away.

**Update:** the first version of this project only contained the Dart code
(`lib/` and `pubspec.yaml`) — it was missing the native Android project
(the `android/` folder: Gradle build files, manifest, launcher icons) that a
real installable app also needs, which is why Codemagic couldn't find
anything to build. That's now included. There's still no `ios/` folder,
since you only need Android — Codemagic will just skip iOS, which is
expected and fine.

---

## How to compile this app (all free, no subscriptions)

### 1. Install the Flutter SDK
Go to the official site and download the SDK for your OS (Windows/Mac/Linux):
`https://docs.flutter.dev/get-started/install`
Extract it somewhere permanent (e.g. `C:\src\flutter` on Windows, or
`~/flutter` on Mac/Linux), then add its `bin` folder to your system PATH.

### 2. Install Android Studio
Free download: `https://developer.android.com/studio`
You need this even if you don't write any code in it — it installs the
Android SDK and lets you accept the Android licenses and run an emulator.
After installing, open a terminal and run:
```
flutter doctor --android-licenses
```
and accept all the licenses (type `y` each time).

### 3. Check your setup
```
flutter doctor
```
This tells you what's missing. Fix any red ✗ items it lists (it usually
tells you exactly what command to run).

### 4. Install a code editor (recommended: VS Code)
Free download: `https://code.visualstudio.com`
Install the "Flutter" extension from the Extensions panel — it also pulls in
the Dart extension automatically. This gives you syntax highlighting, error
checking, and a "Run" button, but isn't strictly required — everything below
also works from a plain terminal.

### 5. Get the project running
- Unzip the project I've attached.
- Open a terminal inside the `rashan_app` folder.
- Run:
  ```
  flutter pub get
  ```
  This downloads the two small packages the app depends on (`sqflite`, `path`).

### 6. Connect a device to test on
The easiest option is a real Android phone:
- On the phone: Settings → About phone → tap "Build number" 7 times to enable
  Developer Options → go back → Developer Options → enable "USB debugging".
- Plug the phone into your computer via USB.
- Run:
  ```
  flutter devices
  ```
  Your phone should show up in the list.

(Alternatively, open Android Studio → Device Manager → create and start a
virtual Android emulator, and `flutter devices` will show that instead.)

### 7. Run the app
```
flutter run
```
This builds the app and installs it on your connected device/emulator. The
first run takes a few minutes; after that, changes reload almost instantly.

### 8. Build a real, installable APK
Once you're happy with it:
```
flutter build apk --release
```
The finished file appears at:
```
build/app/outputs/flutter-apk/app-release.apk
```
Copy that file to any Android phone (via USB cable, Google Drive, WhatsApp,
email — whatever's easiest) and open it to install. Android will warn about
"unknown sources" the first time — that's expected for an app installed
outside the Play Store; enable "Install unknown apps" for whichever app you
used to transfer the file, and proceed.

**No Play Store account or subscription is needed for this** — since this
app is only for your own survey/delivery staff, you can hand them the APK
file directly instead of publishing it anywhere.
