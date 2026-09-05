---
name: testflight-ios-deploy
description: Deploy an iOS app to TestFlight and manage beta groups/testers through Codemagic, Fastlane, and the App Store Connect API. Use when setting up or debugging TestFlight uploads, beta groups, tester invites, code signing in Codemagic, or Spaceship/fastlane scripts for this repo.
---

# TestFlight deploy and beta group management via API

This repo ships the `Ebb` iOS app to TestFlight from **Codemagic** using **Fastlane**
and small Ruby scripts using Spaceship (the API client inside the `fastlane` gem).

## Working configuration

| Piece | Location |
|-------|----------|
| CI config | `codemagic.yaml` (workflows `ebb-unit-tests`, `ebb-testflight`, `ebb-adhoc-device`) |
| Fastlane lanes | `Ebb/fastlane/Fastfile` (`test`, `beta`, `adhoc`) |
| Setup guide | `Ebb/CODEMAGIC_SETUP.md` |
| Bundle ID registration | `Ebb/ci/register_bundle_id.rb` |
| App record existence check | `Ebb/ci/verify_app_store_connect_app.rb` |
| Beta group + testers | `Ebb/ci/create_beta_group.rb` |
| Entitlement verification | `Ebb/ci/verify_release_entitlements.rb` |
| Simulator destination | `Ebb/ci/resolve_simulator_destination.sh` |
| Capabilities helper | `Ebb/ci/bundle_capabilities.rb` |

Codemagic **Team integration** named **`ebb`** injects:

- `APP_STORE_CONNECT_KEY_IDENTIFIER`
- `APP_STORE_CONNECT_ISSUER_ID`
- `APP_STORE_CONNECT_PRIVATE_KEY`

Fastlane reads these for `cert`, `sigh`, and `upload_to_testflight`. Ruby scripts
expect `APPSTORE_*` env vars and a `.p8` file — Fastlane's `write_api_key_for_ruby_scripts`
helper bridges the two naming conventions at build time.

## `fastlane beta` pipeline order

1. Validate App Store Connect API credentials from Codemagic integration.
2. Write `.p8` key to `~/.appstoreconnect/private_keys/AuthKey_<KEY_ID>.p8` for Ruby scripts.
3. Register bundle ID (idempotent), verify ASC app record exists, create beta group.
4. `setup_ci` — temporary keychain on the build machine.
5. `cert` — create or reuse Apple Distribution certificate via API.
6. `sigh` — create/refresh App Store provisioning profile (`Ebb App Store CI`).
7. `increment_build_number` from Codemagic `BUILD_NUMBER`.
8. `build_app` — archive and export signed IPA.
9. `verify_release_entitlements.rb` — CloudKit production entitlements check.
10. `upload_to_testflight` — distribute to **Ebb Internal** group.

Auth boilerplate shared by Ruby scripts:

```ruby
require "spaceship"
Spaceship::ConnectAPI.token = Spaceship::ConnectAPI::Token.create(
  key_id: ENV.fetch("APPSTORE_API_KEY_ID"),
  issuer_id: ENV.fetch("APPSTORE_ISSUER_ID"),
  filepath: File.expand_path("~/.appstoreconnect/private_keys/AuthKey_#{ENV.fetch('APPSTORE_API_KEY_ID')}.p8")
)
```

## Hard-won API facts (verified against live runs, fastlane 2.236.1)

1. **App records cannot be created via the API**, even with an Admin key.
   Creating the app (name, SKU, bundle ID) is a one-time browser step. The
   ASC app name ("Ebbie") is independent of the bundle ID and display name;
   everything matches by bundle ID (`com.bcbs.ebb`).

2. **Spaceship's `App#create_beta_group` is broken for internal groups.**
   It always sends `publicLinkEnabled`/`publicLinkLimit*` attributes and Apple
   rejects them: "Public link limit cannot be applied to internal group".
   Post the request directly instead:

```ruby
body = {
  data: {
    type: "betaGroups",
    attributes: { name: GROUP_NAME, isInternalGroup: true, hasAccessToAllBuilds: true },
    relationships: { app: { data: { type: "apps", id: app.id } } }
  }
}
Spaceship::ConnectAPI.client.test_flight_request_client.post("v1/betaGroups", body)
```

3. **`BetaGroup#post_bulk_beta_tester_assignments` fails with API-key auth** —
   `/v1/bulkBetaTesterAssignments` is a private ASC-web endpoint ("The URL
   path is not valid"). Use the documented endpoint instead:

```ruby
Spaceship::ConnectAPI.post_beta_tester_assignment(
  beta_group_ids: [group.id],
  attributes: { email: "...", firstName: "...", lastName: "..." }
)
```

4. **Internal vs external groups.** Internal groups (`isInternalGroup: true`)
   skip Beta App Review, and with `hasAccessToAllBuilds: true` every uploaded
   build is distributed automatically — no per-build assignment. But testers
   must be ASC **team members** (inviting new team members requires the
   browser). External groups accept anyone and support public invite links
   (`publicLinkEnabled`), but the first build needs Beta App Review (hours to
   a day) and each build must be assigned via `Build#add_beta_groups`.

5. **Export compliance**: `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO`
   is set in `project.pbxproj`, so builds never get stuck on
   "Missing Compliance".

6. **App Store uploads require the current iOS SDK** — Codemagic uses `xcode: latest`
   on `mac_mini_m2` instances. Older Xcode versions get rejected by Apple.

7. **Fastlane `cert`/`sigh` manage signing via API** — no manual `.p12` upload
   in Codemagic. Apple allows at most three IOS_DISTRIBUTION certificates per
   account; revoke unused certs if `cert` reports the limit is reached.

8. Idempotency pattern used everywhere: find first, create only if missing,
   exit 0 either way — every deploy re-runs all setup steps safely.

## Operational notes

- Testers get one TestFlight email invite; after accepting, new builds appear
  automatically (internal group). Add testers by appending to the `TESTERS`
  array in `Ebb/ci/create_beta_group.rb`.
- **Ebb — TestFlight** triggers on push to `main` when `Ebb/**` or
  `codemagic.yaml` changes. **Ebb — Unit tests** also runs on PRs.
  Apple's post-upload processing adds 10–30 minutes before the build is
  installable.
- Debug failures in the Codemagic build log for the **Build and upload to
  TestFlight** step. Spaceship errors surface Apple's exact message (e.g.
  attribute rejections) in the log.
- To test Spaceship calls without credentials, generate a throwaway key:
  `OpenSSL::PKey::EC.generate("prime256v1").to_pem` and pass it as `key:` to
  `Token.create` — client wiring can be exercised locally; only the HTTP call
  needs the real key.
