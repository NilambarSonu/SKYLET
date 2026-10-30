//
//  CurrencySelectorView.swift
//  Skylet
//
//  Intelligent, searchable currency selector modal.
//

import SwiftUI
import DroppyKit
import SkyletCore

public struct CurrencySelectorView: View {
    @Binding var selectedCurrency: CurrencyCode
    let onSelect: (CurrencyCode) -> Void
    let onDismiss: () -> Void

    @State private var searchText: String = ""
    @FocusState private var isSearchFocused: Bool

    private var allCurrencies: [CurrencyInfo] {
        CurrencyRegistry.knownCurrencies.values
            .sorted { $0.code.rawValue < $1.code.rawValue }
    }

    private var filteredCurrencies: [CurrencyInfo] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else {
            return allCurrencies
        }
        return allCurrencies.filter { info in
            info.code.rawValue.lowercased().contains(query) ||
            info.name.lowercased().contains(query) ||
            info.symbol.lowercased().contains(query) ||
            info.aliases.contains { $0.lowercased().contains(query) }
        }
    }

    public init(
        selectedCurrency: Binding<CurrencyCode>,
        onSelect: @escaping (CurrencyCode) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self._selectedCurrency = selectedCurrency
        self.onSelect = onSelect
        self.onDismiss = onDismiss
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: DroppySpacing.sm) {
            // Header Bar
            HStack(spacing: DroppySpacing.xsm) {
                Text("Select Currency")
                    .font(SkyletTheme.headerFont)
                    .foregroundStyle(SkyletTheme.primaryText)

                Spacer(minLength: DroppySpacing.md)

                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(SkyletTheme.tertiaryText)
                }
                .buttonStyle(.plain)
                .help("Close currency picker (Esc)")
            }

            // Search Bar
            HStack(spacing: DroppySpacing.xs) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11))
                    .foregroundStyle(SkyletTheme.tertiaryText)

                TextField("Search by code or country…", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(SkyletTheme.inputFont)
                    .foregroundStyle(SkyletTheme.primaryText)
                    .focused($isSearchFocused)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(SkyletTheme.tertiaryText)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, DroppySpacing.sm)
            .padding(.vertical, DroppySpacing.xsm)
            .background(SkyletTheme.controlBackground)
            .clipShape(RoundedRectangle(cornerRadius: DroppyRadius.sm, style: .continuous))

            // Popular Quick-Pills (shown when search is empty)
            if searchText.isEmpty {
                VStack(alignment: .leading, spacing: DroppySpacing.xs) {
                    Text("Popular")
                        .font(SkyletTheme.captionFont)
                        .foregroundStyle(SkyletTheme.tertiaryText)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DroppySpacing.xs) {
                            ForEach(CurrencyRegistry.popularCurrencies, id: \.self) { code in
                                let info = CurrencyRegistry.info(for: code)
                                Button {
                                    selectCurrency(code)
                                } label: {
                                    HStack(spacing: 3) {
                                        Text(info.flag)
                                            .font(.system(size: 11))
                                        Text(code.rawValue)
                                            .font(SkyletTheme.compactButtonFont)
                                    }
                                    .padding(.horizontal, DroppySpacing.sm)
                                    .padding(.vertical, DroppySpacing.xs)
                                    .background(selectedCurrency == code ? SkyletTheme.skyBlue.opacity(0.22) : SkyletTheme.controlBackground)
                                    .foregroundStyle(selectedCurrency == code ? SkyletTheme.skyBlue : SkyletTheme.primaryText)
                                    .clipShape(RoundedRectangle(cornerRadius: DroppyRadius.xs, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }

            // Scrollable Currency List
            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(spacing: 2) {
                    ForEach(filteredCurrencies, id: \.code) { info in
                        currencyRow(info)
                    }
                }
            }
            .frame(maxHeight: 180)
        }
        .padding(DroppySpacing.md)
        .background(SkyletTheme.midnightSurface)
        .clipShape(RoundedRectangle(cornerRadius: DroppyRadius.medium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DroppyRadius.medium, style: .continuous)
                .stroke(SkyletTheme.cardFill, lineWidth: 1)
        )
        .onAppear {
            isSearchFocused = true
        }
    }

    private func currencyRow(_ info: CurrencyInfo) -> some View {
        Button {
            selectCurrency(info.code)
        } label: {
            HStack(spacing: DroppySpacing.sm) {
                // Flag
                Text(info.flag)
                    .font(.system(size: 14))

                // Currency Code and Symbol
                HStack(spacing: 4) {
                    Text(info.code.rawValue)
                        .font(SkyletTheme.subheadFont)
                        .foregroundStyle(SkyletTheme.primaryText)

                    Text("(\(info.symbol))")
                        .font(SkyletTheme.captionFont)
                        .foregroundStyle(SkyletTheme.tertiaryText)
                }

                // Currency Full Name
                Text(info.name)
                    .font(SkyletTheme.captionFont)
                    .foregroundStyle(SkyletTheme.secondaryText)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer(minLength: DroppySpacing.md)

                // Selection Checkmark
                if selectedCurrency == info.code {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(SkyletTheme.skyBlue)
                }
            }
            .padding(.horizontal, DroppySpacing.sm)
            .padding(.vertical, DroppySpacing.xsm)
            .background(selectedCurrency == info.code ? SkyletTheme.skyBlue.opacity(0.12) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: DroppyRadius.xs, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func selectCurrency(_ code: CurrencyCode) {
        selectedCurrency = code
        onSelect(code)
        onDismiss()
    }
}

