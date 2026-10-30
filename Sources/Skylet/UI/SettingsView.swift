//
//  SettingsView.swift
//  Skylet
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
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                Label("Twelve Data Forex API", systemImage: "key.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(SkyletTheme.skyBlue)
                Spacer()
                if hasStoredKey {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                        Text("Configured in Keychain")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Text("Enter your Twelve Data API key to enable live, real-time USD/INR and global forex quotes. Your key is stored securely in macOS Keychain and never leaves your Mac.")
                .font(.system(size: 11))
                .foregroundStyle(SkyletTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            // API Key Input Row
            HStack(spacing: 8) {
                Group {
                    if isRevealed {
                        TextField("Twelve Data API Key", text: $apiKeyInput)
                    } else {
                        SecureField("Twelve Data API Key", text: $apiKeyInput)
                    }
                }
                .textFieldStyle(.plain)
                .font(.system(size: 12, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(SkyletTheme.cardFill)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )

                // Toggle mask
                Button {
                    isRevealed.toggle()
                } label: {
                    Image(systemName: isRevealed ? "eye.slash" : "eye")
                        .font(.system(size: 11))
                        .foregroundStyle(SkyletTheme.secondaryText)
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
                }
                .buttonStyle(.plain)
                .help("Paste key from clipboard")
            }

            // Action Buttons
            HStack(spacing: 8) {
                // Save Button
                Button {
                    saveKey()
                } label: {
                    Text("Save Key")
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(SkyletTheme.skyBlue)
                        .foregroundStyle(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
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
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.1))
                    .foregroundStyle(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(isTesting || (apiKeyInput.isEmpty && !hasStoredKey))

                // Remove Button
                if hasStoredKey {
                    Button {
                        removeKey()
                    } label: {
                        Text("Remove")
                            .font(.system(size: 11, weight: .medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color.red.opacity(0.15))
                            .foregroundStyle(Color.red.opacity(0.9))
                            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }

            // Test Feedback / Status
            if let result = testResult {
                switch result {
                case .success(let rate, let timestamp, let latency):
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.green)
                        Text("Connected: 1 USD = ₹\(rate) · \(timestamp) (\(latency)ms)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.green)
                    }
                    .padding(6)
                    .background(Color.green.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                case .failure(let errorMsg):
                    HStack(spacing: 6) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.red)
                        Text(errorMsg)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.red)
                            .lineLimit(2)
                    }
                    .padding(6)
                    .background(Color.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
            } else if let msg = statusMessage {
                Text(msg)
                    .font(.system(size: 11))
                    .foregroundStyle(SkyletTheme.skyBlue)
            }

            // Free Plan Quota Note
            HStack(spacing: 4) {
                Image(systemName: "info.circle")
                    .font(.system(size: 10))
                Text("Free Basic Plan: 8 credits/min, 800 req/day. Skylet automatically caches queries for 5 minutes.")
                    .font(.system(size: 10))
            }
            .foregroundStyle(SkyletTheme.tertiaryText)
        }
        .padding(12)
        .background(SkyletTheme.midnightSurface)
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
            // Temporary in-memory keychain for testing
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
