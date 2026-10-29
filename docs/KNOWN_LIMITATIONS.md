# Known Limitations & Platform Boundaries

This document provides transparent engineering documentation regarding platform boundaries, edge cases, and design trade-offs in Skylet.

## 1. Global Text Selection Across Arbitrary Applications
- **Platform Constraint**: In macOS, detecting highlighted text across arbitrary third-party applications without explicit user action requires broad Accessibility (`AXUIElement`) permissions, active background polling, or simulated keyboard shortcuts (`⌘C`).
- **Skylet Design Decision**: Skylet intentionally avoids broad accessibility scraping or background clipboard polling to protect user privacy. Instead, Skylet provides a seamless explicit clipboard import: copy any price from any app, open Skylet on your shelf, and click **Paste**.

## 2. Display-Awake Scope vs System Hardware Sleep
- **Platform Scope**: Skylet utilizes `ProcessInfo.processInfo.beginActivity(options: .idleDisplaySleepDisabled, reason:)`.
- **What it does**: Prevents macOS from dimming or turning off the display due to user inactivity during a study or focus session.
- **What it does NOT do**: It does not override closing the laptop lid (clamshell sleep without external display and power), critical thermal throttling, hardware power button presses, or low battery shutdowns.

## 3. Exchange Rate Providers & Update Frequency
- **Daily Reference Rates**: The free, keyless exchange rate endpoints (`open.er-api.com` and `api.frankfurter.dev`) update once daily (typically reflecting central bank reference rates or end-of-day market closes).
- **Honest Rate Display**: Skylet explicitly labels reference rates with their provider date and indicates whether a rate is current or cached. Skylet does not fabricate real-time minute-by-minute trading timestamps when the provider publishes daily reference updates.

## 4. Unsupported Currencies
- Unofficial, defunct, or unlisted currencies not included in ISO 4217 or unsupported by the public API cannot be converted. In such cases, Skylet indicates that the currency pair is unsupported and offers fallback options.
