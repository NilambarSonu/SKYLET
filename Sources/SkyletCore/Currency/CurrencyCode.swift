//
//  CurrencyCode.swift
//  SkyletCore
//

import Foundation

/// A validated 3-letter ISO 4217 currency code.
public struct CurrencyCode: Hashable, Codable, Sendable, CustomStringConvertible, ExpressibleByStringLiteral {
    public let rawValue: String

    public init?(_ code: String) {
        let cleaned = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard cleaned.count == 3, cleaned.allSatisfy({ $0.isASCII && $0.isLetter }) else {
            return nil
        }
        self.rawValue = cleaned
    }

    public init(stringLiteral value: String) {
        guard let code = CurrencyCode(value) else {
            fatalError("Invalid CurrencyCode string literal: \(value)")
        }
        self = code
    }

    public var description: String { rawValue }

    // Common standard currencies
    public static let inr: CurrencyCode = "INR"
    public static let usd: CurrencyCode = "USD"
    public static let eur: CurrencyCode = "EUR"
    public static let gbp: CurrencyCode = "GBP"
    public static let jpy: CurrencyCode = "JPY"
    public static let cny: CurrencyCode = "CNY"
    public static let aud: CurrencyCode = "AUD"
    public static let cad: CurrencyCode = "CAD"
    public static let sgd: CurrencyCode = "SGD"
    public static let chf: CurrencyCode = "CHF"
    public static let aed: CurrencyCode = "AED"
    public static let sar: CurrencyCode = "SAR"
    public static let nzd: CurrencyCode = "NZD"
    public static let hkd: CurrencyCode = "HKD"
    public static let krw: CurrencyCode = "KRW"
    public static let brl: CurrencyCode = "BRL"
    public static let thb: CurrencyCode = "THB"
    public static let myr: CurrencyCode = "MYR"
    public static let idr: CurrencyCode = "IDR"
    public static let bdt: CurrencyCode = "BDT"
    public static let pkr: CurrencyCode = "PKR"
    public static let npr: CurrencyCode = "NPR"
}

