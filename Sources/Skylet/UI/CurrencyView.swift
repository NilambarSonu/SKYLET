//
//  CurrencyView.swift
//  Skylet
//
//  Premium Currency Intelligence & Instant Conversion View
//  Quiet Precision. Instant Intelligence.
//

import SwiftUI
import AppKit
import DroppyKit
import SkyletCore

public struct CurrencyView: View {
    @ObservedObject var droplet: SkyletDroplet
    let isCompact: Bool

    @State private var inputText: String = ""
    @State private var selectedCurrency: CurrencyCode = .usd
    @State private var ambiguousCandidates: [CurrencyCode] = []
    @State private var detectedAmount: Decimal?
    @State private var conversionResult: CurrencyConversionResult?
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var copiedConfirmation: Bool = false
    @State private var isReversed: Bool = false
    @State private var showCurrencyPicker: Bool = false
    @State private var swapRotation: Double = 0
    @State private var refreshRotation: Double = 0

    @FocusState private var isInputFocused: Bool

    public init(droplet: SkyletDroplet, isCompact: Bool) {
        self.droplet = droplet
        self.isCompact = isCompact
    }

    public var body: some View {
        Group {
            if isCompact {
                compactBody
            } else {
                fullBody
            }
        }
        .sheet(isPresented: $showCurrencyPicker) {
            CurrencySelectorView(
                selectedCurrency: $selectedCurrency,
                onSelect: { code in
                    selectedCurrency = code
                    ambiguousCandidates = []
                    if let amt = detectedAmount {
                        executeConversion(amount: amt, source: code)
                    }
                },
                onDismiss: {
                    showCurrencyPicker = false
                }
            )
        }
    }

    // MARK: - Full (Solo) Body

    private var fullBody: some View {
        VStack(alignment: .leading, spacing: DroppySpacing.xs) {
            // 1. Amount Input & Clipboard Bar
            inputRow

            // 2. Ambiguous Candidates Bar (when applicable)
            if !ambiguousCandidates.isEmpty {
                ambiguousCandidateRow
            }

            // 3. Main Result & Conversion Area
            if isLoading && conversionResult == nil {
                loadingRow
            } else if let result = conversionResult {
                resultHeroSection(result)
            } else if let error = errorMessage {
                errorRow(error)
            } else {
                emptyStateRow
            }
        }
    }

    // MARK: - Input Row

    private var inputRow: some View {
        HStack(spacing: DroppySpacing.xs) {
            HStack(spacing: DroppySpacing.xs) {
                // Currency Symbol or Flag of selected source
                Button {
                    showCurrencyPicker = true
                } label: {
                    HStack(spacing: 2) {
                        Text(currentSourceInfo.flag)
                            .font(.system(size: 11))
                        Text(currentSourceCurrency.rawValue)
                            .font(SkyletTheme.compactButtonFont)
                            .foregroundStyle(SkyletTheme.primaryText)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundStyle(SkyletTheme.tertiaryText)
                    }
                    .padding(.horizontal, 5)
                    .padding(.vertical, 3)
                    .background(SkyletTheme.controlBackground)
                    .clipShape(RoundedRectangle(cornerRadius: DroppyRadius.xs, style: .continuous))
                }
                .buttonStyle(.plain)
                .help("Change source currency")

                // Text Field
                TextField("Amount (e.g. $25, €49.99, 100 USD)", text: $inputText)
                    .textFieldStyle(.plain)
                    .font(SkyletTheme.inputFont)
                    .foregroundStyle(SkyletTheme.primaryText)
                    .focused($isInputFocused)
                    .onSubmit {
                        processInput(inputText)
                    }

                // Clear button
                if !inputText.isEmpty {
                    Button {
                        withAnimation(SkyletTheme.quickAnimation) {
                            inputText = ""
                            conversionResult = nil
                            errorMessage = nil
                            ambiguousCandidates = []
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(SkyletTheme.tertiaryText)
                    }
                    .buttonStyle(.plain)
                    .help("Clear input")
                }
            }
            .padding(.horizontal, DroppySpacing.sm)
            .padding(.vertical, 5)
            .background(SkyletTheme.controlBackground)
            .clipShape(RoundedRectangle(cornerRadius: DroppyRadius.sm, style: .continuous))

            // Paste button (Quiet Liquid Glass pill)
            Button {
                importFromClipboard()
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 10))
                    Text("Paste")
                        .font(SkyletTheme.buttonFont)
                }
                .padding(.horizontal, DroppySpacing.sm)
                .padding(.vertical, 5)
                .background(SkyletTheme.controlBackground)
                .foregroundStyle(SkyletTheme.primaryText)
                .clipShape(RoundedRectangle(cornerRadius: DroppyRadius.sm, style: .continuous))
            }
            .buttonStyle(.plain)
            .help("Convert amount from clipboard (⌘V)")
        }
    }

    // MARK: - Ambiguous Candidate Row

    private var ambiguousCandidateRow: some View {
        HStack(spacing: DroppySpacing.xs) {
            Text("Match:")
                .font(SkyletTheme.captionFont)
                .foregroundStyle(SkyletTheme.tertiaryText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DroppySpacing.xs) {
                    ForEach(ambiguousCandidates.prefix(6), id: \.self) { code in
                        let info = CurrencyRegistry.info(for: code)
                        Button {
                            withAnimation(SkyletTheme.quickAnimation) {
                                selectedCurrency = code
                                ambiguousCandidates = []
                                if let amt = detectedAmount {
                                    executeConversion(amount: amt, source: code)
                                }
                            }
                        } label: {
                            HStack(spacing: 2) {
                                Text(info.flag)
                                    .font(.system(size: 10))
                                Text(code.rawValue)
                                    .font(SkyletTheme.compactButtonFont)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(selectedCurrency == code ? SkyletTheme.skyBlue.opacity(0.25) : SkyletTheme.controlBackground)
                            .foregroundStyle(selectedCurrency == code ? SkyletTheme.skyBlue : SkyletTheme.secondaryText)
                            .clipShape(RoundedRectangle(cornerRadius: DroppyRadius.xs, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.vertical, 1)
    }

    // MARK: - Result Hero Section

    private func resultHeroSection(_ result: CurrencyConversionResult) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            // Hero converted amount & primary actions row
            HStack(alignment: .firstTextBaseline, spacing: DroppySpacing.sm) {
                // Hero Target Amount
                Text(formatConverted(result))
                    .font(SkyletTheme.heroAmountFont)
                    .monospacedDigit()
                    .foregroundStyle(SkyletTheme.skyBlue)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                // Source amount tag
                HStack(spacing: 3) {
                    Text("from")
                        .font(SkyletTheme.captionFont)
                        .foregroundStyle(SkyletTheme.tertiaryText)
                    Text(formatSource(result))
                        .font(SkyletTheme.subheadFont)
                        .foregroundStyle(SkyletTheme.secondaryText)
                }

                Spacer(minLength: DroppySpacing.sm)

                // Swap Direction Button
                Button {
                    withAnimation(SkyletTheme.standardAnimation) {
                        swapRotation += 180
                        swapCurrencies()
                    }
                } label: {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(isReversed ? SkyletTheme.skyBlue : SkyletTheme.secondaryText)
                        .rotationEffect(.degrees(swapRotation))
                        .padding(5)
                        .background(isReversed ? SkyletTheme.skyBlue.opacity(0.18) : SkyletTheme.controlBackground)
                        .clipShape(RoundedRectangle(cornerRadius: DroppyRadius.xs, style: .continuous))
                }
                .buttonStyle(.plain)
                .help("Swap conversion direction (\(result.sourceCurrency.rawValue) ⇄ \(result.targetCurrency.rawValue))")

                // Copy Action Button
                Button {
                    copyResult(result)
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: copiedConfirmation ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 9, weight: .semibold))
                        Text(copiedConfirmation ? "Copied" : "Copy")
                            .font(SkyletTheme.compactButtonFont)
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(copiedConfirmation ? SkyletTheme.statusLive.opacity(0.2) : SkyletTheme.controlBackground)
                    .foregroundStyle(copiedConfirmation ? SkyletTheme.statusLive : SkyletTheme.primaryText)
                    .clipShape(RoundedRectangle(cornerRadius: DroppyRadius.xs, style: .continuous))
                }
                .buttonStyle(.plain)
                .help("Copy converted amount to clipboard")
            }

            // Rate Provenance & Freshness Subtitle
            HStack(spacing: 5) {
                // Exchange Rate formula
                Text(CurrencyFormatter.formatRateCompact(from: result.sourceCurrency, to: result.targetCurrency, rate: result.rate))
                    .font(SkyletTheme.captionFont)
                    .monospacedDigit()
                    .foregroundStyle(SkyletTheme.secondaryText)

                Text("•")
                    .font(SkyletTheme.captionFont)
                    .foregroundStyle(SkyletTheme.tertiaryText)

                // Restrained Freshness Dot
                Circle()
                    .fill(freshnessColor(for: result.freshness))
                    .frame(width: 5, height: 5)

                // Provenance Text
                Text(result.formattedSubtext)
                    .font(SkyletTheme.captionFont)
                    .foregroundStyle(freshnessTextColor(for: result.freshness))
                    .lineLimit(1)

                // Live Refresh Action Button
                Button {
                    refreshLiveRate()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(isLoading ? SkyletTheme.tertiaryText : SkyletTheme.skyBlue)
                        .rotationEffect(.degrees(refreshRotation))
                }
                .buttonStyle(.plain)
                .disabled(isLoading)
                .help("Refresh exchange rate from provider")

                // Settings indicator if using daily reference
                if result.freshness == .dailyReference && droplet.keychain.get(key: "twelvedata_api_key") == nil {
                    Button {
                        droplet.selectedMode = .settings
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 9))
                            .foregroundStyle(SkyletTheme.tertiaryText)
                    }
                    .buttonStyle(.plain)
                    .help("Configure Twelve Data API Key for real-time rates")
                }
            }
            .padding(.top, 2)
        }
        .padding(.top, 2)
    }

    // MARK: - Loading State

    private var loadingRow: some View {
        HStack(spacing: DroppySpacing.sm) {
            ProgressView()
                .controlSize(.small)
            Text("Fetching exchange rate…")
                .font(SkyletTheme.captionFont)
                .foregroundStyle(SkyletTheme.secondaryText)
            Spacer()
        }
        .padding(.vertical, DroppySpacing.sm)
    }

    // MARK: - Error State

    private func errorRow(_ error: String) -> some View {
        HStack(spacing: DroppySpacing.xs) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 11))
                .foregroundStyle(SkyletTheme.statusDelayed)

            Text(error)
                .font(SkyletTheme.captionFont)
                .foregroundStyle(SkyletTheme.secondaryText)
                .lineLimit(2)

            Spacer(minLength: DroppySpacing.sm)

            Button("Retry") {
                if let amt = detectedAmount {
                    executeConversion(amount: amt, source: selectedCurrency, forceRefresh: true)
                }
            }
            .font(SkyletTheme.compactButtonFont)
            .foregroundStyle(SkyletTheme.skyBlue)
            .buttonStyle(.plain)

            Button("Settings") {
                droplet.selectedMode = .settings
            }
            .font(SkyletTheme.compactButtonFont)
            .foregroundStyle(SkyletTheme.tertiaryText)
            .buttonStyle(.plain)
        }
        .padding(.vertical, 3)
    }

    // MARK: - Empty State Suggestions

    private var emptyStateRow: some View {
        HStack(spacing: DroppySpacing.xs) {
            Text("Suggestions:")
                .font(SkyletTheme.captionFont)
                .foregroundStyle(SkyletTheme.tertiaryText)

            ForEach(["$25", "€49.99", "100 USD", "£12.50"], id: \.self) { sample in
                Button(sample) {
                    withAnimation(SkyletTheme.quickAnimation) {
                        inputText = sample
                        processInput(sample)
                    }
                }
                .font(SkyletTheme.captionFont)
                .foregroundStyle(SkyletTheme.skyBlue)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(SkyletTheme.controlBackground)
                .clipShape(RoundedRectangle(cornerRadius: DroppyRadius.xs, style: .continuous))
                .buttonStyle(.plain)
            }
        }
        .padding(.top, DroppySpacing.xs)
    }

    // MARK: - Compact (Paired) Body

    private var compactBody: some View {
        VStack(alignment: .leading, spacing: DroppySpacing.xs) {
            if let result = conversionResult {
                HStack(alignment: .firstTextBaseline) {
                    Text(formatConverted(result))
                        .font(SkyletTheme.mediumAmountFont)
                        .monospacedDigit()
                        .foregroundStyle(SkyletTheme.skyBlue)
                        .lineLimit(1)

                    Spacer(minLength: DroppySpacing.xs)

                    Button {
                        withAnimation(SkyletTheme.standardAnimation) {
                            swapCurrencies()
                        }
                    } label: {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 8))
                            .foregroundStyle(SkyletTheme.tertiaryText)
                    }
                    .buttonStyle(.plain)
                }

                HStack(spacing: 4) {
                    Circle()
                        .fill(freshnessColor(for: result.freshness))
                        .frame(width: 4, height: 4)
                    Text(result.formattedSubtext)
                        .font(SkyletTheme.captionFont)
                        .foregroundStyle(SkyletTheme.tertiaryText)
                        .lineLimit(1)
                }
            } else {
                Button {
                    importFromClipboard()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.clipboard")
                            .font(.system(size: 10))
                        Text("Paste amount")
                            .font(SkyletTheme.buttonFont)
                    }
                    .foregroundStyle(SkyletTheme.skyBlue)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Freshness Helpers

    private func freshnessColor(for freshness: RateFreshness) -> Color {
        switch freshness {
        case .live: return SkyletTheme.statusLive
        case .delayed: return SkyletTheme.statusDelayed
        case .cached: return SkyletTheme.statusCached
        case .dailyReference: return SkyletTheme.statusReference
        case .stale: return SkyletTheme.statusDelayed
        case .unavailable: return SkyletTheme.statusError
        }
    }

    private func freshnessTextColor(for freshness: RateFreshness) -> Color {
        switch freshness {
        case .stale, .delayed: return SkyletTheme.statusDelayed
        case .unavailable: return SkyletTheme.statusError
        default: return SkyletTheme.tertiaryText
        }
    }

    private var currentSourceCurrency: CurrencyCode {
        isReversed ? .inr : selectedCurrency
    }

    private var currentSourceInfo: CurrencyInfo {
        CurrencyRegistry.info(for: currentSourceCurrency)
    }

    // MARK: - Actions & Calculations

    private func processInput(_ text: String) {
        errorMessage = nil
        let outcome = CurrencyParser.parse(text)
        switch outcome {
        case .empty:
            conversionResult = nil
            detectedAmount = nil
            ambiguousCandidates = []

        case .invalidAmount(let raw):
            errorMessage = "No numerical amount found in: \"\(raw)\""
            conversionResult = nil

        case .multipleAmountsFound(let amounts):
            errorMessage = "Multiple amounts found (\(amounts.map { "\($0)" }.joined(separator: ", "))). Please enter one."
            conversionResult = nil

        case .unambiguous(let amount, let currency, _):
            self.detectedAmount = amount
            self.selectedCurrency = currency
            self.ambiguousCandidates = []
            executeConversion(amount: amount, source: currency)

        case .ambiguous(let amount, _, let candidates, _):
            self.detectedAmount = amount
            self.ambiguousCandidates = candidates
            self.selectedCurrency = candidates.first ?? .usd
            executeConversion(amount: amount, source: selectedCurrency)

        case .amountOnly(let amount, _):
            self.detectedAmount = amount
            self.ambiguousCandidates = CurrencyRegistry.popularCurrencies
            executeConversion(amount: amount, source: selectedCurrency)

        case .unknownCurrency(let amount, let token, _):
            self.detectedAmount = amount
            if let code = CurrencyCode(token) {
                self.selectedCurrency = code
                executeConversion(amount: amount, source: code)
            } else {
                self.ambiguousCandidates = CurrencyRegistry.popularCurrencies
                errorMessage = "Unrecognized currency code: \(token)"
            }

        @unknown default:
            break
        }
    }

    private func executeConversion(amount: Decimal, source: CurrencyCode, forceRefresh: Bool = false) {
        isLoading = true
        errorMessage = nil

        let fromCode = isReversed ? .inr : source
        let toCode = isReversed ? source : CurrencyCode.inr

        Task {
            do {
                let result = try await droplet.rateService.convert(
                    amount: amount,
                    from: fromCode,
                    to: toCode,
                    forceRefresh: forceRefresh
                )
                await MainActor.run {
                    withAnimation(SkyletTheme.standardAnimation) {
                        self.conversionResult = result
                        self.isLoading = false
                        self.droplet.updateLatestConversion(result)
                    }
                }
            } catch {
                await MainActor.run {
                    withAnimation(SkyletTheme.quickAnimation) {
                        self.errorMessage = error.localizedDescription
                        self.isLoading = false
                    }
                }
            }
        }
    }

    private func refreshLiveRate() {
        guard let amt = detectedAmount else { return }
        withAnimation(.linear(duration: 0.6)) {
            refreshRotation += 360
        }
        executeConversion(amount: amt, source: selectedCurrency, forceRefresh: true)
    }

    private func importFromClipboard() {
        guard let clipboardText = NSPasteboard.general.string(forType: .string), !clipboardText.isEmpty else {
            errorMessage = "Clipboard is empty."
            return
        }
        inputText = clipboardText.trimmingCharacters(in: .whitespacesAndNewlines)
        processInput(inputText)
    }

    private func swapCurrencies() {
        isReversed.toggle()
        if let amt = detectedAmount {
            executeConversion(amount: amt, source: selectedCurrency)
        }
    }

    private func copyResult(_ result: CurrencyConversionResult) {
        let copyText = CurrencyFormatter.copyableSummary(
            fromAmount: result.sourceAmount,
            fromCurrency: result.sourceCurrency,
            toAmount: result.targetAmount,
            toCurrency: result.targetCurrency
        )
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(copyText, forType: .string)

        withAnimation(SkyletTheme.quickAnimation) {
            copiedConfirmation = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(SkyletTheme.quickAnimation) {
                copiedConfirmation = false
            }
        }
    }

    private func formatSource(_ result: CurrencyConversionResult) -> String {
        CurrencyFormatter.format(amount: result.sourceAmount, currency: result.sourceCurrency)
    }

    private func formatConverted(_ result: CurrencyConversionResult) -> String {
        CurrencyFormatter.format(amount: result.targetAmount, currency: result.targetCurrency)
    }
}
