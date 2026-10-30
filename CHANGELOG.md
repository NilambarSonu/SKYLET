# Changelog

All notable changes to **Skylet** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

[1.0.0]: https://github.com/NilambarSonu/SKYLET/releases/tag/v1.0.0
