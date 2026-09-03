# Ebb

A privacy-first, on-device menstrual-migraine and period symptom tracker.
See `docs/ebb-build-plan.md` for the phased plan and architecture, and
`docs/symptom-tracker-classification-spec.md` for the schema that drives
both the UI and (later) the on-device classifier.

## Requirements

- Xcode 16+
- iOS 17.0+

## Structure

```
Ebb/
  Ebb/            App source (App, Models, DesignSystem, Features, Services)
  EbbTests/       Swift Testing unit tests
  ci/             CI helpers and TestFlight scripts
docs/             Product specs, build plan, and design references
```

## Run locally

1. Open `Ebb/Ebb.xcodeproj` in Xcode
2. Select an iPhone simulator or device
3. Press **Run** (⌘R)

## Tests

```sh
DEST="$(bash Ebb/ci/resolve_simulator_destination.sh)"
xcodebuild test \
  -project Ebb/Ebb.xcodeproj \
  -scheme Ebb \
  -destination "$DEST"
```

## Deploy to your iPhone (TestFlight)

1. Add GitHub secrets/variables (see [Ebb/TESTFLIGHT_SETUP.md](Ebb/TESTFLIGHT_SETUP.md))
2. Go to **Actions → TestFlight → Run workflow**
3. Install **Ebb** from the TestFlight app on your iPhone
