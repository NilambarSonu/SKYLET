//
//  SettingsView.swift
//  Skylet
//
//  Twelve Data Forex API & Keychain Configuration View
//  Quiet Precision. Instant Intelligence.
//

import SwiftUI
import DroppyKit
import SkyletCore

public struct SettingsView: View {
    @ObservedObject var droplet: SkyletDroplet

    @State private var apiKeyInput: String = ""
    @State private var isRevealed: Bool = false
    @State private var hasStoredKey: Bool = false
    @State private var isTesting: Bool = false
    @State private var testResult: TestResult? = nil
    @State private var statusMessage: String? = nil

    private enum TestResult {
        case success(rate: Decimal, timestamp: String, latencyMs: Int)
        case failure(message: String)
    }

    public init(droplet: SkyletDroplet) {
        self.droplet = droplet
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: DroppySpacing.sm) {
            // Header
            HStack {
                Label("Twelve Data Forex API", systemImage: "key.fill")
                    .font(SkyletTheme.headerFont)
                    .foregroundStyle(SkyletTheme.skyBlue)
                Spacer()
                if hasStoredKey {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(SkyletTheme.statusLive)
                            .frame(width: 5, height: 5)
                        Text("Configured in Keychain")
                            .font(SkyletTheme.captionFont)
                            .foregroundStyle(SkyletTheme.secondaryText)
                    }
                }
            }

            Text("Enter your Twelve Data API key to enable live, real-time USD/INR and global forex quotes. Your key is stored securely in macOS Keychain and never leaves your Mac.")
                .font(SkyletTheme.captionFont)
                .foregroundStyle(SkyletTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            // API Key Input Row
            HStack(spacing: DroppySpacing.xs) {
                Group {
                    if isRevealed {
                        TextField("Twelve Data API Key", text: $apiKeyInput)
                    } else {
                        SecureField("Twelve Data API Key", text: $apiKeyInput)
                    }
                }
                .textFieldStyle(.plain)
                .font(.system(size: 11, design: .monospaced))
                .padding(.horizontal, DroppySpacing.sm)
                .padding(.vertical, 5)
                .background(SkyletTheme.controlBackground)
                .clipShape(RoundedRectangle(cornerRadius: DroppyRadius.sm, style: .continuous))

                // Toggle mask
                Button {
                    isRevealed.toggle()
                } label: {
                    Image(systemName: isRevealed ? "eye.slash" : "eye")
                        .font(.system(size: 11))
                        .foregroundStyle(SkyletTheme.tertiaryText)
                        .padding(5)
                        .background(SkyletTheme.controlBackground)
                        .clipShape(RoundedRectangle(cornerRadius: DroppyRadius.xs, style: .continuous))
                }
                .buttonStyle(.plain)
                .help(isRevealed ? "Hide key" : "Show key")

                // Paste button
                Button {
                    if let text = NSPasteboard.general.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines),
                       !text.isEmpty {
                        apiKeyInput = text
                    }
                } label: {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 11))
                        .foregroundStyle(SkyletTheme.skyBlue)
                        .padding(5)
                        .background(SkyletTheme.controlBackground)
                        .clipShape(RoundedRectangle(cornerRadius: DroppyRadius.xs, style: .continuous))
                }
                .buttonStyle(.plain)
                .help("Paste key from clipboard")
            }

            // Action Buttons
            HStack(spacing: DroppySpacing.xs) {
                // Save Button
                Button {
                    saveKey()
                } label: {
                    Text("Save Key")
                        .font(SkyletTheme.compactButtonFont)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(SkyletTheme.skyBlue)
                        .foregroundStyle(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: DroppyRadius.xs, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                // Test Connection Button
                Button {
                    testConnection()
                } label: {
                    HStack(spacing: 4) {
                        if isTesting {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "network")
                        }
                        Text("Test Connection")
                    }
                    .font(SkyletTheme.compactButtonFont)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(SkyletTheme.controlBackground)
                    .foregroundStyle(SkyletTheme.primaryText)
                    .clipShape(RoundedRectangle(cornerRadius: DroppyRadius.xs, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(isTesting || (apiKeyInput.isEmpty && !hasStoredKey))

                // Remove Button
                if hasStoredKey {
                    Button {
                        removeKey()
                    } label: {
                        Text("Remove")
                            .font(SkyletTheme.compactButtonFont)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(SkyletTheme.statusError.opacity(0.18))
                            .foregroundStyle(SkyletTheme.statusError)
                            .clipShape(RoundedRectangle(cornerRadius: DroppyRadius.xs, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }

            // Test Feedback / Status
            if let result = testResult {
                switch result {
                case .success(let rate, let timestamp, let latency):
                    HStack(spacing: 5) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(SkyletTheme.statusLive)
                        Text("Connected: 1 USD = ₹\(rate) · \(timestamp) (\(latency)ms)")
                            .font(SkyletTheme.captionFont)
                            .foregroundStyle(SkyletTheme.statusLive)
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(SkyletTheme.statusLive.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: DroppyRadius.xs, style: .continuous))

                case .failure(let errorMsg):
                    HStack(spacing: 5) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(SkyletTheme.statusError)
                        Text(errorMsg)
                            .font(SkyletTheme.captionFont)
                            .foregroundStyle(SkyletTheme.statusError)
                            .lineLimit(2)
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(SkyletTheme.statusError.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: DroppyRadius.xs, style: .continuous))
                }
            } else if let msg = statusMessage {
                Text(msg)
                    .font(SkyletTheme.captionFont)
                    .foregroundStyle(SkyletTheme.skyBlue)
            }

            // Free Plan Quota Note
            HStack(spacing: 4) {
                Image(systemName: "info.circle")
                    .font(.system(size: 9))
                Text("Free Basic Plan: 8 credits/min, 800 req/day. Skylet automatically caches queries for 5 minutes.")
                    .font(SkyletTheme.captionFont)
            }
            .foregroundStyle(SkyletTheme.tertiaryText)
        }
        .padding(DroppySpacing.sm)
        .onAppear {
            loadExistingKeyStatus()
        }
    }

    private func loadExistingKeyStatus() {
        if let stored = droplet.keychain.get(key: "twelvedata_api_key"), !stored.isEmpty {
            hasStoredKey = true
            apiKeyInput = stored
        } else {
            hasStoredKey = false
        }
    }

    private func saveKey() {
        let trimmed = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        do {
            try droplet.keychain.save(key: "twelvedata_api_key", value: trimmed)
            hasStoredKey = true
            statusMessage = "Key saved securely to macOS Keychain."
            testResult = nil
        } catch {
            statusMessage = "Failed to save: \(error.localizedDescription)"
        }
    }

    private func removeKey() {
        do {
            try droplet.keychain.delete(key: "twelvedata_api_key")
            hasStoredKey = false
            apiKeyInput = ""
            statusMessage = "Key removed from Keychain. Fallback reference rates will be used."
            testResult = nil
        } catch {
            statusMessage = "Failed to remove: \(error.localizedDescription)"
        }
    }

    private func testConnection() {
        isTesting = true
        testResult = nil
        statusMessage = nil

        let testKey = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? (droplet.keychain.get(key: "twelvedata_api_key") ?? "")
            : apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !testKey.isEmpty else {
            isTesting = false
            testResult = .failure(message: "No API key provided to test.")
            return
        }

        let startTime = DispatchTime.now()

        Task {
            let tempKeychain = InMemoryKeychainManager(initialItems: ["twelvedata_api_key": testKey])
            let provider = TwelveDataRateProvider(keychain: tempKeychain)

            do {
                let entry = try await provider.fetchRate(from: .usd, to: .inr)
                let endTime = DispatchTime.now()
                let nanoTime = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
                let latencyMs = Int(nanoTime / 1_000_000)

                await MainActor.run {
                    self.isTesting = false
                    self.testResult = .success(
                        rate: entry.rate,
                        timestamp: entry.providerDateString,
                        latencyMs: latencyMs
                    )
                }
            } catch {
                await MainActor.run {
                    self.isTesting = false
                    self.testResult = .failure(message: error.localizedDescription)
                }
            }
        }
    }
}
