//
//  CurrencyRateService.swift
//  SkyletCore
//

import Foundation

public struct CurrencyConversionResult: Equatable, Sendable {
    public let sourceAmount: Decimal
    public let sourceCurrency: CurrencyCode
    public let targetAmount: Decimal
    public let targetCurrency: CurrencyCode
    public let rate: Decimal
    public let rateDateString: String
    public let providerName: String
    public let isCached: Bool
    public let isStale: Bool
    public let freshness: RateFreshness
    public let quoteTimestamp: Date?
    public let fetchTimestamp: Date

    public init(
        sourceAmount: Decimal,
        sourceCurrency: CurrencyCode,
        targetAmount: Decimal,
        targetCurrency: CurrencyCode,
        rate: Decimal,
        rateDateString: String,
        providerName: String,
        isCached: Bool,
        isStale: Bool,
        freshness: RateFreshness = .dailyReference,
        quoteTimestamp: Date? = nil,
        fetchTimestamp: Date = Date()
    ) {
        self.sourceAmount = sourceAmount
        self.sourceCurrency = sourceCurrency
        self.targetAmount = targetAmount
        self.targetCurrency = targetCurrency
        self.rate = rate
        self.rateDateString = rateDateString
        self.providerName = providerName
        self.isCached = isCached
        self.isStale = isStale
        self.freshness = freshness
        self.quoteTimestamp = quoteTimestamp
        self.fetchTimestamp = fetchTimestamp
    }

    /// Informative, compact subtext formatted according to exact freshness and provenance rules.
    public var formattedSubtext: String {
        switch freshness {
        case .live:
            return "\(providerName) · Live quote · \(rateDateString)"
        case .delayed:
            return "\(providerName) · Delayed · Quote from \(rateDateString)"
        case .cached:
            return "\(providerName) · Cached · Quote from \(rateDateString)"
        case .dailyReference:
            return "\(providerName) · Daily reference · \(rateDateString)"
        case .stale:
            return "\(providerName) · Stale · Quote from \(rateDateString)"
        case .unavailable:
            return "\(providerName) · Unavailable"
        }
    }
}

/// Service coordinating real-time Forex providers, reference fallbacks, request deduplication,
/// and decimal-safe conversions.
public actor CurrencyRateService {
    private let realTimeProvider: CurrencyRateProviding
    private let primaryReferenceProvider: CurrencyRateProviding
    private let secondaryReferenceProvider: CurrencyRateProviding?
    private let cache: CurrencyRateCache

    /// In-flight request deduplication map
    private var inFlightRequests: [String: Task<CurrencyRateEntry, Error>] = [:]

    public init(
        realTimeProvider: CurrencyRateProviding = TwelveDataRateProvider(),
        primaryReferenceProvider: CurrencyRateProviding = ExchangeRateAPIProvider(),
        secondaryReferenceProvider: CurrencyRateProviding? = FrankfurterRateProvider(),
        cache: CurrencyRateCache = CurrencyRateCache.shared
    ) {
        self.realTimeProvider = realTimeProvider
        self.primaryReferenceProvider = primaryReferenceProvider
        self.secondaryReferenceProvider = secondaryReferenceProvider
        self.cache = cache
    }

    /// Converts a source amount from one currency to another (defaulting target to INR).
    public func convert(
        amount: Decimal,
        from source: CurrencyCode,
        to target: CurrencyCode = .inr,
        forceRefresh: Bool = false
    ) async throws -> CurrencyConversionResult {
        // 1. Identical currency short-circuit (e.g. INR to INR)
        if source == target {
            return CurrencyConversionResult(
                sourceAmount: amount,
                sourceCurrency: source,
                targetAmount: amount,
                targetCurrency: target,
                rate: 1.0,
                rateDateString: "Local (Same Currency)",
                providerName: "Local",
                isCached: false,
                isStale: false,
                freshness: .live,
                quoteTimestamp: Date(),
                fetchTimestamp: Date()
            )
        }

        // 2. Check fresh cache unless forced refresh
        if !forceRefresh, let cached = await cache.get(from: source, to: target), !cached.isStale {
            let targetAmount = calculateTargetAmount(amount: amount, rate: cached.entry.rate)
            return CurrencyConversionResult(
                sourceAmount: amount,
                sourceCurrency: source,
                targetAmount: targetAmount,
                targetCurrency: target,
                rate: cached.entry.rate,
                rateDateString: cached.entry.providerDateString,
                providerName: cached.entry.providerName,
                isCached: true,
                isStale: false,
                freshness: cached.entry.freshness,
                quoteTimestamp: cached.entry.quoteTimestamp,
                fetchTimestamp: cached.entry.fetchTimestamp
            )
        }

        // 3. Deduplicated network fetch
        let deduplicationKey = "\(source.rawValue)_\(target.rawValue)"

        let rateTask: Task<CurrencyRateEntry, Error>
        if let existing = inFlightRequests[deduplicationKey] {
            rateTask = existing
        } else {
            let task = Task<CurrencyRateEntry, Error> {
                try await self.fetchWithFallback(from: source, to: target)
            }
            inFlightRequests[deduplicationKey] = task
            rateTask = task
        }

        let entry: CurrencyRateEntry
        do {
            entry = try await rateTask.value
            inFlightRequests.removeValue(forKey: deduplicationKey)
        } catch {
            inFlightRequests.removeValue(forKey: deduplicationKey)
            // 4. If all network fetches failed, check if we have any cached entry (even stale)
            if let staleCached = await cache.get(from: source, to: target) {
                let targetAmount = calculateTargetAmount(amount: amount, rate: staleCached.entry.rate)
                return CurrencyConversionResult(
                    sourceAmount: amount,
                    sourceCurrency: source,
                    targetAmount: targetAmount,
                    targetCurrency: target,
                    rate: staleCached.entry.rate,
                    rateDateString: staleCached.entry.providerDateString,
                    providerName: staleCached.entry.providerName,
                    isCached: true,
                    isStale: true,
                    freshness: .stale,
                    quoteTimestamp: staleCached.entry.quoteTimestamp,
                    fetchTimestamp: staleCached.entry.fetchTimestamp
                )
            }
            throw error
        }

        // Cache valid entry
        await cache.set(entry)

        let targetAmount = calculateTargetAmount(amount: amount, rate: entry.rate)
        return CurrencyConversionResult(
            sourceAmount: amount,
            sourceCurrency: source,
            targetAmount: targetAmount,
            targetCurrency: target,
            rate: entry.rate,
            rateDateString: entry.providerDateString,
            providerName: entry.providerName,
            isCached: false,
            isStale: false,
            freshness: entry.freshness,
            quoteTimestamp: entry.quoteTimestamp,
            fetchTimestamp: entry.fetchTimestamp
        )
    }

    /// Fetches from real-time provider first; falls back to daily reference providers if unavailable.
    private func fetchWithFallback(from source: CurrencyCode, to target: CurrencyCode) async throws -> CurrencyRateEntry {
        var lastError: Error?

        // Attempt Twelve Data real-time provider
        do {
            let entry = try await realTimeProvider.fetchRate(from: source, to: target)
            return entry
        } catch {
            lastError = error
        }

        // Fallback to Primary Reference Provider (ExchangeRate-API)
        do {
            let entry = try await primaryReferenceProvider.fetchRate(from: source, to: target)
            return entry
        } catch {
            lastError = error
        }

        // Fallback to Secondary Reference Provider (Frankfurter)
        if let secondary = secondaryReferenceProvider {
            do {
                let entry = try await secondary.fetchRate(from: source, to: target)
                return entry
            } catch {
                lastError = error
            }
        }

        throw lastError ?? CurrencyRateError.networkUnavailable
    }

    private func calculateTargetAmount(amount: Decimal, rate: Decimal) -> Decimal {
        var result = Decimal()
        var a = amount
        var r = rate
        NSDecimalMultiply(&result, &a, &r, .plain)
        return result
    }
}


