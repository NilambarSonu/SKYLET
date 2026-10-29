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

    public init(ttl: TimeInterval = 12 * 3600) {
        self.ttl = ttl
        if let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
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

        let age = Date().timeIntervalSince(entry.timestamp)
        let isStale = age > ttl
        return (entry, isStale)
    }

    public func set(_ entry: CurrencyRateEntry) {
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
        return decoded
    }

    private func saveToDisk() {
        guard let fileURL else { return }
        if let data = try? JSONEncoder().encode(entries) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }
}
