//
//  FocusTimerView.swift
//  Skylet
//
//  Redesigned Solar Focus Instrument & Display-Awake Manager
//  Quiet Precision. Instant Intelligence.
//

import SwiftUI
import DroppyKit
import SkyletCore

public struct FocusTimerView: View {
    @ObservedObject var droplet: SkyletDroplet
    @ObservedObject var timerEngine: FocusTimerEngine
    let isCompact: Bool

    @State private var selectedPreset: FocusPreset = .thirty
    @State private var customMinutes: String = ""
    @State private var isCustomSelected: Bool = false

    public init(droplet: SkyletDroplet, isCompact: Bool) {
        self.droplet = droplet
        self.timerEngine = droplet.timerEngine
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
    }

    // MARK: - Full (Solo) Body

    private var fullBody: some View {
        VStack(alignment: .leading, spacing: DroppySpacing.xs) {
            // Hero Solar Row: Animated Sun, Status Info, & Action Controls
            HStack(spacing: DroppySpacing.md) {
                // The Animated Sun (Primary Visual Timer Instrument)
                SolarSunView(
                    status: timerEngine.status,
                    diameter: 68,
                    showAura: true
                )

                // Session Status & Secondary Duration Information
                VStack(alignment: .leading, spacing: 3) {
                    // Status Badge (READY, FOCUSING, PAUSED, COMPLETED)
                    statusBadge

                    // Secondary Session Progress / Duration (Calm, Not Overpowering)
                    secondarySessionInfo

                    // Display-Awake Notice
                    displayAwakeNotice
                }

                Spacer(minLength: DroppySpacing.sm)

                // Action Controls (Start Focus / Pause / Resume / Start Again + Reset)
                actionButtonsGroup
            }
            .padding(.vertical, 2)

            // Duration Presets (available when idle or completed)
            if !timerEngine.status.isRunning && !timerEngine.status.isPaused {
                presetRow
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                activeSessionFooter
                    .transition(.opacity)
            }
        }
    }

    // MARK: - Status Badge

    @ViewBuilder
    private var statusBadge: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(statusIndicatorColor)
                .frame(width: 6, height: 6)

            Text(statusBadgeTitle)
                .font(SkyletTheme.statusBadgeFont)
                .foregroundStyle(statusIndicatorColor)
                .tracking(0.8)
        }
    }

    private var statusBadgeTitle: String {
        switch timerEngine.status {
        case .idle:
            return "READY"
        case .running:
            return "FOCUSING"
        case .paused:
            return "PAUSED"
        case .completed:
            return "COMPLETED"
        @unknown default:
            return "FOCUS"
        }
    }

    private var statusIndicatorColor: Color {
        switch timerEngine.status {
        case .idle:
            return SkyletTheme.solarGold
        case .running:
            return SkyletTheme.solarGold
        case .paused:
            return SkyletTheme.statusDelayed
        case .completed:
            return SkyletTheme.statusLive
        @unknown default:
            return SkyletTheme.tertiaryText
        }
    }

    // MARK: - Secondary Session Info (Calm & Non-Dominant)

    @ViewBuilder
    private var secondarySessionInfo: some View {
        switch timerEngine.status {
        case .idle:
            Text("\(Int(durationForStart() / 60)) min focus session")
                .font(SkyletTheme.sessionSubtitleFont)
                .foregroundStyle(SkyletTheme.primaryText)

        case .running(_, let remaining, _):
            HStack(spacing: 4) {
                Text(FocusTimerEngine.formatCountdown(remaining))
                    .font(SkyletTheme.sessionSubtitleFont)
                    .monospacedDigit()
                    .foregroundStyle(SkyletTheme.primaryText)
                Text("remaining")
                    .font(SkyletTheme.captionFont)
                    .foregroundStyle(SkyletTheme.secondaryText)
            }

        case .paused(_, let remaining, _):
            HStack(spacing: 4) {
                Text(FocusTimerEngine.formatCountdown(remaining))
                    .font(SkyletTheme.sessionSubtitleFont)
                    .monospacedDigit()
                    .foregroundStyle(SkyletTheme.statusDelayed)
                Text("paused")
                    .font(SkyletTheme.captionFont)
                    .foregroundStyle(SkyletTheme.statusDelayed)
            }

        case .completed(let total):
            Text("\(Int(total / 60)) min session finished")
                .font(SkyletTheme.sessionSubtitleFont)
                .foregroundStyle(SkyletTheme.statusLive)

        @unknown default:
            EmptyView()
        }
    }

    // MARK: - Display-Awake Notice

    @ViewBuilder
    private var displayAwakeNotice: some View {
        HStack(spacing: 4) {
            Image(systemName: timerEngine.isDisplayAwake ? "sun.max.fill" : "sun.max")
                .font(.system(size: 9))
                .foregroundStyle(timerEngine.isDisplayAwake ? SkyletTheme.solarGold : SkyletTheme.tertiaryText)

            Text(timerEngine.isDisplayAwake ? "Display kept awake" : "Keeps display awake during focus")
                .font(SkyletTheme.captionFont)
                .foregroundStyle(timerEngine.isDisplayAwake ? SkyletTheme.solarGold.opacity(0.9) : SkyletTheme.tertiaryText)
                .lineLimit(1)
        }
    }

    // MARK: - Action Buttons Group

    private var actionButtonsGroup: some View {
        HStack(spacing: DroppySpacing.xs) {
            // Secondary Reset Button (shown only during active or paused session)
            if timerEngine.status.isRunning || timerEngine.status.isPaused {
                Button {
                    withAnimation(SkyletTheme.quickAnimation) {
                        timerEngine.reset()
                    }
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(SkyletTheme.secondaryText)
                        .padding(7)
                        .background(SkyletTheme.controlBackground)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Reset session to idle")
                .accessibilityLabel("Reset focus timer")
            }

            // Primary Action Button
            primaryActionButton
        }
    }

    @ViewBuilder
    private var primaryActionButton: some View {
        switch timerEngine.status {
        case .idle:
            Button {
                withAnimation(SkyletTheme.standardAnimation) {
                    startSelectedSession()
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 9, weight: .bold))
                    Text("Start Focus")
                        .font(SkyletTheme.buttonFont)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(Color.black)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(SkyletTheme.solarGold)
                .clipShape(RoundedRectangle(cornerRadius: DroppyRadius.sm, style: .continuous))
                .shadow(color: SkyletTheme.solarGold.opacity(0.25), radius: 3, x: 0, y: 1)
            }
            .buttonStyle(.plain)
            .help("Start focus session and keep display awake")
            .accessibilityLabel("Start Focus session")

        case .running:
            Button {
                withAnimation(SkyletTheme.quickAnimation) {
                    timerEngine.pause()
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 9, weight: .bold))
                    Text("Pause")
                        .font(SkyletTheme.buttonFont)
                }
                .foregroundStyle(SkyletTheme.primaryText)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(SkyletTheme.controlBackground)
                .clipShape(RoundedRectangle(cornerRadius: DroppyRadius.sm, style: .continuous))
            }
            .buttonStyle(.plain)
            .help("Pause timer (releases display-awake assertion)")
            .accessibilityLabel("Pause focus timer")

        case .paused:
            Button {
                withAnimation(SkyletTheme.quickAnimation) {
                    timerEngine.resume()
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 9, weight: .bold))
                    Text("Resume")
                        .font(SkyletTheme.buttonFont)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(Color.black)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(SkyletTheme.solarGold)
                .clipShape(RoundedRectangle(cornerRadius: DroppyRadius.sm, style: .continuous))
            }
            .buttonStyle(.plain)
            .help("Resume timer (re-acquires display-awake assertion)")
            .accessibilityLabel("Resume focus timer")

        case .completed:
            Button {
                withAnimation(SkyletTheme.standardAnimation) {
                    startSelectedSession()
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 9, weight: .bold))
                    Text("Start Again")
                        .font(SkyletTheme.buttonFont)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(Color.black)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(SkyletTheme.statusLive)
                .clipShape(RoundedRectangle(cornerRadius: DroppyRadius.sm, style: .continuous))
            }
            .buttonStyle(.plain)
            .help("Start another focus session")
            .accessibilityLabel("Start Again")

        @unknown default:
            EmptyView()
        }
    }

    // MARK: - Presets Row

    private var presetRow: some View {
        HStack(spacing: DroppySpacing.xs) {
            ForEach(FocusPreset.allCases) { preset in
                Button {
                    withAnimation(SkyletTheme.quickAnimation) {
                        isCustomSelected = false
                        selectedPreset = preset
                    }
                } label: {
                    Text(preset.title)
                        .font(SkyletTheme.compactButtonFont)
                        .padding(.horizontal, DroppySpacing.sm)
                        .padding(.vertical, 3)
                        .background((!isCustomSelected && selectedPreset == preset) ? SkyletTheme.solarGold.opacity(0.25) : SkyletTheme.controlBackground)
                        .foregroundStyle((!isCustomSelected && selectedPreset == preset) ? SkyletTheme.solarGold : SkyletTheme.primaryText)
                        .clipShape(RoundedRectangle(cornerRadius: DroppyRadius.xs, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            // Custom Duration Field
            HStack(spacing: 2) {
                TextField("Custom", text: $customMinutes)
                    .textFieldStyle(.plain)
                    .font(SkyletTheme.compactButtonFont)
                    .frame(width: 28)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(SkyletTheme.primaryText)
                    .onChange(of: customMinutes) { _, newVal in
                        if !newVal.isEmpty {
                            isCustomSelected = true
                        }
                    }

                Text("m")
                    .font(SkyletTheme.captionFont)
                    .foregroundStyle(SkyletTheme.tertiaryText)
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 3)
            .background(isCustomSelected ? SkyletTheme.solarGold.opacity(0.25) : SkyletTheme.controlBackground)
            .clipShape(RoundedRectangle(cornerRadius: DroppyRadius.xs, style: .continuous))
        }
        .padding(.top, 2)
    }

    // MARK: - Active Session Footer

    private var activeSessionFooter: some View {
        HStack(spacing: DroppySpacing.xs) {
            // Subtle session details
            Text("Focus Session Active")
                .font(SkyletTheme.captionFont)
                .foregroundStyle(SkyletTheme.secondaryText)

            Spacer()

            // Reset shortcut hint
            Text("Click reset to stop early")
                .font(SkyletTheme.captionFont)
                .foregroundStyle(SkyletTheme.tertiaryText)
        }
        .padding(.top, 2)
    }

    // MARK: - Compact (Paired) Body

    private var compactBody: some View {
        HStack(spacing: DroppySpacing.sm) {
            // Mini Animated Sun
            SolarSunView(
                status: timerEngine.status,
                diameter: 38,
                showAura: false
            )

            VStack(alignment: .leading, spacing: 1) {
                Text(statusBadgeTitle)
                    .font(SkyletTheme.statusBadgeFont)
                    .foregroundStyle(statusIndicatorColor)

                Text(compactTimeText)
                    .font(SkyletTheme.smallCountdownFont)
                    .monospacedDigit()
                    .foregroundStyle(SkyletTheme.primaryText)
            }

            Spacer(minLength: 0)

            Button {
                withAnimation(SkyletTheme.quickAnimation) {
                    toggleTimer()
                }
            } label: {
                Image(systemName: compactToggleIcon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(timerEngine.status.isRunning ? SkyletTheme.primaryText : Color.black)
                    .padding(6)
                    .background(timerEngine.status.isRunning ? SkyletTheme.controlBackground : SkyletTheme.solarGold)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(statusBadgeTitle)
        }
    }

    private var compactTimeText: String {
        switch timerEngine.status {
        case .idle:
            return FocusTimerEngine.formatCountdown(durationForStart())
        case .running(_, let remaining, _), .paused(_, let remaining, _):
            return FocusTimerEngine.formatCountdown(remaining)
        case .completed:
            return "Done"
        @unknown default:
            return "00:00"
        }
    }

    private var compactToggleIcon: String {
        switch timerEngine.status {
        case .idle:
            return "play.fill"
        case .running:
            return "pause.fill"
        case .paused:
            return "play.fill"
        case .completed:
            return "arrow.clockwise"
        @unknown default:
            return "play.fill"
        }
    }

    // MARK: - Helpers

    private func durationForStart() -> TimeInterval {
        if isCustomSelected, let mins = Double(customMinutes), mins > 0 {
            return mins * 60
        }
        return selectedPreset.durationSeconds
    }

    private func startSelectedSession() {
        let duration = durationForStart()
        timerEngine.start(duration: duration)
    }

    private func toggleTimer() {
        switch timerEngine.status {
        case .idle, .completed:
            startSelectedSession()
        case .running:
            timerEngine.pause()
        case .paused:
            timerEngine.resume()
        @unknown default:
            break
        }
    }
}
