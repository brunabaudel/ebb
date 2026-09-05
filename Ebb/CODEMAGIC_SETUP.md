# Codemagic setup

Codemagic builds the Ebb iOS app on branch **`main`** using **Fastlane** and a single App Store Connect API key. Three workflows in [`codemagic.yaml`](../codemagic.yaml) at the repo root:

| Workflow | Trigger | What it does |
|----------|---------|--------------|
| **Ebb — Unit tests** | Push or PR to `main` (when `Ebb/**` changes) | `fastlane test` on iOS Simulator, no signing |
| **Ebb — TestFlight** | Push to `main` (when `Ebb/**` changes) | `fastlane beta` — cert/sigh via API, archive, upload to TestFlight, distribute to **Ebb Internal** |
| **Ebb — Ad Hoc (install on device)** | Manual start in Codemagic UI | `fastlane adhoc` — signed `.ipa` for direct install on registered devices |

PRs run unit tests only. Pushes run unit tests and TestFlight in parallel. Start the ad hoc workflow when you want a build to sideload onto a registered iPhone.

## 1. Add the app in Codemagic

1. Sign in at [codemagic.io](https://codemagic.io) and click **Add application**.
2. Connect GitHub repository **`brunabaudel/ebb`**.
3. When asked for configuration, choose **codemagic.yaml** (not the Workflow Editor).
4. Select branch **`main`** and click **Check for configuration file** — Codemagic should detect `codemagic.yaml`.

## 2. App Store Connect API key (the only credential)

Add **one** Admin or App Manager API key under Codemagic Team settings. Fastlane uses it to create/fetch distribution certificates and provisioning profiles — you do **not** need to upload a `.p12` or maintain separate signing secrets in GitHub.

| Field | Value |
|-------|-------|
| Key name in Codemagic | **`ebb`** (must match `integrations.app_store_connect` in `codemagic.yaml`) |
| Issuer ID | From App Store Connect → Users and Access → Integrations → App Store Connect API |
| Key ID | From the same page |
| `.p8` file | Download when creating the key (only available once) |

Steps: **Team settings → Team integrations → Developer Portal → Manage keys → Add key**.

Codemagic injects three environment variables into workflows that declare `integrations.app_store_connect: ebb`:

- `APP_STORE_CONNECT_KEY_IDENTIFIER`
- `APP_STORE_CONNECT_ISSUER_ID`
- `APP_STORE_CONNECT_PRIVATE_KEY`

Fastlane reads these directly (`app_store_connect_api_key`, `cert`, `sigh`, `upload_to_testflight`).

> **Add this key before your first signed build.** Until the integration exists, TestFlight and Ad Hoc workflows will fail with a missing-credentials error.

## 3. How signing works

Fastlane lanes in [`fastlane/Fastfile`](fastlane/Fastfile):

1. **`setup_ci`** — temporary keychain on the build machine
2. **`cert`** — create or reuse an Apple Distribution certificate via the API
3. **`sigh`** — create or refresh the provisioning profile (App Store or Ad Hoc)
4. **`build_app`** — archive and export a signed IPA
5. **`upload_to_testflight`** (TestFlight lane only)

Ruby scripts under `ci/` still run for bundle-ID registration, beta-group setup, and entitlement verification — they share the same API key file that Fastlane writes at build time.

### Certificate limit

Apple allows at most **three** Apple Distribution certificates per account. If Fastlane reports that the limit is reached, revoke an unused distribution certificate in [Apple Developer → Certificates](https://developer.apple.com/account/resources/certificates/list) and re-run the build.

## 4. One-time: iCloud container for CloudKit sync

Phase 8 adds CloudKit backup. The App Store profile must include container `iCloud.com.bcbs.ebb` (matching `Ebb/Ebb.entitlements` and `Ebb/EbbRelease.entitlements`).

1. Open [Apple Developer → Identifiers](https://developer.apple.com/account/resources/identifiers/list)
2. If missing, click **+** → **iCloud Containers** → create identifier **`iCloud.com.bcbs.ebb`**
3. Open App ID **`com.bcbs.ebb`** → enable **iCloud** → choose **Include CloudKit support**
4. Click **Configure** (or **Edit**) next to iCloud → check **`iCloud.com.bcbs.ebb`** → **Save**
5. On the same App ID, enable **Push Notifications** (required for CloudKit sync uploads)
6. Push to **`main`** or re-run **Ebb — TestFlight** in Codemagic. Fastlane `sigh` regenerates the App Store profile automatically.

CI enables the iCloud capability via API, but Apple still requires the container to be selected on the App ID in the developer portal (cannot be done via API key alone).

Push Notifications only needs the **capability enabled** on the App ID. You do **not** need to create an APNs SSL certificate or Auth Key — CloudKit sends silent pushes through Apple's servers.

## 5. One-time: deploy CloudKit schema to Production

TestFlight and App Store builds use the **Production** CloudKit environment. Production does **not** inherit your Development schema automatically — you must deploy it once (and again after model changes).

Debug builds (`Ebb.entitlements`) use **Development**; Release/TestFlight builds (`EbbRelease.entitlements`) use **Production** with `aps-environment=production`.

1. Connect an iPhone and run Ebb from **Xcode** (Debug — not TestFlight, not Simulator).
2. Sign in to iCloud on the device, open Ebb, and **save one symptom log**.
3. Open [CloudKit Console](https://icloud.developer.apple.com/) → container **`iCloud.com.bcbs.ebb`** → **Development** → **Schema**.
4. Confirm record types such as **`CD_SymptomEntry`** appear (not just `Users`).
5. In the left sidebar, click **Deploy Schema Changes…** → deploy to **Production**.
6. Verify **Production → Schema** shows the same record types.
7. Install the latest **TestFlight** build, add a log on Wi‑Fi, and confirm **Production → Data** shows records in zone `com.apple.coredata.cloudkit.zone`.

After app updates that change the SwiftData model, run Ebb once from **Xcode on a device** (Debug), save a log, then **Deploy Schema Changes…** to Production again so fields such as `CD_iCloudExportToken` exist server-side.

Every TestFlight build runs `ci/verify_release_entitlements.rb` to ensure `aps-environment` is `production` and the CloudKit container environment is `Production`.

## 6. One-time: App Store Connect app record (done)

The app record exists as **Ebbie** (the name "Ebb" was already taken on the App Store). The App Store Connect name is independent of the bundle ID and the on-device display name — CI matches builds by bundle ID only (`com.bcbs.ebb`).

App records cannot be created via the API, even with an Admin key — creating the app (name, SKU, bundle ID) is a one-time browser step.

## 7. Webhook (if builds do not start automatically)

For GitHub repos connected over HTTPS, Codemagic usually installs the webhook automatically. If pushes to `main` do not trigger builds:

1. Open the app in Codemagic → **Webhooks**
2. Click **Update webhook** (team admin who added the repo)

## 8. First build

**TestFlight**

1. Complete step 2 (API key integration).
2. Push a commit touching `Ebb/**` on branch **`main`**, or start **Ebb — TestFlight** manually from the Codemagic UI.
3. Wait ~10–15 minutes after upload, then open **TestFlight** on your iPhone and install **Ebbie**.

**Ad hoc (direct install)**

1. Register your iPhone UDID in the Apple Developer portal.
2. Start **Ebb — Ad Hoc (install on device)** manually in Codemagic. Fastlane creates/refreshes an Ad Hoc profile that includes registered devices.
3. Download the `.ipa` from build artifacts (or the email link) and install via Finder or Apple Configurator.

Build numbers use Codemagic's `BUILD_NUMBER`.

## Beta group

CI manages an **internal** TestFlight group named **Ebb Internal** — no App Store Connect access needed. `ci/create_beta_group.rb` (idempotent, runs on every `fastlane beta` deploy):

- creates the group with **access to all builds**, so every uploaded build is distributed to the group automatically once Apple finishes processing it — no Beta App Review, no per-build assignment
- adds `brubaudel@gmail.com` (the account owner) as a tester

The tester receives a TestFlight email invite on first run; after accepting it once, new builds just appear in the TestFlight app.

Internal groups only accept App Store Connect **team members**. To add more testers, add their email to the `TESTERS` list in `ci/create_beta_group.rb` — but they must first be invited to the ASC team (Users and Access), which requires the browser. For testers outside the team, an external group with a public link would be needed instead (first build then requires Beta App Review).

## Troubleshooting

| Error | Fix |
|-------|-----|
| `No workflows configured` on PR | Ensure `codemagic.yaml` exists on the **PR source branch** |
| Missing App Store Connect API credentials | Add the **`ebb`** Team integration (step 2) |
| Integration name mismatch | Rename the Codemagic API key to **`ebb`** or update `integrations.app_store_connect` in `codemagic.yaml` |
| Distribution certificate limit reached | Revoke an unused IOS_DISTRIBUTION cert in Apple Developer portal |
| iCloud / HealthKit profile errors | Complete the iCloud container steps above; re-run **Ebb — TestFlight** so `sigh` regenerates the profile |
| `doesn't match the entitlements file's value for the com.apple.developer.icloud-container-identifiers entitlement` | Associate container `iCloud.com.bcbs.ebb` with App ID `com.bcbs.ebb` in Apple Developer |
| `No App Store Connect app found` | App record **Ebbie** must exist (one-time browser step, already done) |
| Ad Hoc install fails on device | Ensure the device UDID is registered; re-run the ad hoc workflow so `sigh` refreshes the profile |
