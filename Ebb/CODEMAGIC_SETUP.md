# Codemagic setup

Codemagic builds the Ebb iOS app on branch **`main`**. Two workflows in [`codemagic.yaml`](../codemagic.yaml) at the repo root:

| Workflow | Trigger | What it does |
|----------|---------|--------------|
| **Ebb — Unit tests** | Push or PR to `main` (when `Ebb/**` changes) | `fastlane test` on iOS Simulator — no signing, no Apple credentials |
| **Ebb — Ad Hoc (install on device)** | Manual start in Codemagic UI | Signed `.ipa` artifact for direct install on registered iPhones |

PRs and pushes run unit tests only. Start the Ad Hoc workflow when you want a build to install on your iPhone.

**No App Store Connect API key is required.** Codemagic does not upload to TestFlight in this setup.

## 1. Add the app in Codemagic

1. Sign in at [codemagic.io](https://codemagic.io) and click **Add application**.
2. Connect GitHub repository **`brunabaudel/ebb`**.
3. When asked for configuration, choose **codemagic.yaml** (not the Workflow Editor).
4. Select branch **`main`** and click **Check for configuration file** — Codemagic should detect `codemagic.yaml`.

## 2. Code signing (required for iPhone install)

An unsigned build **cannot** be installed on a physical iPhone. You must upload signing files in Codemagic before the Ad Hoc workflow can succeed.

### What you need

| File | Where to get it |
|------|-----------------|
| **Apple Distribution** certificate (`.p12`) | [Apple Developer → Certificates](https://developer.apple.com/account/resources/certificates/list) — create or export an **Apple Distribution** cert and its private key as PKCS#12 |
| **Ad Hoc** provisioning profile (`.mobileprovision`) | [Apple Developer → Profiles](https://developer.apple.com/account/resources/profiles/list) — create an **Ad Hoc** profile for App ID **`com.bcbs.ebb`** that includes your iPhone's UDID |

### Register your iPhone

1. Find your device UDID (Finder → select iPhone → click the serial number until UDID appears, or Xcode → Window → Devices and Simulators).
2. Add the UDID under [Apple Developer → Devices](https://developer.apple.com/account/resources/devices/list).
3. Edit or recreate the Ad Hoc profile so it includes that device, then download the updated `.mobileprovision`.

### Upload to Codemagic

1. Open **Team settings → codemagic.yaml settings → Code signing identities**.
2. Under **iOS certificates**, upload your `.p12` Distribution certificate (with its password).
3. Under **iOS provisioning profiles**, upload the Ad Hoc profile for **`com.bcbs.ebb`**.

The workflow declares:

```yaml
ios_signing:
  distribution_type: ad_hoc
  bundle_identifier: com.bcbs.ebb
```

Codemagic fetches matching uploaded certificate and profile files during the build. If either is missing, the Ad Hoc workflow fails — there is no fallback to unsigned output.

## 3. How the device build works

1. You start **Ebb — Ad Hoc (install on device)** manually in the Codemagic UI.
2. Codemagic installs the uploaded certificate and Ad Hoc profile on the build machine.
3. `xcode-project use-profiles` applies them to the Xcode project.
4. `fastlane adhoc` archives and exports a signed `.ipa` as a build artifact.
5. Download the `.ipa` and install it on your iPhone via **Finder** (drag to the device) or **Apple Configurator**.

Build numbers use Codemagic's `BUILD_NUMBER`.

## 4. One-time: iCloud container for CloudKit sync

Phase 8 adds CloudKit backup. The Ad Hoc profile must include container `iCloud.com.bcbs.ebb` (matching `Ebb/Ebb.entitlements` and `Ebb/EbbRelease.entitlements`).

1. Open [Apple Developer → Identifiers](https://developer.apple.com/account/resources/identifiers/list)
2. If missing, click **+** → **iCloud Containers** → create identifier **`iCloud.com.bcbs.ebb`**
3. Open App ID **`com.bcbs.ebb`** → enable **iCloud** → choose **Include CloudKit support**
4. Click **Configure** (or **Edit**) next to iCloud → check **`iCloud.com.bcbs.ebb`** → **Save**
5. On the same App ID, enable **Push Notifications** (required for CloudKit sync uploads)
6. Regenerate and re-upload the Ad Hoc provisioning profile in Codemagic so it includes the updated capabilities.

Push Notifications only needs the **capability enabled** on the App ID. You do **not** need to create an APNs SSL certificate or Auth Key — CloudKit sends silent pushes through Apple's servers.

## 5. One-time: deploy CloudKit schema to Production

Release builds (`EbbRelease.entitlements`) use the **Production** CloudKit environment. Production does **not** inherit your Development schema automatically — you must deploy it once (and again after model changes).

Debug builds (`Ebb.entitlements`) use **Development**; Release/Ad Hoc builds use **Production** with `aps-environment=production`.

1. Connect an iPhone and run Ebb from **Xcode** (Debug — not Ad Hoc, not Simulator).
2. Sign in to iCloud on the device, open Ebb, and **save one symptom log**.
3. Open [CloudKit Console](https://icloud.developer.apple.com/) → container **`iCloud.com.bcbs.ebb`** → **Development** → **Schema**.
4. Confirm record types such as **`CD_SymptomEntry`** appear (not just `Users`).
5. In the left sidebar, click **Deploy Schema Changes…** → deploy to **Production**.
6. Verify **Production → Schema** shows the same record types.
7. Install the latest Ad Hoc build, add a log on Wi‑Fi, and confirm **Production → Data** shows records in zone `com.apple.coredata.cloudkit.zone`.

After app updates that change the SwiftData model, run Ebb once from **Xcode on a device** (Debug), save a log, then **Deploy Schema Changes…** to Production again so fields such as `CD_iCloudExportToken` exist server-side.

## 6. Webhook (if builds do not start automatically)

For GitHub repos connected over HTTPS, Codemagic usually installs the webhook automatically. If pushes to `main` do not trigger builds:

1. Open the app in Codemagic → **Webhooks**
2. Click **Update webhook** (team admin who added the repo)

## 7. First build

**Unit tests**

Push a commit touching `Ebb/**` on branch **`main`**, or open a PR — **Ebb — Unit tests** runs automatically.

**Install on iPhone**

1. Complete step 2 (upload Distribution certificate + Ad Hoc profile with your device UDID).
2. Start **Ebb — Ad Hoc (install on device)** manually in Codemagic.
3. Download the `.ipa` from build artifacts (or the email link).
4. Connect your iPhone and install via Finder or Apple Configurator.

Without the signing files from step 2, the workflow cannot produce an installable build.

## Troubleshooting

| Error | Fix |
|-------|-----|
| `No workflows configured` on PR | Ensure `codemagic.yaml` exists on the **PR source branch** |
| Code signing / provisioning profile errors | Upload an Apple Distribution `.p12` and an Ad Hoc `.mobileprovision` for `com.bcbs.ebb` in Code signing identities |
| Ad Hoc install fails on device | Ensure the device UDID is registered and included in the Ad Hoc profile; re-upload the updated profile to Codemagic and re-run the workflow |
| iCloud / HealthKit profile errors | Complete the iCloud container steps above; regenerate the Ad Hoc profile and re-upload it |
| `doesn't match the entitlements file's value for the com.apple.developer.icloud-container-identifiers entitlement` | Associate container `iCloud.com.bcbs.ebb` with App ID `com.bcbs.ebb` in Apple Developer, then regenerate the profile |
| Certificate limit reached | Apple allows at most three Apple Distribution certificates — revoke an unused one in the Developer portal |
