//
//  CurrencyMetadata.swift
//  SkyletCore
//

import Foundation

public struct CurrencyInfo: Hashable, Sendable {
    public let code: CurrencyCode
    public let symbol: String
    public let name: String
    public let flag: String
    public let decimals: Int
    public let aliases: [String]

    public init(
        code: CurrencyCode,
        symbol: String,
        name: String,
        flag: String,
        decimals: Int = 2,
        aliases: [String] = []
    ) {
        self.code = code
        self.symbol = symbol
        self.name = name
        self.flag = flag
        self.decimals = decimals
        self.aliases = aliases
    }
}

public enum CurrencyRegistry {
    /// Currencies supported with detailed metadata.
    public static let knownCurrencies: [CurrencyCode: CurrencyInfo] = [
        .usd: CurrencyInfo(
            code: .usd,
            symbol: "$",
            name: "US Dollar",
            flag: "🇺🇸",
            decimals: 2,
            aliases: ["usd", "dollar", "dollars", "us dollar", "us dollars", "buck", "bucks"]
        ),
        .eur: CurrencyInfo(
            code: .eur,
            symbol: "€",
            name: "Euro",
            flag: "🇪🇺",
            decimals: 2,
            aliases: ["eur", "euro", "euros"]
        ),
        .gbp: CurrencyInfo(
            code: .gbp,
            symbol: "£",
            name: "British Pound",
            flag: "🇬🇧",
            decimals: 2,
            aliases: ["gbp", "pound", "pounds", "british pound", "pounds sterling", "sterling"]
        ),
        .inr: CurrencyInfo(
            code: .inr,
            symbol: "₹",
            name: "Indian Rupee",
            flag: "🇮🇳",
            decimals: 2,
            aliases: ["inr", "rupee", "rupees", "indian rupee", "indian rupees", "inr."]
        ),
        .jpy: CurrencyInfo(
            code: .jpy,
            symbol: "¥",
            name: "Japanese Yen",
            flag: "🇯🇵",
            decimals: 0,
            aliases: ["jpy", "yen", "japanese yen"]
        ),
        .cny: CurrencyInfo(
            code: .cny,
            symbol: "¥",
            name: "Chinese Yuan",
            flag: "🇨🇳",
            decimals: 2,
            aliases: ["cny", "rmb", "yuan", "renminbi", "chinese yuan"]
        ),
        .aud: CurrencyInfo(
            code: .aud,
            symbol: "A$",
            name: "Australian Dollar",
            flag: "🇦🇺",
            decimals: 2,
            aliases: ["aud", "australian dollar", "australian dollars", "aussie dollar"]
        ),
        .cad: CurrencyInfo(
            code: .cad,
            symbol: "C$",
            name: "Canadian Dollar",
            flag: "🇨🇦",
            decimals: 2,
            aliases: ["cad", "canadian dollar", "canadian dollars", "loonie"]
        ),
        .sgd: CurrencyInfo(
            code: .sgd,
            symbol: "S$",
            name: "Singapore Dollar",
            flag: "🇸🇬",
            decimals: 2,
            aliases: ["sgd", "singapore dollar", "singapore dollars"]
        ),
        .chf: CurrencyInfo(
            code: .chf,
            symbol: "CHF",
            name: "Swiss Franc",
            flag: "🇨🇭",
            decimals: 2,
            aliases: ["chf", "swiss franc", "swiss francs", "franc", "francs"]
        ),
        .aed: CurrencyInfo(
            code: .aed,
            symbol: "AED",
            name: "UAE Dirham",
            flag: "🇦🇪",
            decimals: 2,
            aliases: ["aed", "dirham", "dirhams", "uae dirham", "emirati dirham"]
        ),
        .sar: CurrencyInfo(
            code: .sar,
            symbol: "SAR",
            name: "Saudi Riyal",
            flag: "🇸🇦",
            decimals: 2,
            aliases: ["sar", "riyal", "riyals", "saudi riyal"]
        ),
        .nzd: CurrencyInfo(
            code: .nzd,
            symbol: "NZ$",
            name: "New Zealand Dollar",
            flag: "🇳🇿",
            decimals: 2,
            aliases: ["nzd", "new zealand dollar", "new zealand dollars", "kiwi dollar"]
        ),
        .hkd: CurrencyInfo(
            code: .hkd,
            symbol: "HK$",
            name: "Hong Kong Dollar",
            flag: "🇭🇰",
            decimals: 2,
            aliases: ["hkd", "hong kong dollar", "hong kong dollars"]
        ),
        .krw: CurrencyInfo(
            code: .krw,
            symbol: "₩",
            name: "South Korean Won",
            flag: "🇰🇷",
            decimals: 0,
            aliases: ["krw", "won", "south korean won", "korean won"]
        ),
        .brl: CurrencyInfo(
            code: .brl,
            symbol: "R$",
            name: "Brazilian Real",
            flag: "🇧🇷",
            decimals: 2,
            aliases: ["brl", "real", "reais", "brazilian real"]
        ),
        .thb: CurrencyInfo(
            code: .thb,
            symbol: "฿",
            name: "Thai Baht",
            flag: "🇹🇭",
            decimals: 2,
            aliases: ["thb", "baht", "thai baht"]
        ),
        .myr: CurrencyInfo(
            code: .myr,
            symbol: "RM",
            name: "Malaysian Ringgit",
            flag: "🇲🇾",
            decimals: 2,
            aliases: ["myr", "ringgit", "malaysian ringgit"]
        ),
        .idr: CurrencyInfo(
            code: .idr,
            symbol: "Rp",
            name: "Indonesian Rupiah",
            flag: "🇮🇩",
            decimals: 0,
            aliases: ["idr", "rupiah", "indonesian rupiah"]
        ),
        .bdt: CurrencyInfo(
            code: .bdt,
            symbol: "৳",
            name: "Bangladeshi Taka",
            flag: "🇧🇩",
            decimals: 2,
            aliases: ["bdt", "taka", "bangladeshi taka"]
        ),
        .pkr: CurrencyInfo(
            code: .pkr,
            symbol: "PKR",
            name: "Pakistani Rupee",
            flag: "🇵🇰",
            decimals: 2,
            aliases: ["pkr", "pakistani rupee", "pakistan rupee"]
        ),
        .npr: CurrencyInfo(
            code: .npr,
            symbol: "NPR",
            name: "Nepalese Rupee",
            flag: "🇳🇵",
            decimals: 2,
            aliases: ["npr", "nepalese rupee", "nepal rupee"]
        )
    ]

    /// Symbols that map to multiple possible currencies and must not be silently assumed.
    public static let ambiguousSymbols: [String: [CurrencyCode]] = [
        "$": [.usd, .cad, .aud, .sgd, .nzd, .hkd],
        "¥": [.jpy, .cny],
        "rs": [.inr, .pkr, .npr],
        "rs.": [.inr, .pkr, .npr]
    ]

    /// Unambiguous symbols mapping directly to a single currency.
    public static let unambiguousSymbols: [String: CurrencyCode] = [
        "€": .eur,
        "£": .gbp,
        "₹": .inr,
        "₩": .krw,
        "฿": .thb,
        "৳": .bdt,
        "a$": .aud,
        "c$": .cad,
        "s$": .sgd,
        "nz$": .nzd,
        "hk$": .hkd,
        "r$": .brl,
        "rm": .myr,
        "rp": .idr
    ]

    /// Lookup metadata for any currency code, generating sensible defaults for unlisted ISO codes.
    public static func info(for code: CurrencyCode) -> CurrencyInfo {
        if let info = knownCurrencies[code] {
            return info
        }
        return CurrencyInfo(
            code: code,
            symbol: code.rawValue,
            name: code.rawValue,
            flag: "🌐",
            decimals: 2,
            aliases: [code.rawValue.lowercased()]
        )
    }

    /// List of primary suggested currencies for quick picking.
    public static let popularCurrencies: [CurrencyCode] = [
        .usd, .eur, .gbp, .aed, .jpy, .cad, .aud, .sgd, .sar, .cny
    ]
}

