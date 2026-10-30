//
//  main.swift
//  SkyletTestsRunner
//
//  Standalone test runner executing all unit tests directly without Xcode framework dependencies.
//

import Foundation
import SkyletCore

@MainActor
func runAllTests() async {
    print("==================================================")
    print("           SKYLET AUTOMATED TEST SUITE            ")
    print("==================================================")

    var passed = 0
    var failed = 0

    func assert(_ condition: Bool, _ name: String) {
        if condition {
            passed += 1
            print("  ✓ \(name)")
        } else {
            failed += 1
            print("  ✗ FAIL: \(name)")
        }
    }

    print("\n[1/3] Currency Parser Tests")

    // Empty and whitespace
    assert(CurrencyParser.parse("") == .empty, "Empty input returns .empty")
    assert(CurrencyParser.parse("   \n\t  ") == .empty, "Whitespace input returns .empty")

    // Invalid string
    if case .invalidAmount = CurrencyParser.parse("hello world without numbers") {
        assert(true, "Alphabetic text returns .invalidAmount")
    } else {
        assert(false, "Alphabetic text returns .invalidAmount")
    }

    // Bare numbers
    assert(CurrencyParser.parse("25") == .amountOnly(amount: 25, rawAmountString: "25"), "Bare number 25 returns .amountOnly")
    assert(CurrencyParser.parse("49.99") == .amountOnly(amount: Decimal(string: "49.99")!, rawAmountString: "49.99"), "Bare decimal 49.99 returns .amountOnly")

    // Unambiguous: EUR
    assert(CurrencyParser.parse("€49.99") == .unambiguous(amount: Decimal(string: "49.99")!, currency: .eur, rawAmountString: "49.99"), "Symbol €49.99 parsed as EUR")
    assert(CurrencyParser.parse("49.99 EUR") == .unambiguous(amount: Decimal(string: "49.99")!, currency: .eur, rawAmountString: "49.99"), "Code 49.99 EUR parsed as EUR")
    assert(CurrencyParser.parse("25 euros") == .unambiguous(amount: 25, currency: .eur, rawAmountString: "25"), "Alias 25 euros parsed as EUR")

    // Unambiguous: GBP
    assert(CurrencyParser.parse("£12.50") == .unambiguous(amount: Decimal(string: "12.50")!, currency: .gbp, rawAmountString: "12.50"), "Symbol £12.50 parsed as GBP")

    // Unambiguous: INR
    assert(CurrencyParser.parse("₹100") == .unambiguous(amount: 100, currency: .inr, rawAmountString: "100"), "Symbol ₹100 parsed as INR")
    assert(CurrencyParser.parse("INR 100") == .unambiguous(amount: 100, currency: .inr, rawAmountString: "100"), "Code INR 100 parsed as INR")
    assert(CurrencyParser.parse("100 INR") == .unambiguous(amount: 100, currency: .inr, rawAmountString: "100"), "Suffix 100 INR parsed as INR")

    // Unambiguous: JPY
    assert(CurrencyParser.parse("JPY 5000") == .unambiguous(amount: 5000, currency: .jpy, rawAmountString: "5000"), "Code JPY 5000 parsed as JPY")
    assert(CurrencyParser.parse("5000 yen") == .unambiguous(amount: 5000, currency: .jpy, rawAmountString: "5000"), "Alias 5000 yen parsed as JPY")

    // Unambiguous: AED
    assert(CurrencyParser.parse("AED 100") == .unambiguous(amount: 100, currency: .aed, rawAmountString: "100"), "Code AED 100 parsed as AED")

    // Unambiguous: USD explicit
    assert(CurrencyParser.parse("USD 25") == .unambiguous(amount: 25, currency: .usd, rawAmountString: "25"), "Code USD 25 parsed as USD")
    assert(CurrencyParser.parse("25 USD") == .unambiguous(amount: 25, currency: .usd, rawAmountString: "25"), "Suffix 25 USD parsed as USD")
    assert(CurrencyParser.parse("25 US dollars") == .unambiguous(amount: 25, currency: .usd, rawAmountString: "25"), "Alias 25 US dollars parsed as USD")

    // Ambiguous: $
    if case .ambiguous(let amount, let symbol, let candidates, _) = CurrencyParser.parse("$25") {
        assert(amount == 25 && symbol == "$" && candidates.contains(.usd) && candidates.contains(.cad), "Symbol $25 flagged as ambiguous candidates")
    } else {
        assert(false, "Symbol $25 flagged as ambiguous candidates")
    }

    // Ambiguous: ¥
    if case .ambiguous(let amount, let symbol, let candidates, _) = CurrencyParser.parse("¥5000") {
        assert(amount == 5000 && symbol == "¥" && candidates == [.jpy, .cny], "Symbol ¥5000 flagged as ambiguous between JPY and CNY")
    } else {
        assert(false, "Symbol ¥5000 flagged as ambiguous between JPY and CNY")
    }

    // Ambiguous: Rs
    if case .ambiguous(let amount, let symbol, let candidates, _) = CurrencyParser.parse("Rs 100") {
        assert(amount == 100 && symbol == "RS" && candidates.contains(.inr), "Symbol Rs 100 flagged as ambiguous South Asian rupee")
    } else {
        assert(false, "Symbol Rs 100 flagged as ambiguous South Asian rupee")
    }

    // Separators
    if case .ambiguous(let amount, _, _, _) = CurrencyParser.parse("$1,299.50") {
        assert(amount == Decimal(string: "1299.50")!, "US separator 1,299.50 parsed correctly")
    } else {
        assert(false, "US separator 1,299.50 parsed correctly")
    }

    assert(CurrencyParser.parse("€1.299,50") == .unambiguous(amount: Decimal(string: "1299.50")!, currency: .eur, rawAmountString: "1.299,50"), "EU separator 1.299,50 parsed correctly")
    assert(CurrencyParser.parse("₹1,00,000") == .unambiguous(amount: 100000, currency: .inr, rawAmountString: "1,00,000"), "Indian separator 1,00,000 parsed correctly")

    // Negative and zero
    assert(CurrencyParser.parse("-49.99 EUR") == .unambiguous(amount: Decimal(string: "-49.99")!, currency: .eur, rawAmountString: "-49.99"), "Negative amount -49.99 EUR parsed")
    assert(CurrencyParser.parse("0 USD") == .unambiguous(amount: 0, currency: .usd, rawAmountString: "0"), "Zero amount 0 USD parsed")

    // Multiple amounts
    if case .multipleAmountsFound(let amounts) = CurrencyParser.parse("The price starts at $25 but goes up to $75.") {
        assert(amounts.count == 2 && amounts.contains(25) && amounts.contains(75), "Multiple amounts identified without silent guessing")
    } else {
        assert(false, "Multiple amounts identified without silent guessing")
    }

    // Embedded in text with trailing punctuation
    if case .ambiguous(let amount, let symbol, _, let raw) = CurrencyParser.parse("Your subscription fee will be $25.") {
        assert(amount == 25 && symbol == "$" && raw == "25", "Embedded in sentence with period trailing handled cleanly")
    } else {
        assert(false, "Embedded in sentence with period trailing handled cleanly")
    }

    // Unknown currency
    assert(CurrencyParser.parse("100 XYZ") == .unambiguous(amount: 100, currency: "XYZ", rawAmountString: "100"), "Valid ISO code 100 XYZ recognized as ISO currency")

    print("\n[2/3] Currency Conversion & Formatting Tests")

    // Mock Provider class
    final class LocalMockProvider: CurrencyRateProviding, @unchecked Sendable {
        let providerName = "Mock"
        var rates: [String: Decimal] = [:]
        var shouldFail = false

        func fetchRate(from: CurrencyCode, to: CurrencyCode) async throws -> CurrencyRateEntry {
            if shouldFail { throw CurrencyRateError.networkUnavailable }
            let key = "\(from.rawValue)_\(to.rawValue)"
            guard let rate = rates[key] else { throw CurrencyRateError.rateNotFound(to) }
            return CurrencyRateEntry(from: from, to: to, rate: rate, providerDateString: "MockDate", providerName: providerName)
        }
    }

    let mockProvider = LocalMockProvider()
    mockProvider.rates["USD_INR"] = Decimal(string: "95.22")!
    mockProvider.rates["EUR_INR"] = Decimal(string: "101.4567")!

    let service = CurrencyRateService(
        realTimeProvider: mockProvider,
        primaryReferenceProvider: mockProvider,
        secondaryReferenceProvider: nil,
        cache: CurrencyRateCache(persistToDisk: false)
    )

    // INR-to-INR identity
    do {
        let inrResult = try await service.convert(amount: 1500, from: .inr, to: .inr)
        assert(inrResult.sourceAmount == 1500 && inrResult.targetAmount == 1500 && inrResult.rate == 1.0, "INR-to-INR identity conversion succeeds instantly")
    } catch {
        assert(false, "INR-to-INR identity conversion succeeds instantly")
    }

    // Normal conversion
    do {
        let convResult = try await service.convert(amount: 100, from: .usd, to: .inr)
        assert(convResult.targetAmount == Decimal(string: "9522.00")! && convResult.rate == Decimal(string: "95.22")!, "USD to INR decimal conversion calculates correctly")
    } catch {
        assert(false, "USD to INR decimal conversion calculates correctly")
    }

    // High decimal precision
    do {
        let preciseResult = try await service.convert(amount: Decimal(string: "49.99")!, from: .eur, to: .inr)
        let expected = Decimal(string: "49.99")! * Decimal(string: "101.4567")!
        assert(preciseResult.targetAmount == expected, "High decimal precision calculation has no floating-point rounding errors")
    } catch {
        assert(false, "High decimal precision calculation has no floating-point rounding errors")
    }

    // Formatting
    assert(CurrencyFormatter.formatINR(amount: 2500) == "₹2,500.00", "CurrencyFormatter.formatINR formats with ₹ and commas")
    assert(CurrencyFormatter.format(amount: 49.99, currency: .eur) == "€49.99", "CurrencyFormatter.format formats EUR with €")
    assert(CurrencyFormatter.format(amount: 100, currency: .aed) == "100.00 AED", "CurrencyFormatter.format formats AED with code suffix")
    assert(CurrencyFormatter.formatRate(from: .usd, to: .inr, rate: Decimal(string: "95.22")!) == "1 USD = 95.22 INR", "CurrencyFormatter.formatRate formats rate pair")
    assert(CurrencyFormatter.formatRateCompact(from: .usd, to: .inr, rate: Decimal(string: "95.24")!) == "1 USD = ₹95.24", "CurrencyFormatter.formatRateCompact formats with ₹ symbol for INR")
    assert(CurrencyFormatter.copyableSummary(fromAmount: 25, fromCurrency: .usd, toAmount: Decimal(string: "2380.50")!) == "$25.00 = ₹2,380.50", "CurrencyFormatter.copyableSummary formats copyable text")

    print("\n[3/4] Real-Time FX, Twelve Data & Keychain Tests")

    // Mock URLProtocol for isolated Twelve Data networking tests
    final class MockURLProtocol: URLProtocol, @unchecked Sendable {
        nonisolated(unsafe) static var mockResponseData: Data?
        nonisolated(unsafe) static var mockStatusCode: Int = 200
        nonisolated(unsafe) static var mockError: Error?
        nonisolated(unsafe) static var lastRequest: URLRequest?

        override class func canInit(with request: URLRequest) -> Bool { true }
        override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

        override func startLoading() {
            Self.lastRequest = request
            if let error = Self.mockError {
                client?.urlProtocol(self, didFailWithError: error)
                return
            }

            let response = HTTPURLResponse(
                url: request.url ?? URL(string: "https://api.twelvedata.com/exchange_rate")!,
                statusCode: Self.mockStatusCode,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)

            if let data = Self.mockResponseData {
                client?.urlProtocol(self, didLoad: data)
            }
            client?.urlProtocolDidFinishLoading(self)
        }

        override func stopLoading() {}
    }

    func makeMockSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }

    // 1. Keychain storage and retrieval
    let memKeychain = InMemoryKeychainManager()
    assert(memKeychain.get(key: "test_key") == nil, "Keychain initially empty for key")
    try! memKeychain.save(key: "test_key", value: "secret_12345")
    assert(memKeychain.get(key: "test_key") == "secret_12345", "Keychain saves and retrieves API key correctly")
    try! memKeychain.save(key: "test_key", value: "updated_secret")
    assert(memKeychain.get(key: "test_key") == "updated_secret", "Keychain updates existing key")
    try! memKeychain.delete(key: "test_key")
    assert(memKeychain.get(key: "test_key") == nil, "Keychain deletes key successfully")

    // 2. Twelve Data: Missing API Key
    let emptyKeychain = InMemoryKeychainManager()
    let mockSession = makeMockSession()
    let providerWithNoKey = TwelveDataRateProvider(keychain: emptyKeychain, session: mockSession)
    do {
        _ = try await providerWithNoKey.fetchRate(from: .usd, to: .inr)
        assert(false, "Twelve Data with missing key should throw missingAPIKey")
    } catch CurrencyRateError.missingAPIKey {
        assert(true, "Twelve Data with missing key throws CurrencyRateError.missingAPIKey")
    } catch {
        assert(false, "Twelve Data with missing key threw unexpected error: \(error)")
    }

    // 3. Twelve Data: Valid JSON response & Authorization header check
    let validKeychain = InMemoryKeychainManager(initialItems: ["twelvedata_api_key": "valid_td_key_xyz"])
    let liveEpoch = Int(Date().timeIntervalSince1970) - 60 // 1 minute ago
    let validJSON = """
    {"symbol": "USD/INR", "rate": 95.2450, "timestamp": \(liveEpoch)}
    """.data(using: .utf8)!
    MockURLProtocol.mockResponseData = validJSON
    MockURLProtocol.mockStatusCode = 200
    MockURLProtocol.mockError = nil

    let validProvider = TwelveDataRateProvider(keychain: validKeychain, session: mockSession, freshnessThreshold: 900)
    do {
        let entry = try await validProvider.fetchRate(from: .usd, to: .inr)
        assert(entry.from == .usd && entry.to == .inr, "Twelve Data returned requested currency pair")
        assert(entry.rate == Decimal(string: "95.2450")!, "Twelve Data rate decoded accurately as Decimal")
        assert(entry.freshness == .live, "Twelve Data within freshness threshold marked as LIVE")
        assert(entry.providerName == "Twelve Data", "Twelve Data providerName is correctly labeled")
        assert(MockURLProtocol.lastRequest?.value(forHTTPHeaderField: "Authorization") == "apikey valid_td_key_xyz", "Twelve Data sends Authorization: apikey header")
    } catch {
        assert(false, "Twelve Data valid response failed: \(error)")
    }

    // 4. Twelve Data: String rate format in JSON parsed with Decimal safety
    let stringRateJSON = """
    {"symbol": "USD/INR", "rate": "95.29615", "timestamp": 1717000000}
    """.data(using: .utf8)!
    MockURLProtocol.mockResponseData = stringRateJSON
    do {
        let entry = try await validProvider.fetchRate(from: .usd, to: .inr)
        assert(entry.rate == Decimal(string: "95.29615")!, "Twelve Data string rate decoded with decimal safety")
    } catch {
        assert(false, "Twelve Data string rate decoding failed: \(error)")
    }

    // 5. Twelve Data: Invalid API key (HTTP 401 & JSON error)
    let invalidKeyJSON = """
    {"code": 401, "message": "apikey parameter is incorrect", "status": "error"}
    """.data(using: .utf8)!
    MockURLProtocol.mockResponseData = invalidKeyJSON
    MockURLProtocol.mockStatusCode = 401
    do {
        _ = try await validProvider.fetchRate(from: .usd, to: .inr)
        assert(false, "Twelve Data 401 should throw invalidAPIKey")
    } catch CurrencyRateError.invalidAPIKey {
        assert(true, "Twelve Data 401 correctly throws CurrencyRateError.invalidAPIKey")
    } catch {
        assert(false, "Twelve Data 401 threw unexpected error: \(error)")
    }

    // 6. Twelve Data: Rate limit reached (HTTP 429)
    let rateLimitJSON = """
    {"code": 429, "message": "You have reached your API call limit", "status": "error"}
    """.data(using: .utf8)!
    MockURLProtocol.mockResponseData = rateLimitJSON
    MockURLProtocol.mockStatusCode = 429
    do {
        _ = try await validProvider.fetchRate(from: .usd, to: .inr)
        assert(false, "Twelve Data 429 should throw rateLimitExceeded")
    } catch CurrencyRateError.rateLimitExceeded {
        assert(true, "Twelve Data 429 correctly throws CurrencyRateError.rateLimitExceeded")
    } catch {
        assert(false, "Twelve Data 429 threw unexpected error: \(error)")
    }

    // 7. Twelve Data: Unsupported currency pair (HTTP 404)
    let notFoundJSON = """
    {"code": 404, "message": "Cannot find requested symbol", "status": "error"}
    """.data(using: .utf8)!
    MockURLProtocol.mockResponseData = notFoundJSON
    MockURLProtocol.mockStatusCode = 200
    do {
        _ = try await validProvider.fetchRate(from: .usd, to: .inr)
        assert(false, "Twelve Data 404 symbol should throw unsupportedCurrencyPair")
    } catch CurrencyRateError.unsupportedCurrencyPair {
        assert(true, "Twelve Data 404 correctly throws CurrencyRateError.unsupportedCurrencyPair")
    } catch {
        assert(false, "Twelve Data 404 threw unexpected error: \(error)")
    }

    // 8. Twelve Data: Malformed JSON
    MockURLProtocol.mockResponseData = "not-json-content".data(using: .utf8)!
    MockURLProtocol.mockStatusCode = 200
    do {
        _ = try await validProvider.fetchRate(from: .usd, to: .inr)
        assert(false, "Malformed JSON should throw malformedData")
    } catch CurrencyRateError.malformedData {
        assert(true, "Malformed JSON correctly throws CurrencyRateError.malformedData")
    } catch {
        assert(false, "Malformed JSON threw unexpected error: \(error)")
    }

    // 9. Twelve Data: Missing timestamp
    let missingTimestampJSON = """
    {"symbol": "USD/INR", "rate": 95.24}
    """.data(using: .utf8)!
    MockURLProtocol.mockResponseData = missingTimestampJSON
    do {
        _ = try await validProvider.fetchRate(from: .usd, to: .inr)
        assert(false, "Missing timestamp should throw malformedData")
    } catch CurrencyRateError.malformedData {
        assert(true, "Missing timestamp in response correctly throws CurrencyRateError.malformedData")
    } catch {
        assert(false, "Missing timestamp threw unexpected error: \(error)")
    }

    // 10. Twelve Data: Zero or non-positive rate
    let zeroRateJSON = """
    {"symbol": "USD/INR", "rate": 0, "timestamp": 1717000000}
    """.data(using: .utf8)!
    MockURLProtocol.mockResponseData = zeroRateJSON
    do {
        _ = try await validProvider.fetchRate(from: .usd, to: .inr)
        assert(false, "Zero rate should throw providerRateNonPositive")
    } catch CurrencyRateError.providerRateNonPositive {
        assert(true, "Zero rate correctly throws CurrencyRateError.providerRateNonPositive")
    } catch {
        assert(false, "Zero rate threw unexpected error: \(error)")
    }

    // 11. Twelve Data: Network timeout handling
    MockURLProtocol.mockError = URLError(.timedOut)
    do {
        _ = try await validProvider.fetchRate(from: .usd, to: .inr)
        assert(false, "Network timeout should throw timeout error")
    } catch CurrencyRateError.timeout {
        assert(true, "URLError.timedOut correctly mapped to CurrencyRateError.timeout")
    } catch {
        assert(false, "Timeout threw unexpected error: \(error)")
    }

    // 12. Rate Freshness: Delayed quote on market closed (e.g. weekend age)
    let marketClosedEpoch = Int(Date().timeIntervalSince1970) - (36 * 3600) // 36 hours old
    let marketClosedJSON = """
    {"symbol": "USD/INR", "rate": 95.24, "timestamp": \(marketClosedEpoch)}
    """.data(using: .utf8)!
    MockURLProtocol.mockError = nil
    MockURLProtocol.mockResponseData = marketClosedJSON
    MockURLProtocol.mockStatusCode = 200
    let delayedProvider = TwelveDataRateProvider(keychain: validKeychain, session: mockSession, freshnessThreshold: 900)
    do {
        let entry = try await delayedProvider.fetchRate(from: .usd, to: .inr)
        assert(entry.freshness == .delayed, "Weekend / closed market quote correctly marked as DELAYED")
    } catch {
        assert(false, "Delayed quote check failed: \(error)")
    }

    // 13. Rate Freshness: Stale quote (exceeding 72 hours)
    let staleEpoch = Int(Date().timeIntervalSince1970) - (80 * 3600) // 80 hours old
    let staleJSON = """
    {"symbol": "USD/INR", "rate": 95.24, "timestamp": \(staleEpoch)}
    """.data(using: .utf8)!
    MockURLProtocol.mockResponseData = staleJSON
    do {
        let entry = try await delayedProvider.fetchRate(from: .usd, to: .inr)
        assert(entry.freshness == .stale, "Older quote exceeding 72h correctly marked as STALE")
    } catch {
        assert(false, "Stale quote check failed: \(error)")
    }

    // 14. CurrencyRateCache: Cached quote marked CACHED (never LIVE)
    let testCache = CurrencyRateCache(persistToDisk: false)
    let liveEntry = CurrencyRateEntry(
        from: .usd,
        to: .inr,
        rate: Decimal(string: "95.24")!,
        quoteTimestamp: Date(),
        fetchTimestamp: Date(),
        providerDateString: "10:42:18 UTC",
        providerName: "Twelve Data",
        freshness: .live,
        isDailyReference: false
    )
    await testCache.set(liveEntry)
    let retrieved = await testCache.get(from: .usd, to: .inr, liveTTL: 300)
    assert(retrieved != nil, "Cache retrieves entry successfully")
    assert(retrieved?.entry.freshness == .cached, "Retrieved live quote from cache is honestly marked CACHED, never LIVE")
    assert(retrieved?.entry.providerDateString == "10:42:18 UTC", "Original provider timestamp preserved in cache retrieval")

    // 15. Formatted subtext formatting checks
    let liveResult = CurrencyConversionResult(
        sourceAmount: 1, sourceCurrency: .usd, targetAmount: Decimal(string: "95.24")!, targetCurrency: .inr,
        rate: Decimal(string: "95.24")!, rateDateString: "10:42:18 UTC", providerName: "Twelve Data",
        isCached: false, isStale: false, freshness: .live
    )
    assert(liveResult.formattedSubtext == "Twelve Data · Live quote · 10:42:18 UTC", "LIVE result subtext formatted accurately")

    let cachedResult = CurrencyConversionResult(
        sourceAmount: 1, sourceCurrency: .usd, targetAmount: Decimal(string: "95.24")!, targetCurrency: .inr,
        rate: Decimal(string: "95.24")!, rateDateString: "10:42:18 UTC", providerName: "Twelve Data",
        isCached: true, isStale: false, freshness: .cached
    )
    assert(cachedResult.formattedSubtext == "Twelve Data · Cached · Quote from 10:42:18 UTC", "CACHED result subtext formatted accurately")

    let referenceResult = CurrencyConversionResult(
        sourceAmount: 1, sourceCurrency: .usd, targetAmount: Decimal(string: "95.22")!, targetCurrency: .inr,
        rate: Decimal(string: "95.22")!, rateDateString: "29 Oct 2026", providerName: "ExchangeRate-API",
        isCached: false, isStale: false, freshness: .dailyReference
    )
    assert(referenceResult.formattedSubtext == "ExchangeRate-API · Daily reference · 29 Oct 2026", "DAILY REFERENCE result subtext formatted accurately")

    // 16. Fallback from Twelve Data to Reference Provider with honest DAILY REFERENCE label
    final class MockReferenceProvider: CurrencyRateProviding, @unchecked Sendable {
        let providerName = "Mock-Reference"
        func fetchRate(from: CurrencyCode, to: CurrencyCode) async throws -> CurrencyRateEntry {
            CurrencyRateEntry(
                from: from,
                to: to,
                rate: Decimal(string: "95.20")!,
                quoteTimestamp: Date(),
                fetchTimestamp: Date(),
                providerDateString: "29 Oct 2026",
                providerName: providerName,
                freshness: .dailyReference,
                isDailyReference: true
            )
        }
    }

    final class FailingLiveProvider: CurrencyRateProviding, @unchecked Sendable {
        let providerName = "Twelve Data"
        func fetchRate(from: CurrencyCode, to: CurrencyCode) async throws -> CurrencyRateEntry {
            throw CurrencyRateError.missingAPIKey("Key missing")
        }
    }

    let serviceWithFallback = CurrencyRateService(
        realTimeProvider: FailingLiveProvider(),
        primaryReferenceProvider: MockReferenceProvider(),
        secondaryReferenceProvider: nil,
        cache: CurrencyRateCache(persistToDisk: false)
    )

    do {
        let fallbackResult = try await serviceWithFallback.convert(amount: 100, from: .usd, to: .inr)
        assert(fallbackResult.providerName == "Mock-Reference", "Service falls back to reference provider when live fails")
        assert(fallbackResult.freshness == .dailyReference, "Fallback result is explicitly marked DAILY REFERENCE, never LIVE")
    } catch {
        assert(false, "Service fallback failed: \(error)")
    }

    // 17. USD/INR conversion calculation with exact Decimal fixture
    let usdAmount = Decimal(string: "889.86")!
    let fxRate = Decimal(string: "95.2450")!
    var fixtureExpected = Decimal()
    var amtCopy = usdAmount
    var rateCopy = fxRate
    NSDecimalMultiply(&fixtureExpected, &amtCopy, &rateCopy, .plain)

    final class FixtureProvider: CurrencyRateProviding, @unchecked Sendable {
        let providerName = "Twelve Data"
        func fetchRate(from: CurrencyCode, to: CurrencyCode) async throws -> CurrencyRateEntry {
            CurrencyRateEntry(
                from: from,
                to: to,
                rate: Decimal(string: "95.2450")!,
                quoteTimestamp: Date(),
                fetchTimestamp: Date(),
                providerDateString: "14:20:00 UTC",
                providerName: providerName,
                freshness: .live,
                isDailyReference: false
            )
        }
    }

    let fixtureService = CurrencyRateService(
        realTimeProvider: FixtureProvider(),
        primaryReferenceProvider: MockReferenceProvider(),
        cache: CurrencyRateCache(persistToDisk: false)
    )

    do {
        let fixtureResult = try await fixtureService.convert(amount: usdAmount, from: .usd, to: .inr)
        assert(fixtureResult.targetAmount == fixtureExpected, "889.86 USD * 95.2450 calculated with decimal-safe precision")
        assert(fixtureResult.freshness == .live, "Fixture result freshness is LIVE")
    } catch {
        assert(false, "Fixture calculation failed: \(error)")
    }

    // 18. Cache isolation check: ensure no synthetic data wrote to disk cache
    let cachePath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
        .appendingPathComponent("Skylet/rates_cache.json").path
    if let path = cachePath, FileManager.default.fileExists(atPath: path) {
        if let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
           let str = String(data: data, encoding: .utf8) {
            assert(!str.contains("Mock") && !str.contains("MockDate"), "Production cache is completely free of test mock entries")
        }
    } else {
        assert(true, "Production cache is not contaminated by test runner")
    }

    // 19. Currency Freshness, Cache Provenance & Controllable Clock Verification (v1.0.1)
    final class ControllableClock: @unchecked Sendable {
        var currentTime: Date
        init(initialTime: Date = Date(timeIntervalSince1970: 1730000000)) {
            self.currentTime = initialTime
        }
        func advance(by seconds: TimeInterval) {
            currentTime = currentTime.addingTimeInterval(seconds)
        }
    }

    let clock = ControllableClock()
    let mockSessionForClock = makeMockSession()
    let testKeychain = InMemoryKeychainManager(initialItems: ["twelvedata_api_key": "dummy_key"])

    // Test Case 1: Fresh live quote (quoteAge <= 15m) -> .live
    let t0 = clock.currentTime
    let quoteAge5mEpoch = Int(t0.timeIntervalSince1970) - 300 // 5m old
    MockURLProtocol.mockResponseData = """
    {"symbol": "USD/INR", "rate": 95.25, "timestamp": \(quoteAge5mEpoch)}
    """.data(using: .utf8)!
    MockURLProtocol.mockStatusCode = 200
    let liveQuoteProvider = TwelveDataRateProvider(
        keychain: testKeychain,
        session: mockSessionForClock,
        dateProvider: { clock.currentTime }
    )
    do {
        let entry = try await liveQuoteProvider.fetchRate(from: .usd, to: .inr)
        assert(entry.freshness == .live, "Case 1: Fresh quote (age 5m <= 15m) evaluated as .live")
    } catch {
        assert(false, "Case 1 failed: \(error)")
    }

    // Test Case 2: Cached live quote (quoteAge <= 15m, fetchAge <= 5m) -> .cached
    let controlledCache = CurrencyRateCache(persistToDisk: false, dateProvider: { clock.currentTime })
    let liveCachedEntry = CurrencyRateEntry(
        from: .usd,
        to: .inr,
        rate: Decimal(string: "95.25")!,
        quoteTimestamp: t0.addingTimeInterval(-120), // quote 2m ago
        fetchTimestamp: t0.addingTimeInterval(-120), // fetch 2m ago
        providerDateString: "10:00:00 UTC",
        providerName: "Twelve Data",
        freshness: .live,
        isDailyReference: false
    )
    await controlledCache.set(liveCachedEntry)
    if let res = await controlledCache.get(from: .usd, to: .inr) {
        assert(res.entry.freshness == .cached && !res.isStale, "Case 2: Cached live quote (age 2m) retrieved as .cached, not stale")
    } else {
        assert(false, "Case 2: Entry not found in cache")
    }

    // Test Case 3: Delayed quote (quoteAge > 15m && <= 72h) -> .delayed
    let quoteAge2hEpoch = Int(t0.timeIntervalSince1970) - 7200 // 2 hours old
    MockURLProtocol.mockResponseData = """
    {"symbol": "USD/INR", "rate": 95.25, "timestamp": \(quoteAge2hEpoch)}
    """.data(using: .utf8)!
    do {
        let entry = try await liveQuoteProvider.fetchRate(from: .usd, to: .inr)
        assert(entry.freshness == .delayed, "Case 3: Delayed quote (age 2h > 15m && <= 72h) evaluated as .delayed")
    } catch {
        assert(false, "Case 3 failed: \(error)")
    }

    // Test Case 4: Cached delayed quote (quote retrieved from cache, originally delayed, fetchAge <= 5m) -> .delayed, isCached: true
    let delayedCachedEntry = CurrencyRateEntry(
        from: .usd,
        to: .inr,
        rate: Decimal(string: "95.25")!,
        quoteTimestamp: t0.addingTimeInterval(-7200), // quote 2 hours old
        fetchTimestamp: t0.addingTimeInterval(-60),   // fetch 1 minute ago
        providerDateString: "08:00:00 UTC",
        providerName: "Twelve Data",
        freshness: .delayed,
        isDailyReference: false
    )
    await controlledCache.set(delayedCachedEntry)
    if let res = await controlledCache.get(from: .usd, to: .inr) {
        assert(res.entry.freshness == .delayed && !res.isStale, "Case 4: Cached delayed quote strictly preserved as .delayed (never converted to .cached)")
    } else {
        assert(false, "Case 4: Entry not found in cache")
    }

    // Test Case 5: Stale quote (quoteAge > 72h) -> .stale
    let quoteAge75hEpoch = Int(t0.timeIntervalSince1970) - (75 * 3600) // 75 hours old
    MockURLProtocol.mockResponseData = """
    {"symbol": "USD/INR", "rate": 95.25, "timestamp": \(quoteAge75hEpoch)}
    """.data(using: .utf8)!
    do {
        let entry = try await liveQuoteProvider.fetchRate(from: .usd, to: .inr)
        assert(entry.freshness == .stale, "Case 5: Stale quote (age 75h > 72h) evaluated as .stale")
    } catch {
        assert(false, "Case 5 failed: \(error)")
    }

    // Test Case 6: Cached stale quote (quote retrieved from cache, quoteAge > 72h) -> .stale
    let staleCachedEntry = CurrencyRateEntry(
        from: .usd,
        to: .inr,
        rate: Decimal(string: "95.25")!,
        quoteTimestamp: t0.addingTimeInterval(-(75 * 3600)), // quote 75 hours old
        fetchTimestamp: t0.addingTimeInterval(-30),          // fetch 30s ago
        providerDateString: "75h ago",
        providerName: "Twelve Data",
        freshness: .stale,
        isDailyReference: false
    )
    await controlledCache.set(staleCachedEntry)
    if let res = await controlledCache.get(from: .usd, to: .inr) {
        assert(res.entry.freshness == .stale && res.isStale, "Case 6: Cached stale quote retrieved strictly as .stale and isStale == true")
    } else {
        assert(false, "Case 6: Entry not found in cache")
    }

    // Test Case 7: Quote that was live when cached, but after advancing time past 72h becomes stale on retrieval -> .stale
    let freshEntryForAdvancement = CurrencyRateEntry(
        from: .eur,
        to: .inr,
        rate: Decimal(string: "103.50")!,
        quoteTimestamp: clock.currentTime,
        fetchTimestamp: clock.currentTime,
        providerDateString: "T0",
        providerName: "Twelve Data",
        freshness: .live,
        isDailyReference: false
    )
    await controlledCache.set(freshEntryForAdvancement)
    clock.advance(by: 73 * 3600)
    if let res = await controlledCache.get(from: .eur, to: .inr) {
        assert(res.entry.freshness == .stale && res.isStale, "Case 7: Quote live when cached becomes .stale after advancing controllable clock past 72h")
    } else {
        assert(false, "Case 7: Entry not found in cache")
    }

    // Test Case 8: Fallback to cache on network failure: returns cached quote with accurate freshness (.stale or .delayed or .cached as determined by age, never upgraded to .live)
    final class FailingProvider: CurrencyRateProviding, @unchecked Sendable {
        let providerName = "Failing Provider"
        func fetchRate(from: CurrencyCode, to: CurrencyCode) async throws -> CurrencyRateEntry {
            throw CurrencyRateError.networkUnavailable
        }
    }
    let networkFailClock = ControllableClock()
    let networkFailCache = CurrencyRateCache(persistToDisk: false, dateProvider: { networkFailClock.currentTime })
    let networkFailService = CurrencyRateService(
        realTimeProvider: FailingProvider(),
        primaryReferenceProvider: FailingProvider(),
        secondaryReferenceProvider: nil,
        cache: networkFailCache,
        dateProvider: { networkFailClock.currentTime }
    )

    // Sub-case 8A: Cache has fresh live quote, network fails -> result is .cached, isCached == true
    let entry8A = CurrencyRateEntry(
        from: .usd,
        to: .inr,
        rate: Decimal(string: "95.20")!,
        quoteTimestamp: networkFailClock.currentTime.addingTimeInterval(-100),
        fetchTimestamp: networkFailClock.currentTime.addingTimeInterval(-100),
        providerDateString: "100s ago",
        providerName: "Twelve Data",
        freshness: .live,
        isDailyReference: false
    )
    await networkFailCache.set(entry8A)
    do {
        let res8A = try await networkFailService.convert(amount: 10, from: .usd, to: .inr, forceRefresh: true)
        assert(res8A.freshness == .cached && res8A.isCached && !res8A.isStale, "Case 8A: Fallback to cached live quote returns .cached, isCached == true, never .live")
    } catch {
        assert(false, "Case 8A failed: \(error)")
    }

    // Sub-case 8B: Cache has delayed quote (20h old), network fails -> result remains .delayed, isCached == true
    let entry8B = CurrencyRateEntry(
        from: .cad,
        to: .inr,
        rate: Decimal(string: "68.50")!,
        quoteTimestamp: networkFailClock.currentTime.addingTimeInterval(-20 * 3600),
        fetchTimestamp: networkFailClock.currentTime.addingTimeInterval(-60),
        providerDateString: "20h ago",
        providerName: "Twelve Data",
        freshness: .delayed,
        isDailyReference: false
    )
    await networkFailCache.set(entry8B)
    do {
        let res8B = try await networkFailService.convert(amount: 10, from: .cad, to: .inr, forceRefresh: true)
        assert(res8B.freshness == .delayed && res8B.isCached, "Case 8B: Fallback to cached delayed quote preserves .delayed, never upgraded to .cached or .live")
    } catch {
        assert(false, "Case 8B failed: \(error)")
    }

    // Sub-case 8C: Cache has stale quote (80h old), network fails -> result is .stale, isStale == true
    let entry8C = CurrencyRateEntry(
        from: .aud,
        to: .inr,
        rate: Decimal(string: "60.00")!,
        quoteTimestamp: networkFailClock.currentTime.addingTimeInterval(-80 * 3600),
        fetchTimestamp: networkFailClock.currentTime.addingTimeInterval(-80 * 3600),
        providerDateString: "80h ago",
        providerName: "Twelve Data",
        freshness: .stale,
        isDailyReference: false
    )
    await networkFailCache.set(entry8C)
    do {
        let res8C = try await networkFailService.convert(amount: 10, from: .aud, to: .inr, forceRefresh: true)
        assert(res8C.freshness == .stale && res8C.isCached && res8C.isStale, "Case 8C: Fallback to cached stale quote strictly marked .stale with isStale == true")
    } catch {
        assert(false, "Case 8C failed: \(error)")
    }

    // Test Case 9: Daily reference fallback: returns .dailyReference (quoteAge <= 12h) or .stale (quoteAge > 12h)
    let refClock = ControllableClock()
    let refCache = CurrencyRateCache(persistToDisk: false, dateProvider: { refClock.currentTime })

    // 9A: quoteAge = 4 hours <= 12h
    let freshRefEntry = CurrencyRateEntry(
        from: .gbp,
        to: .inr,
        rate: Decimal(string: "123.40")!,
        quoteTimestamp: refClock.currentTime.addingTimeInterval(-4 * 3600),
        fetchTimestamp: refClock.currentTime.addingTimeInterval(-1800),
        providerDateString: "Today",
        providerName: "ECB Reference",
        freshness: .dailyReference,
        isDailyReference: true
    )
    await refCache.set(freshRefEntry)
    if let refResultA = await refCache.get(from: .gbp, to: .inr) {
        assert(refResultA.entry.freshness == .dailyReference && !refResultA.isStale, "Case 9A: Daily reference (age 4h <= 12h) returns .dailyReference and isStale == false")
    } else {
        assert(false, "Case 9A: Entry not found")
    }

    // 9B: quoteAge = 14 hours > 12h
    let staleRefEntry = CurrencyRateEntry(
        from: .sgd,
        to: .inr,
        rate: Decimal(string: "71.20")!,
        quoteTimestamp: refClock.currentTime.addingTimeInterval(-14 * 3600),
        fetchTimestamp: refClock.currentTime.addingTimeInterval(-1800),
        providerDateString: "Yesterday",
        providerName: "ECB Reference",
        freshness: .dailyReference,
        isDailyReference: true
    )
    await refCache.set(staleRefEntry)
    if let refResultB = await refCache.get(from: .sgd, to: .inr) {
        assert(refResultB.entry.freshness == .stale && refResultB.isStale, "Case 9B: Daily reference (age 14h > 12h) returns .stale and isStale == true")
    } else {
        assert(false, "Case 9B: Entry not found")
    }

    // 20. Optional Integration Test: If user configured TWELVEDATA_API_KEY via environment
    if let envKey = ProcessInfo.processInfo.environment["TWELVEDATA_API_KEY"], !envKey.isEmpty {
        print("  * Found TWELVEDATA_API_KEY in environment! Testing live USD/INR...")
        let envKeychain = InMemoryKeychainManager(initialItems: ["twelvedata_api_key": envKey])
        let liveProvider = TwelveDataRateProvider(keychain: envKeychain)
        do {
            let liveEntry = try await liveProvider.fetchRate(from: .usd, to: .inr)
            print("  ✓ Real Twelve Data Live USD/INR: 1 USD = ₹\(liveEntry.rate) at \(liveEntry.providerDateString)")
            assert(liveEntry.rate > 0, "Real Twelve Data returned positive USD/INR rate")
        } catch {
            print("  ! Real Twelve Data key test result: \(error.localizedDescription)")
        }
    }

    print("\n[4/4] Focus Timer 16 Lifecycle Requirements & UI State Tests")

    final class LocalMockPower: PowerAssertionControlling, @unchecked Sendable {
        var isDisplayAwakeActive = false
        var beginCount = 0
        var endCount = 0
        var shouldFail = false

        func beginDisplayAwake(reason: String) -> Bool {
            if shouldFail { return false }
            beginCount += 1
            isDisplayAwakeActive = true
            return true
        }

        func endDisplayAwake() {
            if isDisplayAwakeActive {
                endCount += 1
                isDisplayAwakeActive = false
            }
        }
    }

    // Presets
    assert(FocusPreset.fifteen.durationSeconds == 900, "15m preset is 900s")
    assert(FocusPreset.thirty.durationSeconds == 1800, "30m preset is 1800s")
    assert(FocusPreset.fortyFive.durationSeconds == 2700, "45m preset is 2700s")
    assert(FocusPreset.sixty.durationSeconds == 3600, "60m preset is 3600s")
    assert(FocusPreset.oneTwenty.durationSeconds == 7200, "120m preset is 7200s")

    // Countdown formatting
    assert(FocusTimerEngine.formatCountdown(60) == "01:00", "Countdown 60s formats as 01:00")
    assert(FocusTimerEngine.formatCountdown(899) == "14:59", "Countdown 899s formats as 14:59")
    assert(FocusTimerEngine.formatCountdown(3600) == "1:00:00", "Countdown 3600s formats as 1:00:00")
    assert(FocusTimerEngine.formatCountdown(0) == "00:00", "Countdown 0s formats as 00:00")

    // UI Action Button & Badge State Mapping
    assert(FocusTimerStatus.idle.actionButtonTitle == "Start Focus", "Idle status has 'Start Focus' action title")
    assert(FocusTimerStatus.idle.actionButtonIcon == "play.fill", "Idle status has play icon")
    assert(FocusTimerStatus.idle.statusBadgeText == "READY", "Idle status badge text is READY")

    let dummyRunning = FocusTimerStatus.running(totalDuration: 900, remaining: 800, progress: 0.11)
    assert(dummyRunning.actionButtonTitle == "Pause", "Running status has 'Pause' action title")
    assert(dummyRunning.actionButtonIcon == "pause.fill", "Running status has pause icon")
    assert(dummyRunning.statusBadgeText == "FOCUSING", "Running status badge text is FOCUSING")

    let dummyPaused = FocusTimerStatus.paused(totalDuration: 900, remaining: 800, progress: 0.11)
    assert(dummyPaused.actionButtonTitle == "Resume", "Paused status has 'Resume' action title")
    assert(dummyPaused.actionButtonIcon == "play.fill", "Paused status has play icon")
    assert(dummyPaused.statusBadgeText == "PAUSED", "Paused status badge text is PAUSED")

    let dummyCompleted = FocusTimerStatus.completed(totalDuration: 900)
    assert(dummyCompleted.actionButtonTitle == "Start Again", "Completed status has 'Start Again' action title")
    assert(dummyCompleted.actionButtonIcon == "arrow.clockwise", "Completed status has reload icon")
    assert(dummyCompleted.statusBadgeText == "COMPLETED", "Completed status badge text is COMPLETED")

    // Lifecycle Requirement 1: Idle -> Running
    let power1 = LocalMockPower()
    let engine1 = FocusTimerEngine(powerController: power1)
    assert(engine1.status == .idle, "Req 1: Engine starts in .idle status")
    engine1.start(duration: 900)
    assert(engine1.status.isRunning, "Req 1: Engine transitions to .running upon start")
    assert(abs(engine1.status.remainingSeconds - 900) <= 1.0, "Req 1: Remaining seconds is 900 initially")

    // Lifecycle Requirement 2: Running -> Paused
    engine1.pause()
    assert(engine1.status.isPaused, "Req 2: Engine transitions to .paused upon pause")
    assert(abs(engine1.status.remainingSeconds - 900) <= 1.0, "Req 2: Remaining seconds preserved on pause")

    // Lifecycle Requirement 3: Paused -> Running
    engine1.resume()
    assert(engine1.status.isRunning, "Req 3: Engine resumes to .running status")

    // Lifecycle Requirement 4: Running -> Reset
    let power4 = LocalMockPower()
    let engine4 = FocusTimerEngine(powerController: power4)
    engine4.start(duration: 600)
    assert(engine4.status.isRunning, "Req 4: Engine started running")
    engine4.reset()
    assert(engine4.status == .idle, "Req 4: Reset while running transitions immediately to .idle")

    // Lifecycle Requirement 5: Paused -> Reset
    let power5 = LocalMockPower()
    let engine5 = FocusTimerEngine(powerController: power5)
    engine5.start(duration: 600)
    engine5.pause()
    assert(engine5.status.isPaused, "Req 5: Engine paused")
    engine5.reset()
    assert(engine5.status == .idle, "Req 5: Reset while paused transitions immediately to .idle")

    // Lifecycle Requirement 6: Session completion
    let power6 = LocalMockPower()
    let engine6 = FocusTimerEngine(powerController: power6)
    engine6.start(duration: 300)
    let completionTime = Date().addingTimeInterval(301)
    engine6.updateTick(now: completionTime)
    assert(engine6.status.isCompleted, "Req 6: Timer naturally marks session completed when deadline reached")
    assert(engine6.status.remainingSeconds == 0, "Req 6: Remaining seconds is 0 when completed")

    // Lifecycle Requirement 7: Completion notification exactly once
    let power7 = LocalMockPower()
    let engine7 = FocusTimerEngine(powerController: power7)
    var callbackCount = 0
    var notifCount = 0
    engine7.onCompletion = { _ in
        callbackCount += 1
    }
    let observer = NotificationCenter.default.addObserver(
        forName: FocusTimerEngine.sessionCompletedNotification,
        object: engine7,
        queue: nil
    ) { _ in
        notifCount += 1
    }
    engine7.start(duration: 100)
    let fireTime = Date().addingTimeInterval(101)
    engine7.updateTick(now: fireTime)
    // Extra tick to verify exactly once guarantee
    engine7.updateTick(now: fireTime.addingTimeInterval(5))
    assert(callbackCount == 1, "Req 7: onCompletion closure fired exactly once")
    assert(notifCount == 1, "Req 7: sessionCompletedNotification posted exactly once")
    NotificationCenter.default.removeObserver(observer)

    // Lifecycle Requirement 8: Display-awake activation
    let power8 = LocalMockPower()
    let engine8 = FocusTimerEngine(powerController: power8)
    assert(!engine8.isDisplayAwake && power8.beginCount == 0, "Req 8: Display awake inactive before start")
    engine8.start(duration: 500)
    assert(engine8.isDisplayAwake && power8.beginCount == 1, "Req 8: Display-awake activated on session start")

    // Lifecycle Requirement 9: Display-awake release on completion
    engine8.updateTick(now: Date().addingTimeInterval(501))
    assert(!engine8.isDisplayAwake && power8.endCount == 1, "Req 9: Display-awake released when session completes")

    // Lifecycle Requirement 10: Display-awake release on reset
    let power10 = LocalMockPower()
    let engine10 = FocusTimerEngine(powerController: power10)
    engine10.start(duration: 500)
    assert(power10.isDisplayAwakeActive, "Req 10: Display-awake active while running")
    engine10.reset()
    assert(!power10.isDisplayAwakeActive && power10.endCount == 1, "Req 10: Display-awake released on reset")

    // Lifecycle Requirement 11: Display-awake release on droplet deactivation
    let power11 = LocalMockPower()
    let engine11 = FocusTimerEngine(powerController: power11)
    engine11.start(duration: 500)
    assert(power11.isDisplayAwakeActive, "Req 11: Display-awake active before deactivation")
    engine11.deactivate()
    assert(!power11.isDisplayAwakeActive && power11.endCount == 1, "Req 11: Display-awake released on droplet deactivation")

    // Lifecycle Requirement 12: No duplicate ticking tasks
    let power12 = LocalMockPower()
    let engine12 = FocusTimerEngine(powerController: power12)
    engine12.start(duration: 600)
    assert(power12.beginCount == 1, "Req 12: First start acquires assertion")
    engine12.start(duration: 600)
    assert(power12.beginCount == 1, "Req 12: Duplicate start does not re-acquire or spawn duplicate tickers")

    // Lifecycle Requirement 13: Duration changes behave correctly
    let power13 = LocalMockPower()
    let engine13 = FocusTimerEngine(powerController: power13)
    engine13.start(preset: .fifteen)
    assert(abs(engine13.status.remainingSeconds - 900) <= 1.0, "Req 13: Started 15m preset has 900s")
    engine13.reset()
    engine13.start(preset: .thirty)
    assert(abs(engine13.status.remainingSeconds - 1800) <= 1.0, "Req 13: Started 30m preset has 1800s")

    // Lifecycle Requirement 14: Progress preservation across pause/resume
    let power14 = LocalMockPower()
    let engine14 = FocusTimerEngine(powerController: power14)
    engine14.start(duration: 1000)
    engine14.updateTick(now: Date().addingTimeInterval(300))
    if case .running(_, let remBefore, let progBefore) = engine14.status {
        assert(abs(remBefore - 700) <= 1.0, "Req 14: 700s remaining before pause")
        engine14.pause()
        if case .paused(_, let remPaused, let progPaused) = engine14.status {
            assert(abs(remPaused - remBefore) < 0.001 && abs(progPaused - progBefore) < 0.001, "Req 14: Progress preserved exactly on pause")
            engine14.resume()
            if case .running(_, let remResumed, _) = engine14.status {
                assert(abs(remResumed - 700) <= 1.0, "Req 14: Remaining time preserved on resume")
            } else {
                assert(false, "Req 14: Did not resume to running")
            }
        } else {
            assert(false, "Req 14: Did not enter paused state")
        }
    } else {
        assert(false, "Req 14: Did not enter running state")
    }

    // Lifecycle Requirement 15: Visual progress reaching zero remaining time
    let power15 = LocalMockPower()
    let engine15 = FocusTimerEngine(powerController: power15)
    engine15.start(duration: 100)
    engine15.updateTick(now: Date().addingTimeInterval(101))
    assert(engine15.status.remainingSeconds == 0, "Req 15: Visual remaining time reaches exactly 0")
    if case .completed(let total) = engine15.status {
        assert(total == 100, "Req 15: Completed status carries total duration")
    } else {
        assert(false, "Req 15: Status is not completed")
    }

    // Lifecycle Requirement 16: Monotonic accuracy under delayed schedule
    let power16 = LocalMockPower()
    let engine16 = FocusTimerEngine(powerController: power16)
    let startTime = Date()
    engine16.start(duration: 1200)
    // Simulate system sleep or UI freeze of 450 seconds
    let delayedWakeTime = startTime.addingTimeInterval(450)
    engine16.updateTick(now: delayedWakeTime)
    assert(abs(engine16.status.remainingSeconds - 750) <= 0.01, "Req 16: Monotonic deadline eliminates schedule delay drift")

    print("\n==================================================")
    print("TEST RESULTS: \(passed) passed, \(failed) failed")
    print("==================================================")

    guard failed == 0 else {
        print("FAILURES DETECTED: \(failed)")
        Darwin.exit(1)
    }
    print("ALL TESTS PASSED SUCCESSFULLY!")
}

Task { @MainActor in
    await runAllTests()
    exit(0)
}

dispatchMain()
