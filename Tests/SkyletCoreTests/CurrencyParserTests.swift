//
//  CurrencyParserTests.swift
//  SkyletCoreTests
//

import XCTest
@testable import SkyletCore

final class CurrencyParserTests: XCTestCase {

    func testEmptyAndWhitespaceInput() {
        XCTAssertEqual(CurrencyParser.parse(""), .empty)
        XCTAssertEqual(CurrencyParser.parse("   \n\t  "), .empty)
    }

    func testInvalidAlphabeticInput() {
        let result = CurrencyParser.parse("hello world without numbers")
        if case .invalidAmount(let str) = result {
            XCTAssertTrue(str.contains("hello world"))
        } else {
            XCTFail("Expected .invalidAmount, got \(result)")
        }
    }

    func testBareNumber() {
        let result = CurrencyParser.parse("25")
        XCTAssertEqual(result, .amountOnly(amount: 25, rawAmountString: "25"))

        let decimalResult = CurrencyParser.parse("49.99")
        XCTAssertEqual(decimalResult, .amountOnly(amount: Decimal(string: "49.99")!, rawAmountString: "49.99"))
    }

    func testUnambiguousCurrencies() {
        // Euros
        XCTAssertEqual(
            CurrencyParser.parse("€49.99"),
            .unambiguous(amount: Decimal(string: "49.99")!, currency: .eur, rawAmountString: "49.99")
        )
        XCTAssertEqual(
            CurrencyParser.parse("49.99 EUR"),
            .unambiguous(amount: Decimal(string: "49.99")!, currency: .eur, rawAmountString: "49.99")
        )
        XCTAssertEqual(
            CurrencyParser.parse("25 euros"),
            .unambiguous(amount: 25, currency: .eur, rawAmountString: "25")
        )

        // British Pounds
        XCTAssertEqual(
            CurrencyParser.parse("£12.50"),
            .unambiguous(amount: Decimal(string: "12.50")!, currency: .gbp, rawAmountString: "12.50")
        )

        // Indian Rupees
        XCTAssertEqual(
            CurrencyParser.parse("₹100"),
            .unambiguous(amount: 100, currency: .inr, rawAmountString: "100")
        )
        XCTAssertEqual(
            CurrencyParser.parse("INR 100"),
            .unambiguous(amount: 100, currency: .inr, rawAmountString: "100")
        )
        XCTAssertEqual(
            CurrencyParser.parse("100 INR"),
            .unambiguous(amount: 100, currency: .inr, rawAmountString: "100")
        )

        // Japanese Yen & Chinese Yuan with explicit codes/names
        XCTAssertEqual(
            CurrencyParser.parse("JPY 5000"),
            .unambiguous(amount: 5000, currency: .jpy, rawAmountString: "5000")
        )
        XCTAssertEqual(
            CurrencyParser.parse("5000 yen"),
            .unambiguous(amount: 5000, currency: .jpy, rawAmountString: "5000")
        )

        // UAE Dirham
        XCTAssertEqual(
            CurrencyParser.parse("AED 100"),
            .unambiguous(amount: 100, currency: .aed, rawAmountString: "100")
        )

        // US Dollar explicit names
        XCTAssertEqual(
            CurrencyParser.parse("USD 25"),
            .unambiguous(amount: 25, currency: .usd, rawAmountString: "25")
        )
        XCTAssertEqual(
            CurrencyParser.parse("25 USD"),
            .unambiguous(amount: 25, currency: .usd, rawAmountString: "25")
        )
        XCTAssertEqual(
            CurrencyParser.parse("25 US dollars"),
            .unambiguous(amount: 25, currency: .usd, rawAmountString: "25")
        )
    }

    func testAmbiguousSymbols() {
        // Dollar sign ($) is ambiguous among USD, CAD, AUD, etc.
        let dollarResult = CurrencyParser.parse("$25")
        if case .ambiguous(let amount, let symbol, let candidates, let raw) = dollarResult {
            XCTAssertEqual(amount, 25)
            XCTAssertEqual(symbol, "$")
            XCTAssertTrue(candidates.contains(.usd))
            XCTAssertTrue(candidates.contains(.cad))
            XCTAssertEqual(raw, "25")
        } else {
            XCTFail("Expected .ambiguous for $25, got \(dollarResult)")
        }

        // Yen symbol (¥) is ambiguous between JPY and CNY
        let yenResult = CurrencyParser.parse("¥5000")
        if case .ambiguous(let amount, let symbol, let candidates, _) = yenResult {
            XCTAssertEqual(amount, 5000)
            XCTAssertEqual(symbol, "¥")
            XCTAssertEqual(candidates, [.jpy, .cny])
        } else {
            XCTFail("Expected .ambiguous for ¥5000, got \(yenResult)")
        }

        // Rs is ambiguous across South Asian rupees (INR, PKR, NPR)
        let rsResult = CurrencyParser.parse("Rs 100")
        if case .ambiguous(let amount, let symbol, let candidates, _) = rsResult {
            XCTAssertEqual(amount, 100)
            XCTAssertEqual(symbol, "RS")
            XCTAssertEqual(candidates, [.inr, .pkr, .npr])
        } else {
            XCTFail("Expected .ambiguous for Rs 100, got \(rsResult)")
        }
    }

    func testNumberSeparators() {
        // US style grouping: 1,299.50
        let usStyle = CurrencyParser.parse("$1,299.50")
        if case .ambiguous(let amount, _, _, _) = usStyle {
            XCTAssertEqual(amount, Decimal(string: "1299.50")!)
        } else {
            XCTFail("Failed to parse US style number: \(usStyle)")
        }

        // European style grouping: 1.299,50
        let euStyle = CurrencyParser.parse("€1.299,50")
        XCTAssertEqual(
            euStyle,
            .unambiguous(amount: Decimal(string: "1299.50")!, currency: .eur, rawAmountString: "1.299,50")
        )

        // Indian style grouping: 1,00,000
        let inStyle = CurrencyParser.parse("₹1,00,000")
        XCTAssertEqual(
            inStyle,
            .unambiguous(amount: 100000, currency: .inr, rawAmountString: "1,00,000")
        )
    }

    func testNegativeAndZeroValues() {
        let negResult = CurrencyParser.parse("-49.99 EUR")
        XCTAssertEqual(
            negResult,
            .unambiguous(amount: Decimal(string: "-49.99")!, currency: .eur, rawAmountString: "-49.99")
        )

        let zeroResult = CurrencyParser.parse("0 USD")
        XCTAssertEqual(
            zeroResult,
            .unambiguous(amount: 0, currency: .usd, rawAmountString: "0")
        )
    }

    func testMultipleAmountsInInput() {
        let multi = CurrencyParser.parse("The price starts at $25 but goes up to $75.")
        if case .multipleAmountsFound(let amounts) = multi {
            XCTAssertEqual(amounts.count, 2)
            XCTAssertTrue(amounts.contains(25))
            XCTAssertTrue(amounts.contains(75))
        } else {
            XCTFail("Expected .multipleAmountsFound, got \(multi)")
        }
    }

    func testEmbeddedInSentenceWithTrailingPunctuation() {
        let text = "Your subscription fee will be $25."
        let result = CurrencyParser.parse(text)
        if case .ambiguous(let amount, let symbol, _, let raw) = result {
            XCTAssertEqual(amount, 25)
            XCTAssertEqual(symbol, "$")
            XCTAssertEqual(raw, "25")
        } else {
            XCTFail("Failed to parse embedded sentence: \(result)")
        }

        let euroSentence = "The special package is 50 euros per year!"
        XCTAssertEqual(
            CurrencyParser.parse(euroSentence),
            .unambiguous(amount: 50, currency: .eur, rawAmountString: "50")
        )
    }

    func testUnknownCurrencyCode() {
        let unknown = CurrencyParser.parse("100 XYZ")
        XCTAssertEqual(
            unknown,
            .unambiguous(amount: 100, currency: CurrencyCode("XYZ")!, rawAmountString: "100")
        )
    }

    func testExcessivelyLongInputHandledSafely() {
        let padding = String(repeating: "word ", count: 500)
        let longInput = "\(padding) €150.00"
        let result = CurrencyParser.parse(longInput)
        // Should not crash or hang
        XCTAssertNotEqual(result, .empty)
    }
}

