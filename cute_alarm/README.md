# Love Alarms 💕

A beautiful pink-and-pastel romantic alarm clock app built with Flutter,
using clean architecture, native Android exact alarms, and 200+ daily
romantic messages that never repeat until the full set has been used.

---

## ✨ Features

1. Daily / repeating / one-time alarms, set with a friendly time picker.
2. When an alarm rings, a **full-screen page** shows:
   - A romantic gradient background image (placeholder included, swap
     with your own photo any time).
   - Animated floating hearts.
   - A random romantic message, picked from 200 built-ins + any custom
     ones you add — no repeats until the whole pool has cycled through.
   - Live clock + full date display.
3. A custom alarm sound — pick from **5 bundled tones** in a sound picker
   (with live tap-to-preview), or swap any of the bundled `.mp3` files
   for your own.
4. **Snooze** and **Dismiss** buttons on the ringing screen.
5. Messages persist their "used" state locally, so the no-repeat logic
   survives app restarts.
6. Pink/pastel Material 3 theme with smooth animations throughout.
7. Messages are stored locally as JSON (`assets/data/messages_seed.json`
   for the 200 built-ins + a SharedPreferences-backed JSON list for your
   custom ones).
8. A dedicated **Messages** screen to add, edit, and delete custom
   romantic messages.
9. Everything (alarms, custom messages, used-message tracking) is
   persisted locally via `shared_preferences` — no backend required.
10. Builds to a real installable Android APK (see below — this is the
    one step you'll run yourself, since I can't execute Android Gradle
    builds in this environment).

---

## 🏗 Architecture

Clean Architecture, three layers:

```
lib/
  domain/          # Pure Dart — entities, repository interfaces, use cases.
                    # No Flutter, no platform code. Fully unit-testable.
  data/            # Implements domain repositories using SharedPreferences
                    # + a MethodChannel bridge to native Android code.
  presentation/    # Flutter UI — BLoC for the alarm list, simple
                    # StatefulWidgets elsewhere where BLoC would be overkill.
```

**Why alarms need native code, not just a Dart timer:** Dart code (and the
whole Flutter engine) can be killed by Android at any time once your app
isn't in the foreground. A real alarm clock must keep ringing even if the
app was swiped away or the phone was rebooted. So the actual scheduling
uses Android's `AlarmManager` (via a Kotlin `MethodChannel` plugin), with
a `BroadcastReceiver` that fires independently of Dart, starts a
foreground `Service` to play sound/vibration, and launches the app's
Activity with "show over lock screen" flags. Dart is only responsible for
*requesting* the schedule and for rendering the pretty ringing UI once the
Activity is showing.

```
android/app/src/main/kotlin/.../romantic_alarm/
  AlarmSchedulerPlugin.kt   # MethodChannel <-> Dart bridge
  AlarmScheduler.kt         # Arms/cancels AlarmManager exact alarms
  AlarmReceiver.kt          # BroadcastReceiver fired when an alarm hits
  AlarmRingingService.kt    # Foreground service: plays sound + vibration
  NativeAlarmStore.kt       # Native SharedPreferences mirror of alarms,
                            # read by BootReceiver without needing Dart
  BootReceiver.kt           # Re-arms every alarm after device reboot
  MainActivity.kt           # Single Activity; applies lock-screen flags
                            # when launched from an alarm
```

### No-repeat message algorithm

`MessageLocalDataSource` keeps:
- the 200 built-in messages as a read-only JSON asset,
- your custom messages as their own JSON list in SharedPreferences,
- a `Set<String>` of "used" message IDs,
- the date + ID of whatever message was last shown.

Each day, it picks a new uniformly-random message from whichever ones
*haven't* been used yet (built-in + custom combined). Once every message
in the pool has been shown, the used-set resets and the cycle starts over
— so you'll see all 200(+) before any repeat. Asking for "today's message"
multiple times on the same calendar day always returns the same one.

---

## 🚀 Running it yourself

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.19+)
- Android Studio **or** just the Android command-line SDK tools
- A physical Android device or emulator (Android 6.0 / API 23+)

### 1. Get dependencies
```bash
cd romantic_alarm
flutter pub get
```

### 2. Point Gradle at your SDKs
Edit `android/local.properties` (already present as a template) and set
real paths:
```properties
sdk.dir=/Users/you/Library/Android/sdk
flutter.sdk=/Users/you/flutter
```

### 3. Regenerate the Gradle wrapper jar (one-time)
This project includes `gradlew` / `gradlew.bat` scripts, but **not** the
binary `gradle-wrapper.jar` (binaries aren't something I can produce in
this environment). Generate it once with your local Flutter/Gradle:
```bash
cd android
gradle wrapper --gradle-version 8.6
```
*(If you don't have a standalone `gradle` install, simply open the
`android/` folder in Android Studio once — it will regenerate the wrapper
automatically — then close it and use the CLI from then on.)*

### 4. Run on a connected device/emulator
```bash
flutter run
```

### 5. Build the release APK
```bash
flutter build apk --release
```
The APK will be at:
```
build/app/outputs/flutter-apk/app-release.apk
```
Install it with:
```bash
flutter install
# or
adb install build/app/outputs/flutter-apk/app-release.apk
```

> **Signing note:** the included `android/app/build.gradle` signs release
> builds with the **debug** keystore purely so `flutter build apk` works
> out of the box for testing. Before publishing anywhere, create your own
> upload keystore and signing config — see
> [Flutter's signing guide](https://docs.flutter.dev/deployment/android#signing-the-app).

---

## 🎨 Swapping in your own assets

- **Background image:** replace
  `assets/images/romantic_background.jpg` with any photo (portrait
  orientation works best). No code changes needed.
- **Alarm sound:** five bundled tones live in `assets/sounds/` and are
  listed in `lib/core/constants/sound_catalog.dart`. To add your own:
  drop a new `.mp3` into `assets/sounds/`, then add a `SoundOption` entry
  pointing at it in `sound_catalog.dart` — it'll automatically show up in
  the in-app sound picker (alarm editor → Options → Alarm sound) with
  live preview. To replace an existing tone instead, just overwrite its
  `.mp3` file with the same filename — no code changes needed.
- **App icon:** the placeholder pink-heart icons live in
  `android/app/src/main/res/mipmap-*/ic_launcher.png`. Easiest way to
  replace them properly (adaptive icons, etc.) is the
  [`flutter_launcher_icons`](https://pub.dev/packages/flutter_launcher_icons)
  package.

---

## 🔐 Android permissions explained

| Permission | Why |
|---|---|
| `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM` | Lets the alarm fire at the *exact* minute you set, not "sometime nearby" |
| `RECEIVE_BOOT_COMPLETED` | Re-arms your alarms after the phone restarts |
| `USE_FULL_SCREEN_INTENT`, `DISABLE_KEYGUARD`, `WAKE_LOCK` | Lets the ringing screen appear over the lock screen and wake the device |
| `FOREGROUND_SERVICE*` | Keeps alarm sound playing reliably |
| `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` | Prevents aggressive OEM battery savers from killing the alarm |
| `POST_NOTIFICATIONS` | Required on Android 13+ to show the ringing notification |

The app proactively asks for the exact-alarm and battery-optimization
exemptions on first launch (`NativeAlarmScheduler.ensureExactAlarmPermission`
/ `requestIgnoreBatteryOptimizations` in `main.dart`).

---

## 🧪 Tests

```bash
flutter test
```
`test/alarm_entity_test.dart` covers the pure-Dart "next trigger time"
logic for one-time, daily, and custom-weekday alarms.

---

## 📌 What I could and couldn't do here

I (Claude) wrote 100% of the Dart and Kotlin source, the Gradle config,
the AndroidManifest, generated placeholder art/audio assets, and verified
the message-generation logic produces exactly 200 unique strings. What I
*can't* do from this sandbox is run the actual Android SDK / Gradle build
to produce a signed `.apk` file — that toolchain isn't available here, and
there's no path to install it. Steps 1–5 above are the exact commands to
go from this source to an installed app on your phone, typically a 5–10
minute process once Flutter + Android SDK are set up.
