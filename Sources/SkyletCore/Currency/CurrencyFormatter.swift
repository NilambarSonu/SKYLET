//
//  CurrencyFormatter.swift
//  SkyletCore
//

import Foundation

public enum CurrencyFormatter {
    private static let inrLocale = Locale(identifier: "en_IN")
    private static let usLocale = Locale(identifier: "en_US")

    /// Formats an amount with its currency symbol/code.
    public static func format(amount: Decimal, currency: CurrencyCode, includeSymbol: Bool = true) -> String {
        let info = CurrencyRegistry.info(for: currency)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = info.decimals
        formatter.maximumFractionDigits = info.decimals

        let locale = (currency == .inr) ? inrLocale : usLocale
        formatter.locale = locale

        let formattedNumber = formatter.string(from: amount as NSDecimalNumber) ?? "\(amount)"
        if includeSymbol {
            if currency == .inr {
                return "₹\(formattedNumber)"
            } else if info.symbol.count <= 2 && !info.symbol.contains(currency.rawValue) {
                return "\(info.symbol)\(formattedNumber)"
            } else {
                return "\(formattedNumber) \(currency.rawValue)"
            }
        }
        return formattedNumber
    }

    /// Formats an INR amount with the standard Indian numbering system (Lakhs, Crores).
    public static func formatINR(amount: Decimal) -> String {
        format(amount: amount, currency: .inr, includeSymbol: true)
    }

    /// Formats an exchange rate pair, e.g., "1 USD = 84.5000 INR".
    public static func formatRate(from: CurrencyCode, to: CurrencyCode, rate: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 4
        formatter.locale = usLocale

        let rateStr = formatter.string(from: rate as NSDecimalNumber) ?? "\(rate)"
        return "1 \(from.rawValue) = \(rateStr) \(to.rawValue)"
    }

    /// Formats an exchange rate pair compactly, e.g. "1 USD = ₹95.24".
    public static func formatRateCompact(from: CurrencyCode, to: CurrencyCode, rate: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 4
        formatter.locale = usLocale

        let rateStr = formatter.string(from: rate as NSDecimalNumber) ?? "\(rate)"
        if to == .inr {
            return "1 \(from.rawValue) = ₹\(rateStr)"
        }
        return "1 \(from.rawValue) = \(rateStr) \(to.rawValue)"
    }

    /// Returns a clean copyable string representing the conversion result.
    public static func copyableSummary(
        fromAmount: Decimal,
        fromCurrency: CurrencyCode,
        toAmount: Decimal,
        toCurrency: CurrencyCode = .inr
    ) -> String {
        let fromStr = format(amount: fromAmount, currency: fromCurrency)
        let toStr = format(amount: toAmount, currency: toCurrency)
        return "\(fromStr) = \(toStr)"
    }
}

