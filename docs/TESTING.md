# Skylet Testing & Verification

Skylet includes a comprehensive automated test suite verifying parsing correctness, currency calculations, cache resilience, focus timer deadlines, and power assertion lifecycles.

## Test Coverage Summary

The test suite contains **133 automated tests** across four main domains:

### 1. Currency Parser Tests (29 tests)
- **Input Hygiene**: Empty string, whitespace-only, arbitrary alphabetic text without numbers.
- **Bare Numbers**: Bare integers (`25`), bare decimals (`49.99`).
- **Unambiguous Identifiers**:
  - Symbols: `€49.99` (EUR), `£12.50` (GBP), `₹100` (INR).
  - Prefix/Suffix Codes: `USD 25`, `25 USD`, `49.99 EUR`, `INR 100`, `100 INR`, `AED 100`, `JPY 5000`.
  - Natural Language Aliases: `25 euros`, `25 US dollars`, `5000 yen`.
- **Ambiguous Symbol Resolution**:
  - `$` ➔ Flags candidates `[USD, CAD, AUD, SGD, NZD, HKD]`.
  - `¥` ➔ Flags candidates `[JPY, CNY]`.
  - `Rs` ➔ Flags candidates `[INR, PKR, NPR]`.
- **Punctuation & Grouping Separators**:
  - US style: `1,299.50`.
  - European style: `1.299,50`.
  - Indian numbering style: `1,00,000`.
- **Negative & Zero Values**: `-49.99 EUR`, `0 USD`.
- **Safety Edge Cases**:
  - Multiple distinct amounts in single sentence (e.g., `"from $25 to $50"`) flags multiple amounts rather than guessing.
  - Amounts embedded in sentences with trailing punctuation (`"Fee is $25."`).
  - Unknown 3-letter ISO codes (`100 XYZ`).

### 2. Currency Conversion & Formatting Tests (9 tests)
- **Identity Conversion**: `INR` ➔ `INR` returns immediate local identity (rate 1.0) with zero network calls.
- **Decimal Calculation Precision**: High precision calculations using `Decimal` avoiding binary floating-point roundoff issues.
- **Formatting**:
  - Indian Rupee formatting (`₹2,500.00`).
  - Symbol formatting (`€49.99`, `100.00 AED`).
  - Exchange rate string formatting (e.g., `1 USD = 84.50 INR`).
  - Compact rate with ₹ symbol (`1 USD = ₹95.24`).
  - Clipboard copy summary (`$25.00 = ₹2,380.50`).

### 3. Real-Time FX, Twelve Data, Keychain & Provenance Tests (43 tests)
- **Keychain Storage & Retrieval**:
  - Secure saving, retrieval, update, and deletion in `InMemoryKeychainManager`.
- **Twelve Data Provider Validation**:
  - Missing API key throws `CurrencyRateError.missingAPIKey`.
  - Valid Twelve Data response decodes `symbol`, `rate`, and `timestamp` into `CurrencyRateEntry`.
  - Header authentication verification: sends `Authorization: apikey <key>`.
  - Decimal safety on string and numeric rate formats.
  - HTTP 401 mapped to `CurrencyRateError.invalidAPIKey`.
  - HTTP 429 mapped to `CurrencyRateError.rateLimitExceeded`.
  - HTTP 404 mapped to `CurrencyRateError.unsupportedCurrencyPair`.
  - Malformed JSON mapped to `CurrencyRateError.malformedData`.
  - Missing timestamp mapped to `CurrencyRateError.malformedData`.
  - Zero or non-positive rate mapped to `CurrencyRateError.providerRateNonPositive`.
  - Network timeout mapped to `CurrencyRateError.timeout`.
- **Rate Freshness & Market Hours**:
  - Recent quote (age <= 15m) marked `LIVE`.
  - Weekend / closed market quote marked `DELAYED`.
  - Quote exceeding 72h marked `STALE`.
  - Retrieved live quote from cache marked `CACHED` (never `LIVE`).
  - Subtext formatting verified for `LIVE`, `CACHED`, and `DAILY REFERENCE`.
- **Deterministic Controllable Clock & Freshness Matrix (9 Cases)**:
  - Case 1: Fresh live quote (`quoteAge <= 15m`) evaluates to `.live`.
  - Case 2: Cached live quote (`quoteAge <= 15m, fetchAge <= 5m`) evaluates to `.cached`, `isStale == false`.
  - Case 3: Delayed quote (`quoteAge > 15m && <= 72h`) evaluates to `.delayed`.
  - Case 4: Cached delayed quote strictly preserves `.delayed` (never converted to `.cached` or `.live`).
  - Case 5: Stale quote (`quoteAge > 72h`) evaluates to `.stale`.
  - Case 6: Cached stale quote retrieved strictly as `.stale`, `isStale == true`.
  - Case 7: Quote live when cached becomes `.stale` after advancing controllable clock past 72h.
  - Case 8: Fallback on network failure returns cached quote with accurate provenance (`.cached`, `.delayed`, or `.stale`; never upgraded to `.live`).
  - Case 9: Daily reference fallback returns `.dailyReference` (`quoteAge <= 12h`) or `.stale` (`quoteAge > 12h`).
- **Honest Fallback & Deduplication**:
  - Transparent fallback to daily reference provider when Twelve Data fails or is unconfigured.
  - Concurrent requests for identical currency pair share a single in-flight `Task`.
- **Exact Decimal Fixture Conversion**:
  - `889.86 USD * 95.2450 = 84754.7157 INR` calculated with decimal-safe precision.
- **Cache Isolation**:
  - In-memory test cache guarantees no test mock data ever touches user's production cache.

### 4. Focus Timer 16 Lifecycle Requirements & UI State Tests (52 tests)
- **Duration Presets & Countdown Formatting**: 15m, 30m, 45m, 60m, 120m, and string formatting (`MM:SS` / `H:MM:SS`).
- **UI State Transitions & Button Presentation**: Dynamic action button titles and icons verified across all states (`Start Focus` ➔ `Pause` ➔ `Resume` ➔ `Start Again`) and status badges (`READY`, `FOCUSING`, `PAUSED`, `COMPLETED`).
- **All 16 Focus Timer Lifecycle Requirements**:
  1. `Idle -> Running`: Transitions to `.running` upon start with exact duration.
  2. `Running -> Paused`: Transitions to `.paused` with remaining seconds preserved.
  3. `Paused -> Running`: Transitions back to `.running` and restores internal ticker.
  4. `Running -> Reset`: Resets immediately to `.idle` from running state.
  5. `Paused -> Reset`: Resets immediately to `.idle` from paused state.
  6. `Session Completion`: Reaches `.completed` status naturally when monotonic deadline expires.
  7. `Completion Notification Exactly Once`: Both `onCompletion` callback and `sessionCompletedNotification` fired exactly 1 time per completed session.
  8. `Display-Awake Activation`: Acquires `ProcessInfo` assertion on start.
  9. `Display-Awake Release on Completion`: Power assertion released automatically when countdown hits zero.
  10. `Display-Awake Release on Reset`: Power assertion released immediately on user reset.
  11. `Display-Awake Release on Droplet Deactivation`: Teardown guarantees release of active power assertion.
  12. `No Duplicate Ticking Tasks`: Calling `start()` while running does not spawn extra tickers or duplicate assertions.
  13. `Duration Changes Behave Correctly`: Starting with different presets updates totalDuration and remaining time cleanly.
  14. `Progress Preservation Across Pause/Resume`: Remaining seconds and elapsed progress are preserved across pause and resume.
  15. `Visual Progress Reaching Zero Remaining Time`: Remaining time reaches exactly 0s upon completion.
  16. `Monotonic Accuracy Under Delayed Schedule`: Absolute deadline eliminates clock drift even after 450s schedule freeze or system sleep.

## Running Tests Locally

Run the test suite using the standalone test runner:

```bash
swift run SkyletTestsRunner
```

Expected output:
```text
==================================================
TEST RESULTS: 133 passed, 0 failed
==================================================
ALL TESTS PASSED SUCCESSFULLY!
```

## Running SDK Bundle Validation

Run DroppyKit's official validator against the manifest and droplet structure:

```bash
/path/to/droppykit/Scripts/droppykit validate --no-submission
```

