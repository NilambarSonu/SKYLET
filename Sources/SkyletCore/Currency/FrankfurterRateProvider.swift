//
//  FrankfurterRateProvider.swift
//  SkyletCore
//

import Foundation

/// Secondary / fallback exchange-rate provider using Frankfurter (European Central Bank reference rates).
public final class FrankfurterRateProvider: CurrencyRateProviding, Sendable {
    public let providerName = "Frankfurter (ECB)"
    private let session: URLSession

    public init(session: URLSession = .shared) {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 10.0
        configuration.timeoutIntervalForResource = 15.0
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: configuration)
    }

    private struct APIResponse: Decodable {
        let amount: Double
        let base: String
        let date: String
        let rates: [String: Double]
    }

    public func fetchRate(from: CurrencyCode, to: CurrencyCode) async throws -> CurrencyRateEntry {
        if from == to {
            return CurrencyRateEntry(
                from: from,
                to: to,
                rate: 1.0,
                timestamp: Date(),
                providerDateString: "Local",
                providerName: providerName,
                isDailyReference: false
            )
        }

        guard let url = URL(string: "https://api.frankfurter.dev/v1/latest?from=\(from.rawValue)&to=\(to.rawValue)") else {
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
            providerDateString: decoded.date,
            providerName: providerName,
            isDailyReference: true
        )
    }
}

