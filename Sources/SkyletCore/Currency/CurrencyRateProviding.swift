//
//  CurrencyRateProviding.swift
//  SkyletCore
//

import Foundation

/// Explicit source freshness status for currency exchange rates.
@frozen
public enum RateFreshness: String, Codable, Sendable, Equatable {
    case live = "LIVE"
    case delayed = "DELAYED"
    case cached = "CACHED"
    case dailyReference = "DAILY REFERENCE"
    case stale = "STALE"
    case unavailable = "UNAVAILABLE"

    public var badgeTitle: String {
        switch self {
        case .live: return "Live quote"
        case .delayed: return "Delayed quote"
        case .cached: return "Cached"
        case .dailyReference: return "Daily reference"
        case .stale: return "Stale"
        case .unavailable: return "Unavailable"
        }
    }
}

/// A snapshot of an exchange rate between two currencies with exact provenance metadata.
public struct CurrencyRateEntry: Codable, Hashable, Sendable {
    public let from: CurrencyCode
    public let to: CurrencyCode
    public let rate: Decimal
    public let quoteTimestamp: Date?
    public let fetchTimestamp: Date
    public let providerDateString: String
    public let providerName: String
    public let freshness: RateFreshness
    public let isDailyReference: Bool

    /// Full initializer with explicit provenance and quote timestamp.
    public init(
        from: CurrencyCode,
        to: CurrencyCode,
        rate: Decimal,
        quoteTimestamp: Date? = nil,
        fetchTimestamp: Date = Date(),
        providerDateString: String,
        providerName: String,
        freshness: RateFreshness = .dailyReference,
        isDailyReference: Bool = true
    ) {
        self.from = from
        self.to = to
        self.rate = rate
        self.quoteTimestamp = quoteTimestamp
        self.fetchTimestamp = fetchTimestamp
        self.providerDateString = providerDateString
        self.providerName = providerName
        self.freshness = freshness
        self.isDailyReference = isDailyReference
    }

    /// Backward-compatible initializer.
    public init(
        from: CurrencyCode,
        to: CurrencyCode,
        rate: Decimal,
        timestamp: Date = Date(),
        providerDateString: String,
        providerName: String,
        isDailyReference: Bool = true
    ) {
        self.init(
            from: from,
            to: to,
            rate: rate,
            quoteTimestamp: timestamp,
            fetchTimestamp: timestamp,
            providerDateString: providerDateString,
            providerName: providerName,
            freshness: isDailyReference ? .dailyReference : .live,
            isDailyReference: isDailyReference
        )
    }

    /// Accessor for timestamp compatibility.
    public var timestamp: Date {
        quoteTimestamp ?? fetchTimestamp
    }
}

/// Errors occurring during currency rate retrieval and conversion.
public enum CurrencyRateError: Error, LocalizedError, Sendable, Equatable {
    case networkUnavailable
    case invalidResponse(Int)
    case malformedData
    case unsupportedCurrencyPair(from: CurrencyCode, to: CurrencyCode)
    case rateNotFound(CurrencyCode)
    case providerRateNonPositive(Decimal)
    case timeout
    case missingAPIKey(String)
    case invalidAPIKey(String)
    case rateLimitExceeded(String)
    case marketClosed(String)

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
        case .missingAPIKey(let msg):
            return msg.isEmpty ? "Twelve Data API key is not configured in settings." : msg
        case .invalidAPIKey(let msg):
            return msg.isEmpty ? "Invalid Twelve Data API key." : msg
        case .rateLimitExceeded(let msg):
            return msg.isEmpty ? "Twelve Data API rate limit reached (free plan: 8 credits/min). Please try again in a moment." : msg
        case .marketClosed(let msg):
            return msg.isEmpty ? "Forex market is closed. Displaying last verified quote." : msg
        }
    }
}

/// Protocol defining the interface for exchange rate providers.
public protocol CurrencyRateProviding: Sendable {
    var providerName: String { get }
    func fetchRate(from: CurrencyCode, to: CurrencyCode) async throws -> CurrencyRateEntry
}

