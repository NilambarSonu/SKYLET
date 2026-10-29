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
  - Implements `CurrencyRateProviding` protocol.
  - `ExchangeRateAPIProvider`: Primary HTTPS endpoint (`https://open.er-api.com/v6/latest/{BASE}`) supporting 162 currencies.
  - `FrankfurterRateProvider`: Fallback ECB reference provider.
  - `CurrencyRateCache`: Actor-isolated thread-safe cache with 12-hour TTL and offline stale-data recovery.
  - Pure `Decimal` arithmetic for zero floating-point drift.
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
  - `LiveActivityProviding`: Publishes compact state in notch wings during active focus sessions.
- **`SkyletTheme` & Views**:
  - Uses native San Francisco rounded and tabular typography.
  - Midnight / elevated dark surfaces with clear sky-blue (`#38BDF8`) accents.
  - Strictly adheres to DroppyKit design rules (no outer borders, single insets, sentence case).

### 3. `SkyletHarness` & `SkyletTestsRunner`
- **`SkyletHarness`**: Embedded harness target running Droppy's real settings chrome for local testing and headless screenshot automation.
- **`SkyletTestsRunner`**: Lightweight executable test harness validating all 65 core unit tests locally.
