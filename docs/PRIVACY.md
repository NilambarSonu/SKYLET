# Privacy Policy for Skylet

**Skylet** is designed from the ground up to respect user privacy and operate quietly as a native macOS utility.

## 1. Local Parsing & Privacy First
- All input parsing and currency symbol extraction occurs **strictly on your Mac**.
- When you paste text into Skylet (or click "Paste"), the text is processed locally in memory.
- Skylet **never** sends the full pasted text, paragraph, or clipboard content across the network.

## 2. Minimal Network Exchange Requests
- To fetch current exchange rates, Skylet transmits only the standard 3-letter currency pair request (e.g., `USD` to `INR`) to the public exchange rate provider.
- No personal data, IP-bound identifiers, account credentials, or device identifiers are sent with rate requests.
- The default exchange rate provider is **ExchangeRate-API** (`open.er-api.com`), with fallback to **Frankfurter** (`api.frankfurter.dev`). Both provide keyless, free, public daily reference rates.

## 3. Explicit Clipboard Interaction
- Skylet **never** continuously polls, monitors, or scrapes your system clipboard.
- The clipboard is read **only** when you click the explicit "Paste" action.
- Skylet does not request or require Accessibility permissions (`AXUIElement`) to scrape text from other applications.

## 4. No Telemetry, Analytics, or Tracking
- Skylet contains **zero** third-party analytics SDKs, trackers, or crash-reporting libraries.
- Skylet does not collect or log usage statistics, converted amounts, conversion history, or user behavior.

## 5. Storage & Caching
- Exchange rates are cached locally in standard temporary storage (`~/Library/Caches/Skylet/rates_cache.json`) to minimize network bandwidth and provide offline resilience.
- The cache stores only public currency exchange rates and timestamps, never personal information or transaction history.

