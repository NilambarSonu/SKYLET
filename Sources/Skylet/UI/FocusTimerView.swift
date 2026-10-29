//
//  FocusTimerView.swift
//  Skylet
//

import SwiftUI
import DroppyKit
import SkyletCore

public struct FocusTimerView: View {
    @ObservedObject var droplet: SkyletDroplet
    let isCompact: Bool

    @State private var selectedPreset: FocusPreset = .twentyFiveOrThirty
    @State private var customMinutes: String = ""
    @State private var isCustomSelected: Bool = false

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
        VStack(spacing: DroppySpacing.xs) {
            // Main countdown row and progress visual
            HStack(spacing: DroppySpacing.md) {
                // Circular Progress Ring
                ZStack {
                    Circle()
                        .stroke(SkyletTheme.cardFill, lineWidth: 4)
                        .frame(width: 54, height: 54)

                    Circle()
                        .trim(from: 0.0, to: CGFloat(currentProgress))
                        .stroke(
                            SkyletTheme.skyBlue,
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 54, height: 54)
                        .animation(.linear(duration: 0.5), value: currentProgress)

                    Image(systemName: droplet.timerEngine.isDisplayAwake ? "sun.max.fill" : "timer")
                        .font(.system(size: 16))
                        .foregroundStyle(droplet.timerEngine.isDisplayAwake ? SkyletTheme.skyBlue : SkyletTheme.secondaryText)
                }

                VStack(alignment: .leading, spacing: 2) {
                    // Countdown Display with Tabular Numerals
                    Text(displayCountdown)
                        .font(SkyletTheme.countdownFont)
                        .monospacedDigit()
                        .foregroundStyle(SkyletTheme.primaryText)

                    // Status line
                    HStack(spacing: 5) {
                        if droplet.timerEngine.isDisplayAwake {
                            Circle()
                                .fill(SkyletTheme.skyBlue)
                                .frame(width: 6, height: 6)
                            Text("Display awake")
                                .font(SkyletTheme.captionFont)
                                .foregroundStyle(SkyletTheme.skyBlue)
                        } else if droplet.timerEngine.status.isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(Color.green)
                            Text("Session complete")
                                .font(SkyletTheme.captionFont)
                                .foregroundStyle(Color.green)
                        } else if droplet.timerEngine.status.isPaused {
                            Text("Paused")
                                .font(SkyletTheme.captionFont)
                                .foregroundStyle(Color.orange)
                        } else {
                            Text("Keeps display awake during focus")
                                .font(SkyletTheme.captionFont)
                                .foregroundStyle(SkyletTheme.tertiaryText)
                        }
                    }
                }

                Spacer(minLength: DroppySpacing.md)

                // Main Action Button (Start / Pause / Resume / Stop)
                actionButtons
            }
            .padding(.vertical, 2)

            // Duration Presets (shown when idle or completed)
            if !droplet.timerEngine.status.isRunning && !droplet.timerEngine.status.isPaused {
                HStack(spacing: 5) {
                    ForEach(FocusPreset.allCases) { preset in
                        Button {
                            isCustomSelected = false
                            selectedPreset = preset
                        } label: {
                            Text(preset.title)
                                .font(.system(size: 11, weight: (!isCustomSelected && selectedPreset == preset) ? .bold : .regular))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background((!isCustomSelected && selectedPreset == preset) ? SkyletTheme.skyBlue.opacity(0.25) : SkyletTheme.cardFill)
                                .foregroundStyle((!isCustomSelected && selectedPreset == preset) ? SkyletTheme.skyBlue : SkyletTheme.primaryText)
                                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }

                    // Custom duration entry
                    HStack(spacing: 2) {
                        TextField("Min", text: $customMinutes)
                            .textFieldStyle(.plain)
                            .font(.system(size: 10))
                            .frame(width: 26)
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
                    .background(isCustomSelected ? SkyletTheme.skyBlue.opacity(0.25) : SkyletTheme.cardFill)
                    .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                }
                .padding(.top, 2)
            }
        }
    }

    // MARK: - Compact (Paired) Body

    private var compactBody: some View {
        HStack(spacing: DroppySpacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text(displayCountdown)
                    .font(SkyletTheme.smallCountdownFont)
                    .monospacedDigit()
                    .foregroundStyle(SkyletTheme.primaryText)
                if droplet.timerEngine.isDisplayAwake {
                    HStack(spacing: 3) {
                        Circle()
                            .fill(SkyletTheme.skyBlue)
                            .frame(width: 5, height: 5)
                        Text("Awake")
                            .font(SkyletTheme.captionFont)
                            .foregroundStyle(SkyletTheme.skyBlue)
                    }
                }
            }

            Spacer(minLength: 0)

            Button {
                toggleTimer()
            } label: {
                Image(systemName: droplet.timerEngine.status.isRunning ? "stop.fill" : "play.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(droplet.timerEngine.status.isRunning ? Color.red : SkyletTheme.skyBlue)
                    .padding(6)
                    .background(SkyletTheme.cardFill)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private var actionButtons: some View {
        switch droplet.timerEngine.status {
        case .idle:
            Button {
                startSelectedSession()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 10))
                    Text("Start")
                        .font(SkyletTheme.buttonFont)
                }
                .foregroundStyle(Color.black)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(SkyletTheme.skyBlue)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            .buttonStyle(.plain)

        case .running:
            HStack(spacing: 6) {
                Button {
                    droplet.timerEngine.pause()
                } label: {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(SkyletTheme.primaryText)
                        .padding(6)
                        .background(SkyletTheme.cardFill)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Button {
                    droplet.timerEngine.stop()
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.red)
                        .padding(6)
                        .background(SkyletTheme.cardFill)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

        case .paused:
            HStack(spacing: 6) {
                Button {
                    droplet.timerEngine.resume()
                } label: {
                    Image(systemName: "play.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(SkyletTheme.skyBlue)
                        .padding(6)
                        .background(SkyletTheme.cardFill)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Button {
                    droplet.timerEngine.stop()
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.red)
                        .padding(6)
                        .background(SkyletTheme.cardFill)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

        case .completed:
            Button {
                droplet.timerEngine.reset()
            } label: {
                Text("Reset")
                    .font(SkyletTheme.buttonFont)
                    .foregroundStyle(SkyletTheme.primaryText)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(SkyletTheme.cardFill)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            .buttonStyle(.plain)

        @unknown default:
            EmptyView()
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
        if isCustomSelected, let mins = Int(customMinutes), mins > 0, mins <= 480 {
            return TimeInterval(mins * 60)
        }
        return selectedPreset.durationSeconds
    }

    private func startSelectedSession() {
        let duration = durationForStart()
        droplet.timerEngine.start(duration: duration)
    }

    private func toggleTimer() {
        if droplet.timerEngine.status.isRunning {
            droplet.timerEngine.stop()
        } else {
            startSelectedSession()
        }
    }
}

extension FocusPreset {
    static var twentyFiveOrThirty: FocusPreset { .thirty }
}

