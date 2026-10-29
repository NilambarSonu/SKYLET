//
//  ExchangeRateAPIProvider.swift
//  SkyletCore
//

import Foundation

/// Primary exchange-rate provider using the documented keyless Open Exchange Rate API (ExchangeRate-API).
/// Provides free daily reference rates for 162 currencies including INR, SAR, AED, BDT, PKR, NPR.
public final class ExchangeRateAPIProvider: CurrencyRateProviding, Sendable {
    public let providerName = "ExchangeRate-API"
    private let session: URLSession

    public init(session: URLSession = .shared) {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 10.0
        configuration.timeoutIntervalForResource = 15.0
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: configuration)
    }

    private struct APIResponse: Decodable {
        let result: String
        let base_code: String
        let time_last_update_utc: String?
        let rates: [String: Double]
    }

    public func fetchRate(from: CurrencyCode, to: CurrencyCode) async throws -> CurrencyRateEntry {
        // Special case: identical currencies
        if from == to {
            return CurrencyRateEntry(
                from: from,
                to: to,
                rate: 1.0,
                timestamp: Date(),
                providerDateString: "Local (Identical Currency)",
                providerName: providerName,
                isDailyReference: false
            )
        }

        guard let url = URL(string: "https://open.er-api.com/v6/latest/\(from.rawValue)") else {
            throw CurrencyRateError.unsupportedCurrencyPair(from: from, to: to)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Skylet-macOS/1.0", forHTTPHeaderField: "User-Agent")

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

        guard (200...299).contains(httpResponse.statusCode) else {
            throw CurrencyRateError.invalidResponse(httpResponse.statusCode)
        }

        let decoded: APIResponse
        do {
            decoded = try JSONDecoder().decode(APIResponse.self, from: data)
        } catch {
            throw CurrencyRateError.malformedData
        }

        guard decoded.result.lowercased() == "success" else {
            throw CurrencyRateError.unsupportedCurrencyPair(from: from, to: to)
        }

        guard let rawRate = decoded.rates[to.rawValue] else {
            throw CurrencyRateError.rateNotFound(to)
        }

        let decimalRate = Decimal(rawRate)
        guard decimalRate > 0 else {
            throw CurrencyRateError.providerRateNonPositive(decimalRate)
        }

        return CurrencyRateEntry(
            from: from,
            to: to,
            rate: decimalRate,
            timestamp: Date(),
            providerDateString: decoded.time_last_update_utc ?? "Latest",
            providerName: providerName,
            isDailyReference: true
        )
    }
}

