# Changelog

All notable changes to **Skylet** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.1.0] - 2026-10-30

### Status
Major Product Redesign, UX Rebuild & Solar Focus Instrument Release.

### Highlights
- **Rebuilt Focus Timer with Solar Sun Instrument**: Replaced dominant numeric countdown with an elegant, custom-drawn `SolarSunView` inspired by natural celestial daylight. 12 radial solar beams progressively recede and fade clockwise as time elapses, creating a calm, ambient visual sense of time without anxious second-by-second countdowns.
- **Fixed Start Button Reactive State Bug**: Resolved state binding issues by directly observing `FocusTimerEngine` and forwarding object changes to `DropletInstance`. The action button immediately transitions between `Start Focus` (amber play) → `Pause` (amber pause) → `Resume` (amber play) → `Start Again` (emerald reload), accompanied by a dedicated `Reset` button for mid-session resets.
- **Continuous Notch & Island Curvature**: Conformed droplet geometry to host container curvature (`18pt` shelf, `26.5pt` island). Replaced AppKit `.sheet` presentation with an in-place layered currency picker overlay, eliminating square modal window edges and visual clipping against the macOS notch.
- **Brand New App Icon & Master Asset**: Designed a distinctive 1024×1024 master icon (`Skylet.icon`) featuring a deep midnight celestial base (`#070B14` to `#0E1A2E`), a warm luminous amber/gold solar core (`#FFB300` to `#FF6F00`), a sky-blue atmospheric horizon arc (`#38BDF8`), and 12 precision solar rays. Hand-tested for crisp legibility from 1024px down to 16px.
- **Comprehensive Lifecycle Test Suite**: Expanded the automated test suite to 133 passing tests in `SkyletTestsRunner`, introducing explicit verification for all 16 focus timer lifecycle requirements (transitions, power assertion acquisition/release, monotonic zero-drift calculations, and exactly-once completion notifications).
- **Notch Compact Live Activity**: Integrated a mini 18pt Solar Sun indicator into Droppy's leading Live Activity wing for seamless at-a-glance focus tracking directly inside the macOS menu bar and notch.

### Changed
- `Sources/Skylet/UI/SolarSunView.swift`: Introduced new custom radial solar timer component with animated beams, celestial horizon ring, and state-adaptive core glyphs.
- `Sources/Skylet/UI/FocusTimerView.swift`: Completely rebuilt layout prioritizing visual calmness, direct `@ObservedObject` observation of `timerEngine`, dynamic action/reset buttons, and non-dominant secondary time info.
- `Sources/Skylet/UI/CurrencyView.swift` & `CurrencySelectorView.swift`: Replaced square `.sheet` modals with in-place spring-animated overlay clipped to continuous 18pt corners.
- `Sources/Skylet/UI/SkyletRootView.swift`: Clipped root container with `.clipShape(SkyletTheme.shelfShape)` for seamless notch integration.
- `Sources/Skylet/Theme/SkyletTheme.swift`: Added solar color palette tokens (`solarGold`, `solarCore`, `solarFlare`, `solarGlow`, `solarRayActive`, `solarRayTrack`) and continuous shelf corner radius tokens.
- `Sources/SkyletCore/Focus/FocusTimerEngine.swift`: Added `actionButtonTitle`, `actionButtonIcon`, `statusBadgeText`, and exactly-once `sessionCompletedNotification` and `onCompletion` callbacks.
- `Sources/SkyletTestsRunner/main.swift`: Expanded test coverage to 133 passing tests covering all 16 lifecycle requirements and UI state transitions.
- `Skylet.icon`: Replaced placeholder mark and background gradients with master celestial solar assets.
- `droplet.json`: Bumped version to `1.1.0` and linked screenshots in `Assets/`.
- `README.md`, `docs/RELEASE.md`, `docs/TESTING.md`, `docs/KNOWN_LIMITATIONS.md`: Updated documentation and screenshots for v1.1.0.

---

## [1.0.1] - 2026-10-30

### Status
Production Release Hardening & Currency Data Integrity Update.

### Highlights
- **Release Pipeline Hardening**: Resolved DroppyKit harness target discovery by ordering `SkyletHarness` before other executable targets in `Package.swift`.
- **Reproducible DroppyKit Build**: Pinned official DroppyKit SDK to verified stable commit `4eee564d5d5896137ecc2b4e0df50975cff5a4c6` (v1.20.1) in `ci/setup-droppykit.sh` with strict SHA verification and fail-fast patch assertions.
- **Explicit CI Harness Verification**: Replaced silent masking (`|| true`) with `ci/run-harness-checks.sh` to validate headless screenshot generation and test report output.
- **Harden Release Triggers**: Enhanced `.github/workflows/release.yml` with semantic tag format validation (`vMAJOR.MINOR.PATCH`), `origin/main` commit ancestry check, and `droplet.json` version synchronization.
- **Strict Currency Provenance & Freshness**: Separated quote age, fetch age, and cache state in `CurrencyRateCache` and `TwelveDataRateProvider`. Quotes originally classified as `.delayed` or `.stale` strictly retain their status on cache retrieval and are never erroneously labeled as `.cached` or `.live`.
- **Unified 72-Hour Stale Threshold**: Standardized the maximum stale threshold to 72 hours across provider, cache, UI, and documentation to properly accommodate weekend forex market closures.
- **Controllable Clock Unit Tests**: Expanded the automated test suite to 109 passing tests in `SkyletTestsRunner`, introducing deterministic tests with injected clocks for all 9 freshness and cache provenance scenarios.
- **Documentation Refinement & Safe Updates**: Removed misleading mock-rate example (`95.22`) from README and public docs, replacing it with an explicitly labeled illustrative example. Added safe staged update and rollback instructions.

### Changed
- `Package.swift`: Reordered targets so `SkyletHarness` is the first executable target.
- `Sources/SkyletCore/Currency/CurrencyRateCache.swift`: Unified stale threshold to 72h; separated quote age vs fetch age; preserved `.delayed` and `.stale` provenance; injected controllable `dateProvider`.
- `Sources/SkyletCore/Currency/TwelveDataRateProvider.swift`: Unified stale threshold to 72h; injected controllable `dateProvider`.
- `Sources/SkyletCore/Currency/CurrencyRateService.swift`: Preserved honest cache provenance during offline fallback; injected controllable `dateProvider`.
- `Sources/SkyletTestsRunner/main.swift`: Added 12 new deterministic tests covering all 9 freshness and cache provenance scenarios; eliminated blocking Keychain prompts in headless execution.
- `.github/workflows/build.yml` & `.github/workflows/release.yml`: Pinned DroppyKit SDK commit; added `ci/run-harness-checks.sh` and release gating preconditions.
- `droplet.json`: Version bumped to `1.0.1`.
- `README.md`, `docs/RELEASE.md`, `docs/KNOWN_LIMITATIONS.md`, `docs/TESTING.md`: Updated documentation, test counts, and safe staged update procedures.

---

## [1.0.0] - 2026-10-30

### Status
First Official Production Release.

### Highlights
- **Instant Currency Intelligence**: Convert international currencies and freelance invoices directly to Indian Rupees (INR) with real-time Twelve Data Forex rates, honest quote timestamps, and Decimal-safe financial precision.
- **Distraction-Free Focus Timer**: Keep your Mac display awake during deep work and study sessions using native macOS power assertions without changing global System Settings.
- **Native Droppy Integration**: Designed specifically for Droppy’s shelf (Solo 420pt & Paired 210pt layouts) and Dynamic Island / notch Live Activities.
- **Premium Design System**: Tailored dark-chrome aesthetic (`#0B1220`) following DroppyKit guidelines, complete with searchable currency picker, spring micro-interactions, and Liquid Glass controls.

### Features
#### Real-Time Forex & Currency Intelligence
- **Twelve Data Integration**: Direct HTTPS connection to Twelve Data Forex API (`https://api.twelvedata.com/exchange_rate`) for high-frequency live rates on USD/INR, EUR/INR, GBP/INR, and over 1,500 currency pairs.
- **Secure Apple Keychain Storage**: API keys are securely persisted in Apple's native macOS Keychain (`kSecClassGenericPassword`, service `app.getdroppy.skylet`). Never logged, never shared, and never committed to source control.
- **Honest Provenance & Freshness**: Every displayed rate explicitly identifies its source state:
  - `LIVE`: Verified quote received within 15 minutes.
  - `DELAYED`: Active quote during closed market hours or weekend trading halts.
  - `CACHED`: Previously retrieved quote served from short 5-minute pair cache (never labeled as live).
  - `DAILY REFERENCE`: Fallback reference rate from ExchangeRate-API or Frankfurter (ECB).
  - `STALE`: Quote age exceeding 72 hours.
  - `UNAVAILABLE`: Complete network failure.
- **Pure Decimal-Safe Calculations**: All multiplications and divisions execute through Foundation `Decimal` (`NSDecimalMultiply`) preventing IEEE-754 binary floating-point roundoff errors.
- **Intelligent Local Parser**: Understands natural inputs including `$25`, `€49.99`, `100 USD`, `25 euros`, `¥5000`, `AED 100`, and `₹100` from typed text or clipboard contents.
- **Ambiguous Symbol Protection**: Safeguards against silent currency confusion: `$25` prompts candidate selection (`USD`, `CAD`, `AUD`, `SGD`, `NZD`), and `¥5000` prompts selection between `JPY` and `CNY`.
- **Searchable Currency Modal (`CurrencySelectorView`)**: Real-time filtering by country, ISO currency code, symbol, or full name, with popular quick-pills (`USD`, `EUR`, `GBP`, `AED`, `CAD`, `AUD`, `SGD`, `JPY`, `SAR`, `CNY`).
- **Interactive Directional Currency Swap**: Instant reversal between foreign currency and INR with smooth $180^\circ$ rotation spring animation.
- **Live Rate Refresh**: Manual refresh control with smooth $360^\circ$ rotation animation and in-flight request deduplication.
- **Zero-Flicker Copy & Paste**: Quick copy summary to clipboard with in-place checkmark confirmation, and explicit clipboard import without continuous background polling.

#### Focus Timer & Display-Awake Instrument
- **Calibrated Duration Presets**: Quick-select duration pills for 15m, 30m, 45m, 60m, 120m, alongside a compact custom duration input.
- **Zero-Drift Monotonic Deadline**: System-clock deadline tracking ensures the countdown never drifts if the UI is hidden or backgrounded.
- **Native Power Assertion**: Utilizes Apple's public `ProcessInfo.beginActivity(options: .idleDisplaySleepDisabled)` API to keep the display awake during sessions without administrator rights or terminal `caffeinate` scripts.
- **Strict Assertion Lifecycle**: Automatically releases display-awake assertions on pause, cancellation, session completion, or droplet deactivation.
- **Restrained Circular Progress Gauge**: Custom 52pt progress ring with subtle track, sky-blue progress stroke, and session status glyphs (`timer`, `sun.max.fill`, `pause.fill`, `checkmark`).

#### Surfaces & Native macOS Integration
- **Droppy Shelf Layouts**: Seamlessly adapts between wide Solo layout (420pt) and compact Paired layout (210pt).
- **Dynamic Island / Notch Live Activity**: Publishes running countdown in the notch wings during active focus sessions, and live converted INR amounts when idle.
- **Native Droppy Settings Pane**: Integrated settings pane in **Droppy Settings ➔ Skylet** with masked key input, latency tester, and quota notices.
- **Universal Mach-O Binary**: Compiled as a native universal binary supporting both Apple Silicon (`arm64`) and Intel (`x86_64`) Macs.

### Verification
- **Automated Unit Tests**: 97 out of 97 automated tests passing in `SkyletTestsRunner` across Parser, Financial Math, Twelve Data & Keychain, and Focus Timer domains.
- **DroppyKit Validation**: Fully validated against DroppyKit ABI 1 manifest and linkage standards via `droppykit validate --no-submission`.
- **Runtime Host Loading**: Dynamically loaded and verified against `/Applications/Droppy.app` framework runtime with zero missing symbols.

### Compatibility
- macOS 14.0 (Sonoma) or macOS 15.0+ (Sequoia)
- Droppy 15.3.0 or later
- Universal binary (`arm64` + `x86_64`)

### Installation & Updating
1. Download `Skylet.droplet.zip` from the [Latest Release](https://github.com/NilambarSonu/SKYLET/releases/latest).
2. Unpack the ZIP archive to reveal `Skylet.droplet`.
3. Drag `Skylet.droplet` into **Droppy Settings ➔ Store ➔ Local Droplets** (or copy to `~/Library/Application Support/Droppy/Droplets/skylet/Skylet.droplet`).
4. Droppy will immediately load Skylet into your shelf.

---

[1.0.1]: https://github.com/NilambarSonu/SKYLET/releases/tag/v1.0.1
[1.0.0]: https://github.com/NilambarSonu/SKYLET/releases/tag/v1.0.0
