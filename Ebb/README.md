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
ci/               Fastlane helper scripts
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

## Deploy to your iPhone (TestFlight)

1. Complete one-time setup in [CODEMAGIC_SETUP.md](CODEMAGIC_SETUP.md)
2. Push to branch **`main`** (or start **Ebb — TestFlight** manually in Codemagic)
3. Install **Ebbie** from the TestFlight app on your iPhone

For a direct device install without TestFlight, run **Ebb — Ad Hoc (install on device)** in Codemagic and sideload the `.ipa` artifact.
