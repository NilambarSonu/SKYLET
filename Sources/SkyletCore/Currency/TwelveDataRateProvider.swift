//
//  TwelveDataRateProvider.swift
//  SkyletCore
//

import Foundation

/// Primary real-time exchange rate provider using Twelve Data Forex API.
/// Endpoint: GET https://api.twelvedata.com/exchange_rate?symbol=BASE/QUOTE
/// Authentication: HTTP Header "Authorization: apikey YOUR_API_KEY"
public final class TwelveDataRateProvider: CurrencyRateProviding, Sendable {
    public let providerName = "Twelve Data"
    private let session: URLSession
    private let keychain: KeychainStoring
    private let keyAccountName: String
    private let freshnessThreshold: TimeInterval // default: 15 minutes for live quotes

    public init(
        keychain: KeychainStoring = MacOSKeychainManager.shared,
        keyAccountName: String = "twelvedata_api_key",
        session: URLSession? = nil,
        freshnessThreshold: TimeInterval = 15 * 60
    ) {
        self.keychain = keychain
        self.keyAccountName = keyAccountName
        self.freshnessThreshold = freshnessThreshold

        if let session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.ephemeral
            config.timeoutIntervalForRequest = 8.0
            config.timeoutIntervalForResource = 12.0
            config.requestCachePolicy = .reloadIgnoringLocalCacheData
            self.session = URLSession(configuration: config)
        }
    }

    private struct APIResponse: Decodable {
        let symbol: String?
        let rate: FlexibleDecimal?
        let timestamp: Int?
        let code: Int?
        let message: String?
        let status: String?
    }

    private struct FlexibleDecimal: Decodable {
        let value: Decimal

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let str = try? container.decode(String.self), let dec = Decimal(string: str) {
                self.value = dec
            } else if let dbl = try? container.decode(Double.self) {
                self.value = Decimal(string: String(dbl)) ?? Decimal(dbl)
            } else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Expected string or number for rate")
            }
        }
    }

    public func fetchRate(from: CurrencyCode, to: CurrencyCode) async throws -> CurrencyRateEntry {
        // 1. Identity conversion
        if from == to {
            return CurrencyRateEntry(
                from: from,
                to: to,
                rate: 1.0,
                quoteTimestamp: Date(),
                fetchTimestamp: Date(),
                providerDateString: "Local (Same Currency)",
                providerName: providerName,
                freshness: .live,
                isDailyReference: false
            )
        }

        // 2. Retrieve user's Twelve Data API key from Keychain
        guard let apiKey = keychain.get(key: keyAccountName)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !apiKey.isEmpty else {
            throw CurrencyRateError.missingAPIKey("Twelve Data API key is not configured in settings.")
        }

        // 3. Prepare URL: https://api.twelvedata.com/exchange_rate?symbol=USD/INR
        let symbolString = "\(from.rawValue)/\(to.rawValue)"
        guard let encodedSymbol = symbolString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://api.twelvedata.com/exchange_rate?symbol=\(encodedSymbol)") else {
            throw CurrencyRateError.unsupportedCurrencyPair(from: from, to: to)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("apikey \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("Skylet-macOS/1.0", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError {
            if urlError.code == .timedOut {
                throw CurrencyRateError.timeout
            }
            throw CurrencyRateError.networkUnavailable
        } catch {
            throw CurrencyRateError.networkUnavailable
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CurrencyRateError.malformedData
        }

        // 4. Handle HTTP status codes
        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            throw CurrencyRateError.invalidAPIKey("Twelve Data rejected the API key (HTTP \(httpResponse.statusCode)).")
        } else if httpResponse.statusCode == 429 {
            throw CurrencyRateError.rateLimitExceeded("Twelve Data rate limit reached (HTTP 429).")
        } else if !(200...299).contains(httpResponse.statusCode) {
            throw CurrencyRateError.invalidResponse(httpResponse.statusCode)
        }

        // 5. Decode Twelve Data JSON
        let decoded: APIResponse
        do {
            decoded = try JSONDecoder().decode(APIResponse.self, from: data)
        } catch {
            throw CurrencyRateError.malformedData
        }

        // 6. Inspect API-level errors
        if let status = decoded.status, status.lowercased() == "error" {
            let msg = decoded.message ?? "Twelve Data API error"
            if decoded.code == 401 || decoded.code == 403 {
                throw CurrencyRateError.invalidAPIKey(msg)
            } else if decoded.code == 429 {
                throw CurrencyRateError.rateLimitExceeded(msg)
            } else if decoded.code == 404 || msg.localizedCaseInsensitiveContains("not found") {
                throw CurrencyRateError.unsupportedCurrencyPair(from: from, to: to)
            } else {
                throw CurrencyRateError.invalidResponse(decoded.code ?? 400)
            }
        }

        // 7. Validate symbol matches requested pair
        guard let returnedSymbol = decoded.symbol,
              returnedSymbol.uppercased() == symbolString.uppercased() else {
            throw CurrencyRateError.unsupportedCurrencyPair(from: from, to: to)
        }

        // 8. Validate positive Decimal rate
        guard let rateWrapper = decoded.rate, rateWrapper.value > 0 else {
            throw CurrencyRateError.providerRateNonPositive(decoded.rate?.value ?? 0)
        }
        let rate = rateWrapper.value

        // 9. Validate quote timestamp
        guard let epoch = decoded.timestamp, epoch > 0 else {
            throw CurrencyRateError.malformedData
        }
        let quoteDate = Date(timeIntervalSince1970: TimeInterval(epoch))
        let now = Date()
        let quoteAge = now.timeIntervalSince(quoteDate)

        // 10. Determine freshness
        let freshness: RateFreshness
        if quoteAge <= freshnessThreshold {
            freshness = .live
        } else if quoteAge <= 72 * 3600 {
            // Market closed (e.g. weekend/holidays) or slight provider delay
            freshness = .delayed
        } else {
            freshness = .stale
        }

        // Format honest UTC timestamp
        let utcFormatter = DateFormatter()
        utcFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        utcFormatter.dateFormat = "HH:mm:ss 'UTC'"
        let dateString = utcFormatter.string(from: quoteDate)

        return CurrencyRateEntry(
            from: from,
            to: to,
            rate: rate,
            quoteTimestamp: quoteDate,
            fetchTimestamp: now,
            providerDateString: dateString,
            providerName: providerName,
            freshness: freshness,
            isDailyReference: false
        )
    }
}
