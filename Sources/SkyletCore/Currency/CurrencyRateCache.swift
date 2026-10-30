//
//  CurrencyRateCache.swift
//  SkyletCore
//

import Foundation

/// In-memory and persistent cache for exchange rates with explicit TTL and stale-data tracking.
public actor CurrencyRateCache {
    public static let shared = CurrencyRateCache()

    /// Default live quote TTL: 5 minutes (300 seconds) to conserve API quotas
    public static let defaultLiveQuoteTTL: TimeInterval = 300
    /// Reference rate TTL: 12 hours (43200 seconds)
    public static let defaultReferenceRateTTL: TimeInterval = 12 * 3600
    /// Maximum stale threshold: 24 hours
    public static let defaultMaxStaleThreshold: TimeInterval = 24 * 3600

    private var entries: [String: CurrencyRateEntry]
    private let fileURL: URL?

    public init(persistToDisk: Bool = true) {
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

    /// Retrieves an entry from cache with updated freshness status.
    /// Live quotes from cache are accurately tagged as `.cached` (or `.stale` if older than max threshold).
    public func get(
        from: CurrencyCode,
        to: CurrencyCode,
        liveTTL: TimeInterval = defaultLiveQuoteTTL,
        referenceTTL: TimeInterval = defaultReferenceRateTTL
    ) -> (entry: CurrencyRateEntry, isStale: Bool)? {
        let key = cacheKey(from: from, to: to)
        guard let entry = entries[key] else { return nil }

        // Sanitize: purge any mock test data
        if entry.providerName.lowercased() == "mock" || entry.providerDateString.lowercased() == "mockdate" {
            entries.removeValue(forKey: key)
            saveToDisk()
            return nil
        }

        let now = Date()
        let fetchAge = now.timeIntervalSince(entry.fetchTimestamp)

        // Determine effective TTL based on entry type
        let effectiveTTL = entry.isDailyReference ? referenceTTL : liveTTL
        let isStale = fetchAge > effectiveTTL

        // Honest freshness: never show cached quote as LIVE
        let derivedFreshness: RateFreshness
        if fetchAge > Self.defaultMaxStaleThreshold {
            derivedFreshness = .stale
        } else if entry.isDailyReference {
            derivedFreshness = isStale ? .stale : .dailyReference
        } else {
            derivedFreshness = isStale ? .stale : .cached
        }

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
        // Filter out any mock test entries
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
