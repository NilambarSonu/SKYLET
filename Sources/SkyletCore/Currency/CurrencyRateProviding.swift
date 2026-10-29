//
//  CurrencyRateProviding.swift
//  SkyletCore
//

import Foundation

/// A snapshot of an exchange rate between two currencies.
public struct CurrencyRateEntry: Codable, Hashable, Sendable {
    public let from: CurrencyCode
    public let to: CurrencyCode
    public let rate: Decimal
    public let timestamp: Date
    public let providerDateString: String
    public let providerName: String
    public let isDailyReference: Bool

    public init(
        from: CurrencyCode,
        to: CurrencyCode,
        rate: Decimal,
        timestamp: Date = Date(),
        providerDateString: String,
        providerName: String,
        isDailyReference: Bool = true
    ) {
        self.from = from
        self.to = to
        self.rate = rate
        self.timestamp = timestamp
        self.providerDateString = providerDateString
        self.providerName = providerName
        self.isDailyReference = isDailyReference
    }
}

/// Errors occurring during currency rate retrieval and conversion.
public enum CurrencyRateError: Error, LocalizedError, Sendable {
    case networkUnavailable
    case invalidResponse(Int)
    case malformedData
    case unsupportedCurrencyPair(from: CurrencyCode, to: CurrencyCode)
    case rateNotFound(CurrencyCode)
    case providerRateNonPositive(Decimal)
    case timeout

    public var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "Network connection is unavailable."
        case .invalidResponse(let statusCode):
            return "Exchange rate provider returned HTTP error \(statusCode)."
        case .malformedData:
            return "Exchange rate response could not be parsed."
        case .unsupportedCurrencyPair(let from, let to):
            return "Conversion between \(from) and \(to) is not supported by the rate provider."
        case .rateNotFound(let code):
            return "Rate for \(code) was not found in the provider response."
        case .providerRateNonPositive(let rate):
            return "Provider returned invalid non-positive rate: \(rate)."
        case .timeout:
            return "Rate request timed out."
        }
    }
}

/// Protocol defining the interface for exchange rate providers.
public protocol CurrencyRateProviding: Sendable {
    var providerName: String { get }
    func fetchRate(from: CurrencyCode, to: CurrencyCode) async throws -> CurrencyRateEntry
}

