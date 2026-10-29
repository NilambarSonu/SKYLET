//
//  CurrencyParser.swift
//  SkyletCore
//

import Foundation

/// The outcome of parsing freeform user text or clipboard contents for currency values.
@frozen
public enum ParseOutcome: Equatable, Sendable {
    case empty
    case invalidAmount(String)
    case multipleAmountsFound([Decimal])
    case unambiguous(amount: Decimal, currency: CurrencyCode, rawAmountString: String)
    case ambiguous(amount: Decimal, symbol: String, candidates: [CurrencyCode], rawAmountString: String)
    case amountOnly(amount: Decimal, rawAmountString: String)
    case unknownCurrency(amount: Decimal, token: String, rawAmountString: String)
}

public enum CurrencyParser {
    private static let maxInputLength = 1000

    /// Parses user-provided text or clipboard contents into a structured ParseOutcome.
    public static func parse(_ rawInput: String) -> ParseOutcome {
        let trimmed = rawInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .empty
        }

        // Guard against pathologically long inputs
        let safeInput: String
        if trimmed.count > maxInputLength {
            safeInput = String(trimmed.prefix(maxInputLength))
        } else {
            safeInput = trimmed
        }

        // 1. Extract potential numerical tokens
        let extractedAmounts = extractNumberCandidates(from: safeInput)
        guard !extractedAmounts.isEmpty else {
            return .invalidAmount(safeInput)
        }

        // 2. If multiple distinct amounts exist in the text, do not guess silently.
        let uniqueAmounts = Array(NSOrderedSet(array: extractedAmounts.map { $0.decimalValue })) as! [Decimal]
        if uniqueAmounts.count > 1 {
            return .multipleAmountsFound(uniqueAmounts)
        }

        let primaryCandidate = extractedAmounts[0]
        let amount = primaryCandidate.decimalValue
        let rawAmountString = primaryCandidate.rawString

        // 3. Search for currency identifiers in the text
        return resolveCurrency(in: safeInput, amount: amount, rawAmountString: rawAmountString)
    }

    // MARK: - Internal Parsing Details

    private struct ExtractedNumber {
        let rawString: String
        let decimalValue: Decimal
        let range: Range<String.Index>
    }

    private static func extractNumberCandidates(from text: String) -> [ExtractedNumber] {
        // Matches numbers like -25, 49.99, 1,299.50, 1.299,50, 5000, 1,00,000
        // Allows optional leading negative sign
        let pattern = #"(?<!\w)[-–—]?\s*\d+(?:[\.,\s]\d+)*(?!\w)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }

        let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = regex.matches(in: text, range: nsRange)

        var results: [ExtractedNumber] = []
        for match in matches {
            guard let range = Range(match.range, in: text) else { continue }
            let rawSubstring = String(text[range])
            if let decimal = parseDecimal(from: rawSubstring) {
                results.append(ExtractedNumber(rawString: rawSubstring, decimalValue: decimal, range: range))
            }
        }
        return results
    }

    /// Converts numeric string with potential commas, periods, or spaces into Decimal.
    public static func parseDecimal(from raw: String) -> Decimal? {
        var cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        var isNegative = false

        if cleaned.hasPrefix("-") || cleaned.hasPrefix("–") || cleaned.hasPrefix("—") {
            isNegative = true
            cleaned = String(cleaned.dropFirst()).trimmingCharacters(in: .whitespaces)
        }

        // Remove whitespace inside number (e.g. "1 000 000")
        cleaned = cleaned.replacingOccurrences(of: " ", with: "")

        let countDots = cleaned.filter { $0 == "." }.count
        let countCommas = cleaned.filter { $0 == "," }.count

        var normalized = cleaned

        if countDots > 0 && countCommas > 0 {
            // Find last dot and comma to determine which is decimal separator
            let lastDot = cleaned.lastIndex(of: ".")!
            let lastComma = cleaned.lastIndex(of: ",")!
            if lastDot > lastComma {
                // Comma is grouping separator, dot is decimal (e.g. 1,299.50)
                normalized = cleaned.replacingOccurrences(of: ",", with: "")
            } else {
                // Dot is grouping separator, comma is decimal (e.g. 1.299,50)
                normalized = cleaned.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
            }
        } else if countCommas > 1 {
            // Multiple commas: grouping separators (e.g. 1,000,000 or Indian 1,00,000)
            normalized = cleaned.replacingOccurrences(of: ",", with: "")
        } else if countDots > 1 {
            // Multiple dots: grouping separators (e.g. 1.000.000)
            normalized = cleaned.replacingOccurrences(of: ".", with: "")
        } else if countCommas == 1 {
            // Single comma. If 1 or 2 digits follow, or JPY-style? Check position.
            let commaIndex = cleaned.firstIndex(of: ",")!
            let fractionalLength = cleaned.distance(from: cleaned.index(after: commaIndex), to: cleaned.endIndex)
            if fractionalLength == 3 && cleaned.count > 4 {
                // Likely thousands separator: e.g. "1,000"
                normalized = cleaned.replacingOccurrences(of: ",", with: "")
            } else {
                // Likely decimal separator: e.g. "49,99"
                normalized = cleaned.replacingOccurrences(of: ",", with: ".")
            }
        }

        guard let decimal = Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX")),
              !decimal.isNaN else {
            return nil
        }
        return isNegative ? -decimal : decimal
    }

    private static func resolveCurrency(in text: String, amount: Decimal, rawAmountString: String) -> ParseOutcome {
        let lower = text.lowercased()

        // 1. Direct multi-character unambiguous symbol check (e.g. "a$", "c$", "s$", "nz$", "hk$", "r$", "rm", "rp")
        for (sym, code) in CurrencyRegistry.unambiguousSymbols where sym.count > 1 {
            if containsToken(in: lower, token: sym) {
                return .unambiguous(amount: amount, currency: code, rawAmountString: rawAmountString)
            }
        }

        // 2. Direct single-character unambiguous symbol check (e.g. "€", "£", "₹", "₩", "฿", "৳")
        for (sym, code) in CurrencyRegistry.unambiguousSymbols where sym.count == 1 {
            if text.contains(sym) {
                return .unambiguous(amount: amount, currency: code, rawAmountString: rawAmountString)
            }
        }

        // 3. Ambiguous symbol check: "rs", "rs.", "$", "¥"
        for (sym, candidates) in CurrencyRegistry.ambiguousSymbols {
            if sym.allSatisfy({ $0.isLetter || $0 == "." }) {
                // Word-based symbol like "rs" or "rs."
                if containsToken(in: lower, token: sym) {
                    return .ambiguous(amount: amount, symbol: sym.uppercased(), candidates: candidates, rawAmountString: rawAmountString)
                }
            } else {
                // Punctuation symbol like "$" or "¥"
                if text.contains(sym) {
                    return .ambiguous(amount: amount, symbol: sym, candidates: candidates, rawAmountString: rawAmountString)
                }
            }
        }

        // 4. Check known currency aliases (e.g. "us dollars", "euro", "pounds sterling", "renminbi")
        // Sort aliases by length descending so longer matches ("us dollar") beat shorter ("dollar")
        let allAliases: [(alias: String, code: CurrencyCode)] = CurrencyRegistry.knownCurrencies.values.flatMap { info in
            info.aliases.map { ($0, info.code) }
        }.sorted { $0.alias.count > $1.alias.count }

        for item in allAliases {
            if containsWordPhrase(in: lower, phrase: item.alias) {
                return .unambiguous(amount: amount, currency: item.code, rawAmountString: rawAmountString)
            }
        }

        // 5. Check for any 3-letter ISO currency code token in the text
        if let isoMatch = findISOCode(in: text, excludingAmount: rawAmountString) {
            if let validCode = CurrencyCode(isoMatch) {
                return .unambiguous(amount: amount, currency: validCode, rawAmountString: rawAmountString)
            } else {
                return .unknownCurrency(amount: amount, token: isoMatch, rawAmountString: rawAmountString)
            }
        }

        // 6. No currency detected -> bare number
        return .amountOnly(amount: amount, rawAmountString: rawAmountString)
    }

    private static func containsToken(in text: String, token: String) -> Bool {
        let pattern = #"(?<![a-z0-9])"# + NSRegularExpression.escapedPattern(for: token) + #"(?![a-z0-9])"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return text.contains(token)
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.firstMatch(in: text, range: range) != nil
    }

    private static func containsWordPhrase(in text: String, phrase: String) -> Bool {
        let pattern = #"\b"# + NSRegularExpression.escapedPattern(for: phrase) + #"\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return text.contains(phrase)
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.firstMatch(in: text, range: range) != nil
    }

    private static func findISOCode(in text: String, excludingAmount: String) -> String? {
        let pattern = #"\b[A-Za-z]{3}\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = regex.matches(in: text, range: range)

        // Ignore common 3-letter English words that are not intended as currency codes unless uppercase
        let ignoredLowerWords: Set<String> = ["the", "and", "for", "are", "but", "not", "you", "all", "any", "can", "had", "her", "was", "one", "our", "out", "day", "get", "has", "him", "his", "how", "man", "new", "now", "old", "see", "two", "way", "who", "boy", "did", "its", "let", "put", "say", "she", "too", "use"]

        for match in matches {
            guard let matchRange = Range(match.range, in: text) else { continue }
            let candidate = String(text[matchRange])
            let candidateUpper = candidate.uppercased()

            // If it's an exact uppercase known currency code (e.g. "USD", "INR", "XYZ")
            if CurrencyCode(candidateUpper) != nil {
                // If it's all uppercase or recognized in known currencies, take it
                if candidate == candidateUpper || CurrencyRegistry.knownCurrencies[CurrencyCode(candidateUpper)!] != nil {
                    return candidateUpper
                }
            }

            // If it's a 3-letter word, only accept if uppercase or known
            if candidate == candidateUpper && !ignoredLowerWords.contains(candidate.lowercased()) {
                return candidateUpper
            }
        }
        return nil
    }
}

