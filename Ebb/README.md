# Ebb

A privacy-first, on-device menstrual-migraine and period symptom tracker.
See `../docs/ebb-build-plan.md` for the phased plan and architecture, and
`../docs/symptom-tracker-classification-spec.md` for the schema that drives
both the UI and (later) the on-device classifier.

## Requirements

- Xcode 16+
- iOS 17.0+

## Structure

```
Ebb/
  App/            entry point, root view, DI wiring
  Models/         SymptomEntry, SchemaConfig, FieldValue, symptom-schema.json
  DesignSystem/   Theme tokens, FieldControl, phase ring, entry card
  Features/       Today, Calendar, Patterns, Settings, Log, Debug
EbbTests/         Swift Testing unit tests
ci/               CI helper scripts
fastlane/         Codemagic CI lanes
```

## Run locally

1. Open `Ebb.xcodeproj` in Xcode
2. Select an iPhone simulator or device
3. Press **Run** (⌘R)

## Tests

```sh
DEST="$(bash ci/resolve_simulator_destination.sh)"
xcodebuild test \
  -project Ebb.xcodeproj \
  -scheme Ebb \
  -destination "$DEST"
```

## Install on your iPhone (Codemagic Ad Hoc)

An unsigned build cannot be installed on a physical iPhone. Use Codemagic to produce a signed Ad Hoc IPA:

1. Complete one-time setup in [CODEMAGIC_SETUP.md](CODEMAGIC_SETUP.md) — upload an Apple Distribution certificate and an Ad Hoc provisioning profile (with your iPhone UDID) in Codemagic **Code signing identities**.
2. Start **Ebb — Ad Hoc (install on device)** manually in Codemagic.
3. Download the `.ipa` from build artifacts and install via **Finder** or **Apple Configurator**.
