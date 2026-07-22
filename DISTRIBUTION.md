# Distribution & Updates

How SplitLLM ships to users and how updates reach them. There are three
independent mechanisms; use them together.

| Mechanism | What it updates | Reaches users | Needs |
| --- | --- | --- | --- |
| **In-app update prompt** (built in) | Tells users a new build exists and links them to it | Everywhere (Android/iOS) | Nothing — already wired |
| **Shorebird code push** | Dart code, over the air, no reinstall | Everywhere the app is installed | Shorebird account |
| **Play internal testing** | Full APK/AAB via the store | Android testers/public | Play Console ($25 one-time) |

Web needs none of this: redeploying to Catalyst updates every user on their next
load.

---

## 1. In-app "update available" prompt (already built)

On launch, the app calls `GET /version` on the backend and compares the running
build to what the backend reports:

- running version **< `minSupported`** → a **blocking "Update required"** dialog
  (user can't proceed without updating).
- running version **< `latest`** → a **dismissible "Update available"** banner.
- otherwise → nothing.

The button opens the platform's `android.url` / `ios.url`. Implemented in
`lib/core/services/update_service.dart`, invoked once per session from the app
shell. It's a no-op on web and silently skips if the check fails.

### Bumping the version users are told about

The backend serves this from a Mongo doc (`app_config` / `_id: "app_version"`)
with fallback to `APP_*` env vars. Change it **without a redeploy** via the admin
endpoint:

```bash
curl -X PUT "$API/db/admin/app-version" \
  -H "Authorization: Bearer $ADMIN_JWT" \
  -H "Content-Type: application/json" \
  -d '{
        "latest": "1.1.0",
        "latestBuild": 3,
        "minSupported": "1.0.0",
        "android": {"url": "https://github.com/<owner>/<repo>/releases/latest/download/app-release.apk"},
        "ios": {"url": "https://apps.apple.com/app/idXXXXXXXXX"},
        "notes": "Faster balances and bug fixes."
      }'
```

Set `minSupported` equal to `latest` only when you must force everyone off an old
build (e.g. a breaking API change).

---

## 2. Release flow (full binary)

1. Bump `version:` in `pubspec.yaml` (e.g. `1.1.0+3` — name`+`build).
2. Commit, then tag and push:
   ```bash
   git tag v1.1.0 && git push origin v1.1.0
   ```
3. CI (`.github/workflows/deploy.yml` → `release-android`) builds the release APK
   and attaches it to a GitHub Release. Stable URL:
   `https://github.com/<owner>/<repo>/releases/latest/download/app-release.apk`
4. Point `android.url` at that URL via the admin call above.

> **Signing:** release builds fall back to the **debug** key unless
> `android/key.properties` exists (see `key.properties.example`). Debug-signed
> APKs are fine for direct installs but the **Play Store rejects them** — create
> an upload keystore before publishing to Play.

---

## 3. Shorebird — over-the-air Dart hot patches

Fixes a Dart bug on installed apps in minutes, no store round-trip, no reinstall.
Cannot change native code, plugins, or dependencies — those still need a release
(section 2).

**One-time setup** (needs your Shorebird login; not doable in CI without a token):

```bash
dart pub global activate shorebird_cli
shorebird login
shorebird init          # generates shorebird.yaml with your app_id — commit it
```

**Ship a release, then patch it:**

```bash
# Cut a Shorebird release (do this instead of `flutter build` for shippable builds)
shorebird release android
# Later, hot-fix that release's Dart code:
shorebird patch android
```

Wire it into CI by adding a `shorebirdtech/setup-shorebird` step and calling
`shorebird release` on tags (store `SHOREBIRD_TOKEN` as a secret). iOS is
`shorebird release ios` / `patch ios`. Free tier covers small userbases.

---

## 4. Google Play (Android store channel)

1. Create an app in the **Play Console** ($25 one-time), set up an **internal
   testing** track (fastest review, invite testers by email).
2. Build an **AAB** with a real keystore: `flutter build appbundle --release`.
3. Upload to the internal track; testers get it (and future updates) from Play.
4. Promote internal → closed → production when ready.

**Optional native prompt:** add the `in_app_update` package to trigger Play's own
"update available" flow (flexible or immediate). It only works once the app is
installed from Play, so gate it to `defaultTargetPlatform == TargetPlatform.android`
and treat it as a complement to the in-app prompt in section 1, not a replacement.

---

## 5. iOS distribution & testing

- **TestFlight / App Store:** requires the **Apple Developer Program ($99/yr)**.
  Archive from Xcode (`ios/Runner.xcworkspace`) and upload; TestFlight then
  handles tester invites and updates.
- **Free on-device testing:** a personal Apple ID works via Xcode automatic
  signing — pick a **unique** bundle id (the placeholder `com.splitllm.app` may be
  taken), select your personal team, run on the device. Apps expire after 7 days
  and must be reinstalled; max 3 sideloaded apps.
- **Simulator testing:** Claude Code Desktop's iOS Simulator pane runs this
  Flutter app in a simulator — it needs full **Xcode + an iOS runtime** installed
  (Command Line Tools alone isn't enough). It drives simulators only, never a
  physical device.
