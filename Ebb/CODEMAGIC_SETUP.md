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

Add **one** Admin or App Manager API key under Codemagic Team settings. Fastlane uses it to create/fetch distribution certificates and provisioning profiles — you do **not** need to upload a `.p12`, set `BUILD_CERTIFICATE_BASE64`, `P12_PASSWORD`, or `KEYCHAIN_PASSWORD`, and you do **not** need a separate environment-variable group for the API key.

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

Fastlane reads these directly (`app_store_connect_api_key`, `cert`, `sigh`, `upload_to_testflight`). No GitHub secrets transfer is required for Codemagic.

> **Add this key before your first signed build.** Until the integration exists, TestFlight and Ad Hoc workflows will fail with a missing-credentials error.

## 3. How signing works

Fastlane lanes in [`fastlane/Fastfile`](fastlane/Fastfile):

1. **`setup_ci`** — temporary keychain on the build machine
2. **`cert`** — create or reuse an Apple Distribution certificate via the API
3. **`sigh`** — create or refresh the provisioning profile (App Store or Ad Hoc)
4. **`build_app`** — archive and export a signed IPA
5. **`upload_to_testflight`** (TestFlight lane only)

Existing Ruby scripts under `ci/` still run for bundle-ID registration, beta-group setup, and entitlement verification — they share the same API key file that Fastlane writes at build time.

### Certificate limit

Apple allows at most **three** Apple Distribution certificates per account. If Fastlane reports that the limit is reached, revoke an unused distribution certificate in [Apple Developer → Certificates](https://developer.apple.com/account/resources/certificates/list) and re-run the build. The GitHub Actions pipeline may still use its own uploaded `.p12`; Codemagic/Fastlane manages signing independently.

### Optional future work: fastlane match

For teams that want one shared certificate store across GitHub Actions and Codemagic, [fastlane match](https://docs.fastlane.tools/actions/match/) can sync certs/profiles through an encrypted git repo. That is **not** required for Codemagic — document and adopt only if you create a dedicated match repository.

## 4. Webhook (if builds do not start automatically)

For GitHub repos connected over HTTPS, Codemagic usually installs the webhook automatically. If pushes to `main` do not trigger builds:

1. Open the app in Codemagic → **Webhooks**
2. Click **Update webhook** (team admin who added the repo)

## 5. First build

**TestFlight**

1. Complete step 2 (API key integration).
2. Push a commit touching `Ebb/**` on branch **`main`**, or start **Ebb — TestFlight** manually from the Codemagic UI.
3. Wait ~10–15 minutes after upload, then open **TestFlight** on your iPhone and install **Ebbie**.

**Ad hoc (direct install)**

1. Register your iPhone UDID in the Apple Developer portal.
2. Start **Ebb — Ad Hoc (install on device)** manually in Codemagic. Fastlane creates/refreshes an Ad Hoc profile that includes registered devices.
3. Download the `.ipa` from build artifacts (or the email link) and install via Finder or Apple Configurator.

Build numbers use Codemagic's `BUILD_NUMBER` (same idea as GitHub's `run_number`).

## GitHub Actions vs Codemagic

Both can deploy the same app:

- **GitHub Actions** — `.github/workflows/testflight.yml`, secrets in GitHub (unchanged)
- **Codemagic** — `codemagic.yaml` + Fastlane, **one** API key in Codemagic Team integrations

You can run either or both. Codemagic does not require copying GitHub signing secrets.

## Troubleshooting

| Error | Fix |
|-------|-----|
| `No workflows configured` on PR | Ensure `codemagic.yaml` exists on the **PR source branch** |
| Missing App Store Connect API credentials | Add the **`ebb`** Team integration (step 2) |
| Integration name mismatch | Rename the Codemagic API key to **`ebb`** or update `integrations.app_store_connect` in `codemagic.yaml` |
| Distribution certificate limit reached | Revoke an unused IOS_DISTRIBUTION cert in Apple Developer portal |
| iCloud / HealthKit profile errors | Same fixes as [TESTFLIGHT_SETUP.md](TESTFLIGHT_SETUP.md) — Fastlane `sigh` regenerates the profile on the next run |
| `No App Store Connect app found` | App record **Ebbie** must exist (one-time browser step, already done) |
| Ad Hoc install fails on device | Ensure the device UDID is registered; re-run the ad hoc workflow so `sigh` refreshes the profile |

See also [TESTFLIGHT_SETUP.md](TESTFLIGHT_SETUP.md) for Apple Developer portal steps and beta group details.
