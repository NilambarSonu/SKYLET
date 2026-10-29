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
        primaryProvider: mockProvider,
        fallbackProvider: nil,
        cache: CurrencyRateCache(ttl: 3600)
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
    assert(CurrencyFormatter.copyableSummary(fromAmount: 25, fromCurrency: .usd, toAmount: Decimal(string: "2380.50")!) == "$25.00 = ₹2,380.50", "CurrencyFormatter.copyableSummary formats copyable text")

    print("\n[3/3] Focus Timer & Power Assertion Lifecycle Tests")

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

    // Countdown string formatting
    assert(FocusTimerEngine.formatCountdown(60) == "01:00", "Countdown 60s formats as 01:00")
    assert(FocusTimerEngine.formatCountdown(899) == "14:59", "Countdown 899s formats as 14:59")
    assert(FocusTimerEngine.formatCountdown(3600) == "1:00:00", "Countdown 3600s formats as 1:00:00")
    assert(FocusTimerEngine.formatCountdown(0) == "00:00", "Countdown 0s formats as 00:00")

    // Engine lifecycle and power assertions
    let mockPower = LocalMockPower()
    let engine = FocusTimerEngine(powerController: mockPower)

    assert(engine.status == .idle, "Initial status is .idle")
    assert(!engine.isDisplayAwake, "Initial isDisplayAwake is false")

    engine.start(duration: 900)
    assert(engine.status.isRunning, "Status is .running after start")
    assert(engine.isDisplayAwake, "isDisplayAwake is true while running")
    assert(mockPower.beginCount == 1, "Acquired power assertion on start")

    // Duplicate start
    engine.start(duration: 900)
    assert(mockPower.beginCount == 1, "Duplicate start does not create duplicate assertion")

    // Monotonic deadline tick
    let now = Date()
    engine.updateTick(now: now.addingTimeInterval(150))
    assert(abs(engine.status.remainingSeconds - 750) <= 1.0, "Remaining seconds calculated accurately via deadline (zero drift)")

    // Pause
    engine.pause()
    assert(engine.status.isPaused, "Status is .paused")
    assert(!engine.isDisplayAwake, "Power assertion released on pause")
    assert(mockPower.endCount == 1, "endActivity called on pause")

    // Resume
    engine.resume()
    assert(engine.status.isRunning, "Status is .running after resume")
    assert(engine.isDisplayAwake, "Power assertion re-acquired on resume")
    assert(mockPower.beginCount == 2, "beginActivity called on resume")

    // Natural completion
    engine.updateTick(now: Date().addingTimeInterval(1000))
    assert(engine.status.isCompleted, "Timer completes when deadline reached")
    assert(!engine.isDisplayAwake, "Power assertion released on natural completion")
    assert(!mockPower.isDisplayAwakeActive, "Mock power controller confirms inactive assertion")

    // Deactivation cleanup
    engine.start(duration: 300)
    assert(mockPower.isDisplayAwakeActive, "Timer running before deactivation")
    engine.deactivate()
    assert(engine.status == .idle, "Status reset to .idle on deactivation")
    assert(!mockPower.isDisplayAwakeActive, "Power assertion guaranteed released on deactivation")

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
