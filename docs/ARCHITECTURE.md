# Skylet Architecture

Skylet is engineered as a native macOS utility designed to run inside **Droppy** via the **DroppyKit SDK**.

```
┌────────────────────────────────────────────────────────┐
│                        Droppy                          │
│  (Host Application: Dynamic Island, Shelf & Settings)  │
└───────────────────────────┬────────────────────────────┘
                            │ Dynamic Linkage
┌───────────────────────────▼────────────────────────────┐
│                    Skylet.droplet                      │
│  ┌───────────────────────┐  ┌────────────────────────┐ │
│  │   SkyletPrincipal     │  │     SkyletDroplet      │ │
│  └───────────────────────┘  └───────────┬────────────┘ │
│                                         │              │
│  ┌───────────────────────┐              │              │
│  │     SkyletRootView    │◄─────────────┤              │
│  │   CurrencyView        │              │              │
│  │   FocusTimerView      │              │              │
│  └───────────────────────┘              │              │
└─────────────────────────────────────────┼──────────────┘
                                          │
                               ┌──────────▼───────────┐
                               │     SkyletCore       │
                               │  - CurrencyParser    │
                               │  - RateService       │
                               │  - FocusTimerEngine  │
                               │  - PowerAssertion    │
                               └──────────────────────┘
```

## Modular Components

### 1. `SkyletCore` (Pure Swift Foundation Layer)
- **Zero UI / Host Coupling**: Independent of DroppyKit's dynamic bundle loader, enabling instant deterministic unit testing.
- **`CurrencyParser`**: Local tokenizer extracting numerical values, currency symbols, ISO codes, and aliases. Handles ambiguous symbols (`$`, `¥`, `Rs`) by yielding candidate lists rather than guessing silently.
- **`CurrencyRateService` & Providers**:
  - `TwelveDataRateProvider`: Preferred real-time Forex provider querying `https://api.twelvedata.com/exchange_rate` using header authentication (`Authorization: apikey`). Returns live quotes, timestamps, and rate freshness indicators.
  - `ExchangeRateAPIProvider`: Primary daily reference rate fallback (`https://open.er-api.com/v6/latest/{BASE}`) supporting 162 currencies.
  - `FrankfurterRateProvider`: Secondary ECB daily reference rate fallback.
  - `CurrencyRateCache`: Actor-isolated thread-safe cache with pair-specific 5-minute live TTL, 12-hour reference TTL, and strict cache isolation to avoid test mock pollution.
  - Request deduplication: in-flight concurrent requests for the same pair share a single network task.
  - Pure `Decimal` arithmetic using `NSDecimalMultiply` for zero floating-point roundoff errors.
- **`MacOSKeychainManager`**:
  - Secure credential storage using Apple's native `Security` framework (`kSecClassGenericPassword`).
  - Stores user's personal Twelve Data API key locally in macOS Keychain without logging or persisting in repositories.
- **`FocusTimerEngine`**:
  - Deadline-based countdown model using monotonic system clocks (`ContinuousClock` / `Date` offsets) to guarantee zero drift during UI suspension or scheduling delays.
  - Manages power assertion transitions (`idle` ➔ `running` ➔ `paused` ➔ `completed`).
- **`PowerAssertionController`**:
  - Wraps macOS `ProcessInfo.processInfo.beginActivity(options: .idleDisplaySleepDisabled, reason:)`.
  - Guarantees exactly one assertion at a time; automatically releases assertions on stop, completion, or droplet deactivation.

### 2. `Skylet` (SwiftUI & DroppyKit Presentation Layer)
- **`SkyletPrincipal`**: Instantiated by Droppy's bundle loader (`NSPrincipalClass`).
- **`SkyletDroplet`**: Entry point conforming to:
  - `Droplet`: Core lifecycle (`activate(host:)`, `deactivate()`).
  - `ShelfWidgetProviding`: Solo (420pt) and Paired (210pt) layouts on Droppy's shelf.
  - `LiveActivityProviding`: Publishes compact state in notch wings (active focus timer or latest currency conversion).
  - `SettingsPaneProviding`: Dedicated page in Droppy Settings with API key management and live connection testing.
- **`SkyletTheme` & Views**:
  - Uses native San Francisco rounded and tabular typography.
  - Midnight / elevated dark surfaces with clear sky-blue (`#38BDF8`) accents.
  - `SettingsView`: Interactive API key configuration with masked input, clipboard paste, Save/Remove actions, and a live "Test Connection" latency reporter.
  - Strictly adheres to DroppyKit design rules (no outer borders, single insets, sentence case).

### 3. `SkyletHarness` & `SkyletTestsRunner`
- **`SkyletHarness`**: Embedded harness target running Droppy's real settings chrome for local testing and headless screenshot automation.
- **`SkyletTestsRunner`**: Lightweight executable test harness validating all 97 core unit tests locally.

