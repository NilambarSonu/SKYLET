//
//  FocusTimerView.swift
//  Skylet
//
//  Premium Focus Instrument & Display-Awake Manager
//  Quiet Precision. Instant Intelligence.
//

import SwiftUI
import DroppyKit
import SkyletCore

public struct FocusTimerView: View {
    @ObservedObject var droplet: SkyletDroplet
    let isCompact: Bool

    @State private var selectedPreset: FocusPreset = .thirty
    @State private var customMinutes: String = ""
    @State private var isCustomSelected: Bool = false

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
    }

    // MARK: - Full (Solo) Body

    private var fullBody: some View {
        VStack(alignment: .leading, spacing: DroppySpacing.xs) {
            // Main Countdown, Progress Ring & Controls Row
            HStack(spacing: DroppySpacing.md) {
                // Circular Progress Ring
                progressRing

                // Countdown and Status Labels
                VStack(alignment: .leading, spacing: 2) {
                    Text(displayCountdown)
                        .font(SkyletTheme.countdownFont)
                        .monospacedDigit()
                        .foregroundStyle(SkyletTheme.primaryText)
                        .lineLimit(1)

                    statusSubtitle
                }

                Spacer(minLength: DroppySpacing.sm)

                // Action Controls
                actionButtons
            }
            .padding(.vertical, 2)

            // Duration Presets (shown when idle or completed)
            if !droplet.timerEngine.status.isRunning && !droplet.timerEngine.status.isPaused {
                presetRow
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
    }

    // MARK: - Circular Progress Ring

    private var progressRing: some View {
        ZStack {
            // Track
            Circle()
                .stroke(SkyletTheme.cardFill, lineWidth: 3.5)
                .frame(width: 52, height: 52)

            // Progress Arc
            Circle()
                .trim(from: 0.0, to: CGFloat(currentProgress))
                .stroke(
                    progressColor,
                    style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 52, height: 52)
                .animation(.linear(duration: 0.5), value: currentProgress)

            // Center Symbol
            centerGlyph
        }
    }

    @ViewBuilder
    private var centerGlyph: some View {
        switch droplet.timerEngine.status {
        case .idle:
            Image(systemName: "timer")
                .font(.system(size: 15))
                .foregroundStyle(SkyletTheme.tertiaryText)

        case .running:
            Image(systemName: droplet.timerEngine.isDisplayAwake ? "sun.max.fill" : "timer")
                .font(.system(size: 15))
                .foregroundStyle(SkyletTheme.skyBlue)

        case .paused:
            Image(systemName: "pause.fill")
                .font(.system(size: 13))
                .foregroundStyle(SkyletTheme.statusDelayed)

        case .completed:
            Image(systemName: "checkmark")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(SkyletTheme.statusLive)

        @unknown default:
            EmptyView()
        }
    }

    private var progressColor: Color {
        switch droplet.timerEngine.status {
        case .completed: return SkyletTheme.statusLive
        case .paused: return SkyletTheme.statusDelayed
        default: return SkyletTheme.skyBlue
        }
    }

    // MARK: - Status Subtitle

    @ViewBuilder
    private var statusSubtitle: some View {
        HStack(spacing: 5) {
            switch droplet.timerEngine.status {
            case .idle:
                Image(systemName: "sun.max")
                    .font(.system(size: 9))
                    .foregroundStyle(SkyletTheme.tertiaryText)
                Text("Keeps display awake during session")
                    .font(SkyletTheme.captionFont)
                    .foregroundStyle(SkyletTheme.tertiaryText)

            case .running:
                Circle()
                    .fill(SkyletTheme.skyBlue)
                    .frame(width: 5, height: 5)
                Text("Display awake")
                    .font(SkyletTheme.captionFont)
                    .foregroundStyle(SkyletTheme.skyBlue)

            case .paused:
                Circle()
                    .fill(SkyletTheme.statusDelayed)
                    .frame(width: 5, height: 5)
                Text("Session paused")
                    .font(SkyletTheme.captionFont)
                    .foregroundStyle(SkyletTheme.statusDelayed)

            case .completed:
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(SkyletTheme.statusLive)
                Text("Session completed")
                    .font(SkyletTheme.captionFont)
                    .foregroundStyle(SkyletTheme.statusLive)

            @unknown default:
                EmptyView()
            }
        }
    }

    // MARK: - Duration Presets Row

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
                        .background((!isCustomSelected && selectedPreset == preset) ? SkyletTheme.skyBlue.opacity(0.22) : SkyletTheme.controlBackground)
                        .foregroundStyle((!isCustomSelected && selectedPreset == preset) ? SkyletTheme.skyBlue : SkyletTheme.primaryText)
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
            .background(isCustomSelected ? SkyletTheme.skyBlue.opacity(0.22) : SkyletTheme.controlBackground)
            .clipShape(RoundedRectangle(cornerRadius: DroppyRadius.xs, style: .continuous))
        }
        .padding(.top, 2)
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private var actionButtons: some View {
        switch droplet.timerEngine.status {
        case .idle:
            Button {
                withAnimation(SkyletTheme.standardAnimation) {
                    startSelectedSession()
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 9))
                    Text("Start")
                        .font(SkyletTheme.buttonFont)
                }
                .foregroundStyle(Color.black)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(SkyletTheme.skyBlue)
                .clipShape(RoundedRectangle(cornerRadius: DroppyRadius.sm, style: .continuous))
            }
            .buttonStyle(.plain)
            .help("Start focus session and keep display awake")

        case .running:
            HStack(spacing: DroppySpacing.xs) {
                Button {
                    withAnimation(SkyletTheme.quickAnimation) {
                        droplet.timerEngine.pause()
                    }
                } label: {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(SkyletTheme.primaryText)
                        .padding(7)
                        .background(SkyletTheme.controlBackground)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Pause timer (releases display-awake assertion)")

                Button {
                    withAnimation(SkyletTheme.quickAnimation) {
                        droplet.timerEngine.stop()
                    }
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(SkyletTheme.statusError)
                        .padding(7)
                        .background(SkyletTheme.controlBackground)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Stop timer and cancel session")
            }

        case .paused:
            HStack(spacing: DroppySpacing.xs) {
                Button {
                    withAnimation(SkyletTheme.quickAnimation) {
                        droplet.timerEngine.resume()
                    }
                } label: {
                    Image(systemName: "play.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(SkyletTheme.skyBlue)
                        .padding(7)
                        .background(SkyletTheme.skyBlue.opacity(0.18))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Resume timer (re-acquires display-awake assertion)")

                Button {
                    withAnimation(SkyletTheme.quickAnimation) {
                        droplet.timerEngine.stop()
                    }
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(SkyletTheme.statusError)
                        .padding(7)
                        .background(SkyletTheme.controlBackground)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Cancel timer")
            }

        case .completed:
            Button {
                withAnimation(SkyletTheme.standardAnimation) {
                    droplet.timerEngine.reset()
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 9))
                    Text("New Session")
                        .font(SkyletTheme.buttonFont)
                }
                .foregroundStyle(SkyletTheme.primaryText)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(SkyletTheme.controlBackground)
                .clipShape(RoundedRectangle(cornerRadius: DroppyRadius.sm, style: .continuous))
            }
            .buttonStyle(.plain)

        @unknown default:
            EmptyView()
        }
    }

    // MARK: - Compact (Paired) Body

    private var compactBody: some View {
        HStack(spacing: DroppySpacing.sm) {
            VStack(alignment: .leading, spacing: 1) {
                Text(displayCountdown)
                    .font(SkyletTheme.smallCountdownFont)
                    .monospacedDigit()
                    .foregroundStyle(SkyletTheme.primaryText)

                if droplet.timerEngine.isDisplayAwake {
                    HStack(spacing: 3) {
                        Circle()
                            .fill(SkyletTheme.skyBlue)
                            .frame(width: 4, height: 4)
                        Text("Awake")
                            .font(SkyletTheme.captionFont)
                            .foregroundStyle(SkyletTheme.skyBlue)
                    }
                } else if droplet.timerEngine.status.isPaused {
                    Text("Paused")
                        .font(SkyletTheme.captionFont)
                        .foregroundStyle(SkyletTheme.statusDelayed)
                }
            }

            Spacer(minLength: 0)

            Button {
                withAnimation(SkyletTheme.quickAnimation) {
                    toggleTimer()
                }
            } label: {
                Image(systemName: droplet.timerEngine.status.isRunning ? "pause.fill" : "play.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(droplet.timerEngine.status.isRunning ? SkyletTheme.statusDelayed : SkyletTheme.skyBlue)
                    .padding(6)
                    .background(SkyletTheme.controlBackground)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Helpers

    private var displayCountdown: String {
        switch droplet.timerEngine.status {
        case .idle:
            let seconds = durationForStart()
            return FocusTimerEngine.formatCountdown(seconds)
        case .running(_, let remaining, _), .paused(_, let remaining, _):
            return FocusTimerEngine.formatCountdown(remaining)
        case .completed:
            return "00:00"
        @unknown default:
            return "00:00"
        }
    }

    private var currentProgress: Double {
        switch droplet.timerEngine.status {
        case .idle: return 0.0
        case .running(_, _, let progress), .paused(_, _, let progress): return progress
        case .completed: return 1.0
        @unknown default: return 0.0
        }
    }

    private func durationForStart() -> TimeInterval {
        if isCustomSelected, let mins = Double(customMinutes), mins > 0 {
            return mins * 60
        }
        return selectedPreset.durationSeconds
    }

    private func startSelectedSession() {
        let duration = durationForStart()
        droplet.timerEngine.start(duration: duration)
    }

    private func toggleTimer() {
        switch droplet.timerEngine.status {
        case .idle, .completed:
            startSelectedSession()
        case .running:
            droplet.timerEngine.pause()
        case .paused:
            droplet.timerEngine.resume()
        @unknown default:
            break
        }
    }
}
