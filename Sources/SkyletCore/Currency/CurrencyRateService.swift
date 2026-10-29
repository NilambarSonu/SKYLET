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

    public init(
        sourceAmount: Decimal,
        sourceCurrency: CurrencyCode,
        targetAmount: Decimal,
        targetCurrency: CurrencyCode,
        rate: Decimal,
        rateDateString: String,
        providerName: String,
        isCached: Bool,
        isStale: Bool
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
    }
}

/// Service that coordinates rate providers, caching, decimal-safe conversions, and offline fallbacks.
public actor CurrencyRateService {
    private let primaryProvider: CurrencyRateProviding
    private let fallbackProvider: CurrencyRateProviding?
    private let cache: CurrencyRateCache

    public init(
        primaryProvider: CurrencyRateProviding = ExchangeRateAPIProvider(),
        fallbackProvider: CurrencyRateProviding? = FrankfurterRateProvider(),
        cache: CurrencyRateCache = CurrencyRateCache.shared
    ) {
        self.primaryProvider = primaryProvider
        self.fallbackProvider = fallbackProvider
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
                isStale: false
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
                isStale: false
            )
        }

        // 3. Perform network fetch with primary and fallback providers
        var lastError: Error?
        do {
            let entry = try await primaryProvider.fetchRate(from: source, to: target)
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
                isStale: false
            )
        } catch {
            lastError = error
        }

        // Try fallback provider if configured
        if let fallback = fallbackProvider {
            do {
                let entry = try await fallback.fetchRate(from: source, to: target)
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
                    isStale: false
                )
            } catch {
                lastError = error
            }
        }

        // 4. If network failed, check if we have any cached entry (even stale)
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
                isStale: true
            )
        }

        // No rate available from network or cache
        throw lastError ?? CurrencyRateError.networkUnavailable
    }

    private func calculateTargetAmount(amount: Decimal, rate: Decimal) -> Decimal {
        amount * rate
    }
}

