# Skylet Testing & Verification

Skylet includes a comprehensive automated test suite verifying parsing correctness, currency calculations, cache resilience, focus timer deadlines, and power assertion lifecycles.

## Test Coverage Summary

The test suite contains **65 automated tests** across three main domains:

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
  - Excessively long input (guarded against ReDoS / CPU stalls).

### 2. Currency Conversion & Formatting Tests (11 tests)
- **Identity Conversion**: `INR` ➔ `INR` returns immediate local identity (rate 1.0) with zero network calls.
- **Decimal Calculation Precision**: High precision calculations using `Decimal` avoiding binary floating-point roundoff issues.
- **Boundary Amounts**: Zero amounts and large financial sums (e.g. 10,000,000 USD).
- **Stale Cache Fallback**: When network requests fail, automatically serves cached rates with explicit `isStale: true` indicators and timestamps.
- **Offline / Failure Handling**: Non-cached network errors throw proper localized error descriptions.
- **Formatting**:
  - Indian Rupee formatting (`₹2,500.00`).
  - Symbol formatting (`€49.99`, `100.00 AED`).
  - Exchange rate string formatting (`1 USD = 95.22 INR`).
  - Clipboard copy summary (`$25.00 = ₹2,380.50`).

### 3. Focus Timer & Power Assertions (25 tests)
- **Presets**: 15m (900s), 30m (1800s), 45m (2700s), 60m (3600s), 120m (7200s).
- **Countdown Formatting**: `60s` ➔ `01:00`, `899s` ➔ `14:59`, `3600s` ➔ `1:00:00`.
- **Monotonic Deadline Timing**: Verified that timer updates calculate remaining duration against absolute deadlines, preventing drift during UI redraws or background scheduling delays.
- **Duplicate Start Prevention**: Repeated `start()` calls while running do not duplicate power assertions.
- **Pause & Resume**: Assertions released on pause, safely re-acquired on resume.
- **Natural Completion**: Power assertions automatically released when countdown hits zero.
- **Truthful Status**: UI reflects assertion failure truthfully if system refuses assertion.
- **Deactivation Cleanup**: Droplet deactivation guarantees immediate release of any active power assertions.

## Running Tests Locally

Run the test suite using the standalone test runner:

```bash
swift run SkyletTestsRunner
```

Expected output:
```text
==================================================
TEST RESULTS: 65 passed, 0 failed
==================================================
ALL TESTS PASSED SUCCESSFULLY!
```

## Running SDK Bundle Validation

Run DroppyKit's official validator against the manifest and droplet structure:

```bash
/path/to/droppykit/Scripts/droppykit validate --no-submission
```
