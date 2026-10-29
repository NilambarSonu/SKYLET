//
//  CurrencyConversionTests.swift
//  SkyletCoreTests
//

import XCTest
@testable import SkyletCore

final class MockRateProvider: CurrencyRateProviding, @unchecked Sendable {
    var providerName: String = "MockProvider"
    var rates: [String: Decimal] = [:]
    var shouldFail: Bool = false
    var failureError: CurrencyRateError = .networkUnavailable

    func setRate(from: CurrencyCode, to: CurrencyCode, rate: Decimal) {
        rates["\(from.rawValue)_\(to.rawValue)"] = rate
    }

    func fetchRate(from: CurrencyCode, to: CurrencyCode) async throws -> CurrencyRateEntry {
        if shouldFail {
            throw failureError
        }
        let key = "\(from.rawValue)_\(to.rawValue)"
        guard let rate = rates[key] else {
            throw CurrencyRateError.rateNotFound(to)
        }
        return CurrencyRateEntry(
            from: from,
            to: to,
            rate: rate,
            timestamp: Date(),
            providerDateString: "MockDate",
            providerName: providerName,
            isDailyReference: true
        )
    }
}

final class CurrencyConversionTests: XCTestCase {

    func testINRToINRIdentity() async throws {
        let service = CurrencyRateService()
        let result = try await service.convert(amount: 1500, from: .inr, to: .inr)
        XCTAssertEqual(result.sourceAmount, 1500)
        XCTAssertEqual(result.targetAmount, 1500)
        XCTAssertEqual(result.rate, 1.0)
        XCTAssertEqual(result.targetCurrency, .inr)
        XCTAssertFalse(result.isStale)
    }

    func testNormalConversion() async throws {
        let mock = MockRateProvider()
        mock.setRate(from: .usd, to: .inr, rate: Decimal(string: "95.22")!)

        let service = CurrencyRateService(
            primaryProvider: mock,
            fallbackProvider: nil,
            cache: CurrencyRateCache(ttl: 3600)
        )

        let result = try await service.convert(amount: 100, from: .usd, to: .inr)
        XCTAssertEqual(result.sourceAmount, 100)
        XCTAssertEqual(result.targetAmount, Decimal(string: "9522.00")!)
        XCTAssertEqual(result.rate, Decimal(string: "95.22")!)
        XCTAssertFalse(result.isCached)
        XCTAssertFalse(result.isStale)
    }

    func testDecimalPrecisionCalculation() async throws {
        let mock = MockRateProvider()
        // Precise rate with 4 decimals
        mock.setRate(from: .eur, to: .inr, rate: Decimal(string: "101.4567")!)

        let service = CurrencyRateService(
            primaryProvider: mock,
            fallbackProvider: nil,
            cache: CurrencyRateCache(ttl: 3600)
        )

        let result = try await service.convert(amount: Decimal(string: "49.99")!, from: .eur, to: .inr)
        // 49.99 * 101.4567 = 5071.820433
        let expected = Decimal(string: "49.99")! * Decimal(string: "101.4567")!
        XCTAssertEqual(result.targetAmount, expected)
    }

    func testZeroAndLargeAmounts() async throws {
        let mock = MockRateProvider()
        mock.setRate(from: .usd, to: .inr, rate: 90)

        let service = CurrencyRateService(
            primaryProvider: mock,
            fallbackProvider: nil,
            cache: CurrencyRateCache(ttl: 3600)
        )

        // Zero
        let zeroRes = try await service.convert(amount: 0, from: .usd, to: .inr)
        XCTAssertEqual(zeroRes.targetAmount, 0)

        // Large amount: 10 million USD
        let largeAmount: Decimal = 10_000_000
        let largeRes = try await service.convert(amount: largeAmount, from: .usd, to: .inr)
        XCTAssertEqual(largeRes.targetAmount, 900_000_000)
    }

    func testStaleCacheFallbackOnNetworkFailure() async throws {
        let mock = MockRateProvider()
        mock.setRate(from: .gbp, to: .inr, rate: 120)

        // Cache with very short TTL of 0.01 seconds
        let cache = CurrencyRateCache(ttl: 0.01)

        let service = CurrencyRateService(
            primaryProvider: mock,
            fallbackProvider: nil,
            cache: cache
        )

        // First successful fetch populates cache
        let first = try await service.convert(amount: 10, from: .gbp, to: .inr)
        XCTAssertFalse(first.isCached)
        XCTAssertFalse(first.isStale)

        // Wait for TTL to expire
        try await Task.sleep(nanoseconds: 30_000_000) // 30ms

        // Make provider fail
        mock.shouldFail = true

        // Conversion should succeed using stale cached rate
        let fallback = try await service.convert(amount: 10, from: .gbp, to: .inr)
        XCTAssertEqual(fallback.targetAmount, 1200)
        XCTAssertTrue(fallback.isCached)
        XCTAssertTrue(fallback.isStale)
    }

    func testNetworkFailureWithoutCacheThrows() async throws {
        let mock = MockRateProvider()
        mock.shouldFail = true

        let service = CurrencyRateService(
            primaryProvider: mock,
            fallbackProvider: nil,
            cache: CurrencyRateCache(ttl: 3600)
        )

        do {
            _ = try await service.convert(amount: 10, from: .jpy, to: .inr)
            XCTFail("Should have thrown network error")
        } catch {
            XCTAssertTrue(error is CurrencyRateError)
        }
    }

    func testCurrencyFormatting() {
        XCTAssertEqual(CurrencyFormatter.formatINR(amount: 2500), "₹2,500.00")
        XCTAssertEqual(CurrencyFormatter.format(amount: 49.99, currency: .eur), "€49.99")
        XCTAssertEqual(CurrencyFormatter.format(amount: 100, currency: .aed), "100.00 AED")

        let rateStr = CurrencyFormatter.formatRate(from: .usd, to: .inr, rate: Decimal(string: "95.22")!)
        XCTAssertEqual(rateStr, "1 USD = 95.22 INR")

        let summary = CurrencyFormatter.copyableSummary(
            fromAmount: 25,
            fromCurrency: .usd,
            toAmount: Decimal(string: "2380.50")!,
            toCurrency: .inr
        )
        XCTAssertEqual(summary, "$25.00 = ₹2,380.50")
    }
}

