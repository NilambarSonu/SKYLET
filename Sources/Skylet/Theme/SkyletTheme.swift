//
//  SkyletTheme.swift
//  Skylet
//

import SwiftUI
import DroppyKit

public enum SkyletTheme {
    // Skylet Brand Sky-Blue Colors
    public static let skyBlue = Color(red: 0.22, green: 0.74, blue: 0.97)       // #38BDF8
    public static let primaryBlue = Color(red: 0.08, green: 0.61, blue: 0.91)   // #159BE8
    public static let lightSky = Color(red: 0.49, green: 0.83, blue: 0.99)      // #7DD3FC
    public static let midnightSurface = Color(red: 0.04, green: 0.07, blue: 0.13) // #0B1220
    public static let elevatedSurface = Color(red: 0.07, green: 0.11, blue: 0.18) // #111B2E

    // Semantic Text Colors conforming to DroppyKit's AdaptiveColors
    public static var primaryText: Color {
        AdaptiveColors.notchSurfacePrimaryText
    }

    public static var secondaryText: Color {
        AdaptiveColors.notchSurfaceSecondaryText
    }

    public static var tertiaryText: Color {
        AdaptiveColors.notchSurfaceTertiaryText
    }

    public static var cardFill: Color {
        AdaptiveColors.notchSurfaceCardFill
    }

    // Typography
    public static let headerFont = Font.system(size: 13, weight: .semibold)
    public static let subheadFont = Font.system(size: 11, weight: .regular)
    public static let valueFont = Font.system(size: 20, weight: .bold, design: .rounded)
    public static let countdownFont = Font.system(size: 32, weight: .medium, design: .rounded)
    public static let smallCountdownFont = Font.system(size: 18, weight: .semibold, design: .rounded)
    public static let captionFont = Font.system(size: 10, weight: .regular)
    public static let buttonFont = Font.system(size: 11, weight: .medium)
}

