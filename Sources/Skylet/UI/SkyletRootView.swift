//
//  SkyletRootView.swift
//  Skylet
//

import SwiftUI
import DroppyKit

public enum SkyletMode: String, CaseIterable, Identifiable {
    case currency = "Currency"
    case focus = "Focus"
    case settings = "Settings"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .currency: return "indianrupeesign.circle.fill"
        case .focus: return "timer"
        case .settings: return "gearshape.fill"
        }
    }
}

public struct SkyletRootView: View {
    @ObservedObject var droplet: SkyletDroplet
    let context: ShelfWidgetContext

    public init(droplet: SkyletDroplet, context: ShelfWidgetContext) {
        self.droplet = droplet
        self.context = context
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: DroppySpacing.xs) {
            // Header Row (Standard Droppy layout)
            headerRow

            // Content branching on selected mode and compactness
            switch droplet.selectedMode {
            case .currency:
                CurrencyView(droplet: droplet, isCompact: context.isCompact)
            case .focus:
                FocusTimerView(droplet: droplet, isCompact: context.isCompact)
            case .settings:
                SettingsView(droplet: droplet)
            }

            Spacer(minLength: 0)
        }
        .padding(context.contentInsets)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: - Header Row

    private var headerRow: some View {
        HStack(spacing: 6) {
            // App symbol and title
            Image(systemName: "sparkles")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(SkyletTheme.skyBlue)

            Text("Skylet")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(SkyletTheme.primaryText)

            Spacer(minLength: DroppySpacing.md)

            // Segmented mode switcher (Currency vs Focus)
            if !context.isCompact {
                HStack(spacing: 2) {
                    ForEach(SkyletMode.allCases) { mode in
                        Button {
                            droplet.selectedMode = mode
                        } label: {
                            HStack(spacing: 3) {
                                Image(systemName: mode.iconName)
                                    .font(.system(size: 9))
                                Text(mode.rawValue)
                                    .font(.system(size: 10, weight: droplet.selectedMode == mode ? .semibold : .regular))
                            }
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(droplet.selectedMode == mode ? SkyletTheme.skyBlue.opacity(0.25) : Color.clear)
                            .foregroundStyle(droplet.selectedMode == mode ? SkyletTheme.skyBlue : SkyletTheme.secondaryText)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(2)
                .background(SkyletTheme.cardFill)
                .clipShape(Capsule())
            } else {
                // Paired compact toggle
                Button {
                    droplet.selectedMode = (droplet.selectedMode == .currency) ? .focus : .currency
                } label: {
                    Image(systemName: droplet.selectedMode.iconName)
                        .font(.system(size: 10))
                        .foregroundStyle(SkyletTheme.skyBlue)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

