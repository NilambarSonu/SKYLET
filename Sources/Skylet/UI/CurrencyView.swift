//
//  CurrencyView.swift
//  Skylet
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

    public init(droplet: SkyletDroplet, isCompact: Bool) {
        self.droplet = droplet
        self.isCompact = isCompact
    }

    public var body: some View {
        if isCompact {
            compactBody
        } else {
            fullBody
        }
    }

    // MARK: - Full (Solo) Body

    private var fullBody: some View {
        VStack(alignment: .leading, spacing: DroppySpacing.xs) {
            // Input and Clipboard bar
            HStack(spacing: DroppySpacing.xs) {
                HStack(spacing: 4) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 11))
                        .foregroundStyle(SkyletTheme.secondaryText)
                    TextField("Enter amount (e.g. $25, €49.99, 100 USD)", text: $inputText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                        .foregroundStyle(SkyletTheme.primaryText)
                        .onSubmit {
                            processInput(inputText)
                        }
                    if !inputText.isEmpty {
                        Button {
                            inputText = ""
                            conversionResult = nil
                            errorMessage = nil
                            ambiguousCandidates = []
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(SkyletTheme.secondaryText)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(SkyletTheme.cardFill)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                // Explicit clipboard import button
                Button {
                    importFromClipboard()
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "doc.on.clipboard")
                            .font(.system(size: 10))
                        Text("Paste")
                            .font(SkyletTheme.buttonFont)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(SkyletTheme.cardFill)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                .buttonStyle(.plain)
                .help("Convert amount currently on the clipboard")
            }

            // Ambiguous candidate selector (if user entered $25, ¥5000, or bare number)
            if !ambiguousCandidates.isEmpty {
                HStack(spacing: 4) {
                    Text("Select currency:")
                        .font(SkyletTheme.captionFont)
                        .foregroundStyle(SkyletTheme.secondaryText)
                    ForEach(ambiguousCandidates.prefix(5), id: \.self) { code in
                        Button {
                            selectedCurrency = code
                            ambiguousCandidates = []
                            if let amt = detectedAmount {
                                executeConversion(amount: amt, source: code)
                            }
                        } label: {
                            Text(code.rawValue)
                                .font(.system(size: 10, weight: selectedCurrency == code ? .bold : .regular))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(selectedCurrency == code ? SkyletTheme.skyBlue.opacity(0.25) : SkyletTheme.cardFill)
                                .foregroundStyle(selectedCurrency == code ? SkyletTheme.skyBlue : SkyletTheme.primaryText)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }

            // Conversion result display
            if isLoading {
                HStack(spacing: 6) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Fetching exchange rate…")
                        .font(SkyletTheme.subheadFont)
                        .foregroundStyle(SkyletTheme.secondaryText)
                }
                .padding(.vertical, 6)
            } else if let result = conversionResult {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        // Converted amount
                        Text(formatConverted(result))
                            .font(SkyletTheme.valueFont)
                            .monospacedDigit()
                            .foregroundStyle(SkyletTheme.skyBlue)

                        // Source amount
                        Text("(\(formatSource(result)))")
                            .font(SkyletTheme.subheadFont)
                            .foregroundStyle(SkyletTheme.secondaryText)

                        Spacer(minLength: DroppySpacing.md)

                        // Copy button
                        Button {
                            copyResult(result)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: copiedConfirmation ? "checkmark" : "doc.on.doc")
                                    .font(.system(size: 10))
                                Text(copiedConfirmation ? "Copied" : "Copy")
                                    .font(SkyletTheme.buttonFont)
                            }
                            .foregroundStyle(copiedConfirmation ? Color.green : SkyletTheme.primaryText)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(SkyletTheme.cardFill)
                            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                        }
                        .buttonStyle(.plain)

                        // Reverse / Swap currencies button
                        Button {
                            swapCurrencies()
                        } label: {
                            Image(systemName: "arrow.left.arrow.right")
                                .font(.system(size: 10))
                                .foregroundStyle(SkyletTheme.secondaryText)
                                .padding(5)
                                .background(SkyletTheme.cardFill)
                                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .help("Swap source and target currencies")
                    }

                    // Exchange rate line, provider timestamp and live refresh button
                    HStack(spacing: 6) {
                        Text(CurrencyFormatter.formatRate(from: result.sourceCurrency, to: result.targetCurrency, rate: result.rate))
                            .font(SkyletTheme.captionFont)
                            .monospacedDigit()
                            .foregroundStyle(SkyletTheme.secondaryText)

                        Text("•")
                            .font(SkyletTheme.captionFont)
                            .foregroundStyle(SkyletTheme.tertiaryText)

                        if result.isStale {
                            Text("Offline · Cached (\(result.rateDateString))")
                                .font(SkyletTheme.captionFont)
                                .foregroundStyle(Color.orange)
                        } else {
                            Text("\(result.providerName) · \(result.rateDateString)")
                                .font(SkyletTheme.captionFont)
                                .foregroundStyle(SkyletTheme.tertiaryText)
                        }

                        Button {
                            if let amt = detectedAmount {
                                executeConversion(amount: amt, source: selectedCurrency, forceRefresh: true)
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(SkyletTheme.skyBlue)
                        }
                        .buttonStyle(.plain)
                        .help("Fetch live exchange rate from network")
                    }
                }
                .padding(.top, 2)
            } else if let error = errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.orange)
                        .font(.system(size: 11))
                    Text(error)
                        .font(SkyletTheme.captionFont)
                        .foregroundStyle(SkyletTheme.secondaryText)
                    Spacer()
                    Button("Retry") {
                        if let amt = detectedAmount {
                            executeConversion(amount: amt, source: selectedCurrency)
                        }
                    }
                    .font(SkyletTheme.captionFont)
                    .foregroundStyle(SkyletTheme.skyBlue)
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 4)
            } else {
                // Empty state hints
                HStack(spacing: 8) {
                    Text("Quick try:")
                        .font(SkyletTheme.captionFont)
                        .foregroundStyle(SkyletTheme.tertiaryText)
                    ForEach(["$25", "€49.99", "100 USD", "5000 yen"], id: \.self) { sample in
                        Button(sample) {
                            inputText = sample
                            processInput(sample)
                        }
                        .font(SkyletTheme.captionFont)
                        .foregroundStyle(SkyletTheme.skyBlue)
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Compact (Paired) Body

    private var compactBody: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let result = conversionResult {
                Text(formatConverted(result))
                    .font(SkyletTheme.valueFont)
                    .monospacedDigit()
                    .foregroundStyle(SkyletTheme.skyBlue)
                    .lineLimit(1)
                Text(formatSource(result))
                    .font(SkyletTheme.captionFont)
                    .foregroundStyle(SkyletTheme.secondaryText)
                    .lineLimit(1)
            } else {
                Button {
                    importFromClipboard()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.clipboard")
                        Text("Paste amount")
                    }
                    .font(SkyletTheme.buttonFont)
                    .foregroundStyle(SkyletTheme.skyBlue)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Helpers

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
                    self.conversionResult = result
                    self.isLoading = false
                    self.droplet.updateLatestConversion(result)
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
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

        copiedConfirmation = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            copiedConfirmation = false
        }
    }

    private func formatSource(_ result: CurrencyConversionResult) -> String {
        CurrencyFormatter.format(amount: result.sourceAmount, currency: result.sourceCurrency)
    }

    private func formatConverted(_ result: CurrencyConversionResult) -> String {
        CurrencyFormatter.format(amount: result.targetAmount, currency: result.targetCurrency)
    }
}

