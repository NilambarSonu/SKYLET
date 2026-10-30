# Known Limitations & Platform Boundaries

This document provides transparent engineering documentation regarding platform boundaries, edge cases, and design trade-offs in Skylet.

---

## 1. Global Text Selection Across Arbitrary Applications
- **Platform Constraint**: In macOS, detecting highlighted text across arbitrary third-party applications without explicit user action requires broad Accessibility (`AXUIElement`) permissions, active background polling, or simulated keyboard shortcuts (`⌘C`).
- **Skylet Design Decision**: Skylet intentionally avoids broad accessibility scraping or background clipboard polling to protect user privacy. Instead, Skylet provides a seamless explicit clipboard import: copy any price from any app, open Skylet on your shelf, and click **Paste**.

---

## 2. Display-Awake Scope vs System Hardware Sleep
- **Platform Scope**: Skylet utilizes `ProcessInfo.processInfo.beginActivity(options: .idleDisplaySleepDisabled, reason:)`.
- **What it does**: Prevents macOS from dimming or turning off the display due to user inactivity during a study or focus session.
- **What it does NOT do**: It does not override closing the laptop lid (clamshell sleep without external display and power), critical thermal throttling, hardware power button presses, or low battery shutdowns.

---

## 3. Real-Time Forex Quotas & Market Hours
- **Twelve Data Free Basic Tier**: Twelve Data provides 800 free API requests per day and up to 8 credits per minute. Skylet incorporates an automatic 5-minute pair cache to keep usage well below free plan limits during active sessions.
- **Weekend Market Closure**: Foreign exchange markets do not operate continuously 24/7 at standard retail liquidity. Over weekends (Friday evening through Sunday evening UTC) or central bank bank holidays, currency quotes are static. Skylet preserves the latest quote and honestly marks it as `DELAYED`, displaying the original quote timestamp rather than faking recent live ticks.
- **Keyless Fallback**: When an API key is not configured, Skylet falls back to open central-bank reference rates (`open.er-api.com` or `Frankfurter`), which update daily. Skylet transparently labels these as `DAILY REFERENCE`.

---

## 4. Unsupported Currencies
- Unofficial, defunct, or unlisted currencies not included in ISO 4217 or unsupported by the forex provider cannot be converted. In such cases, Skylet indicates that the currency pair is unsupported and displays a clear explanation.
