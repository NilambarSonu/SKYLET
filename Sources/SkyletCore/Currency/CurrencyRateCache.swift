//
//  CurrencyRateCache.swift
//  SkyletCore
//

import Foundation

/// In-memory and persistent cache for exchange rates with explicit TTL and stale-data tracking.
public actor CurrencyRateCache {
    public static let shared = CurrencyRateCache()

    /// Standard TTL of 12 hours for daily reference rates
    private let ttl: TimeInterval
    private var entries: [String: CurrencyRateEntry]
    private let fileURL: URL?

    public init(ttl: TimeInterval = 12 * 3600, persistToDisk: Bool = true) {
        self.ttl = ttl
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

    public func get(from: CurrencyCode, to: CurrencyCode) -> (entry: CurrencyRateEntry, isStale: Bool)? {
        let key = cacheKey(from: from, to: to)
        guard let entry = entries[key] else { return nil }

        // Sanitize: purge any mock test data
        if entry.providerName.lowercased() == "mock" || entry.providerDateString.lowercased() == "mockdate" {
            entries.removeValue(forKey: key)
            saveToDisk()
            return nil
        }

        let age = Date().timeIntervalSince(entry.timestamp)
        let isStale = age > ttl
        return (entry, isStale)
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
