//
//  CurrencyRateCache.swift
//  SkyletCore
//
//  In-memory and persistent cache for exchange rates with explicit TTL and stale-data tracking.
//

import Foundation

/// In-memory and persistent cache for exchange rates with explicit TTL and stale-data tracking.
public actor CurrencyRateCache {
    public static let shared = CurrencyRateCache()

    /// Default live quote cache TTL: 5 minutes (300 seconds) to conserve API quotas
    public static let defaultLiveQuoteTTL: TimeInterval = 300
    /// Default reference rate cache TTL: 12 hours (43,200 seconds)
    public static let defaultReferenceRateTTL: TimeInterval = 12 * 3600
    /// Live quote freshness window: 15 minutes (900 seconds)
    public static let defaultLiveFreshnessThreshold: TimeInterval = 15 * 60
    /// Unified maximum stale threshold: 72 hours (259,200 seconds, covering weekend market halts)
    public static let defaultMaxStaleThreshold: TimeInterval = 72 * 3600

    private var entries: [String: CurrencyRateEntry]
    private let fileURL: URL?
    private let dateProvider: @Sendable () -> Date

    public init(
        persistToDisk: Bool = true,
        dateProvider: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.dateProvider = dateProvider
        if persistToDisk, let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            let skyletDir = cacheDir.appendingPathComponent("Skylet", isDirectory: true)
            try? FileManager.default.createDirectory(at: skyletDir, withIntermediateDirectories: true)
            let url = skyletDir.appendingPathComponent("rates_cache.json")
            self.fileURL = url
            self.entries = Self.loadEntries(from: url)
        } else {
            self.fileURL = nil
            self.entries = [:]
        }
    }

    private func cacheKey(from: CurrencyCode, to: CurrencyCode) -> String {
        "\(from.rawValue)_\(to.rawValue)"
    }

    /// Retrieves an entry from cache with rigorously preserved quote freshness and provenance.
    ///
    /// Rules:
    /// 1. A quote originally classified as `.stale` or `.delayed` never becomes `.cached` merely because it was fetched recently.
    /// 2. Quote age (underlying market observation time) and Fetch age (retrieval time) are tracked separately.
    /// 3. Cached live quotes are labeled `.cached`, never falsely marked `.live`.
    /// 4. Quotes exceeding the unified 72-hour threshold transition to `.stale`.
    public func get(
        from: CurrencyCode,
        to: CurrencyCode,
        liveTTL: TimeInterval = defaultLiveQuoteTTL,
        referenceTTL: TimeInterval = defaultReferenceRateTTL,
        asOf date: Date? = nil
    ) -> (entry: CurrencyRateEntry, isStale: Bool)? {
        let key = cacheKey(from: from, to: to)
        guard let entry = entries[key] else { return nil }

        // Sanitize: purge any synthetic mock test data
        if entry.providerName.lowercased() == "mock" || entry.providerDateString.lowercased() == "mockdate" {
            entries.removeValue(forKey: key)
            saveToDisk()
            return nil
        }

        let now = date ?? dateProvider()
        let fetchAge = now.timeIntervalSince(entry.fetchTimestamp)
        let quoteDate = entry.quoteTimestamp ?? entry.fetchTimestamp
        let quoteAge = now.timeIntervalSince(quoteDate)

        // Effective TTL for cache retention
        let effectiveTTL = entry.isDailyReference ? referenceTTL : liveTTL
        let isCacheExpired = fetchAge > effectiveTTL

        // Rigorous freshness derivation
        let derivedFreshness: RateFreshness
        if entry.freshness == .stale || quoteAge > Self.defaultMaxStaleThreshold || fetchAge > Self.defaultMaxStaleThreshold {
            derivedFreshness = .stale
        } else if entry.isDailyReference {
            derivedFreshness = (quoteAge > referenceTTL || isCacheExpired) ? .stale : .dailyReference
        } else if entry.freshness == .delayed || quoteAge > Self.defaultLiveFreshnessThreshold {
            derivedFreshness = .delayed
        } else {
            // Original quote was live and quoteAge <= 15m
            derivedFreshness = isCacheExpired ? .stale : .cached
        }

        let isStale = (derivedFreshness == .stale || isCacheExpired)

        let presentationEntry = CurrencyRateEntry(
            from: entry.from,
            to: entry.to,
            rate: entry.rate,
            quoteTimestamp: entry.quoteTimestamp,
            fetchTimestamp: entry.fetchTimestamp,
            providerDateString: entry.providerDateString,
            providerName: entry.providerName,
            freshness: derivedFreshness,
            isDailyReference: entry.isDailyReference
        )

        return (presentationEntry, isStale)
    }

    public func set(_ entry: CurrencyRateEntry) {
        // Refuse to persist synthetic mock test data to real cache
        if entry.providerName.lowercased() == "mock" || entry.providerDateString.lowercased() == "mockdate" {
            let key = cacheKey(from: entry.from, to: entry.to)
            entries[key] = entry
            return
        }
        let key = cacheKey(from: entry.from, to: entry.to)
        entries[key] = entry
        saveToDisk()
    }

    public func clear() {
        entries.removeAll()
        if let fileURL {
            try? FileManager.default.removeItem(at: fileURL)
        }
    }

    private static func loadEntries(from fileURL: URL) -> [String: CurrencyRateEntry] {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([String: CurrencyRateEntry].self, from: data) else {
            return [:]
        }
        return decoded.filter { _, entry in
            entry.providerName.lowercased() != "mock" &&
            entry.providerDateString.lowercased() != "mockdate"
        }
    }

    private func saveToDisk() {
        guard let fileURL else { return }
        if let data = try? JSONEncoder().encode(entries) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }
}
