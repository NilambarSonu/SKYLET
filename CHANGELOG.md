# Changelog

All notable changes to **Skylet** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-10-29

### Added
- **Currency Intelligence**:
  - Smart local parsing of international prices and amounts from freeform text or clipboard contents.
  - Ambiguous symbol detection (`$`, `¥`, `Rs`) with quick candidate selectors.
  - Comprehensive metadata support for USD, EUR, GBP, INR, JPY, CNY, AUD, CAD, SGD, CHF, AED, SAR, NZD, HKD, KRW, BRL, THB, MYR, IDR, BDT, PKR, NPR, and all ISO 4217 codes.
  - Zero floating-point rounding errors via pure `Decimal` financial arithmetic.
  - Primary free, keyless HTTPS exchange rate provider (`open.er-api.com`) with secondary fallback (`api.frankfurter.dev`).
  - Actor-isolated rate cache with 12-hour TTL and graceful offline stale-rate serving.
  - Currency swap / reversal affordance (e.g., INR to foreign currencies).
  - One-click copy result with immediate visual confirmation.
- **Focus Timer & Display-Awake**:
  - Calibrated presets: 15m, 30m, 45m, 60m, 120m, and custom duration input.
  - Monotonic deadline-based timer model with zero scheduling drift.
  - Native display-awake mode via macOS `ProcessInfo` activity assertions without requiring administrator privileges or permanent system setting changes.
  - Strictly scoped assertion lifecycle: single assertion, reliable cleanup on stop, pause, natural completion, or droplet deactivation.
- **DroppyKit Integration**:
  - Shelf widget conforming to both Solo (420pt) and Paired (210pt) layout surfaces.
  - Live Activity integration displaying running countdown in notch wings.
  - Premium native visual styling in midnight surfaces and clear sky-blue (`#38BDF8`) accents.
- **Automated Verification**:
  - Standalone automated test runner (`SkyletTestsRunner`) executing 65 unit tests locally.
  - GitHub Actions CI workflow for cloud compilation, validation, and release packaging.

