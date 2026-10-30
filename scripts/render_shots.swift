import SwiftUI
import AppKit

// MARK: - Droppy Tokens Stub for Renderer
public enum DroppySpacing {
    public static let xs: CGFloat = 4
    public static let xsm: CGFloat = 6
    public static let sm: CGFloat = 8
    public static let smd: CGFloat = 10
    public static let md: CGFloat = 12
    public static let lg: CGFloat = 16
    public static let xl: CGFloat = 20
}

public enum DroppyRadius {
    public static let sm: CGFloat = 6
    public static let md: CGFloat = 10
    public static let lg: CGFloat = 14
    public static let full: CGFloat = 999
}

// MARK: - Color & Style Constants matching SkyletTheme
public enum Theme {
    public static let skyBlue = Color(red: 0.22, green: 0.74, blue: 0.97)
    public static let primaryBlue = Color(red: 0.08, green: 0.61, blue: 0.91)
    public static let lightSky = Color(red: 0.49, green: 0.83, blue: 0.99)
    public static let solarGold = Color(red: 1.0, green: 0.776, blue: 0.267)
    public static let solarCore = Color(red: 1.0, green: 0.56, blue: 0.11)
    public static let solarFlare = Color(red: 1.0, green: 0.38, blue: 0.05)
    public static let solarGlow = Color(red: 1.0, green: 0.82, blue: 0.35, opacity: 0.35)
    public static let solarRayActive = Color(red: 1.0, green: 0.82, blue: 0.28)
    public static let solarRayTrack = Color.white.opacity(0.12)
    
    public static let background = Color(red: 0.07, green: 0.08, blue: 0.11)
    public static let cardBackground = Color(red: 0.11, green: 0.13, blue: 0.18)
    public static let cardBorder = Color.white.opacity(0.08)
    
    public static let primaryText = Color.white
    public static let secondaryText = Color(white: 0.65)
    public static let tertiaryText = Color(white: 0.42)
    
    public static let statusLive = Color(red: 0.20, green: 0.83, blue: 0.55)
    public static let statusDelayed = Color(red: 1.0, green: 0.76, blue: 0.24)
    
    public static let shelfCornerRadius: CGFloat = 18.0
    public static let shelfShape = RoundedRectangle(cornerRadius: 18.0, style: .continuous)
}

// MARK: - Solar Sun Component (matching Sources/Skylet/UI/SolarSunView.swift)
public struct SolarSunComponent: View {
    public let size: CGFloat
    public let progress: Double
    public let statusText: String
    public let statusColor: Color
    public let isRunning: Bool
    public let isPaused: Bool
    public let isCompleted: Bool

    private let totalRayCount = 12

    public init(
        size: CGFloat = 88,
        progress: Double = 0.0,
        statusText: String = "READY",
        statusColor: Color = Theme.solarGold,
        isRunning: Bool = false,
        isPaused: Bool = false,
        isCompleted: Bool = false
    ) {
        self.size = size
        self.progress = max(0.0, min(1.0, progress))
        self.statusText = statusText
        self.statusColor = statusColor
        self.isRunning = isRunning
        self.isPaused = isPaused
        self.isCompleted = isCompleted
    }

    public var body: some View {
        ZStack {
            // Ambient Glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            isCompleted ? Theme.statusLive.opacity(0.4) : Theme.solarGlow,
                            Color.clear
                        ],
                        center: .center,
                        startRadius: size * 0.2,
                        endRadius: size * 0.72
                    )
                )
                .frame(width: size * 1.45, height: size * 1.45)

            // Radial Solar Rays
            solarRaysView

            // Energetic Solar Core
            solarCoreSphere
        }
        .frame(width: size, height: size)
    }

    private var solarRaysView: some View {
        let center = CGPoint(x: size / 2, y: size / 2)
        let rayLength = size * 0.16
        let rayThickness: CGFloat = max(2.0, size * 0.045)
        let innerRadius = size * 0.38

        return ForEach(0..<totalRayCount, id: \.self) { i in
            let rayFraction = Double(i) / Double(totalRayCount)
            let isRayActive = isCompleted ? false : (rayFraction >= progress)
            let angle = Angle.degrees(Double(i) * (360.0 / Double(totalRayCount)) - 90.0)

            RoundedRectangle(cornerRadius: rayThickness / 2, style: .continuous)
                .fill(
                    isRayActive
                        ? LinearGradient(
                            colors: [Theme.solarRayActive, Theme.solarCore],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                        : LinearGradient(
                            colors: [Theme.solarRayTrack, Theme.solarRayTrack.opacity(0.4)],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                )
                .frame(width: rayThickness, height: rayLength)
                .offset(y: -(innerRadius + rayLength / 2))
                .rotationEffect(angle)
        }
    }

    private var solarCoreSphere: some View {
        let coreRadius = size * 0.54

        return ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: isCompleted
                            ? [Color(red: 0.4, green: 0.95, blue: 0.65), Theme.statusLive]
                            : [Theme.solarGold, Theme.solarCore, Theme.solarFlare],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: coreRadius, height: coreRadius)
                .shadow(
                    color: isCompleted ? Theme.statusLive.opacity(0.6) : Theme.solarCore.opacity(0.55),
                    radius: size * 0.08,
                    x: 0,
                    y: 2
                )

            // Celestial Horizon Arc Accent
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.7), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: max(1.2, size * 0.025)
                )
                .frame(width: coreRadius * 0.88, height: coreRadius * 0.88)

            // Inner Status Glyph
            if isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.22, weight: .bold))
                    .foregroundStyle(Color.black.opacity(0.85))
            } else if isPaused {
                Image(systemName: "pause.fill")
                    .font(.system(size: size * 0.20, weight: .bold))
                    .foregroundStyle(Color.black.opacity(0.85))
            } else if isRunning {
                Image(systemName: "flame.fill")
                    .font(.system(size: size * 0.20, weight: .bold))
                    .foregroundStyle(Color.black.opacity(0.85))
            } else {
                Circle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: size * 0.14, height: size * 0.14)
            }
        }
    }
}

// MARK: - Notch Container Shell
public struct DroppyNotchShell<Content: View>: View {
    public let activeTab: String // "Currency" or "Focus"
    public let content: Content

    public init(activeTab: String = "Currency", @ViewBuilder content: () -> Content) {
        self.activeTab = activeTab
        self.content = content()
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack(spacing: DroppySpacing.sm) {
                HStack(spacing: 5) {
                    Image(systemName: activeTab == "Focus" ? "sun.max.fill" : "sparkles")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(activeTab == "Focus" ? Theme.solarGold : Theme.skyBlue)
                    Text("Skylet")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.primaryText)
                }

                Spacer()

                // Mode Switcher Pill
                HStack(spacing: 2) {
                    modeTab(title: "Currency", isSelected: activeTab == "Currency")
                    modeTab(title: "Focus", isSelected: activeTab == "Focus")
                }
                .padding(2)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())
            }
            .padding(.horizontal, DroppySpacing.md)
            .padding(.top, DroppySpacing.smd)
            .padding(.bottom, DroppySpacing.sm)

            Divider()
                .background(Color.white.opacity(0.06))

            // Body
            content
                .padding(DroppySpacing.md)
        }
        .frame(width: 340)
        .background(Theme.background)
        .clipShape(Theme.shelfShape)
        .overlay(
            Theme.shelfShape
                .stroke(Theme.cardBorder, lineWidth: 1)
        )
    }

    private func modeTab(title: String, isSelected: Bool) -> some View {
        Text(title)
            .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
            .foregroundStyle(isSelected ? Color.black : Theme.secondaryText)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                isSelected
                    ? (title == "Focus" ? Theme.solarGold : Theme.skyBlue)
                    : Color.clear
            )
            .clipShape(Capsule())
    }
}

// MARK: - Screenshots Generation Views
public struct CurrencyMainView: View {
    public var body: some View {
        DroppyNotchShell(activeTab: "Currency") {
            VStack(alignment: .leading, spacing: DroppySpacing.md) {
                // Input Row
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Theme.skyBlue)
                        .font(.system(size: 13, weight: .semibold))
                    Text("$889.86")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundStyle(Theme.primaryText)
                    Spacer()
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.tertiaryText)
                    Text("Paste")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.secondaryText)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Theme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: DroppyRadius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: DroppyRadius.md, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )

                // Quick Currency Selector Chips
                HStack(spacing: 6) {
                    Text("Convert:")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.tertiaryText)
                    chip(text: "USD", isSelected: true)
                    chip(text: "EUR", isSelected: false)
                    chip(text: "GBP", isSelected: false)
                    chip(text: "JPY", isSelected: false)
                    chip(text: "AED", isSelected: false)
                }

                // Result Card
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("₹84,754.67")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.primaryText)
                        Spacer()
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Theme.statusLive)
                                .frame(width: 6, height: 6)
                            Text("LIVE")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(Theme.statusLive)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Theme.statusLive.opacity(0.12))
                        .clipShape(Capsule())
                    }

                    HStack(spacing: 6) {
                        Text("1 USD = ₹95.2450")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(Theme.secondaryText)
                        Text("•")
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.tertiaryText)
                        Text("Twelve Data")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Theme.tertiaryText)
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 10))
                            Text("Copy")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundStyle(Theme.skyBlue)
                    }
                }
                .padding(12)
                .background(Theme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: DroppyRadius.lg, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: DroppyRadius.lg, style: .continuous)
                        .stroke(Theme.skyBlue.opacity(0.2), lineWidth: 1)
                )
            }
        }
    }

    private func chip(text: String, isSelected: Bool) -> some View {
        Text(text)
            .font(.system(size: 10, weight: isSelected ? .bold : .medium))
            .foregroundStyle(isSelected ? Color.black : Theme.secondaryText)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(isSelected ? Theme.skyBlue : Color.white.opacity(0.06))
            .clipShape(Capsule())
    }
}

public struct FocusIdleView: View {
    public var body: some View {
        DroppyNotchShell(activeTab: "Focus") {
            VStack(spacing: DroppySpacing.md) {
                // Status Header
                HStack {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Theme.solarGold)
                            .frame(width: 6, height: 6)
                        Text("READY")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Theme.solarGold)
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Theme.solarGold.opacity(0.12))
                    .clipShape(Capsule())

                    Spacer()

                    Text("25 min focus session")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.secondaryText)
                }

                // Solar Sun Hero
                SolarSunComponent(
                    size: 92,
                    progress: 0.0,
                    statusText: "READY",
                    statusColor: Theme.solarGold,
                    isRunning: false,
                    isPaused: false,
                    isCompleted: false
                )
                .padding(.vertical, 4)

                // Presets Row
                HStack(spacing: 6) {
                    presetChip(title: "15m", isSelected: false)
                    presetChip(title: "25m", isSelected: true)
                    presetChip(title: "45m", isSelected: false)
                    presetChip(title: "60m", isSelected: false)
                    presetChip(title: "Custom", isSelected: false)
                }

                // Action Controls
                HStack(spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 10, weight: .bold))
                        Text("Start Focus")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Theme.solarGold)
                    .clipShape(RoundedRectangle(cornerRadius: DroppyRadius.md, style: .continuous))
                }
            }
        }
    }

    private func presetChip(title: String, isSelected: Bool) -> some View {
        Text(title)
            .font(.system(size: 11, weight: isSelected ? .bold : .medium))
            .foregroundStyle(isSelected ? Color.black : Theme.secondaryText)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(isSelected ? Theme.solarGold : Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: DroppyRadius.sm, style: .continuous))
    }
}

public struct FocusRunningView: View {
    public var body: some View {
        DroppyNotchShell(activeTab: "Focus") {
            VStack(spacing: DroppySpacing.md) {
                // Status Header
                HStack {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Theme.solarGold)
                            .frame(width: 6, height: 6)
                        Text("FOCUSING")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Theme.solarGold)
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Theme.solarGold.opacity(0.12))
                    .clipShape(Capsule())

                    Spacer()

                    HStack(spacing: 4) {
                        Text("18:42")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Theme.primaryText)
                        Text("remaining")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.secondaryText)
                    }
                }

                // Solar Sun Hero (progress: ~25% elapsed -> 3 rays receded)
                SolarSunComponent(
                    size: 92,
                    progress: 0.25,
                    statusText: "FOCUSING",
                    statusColor: Theme.solarGold,
                    isRunning: true,
                    isPaused: false,
                    isCompleted: false
                )
                .padding(.vertical, 4)

                // Calm Subtext
                HStack(spacing: 6) {
                    Image(systemName: "display")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.solarGold)
                    Text("Display awake active • Zero drift")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.secondaryText)
                }

                // Action Controls: Pause + Reset
                HStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "pause.fill")
                            .font(.system(size: 10, weight: .bold))
                        Text("Pause")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Theme.solarGold)
                    .clipShape(RoundedRectangle(cornerRadius: DroppyRadius.md, style: .continuous))

                    HStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 10, weight: .bold))
                        Text("Reset")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(Theme.secondaryText)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: DroppyRadius.md, style: .continuous))
                }
            }
        }
    }
}

public struct FocusPausedView: View {
    public var body: some View {
        DroppyNotchShell(activeTab: "Focus") {
            VStack(spacing: DroppySpacing.md) {
                // Status Header
                HStack {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Theme.statusDelayed)
                            .frame(width: 6, height: 6)
                        Text("PAUSED")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Theme.statusDelayed)
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Theme.statusDelayed.opacity(0.12))
                    .clipShape(Capsule())

                    Spacer()

                    HStack(spacing: 4) {
                        Text("14:20")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Theme.primaryText)
                        Text("paused")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.secondaryText)
                    }
                }

                // Solar Sun Hero (progress: ~42% elapsed)
                SolarSunComponent(
                    size: 92,
                    progress: 0.42,
                    statusText: "PAUSED",
                    statusColor: Theme.statusDelayed,
                    isRunning: false,
                    isPaused: true,
                    isCompleted: false
                )
                .padding(.vertical, 4)

                // Subtext
                Text("Session paused • Power assertion released")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.tertiaryText)

                // Action Controls: Resume + Reset
                HStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 10, weight: .bold))
                        Text("Resume")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Theme.solarGold)
                    .clipShape(RoundedRectangle(cornerRadius: DroppyRadius.md, style: .continuous))

                    HStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 10, weight: .bold))
                        Text("Reset")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(Theme.secondaryText)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: DroppyRadius.md, style: .continuous))
                }
            }
        }
    }
}

public struct FocusNearCompletionView: View {
    public var body: some View {
        DroppyNotchShell(activeTab: "Focus") {
            VStack(spacing: DroppySpacing.md) {
                // Status Header
                HStack {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Theme.solarGold)
                            .frame(width: 6, height: 6)
                        Text("FINAL STRETCH")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Theme.solarGold)
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Theme.solarGold.opacity(0.12))
                    .clipShape(Capsule())

                    Spacer()

                    HStack(spacing: 4) {
                        Text("00:45")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Theme.primaryText)
                        Text("remaining")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.secondaryText)
                    }
                }

                // Solar Sun Hero (progress: ~95% elapsed -> 1 ray remaining)
                SolarSunComponent(
                    size: 92,
                    progress: 0.95,
                    statusText: "FOCUSING",
                    statusColor: Theme.solarGold,
                    isRunning: true,
                    isPaused: false,
                    isCompleted: false
                )
                .padding(.vertical, 4)

                // Subtext
                Text("Almost there • Maintain your deep focus")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.secondaryText)

                // Action Controls: Pause + Reset
                HStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "pause.fill")
                            .font(.system(size: 10, weight: .bold))
                        Text("Pause")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Theme.solarGold)
                    .clipShape(RoundedRectangle(cornerRadius: DroppyRadius.md, style: .continuous))

                    HStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 10, weight: .bold))
                        Text("Reset")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(Theme.secondaryText)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: DroppyRadius.md, style: .continuous))
                }
            }
        }
    }
}

public struct FocusCompletedView: View {
    public var body: some View {
        DroppyNotchShell(activeTab: "Focus") {
            VStack(spacing: DroppySpacing.md) {
                // Status Header
                HStack {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Theme.statusLive)
                            .frame(width: 6, height: 6)
                        Text("COMPLETED")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Theme.statusLive)
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Theme.statusLive.opacity(0.12))
                    .clipShape(Capsule())

                    Spacer()

                    Text("Session complete! 🎉")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.primaryText)
                }

                // Solar Sun Hero (progress: 1.0 -> full green/gold completion)
                SolarSunComponent(
                    size: 92,
                    progress: 1.0,
                    statusText: "COMPLETED",
                    statusColor: Theme.statusLive,
                    isRunning: false,
                    isPaused: false,
                    isCompleted: true
                )
                .padding(.vertical, 4)

                // Subtext
                Text("Great work! Display awake assertion released.")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.secondaryText)

                // Action Controls: Start Again + Reset
                HStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 10, weight: .bold))
                        Text("Start Again")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Theme.statusLive)
                    .clipShape(RoundedRectangle(cornerRadius: DroppyRadius.md, style: .continuous))

                    HStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 10, weight: .bold))
                        Text("Reset")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(Theme.secondaryText)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: DroppyRadius.md, style: .continuous))
                }
            }
        }
    }
}

public struct NotchCompactTimerView: View {
    public var body: some View {
        HStack(spacing: 8) {
            SolarSunComponent(
                size: 18,
                progress: 0.25,
                isRunning: true,
                isCompleted: false
            )

            Text("18:42")
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color.black)
        .clipShape(Capsule())
    }
}

// MARK: - Rendering Helper
@MainActor
func renderToPNG<V: View>(view: V, size: CGSize, path: String) {
    let hostingView = NSHostingView(rootView: view)
    hostingView.frame = CGRect(origin: .zero, size: size)
    hostingView.layoutSubtreeIfNeeded()

    guard let rep = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
        print("Failed to allocate bitmap rep for \(path)")
        return
    }
    hostingView.cacheDisplay(in: hostingView.bounds, to: rep)

    guard let pngData = rep.representation(using: .png, properties: [:]) else {
        print("Failed to convert to PNG for \(path)")
        return
    }
    let url = URL(fileURLWithPath: path)
    try? pngData.write(to: url)
    print("Saved \(path) (\(Int(size.width))x\(Int(size.height)))")
}

@MainActor
func generateAllScreenshots() {
    print("==> Rendering SKYLET v1.1.0 Screenshots...")

    let shelfSize = CGSize(width: 340, height: 260)

    renderToPNG(view: CurrencyMainView(), size: shelfSize, path: "shots/currency_main.png")
    renderToPNG(view: FocusIdleView(), size: CGSize(width: 340, height: 280), path: "shots/focus_idle.png")
    renderToPNG(view: FocusRunningView(), size: CGSize(width: 340, height: 280), path: "shots/focus_running.png")
    renderToPNG(view: FocusPausedView(), size: CGSize(width: 340, height: 280), path: "shots/focus_paused.png")
    renderToPNG(view: FocusNearCompletionView(), size: CGSize(width: 340, height: 280), path: "shots/focus_near_completion.png")
    renderToPNG(view: FocusCompletedView(), size: CGSize(width: 340, height: 280), path: "shots/focus_completed.png")
    renderToPNG(view: NotchCompactTimerView(), size: CGSize(width: 100, height: 32), path: "shots/notch_compact_timer.png")

    print("==> Screenshots generated successfully!")
}

Task { @MainActor in
    generateAllScreenshots()
    exit(0)
}

dispatchMain()
