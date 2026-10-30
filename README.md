# Skylet ✦

**Premium Native DroppyKit Utility for macOS — Currency Intelligence + Focus Timer**

Skylet is a lightweight, beautifully crafted native macOS droplet for [Droppy](https://getdroppy.app). It lives directly inside Droppy’s Dynamic Island and shelf, delivering two focused productivity tools without requiring an account, API key, background daemon, or system-wide setting changes:

1. **Currency Intelligence**: Real-time foreign exchange conversion to Indian Rupees (INR) using live quotes from Twelve Data Forex API with fallback reference providers, keychain-secured API key management, and instant clipboard import.
2. **Focus Timer**: Keep your Mac’s display awake during deep study, reading, or coding sessions without modifying global macOS System Settings.

---

## Features

### 🪙 Currency Intelligence & Real-Time FX
- **Twelve Data Real-Time Forex API**: High-frequency real-time quotes for USD/INR, EUR/INR, GBP/INR, and over 1,500 currency pairs.
- **Secure macOS Keychain API Key Storage**: Stores your personal Twelve Data API key directly in Apple Keychain (`kSecClassGenericPassword`). Never logged, never shared, and never committed to GitHub.
- **Honest Provenance & Freshness Badges**: Rates explicitly indicate whether they are `LIVE` (verified recent quote), `DELAYED` (market closed / delayed), `CACHED` (short 5m pair cache), or `DAILY REFERENCE` (fallback).
- **Intelligent Local Parsing**: Paste or type amounts like `$25`, `€49.99`, `100 USD`, `25 euros`, `¥5000`, `AED 100`, or `₹100`.
- **Ambiguous Symbol Protection**: Never silently guesses ambiguous symbols. An input of `$25` gracefully offers candidate selectors (`USD`, `CAD`, `AUD`, `SGD`, etc.), and `¥5000` distinguishes between `JPY` and `CNY`.
- **Decimal-Safe Financial Arithmetic**: Calculations use pure Swift `Decimal` (`NSDecimalMultiply`) to avoid binary floating-point roundoff errors.
- **Keyless Fallback Providers**: Seamless fallback to [ExchangeRate-API](https://open.er-api.com) and [Frankfurter (ECB)](https://api.frankfurter.dev) if an API key is unconfigured or rate limited.
- **Offline & Stale-Rate Resilience**: Actor-isolated caching serves cached rates with an honest stale notice when offline.
- **Explicit Clipboard Workflow**: Read clipboard content only upon clicking the explicit **Paste** button — no continuous background clipboard polling.
- **One-Click Copy & Currency Swap**: Copy the formatted result (`₹2,380.50`) with immediate visual confirmation, or swap source and target currencies.
- **Live Dynamic Island Display**: Shows latest converted INR amount right on the notch when Focus Timer is idle.
- **Dedicated Settings Pane**: Configure and test your Twelve Data API key in Droppy Settings or right in the widget with live latency feedback.

### ⏱️ Focus Timer & Display-Awake Mode
- **Zero-Drift Countdown**: Deadline-based timer model ensures countdown never drifts if the UI is hidden or the system experiences scheduling delays.
- **Native Power Assertion**: Uses Apple's public `ProcessInfo.processInfo.beginActivity(options: .idleDisplaySleepDisabled)` API to prevent idle screen sleep without administrator privileges, terminal `caffeinate` scripts, or mouse jiggling.
- **Strict Assertion Lifecycle**: Acquires exactly one power assertion on start; releases it immediately on stop, pause, natural completion, or droplet deactivation.
- **Live Activity Integration**: Publishes a compact live activity row showing countdown status in the Dynamic Island / notch wings during active sessions.
- **Flexible Presets**: Instant 15m, 30m, 45m, 60m, 120m duration pills and custom duration entry.

---

## Design System

Skylet adheres strictly to the official [DroppyKit Design Guidelines](https://getdroppy.app/docs/droppykit/design):
- **Surfaces**: Dark, dense chrome (`#0B1220`) matching Droppy's notch shell. No faux card borders or heavy outlines.
- **Accent**: Clear sky blue (`#38BDF8`) with refined secondary tones (`#7DD3FC`).
- **Typography**: Native Apple San Francisco typography with tabular and monospaced digits for jitter-free numbers.
- **Dual Surface Layouts**: Full interactive experience in Solo shelf layout (420pt) and streamlined glanceable layout in Paired shelf mode (210pt).

---

## Compatibility & Requirements

| Component | Minimum Version |
| :--- | :--- |
| **macOS** | 14.0 (Sonoma) or later |
| **Droppy** | 15.3.0 or later |
| **DroppyKit SDK** | 1.6.0+ (ABI 1 compatible) |
| **Swift Toolchain** | Swift 6.0+ / Xcode 15.4+ or Xcode 16+ |

---

## Building & Verification

### 1. Run Automated Unit Tests (Locally)
Skylet includes 97 automated tests covering parsing, arithmetic precision, Twelve Data real-time integration, Keychain security, cache behavior, deadline accuracy, and power assertion lifecycles:

```bash
swift run SkyletTestsRunner
```

Expected output:
```text
==================================================
TEST RESULTS: 97 passed, 0 failed
==================================================
ALL TESTS PASSED SUCCESSFULLY!
```

### 2. Validate with DroppyKit
Run DroppyKit's official submission and manifest validator:

```bash
export PATH="/path/to/droppykit/Scripts:$PATH"
droppykit validate --no-submission
```

### 3. Build the Shipping Droplet Bundle
Build the release bundle using DroppyKit's compiler script (ensures library evolution and dynamic framework linkage):

```bash
droppykit build --arch arm64
```
This produces `.build/Skylet.droplet`.

### 4. Run the Development Harness
Preview Skylet inside Droppy's authentic settings chrome:

```bash
droppykit run
```
Or run headless screenshot and verdict capture:

```bash
swift run SkyletHarness -- --shots ./shots --report ./shots/report.json
```

---

## Safe Installation into Droppy

1. Open **Droppy** on your Mac.
2. Open **Settings** (`⌘,`).
3. Navigate to **Store** ➔ **Local Droplets** (or Developer tab).
4. Drag and drop `Skylet.droplet` into the window.
5. Droppy verifies the droplet handshake and loads Skylet onto your shelf.

*To uninstall or rollback, remove Skylet from Droppy Settings ➔ Installed Droplets.*

---

## Architecture

For an in-depth breakdown of components and data flows, see [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

For verification details and test suites, see [docs/TESTING.md](docs/TESTING.md).

For release instructions and checksum verification, see [docs/RELEASE.md](docs/RELEASE.md).

For privacy commitments, see [docs/PRIVACY.md](docs/PRIVACY.md).

For platform limitations and boundaries, see [docs/KNOWN_LIMITATIONS.md](docs/KNOWN_LIMITATIONS.md).

---

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
Copyright © 2026 NilambarSonu Behera.

