//
//  FocusTimerEngine.swift
//  SkyletCore
//

import Foundation
import Combine

public enum FocusPreset: Int, CaseIterable, Identifiable, Sendable {
    case fifteen = 15
    case thirty = 30
    case fortyFive = 45
    case sixty = 60
    case oneTwenty = 120

    public var id: Int { rawValue }

    public var title: String {
        "\(rawValue)m"
    }

    public var durationSeconds: TimeInterval {
        TimeInterval(rawValue * 60)
    }
}

public enum FocusTimerStatus: Equatable, Sendable {
    case idle
    case running(totalDuration: TimeInterval, remaining: TimeInterval, progress: Double)
    case paused(totalDuration: TimeInterval, remaining: TimeInterval, progress: Double)
    case completed(totalDuration: TimeInterval)

    public var isRunning: Bool {
        if case .running = self { return true }
        return false
    }

    public var isPaused: Bool {
        if case .paused = self { return true }
        return false
    }

    public var isCompleted: Bool {
        if case .completed = self { return true }
        return false
    }

    public var remainingSeconds: TimeInterval {
        switch self {
        case .idle: return 0
        case .running(_, let remaining, _), .paused(_, let remaining, _): return remaining
        case .completed: return 0
        }
    }
}

/// Deadline-based focus timer engine ensuring zero drift during UI suspension or scheduling delays.
@MainActor
public final class FocusTimerEngine: ObservableObject {
    @Published public private(set) var status: FocusTimerStatus = .idle
    @Published public private(set) var isDisplayAwake: Bool = false

    private let powerController: PowerAssertionControlling
    private var deadline: Date?
    private var totalDuration: TimeInterval = 0
    private var pausedRemaining: TimeInterval?
    private var internalTimer: AnyCancellable?

    public init(powerController: PowerAssertionControlling = MacOSPowerAssertionController()) {
        self.powerController = powerController
    }

    /// Starts a session with the specified duration in seconds.
    public func start(duration: TimeInterval) {
        guard duration > 0 else { return }

        // If already running with this duration, avoid duplicate start
        if case .running = status { return }

        self.totalDuration = duration
        self.deadline = Date().addingTimeInterval(duration)
        self.pausedRemaining = nil

        let acquired = powerController.beginDisplayAwake(reason: "Skylet focus session")
        self.isDisplayAwake = acquired && powerController.isDisplayAwakeActive

        updateTick()
        startInternalTicker()
    }

    /// Starts a session using a preset duration.
    public func start(preset: FocusPreset) {
        start(duration: preset.durationSeconds)
    }

    /// Pauses the running timer if active.
    public func pause() {
        guard case .running(let total, let remaining, let progress) = status else { return }
        internalTimer?.cancel()
        internalTimer = nil
        pausedRemaining = remaining
        deadline = nil
        powerController.endDisplayAwake()
        isDisplayAwake = false
        status = .paused(totalDuration: total, remaining: remaining, progress: progress)
    }

    /// Resumes a paused session.
    public func resume() {
        guard case .paused(let total, let remaining, _) = status, remaining > 0 else { return }
        self.totalDuration = total
        self.deadline = Date().addingTimeInterval(remaining)
        self.pausedRemaining = nil

        let acquired = powerController.beginDisplayAwake(reason: "Skylet focus session")
        self.isDisplayAwake = acquired && powerController.isDisplayAwakeActive

        updateTick()
        startInternalTicker()
    }

    /// Stops the timer and releases power assertions immediately.
    public func stop() {
        cleanup()
        status = .idle
    }

    /// Resets completion or idle state.
    public func reset() {
        stop()
    }

    /// Ticks or recalculates remaining time based on the fixed deadline.
    public func updateTick(now: Date = Date()) {
        guard let deadline = deadline else { return }

        let remaining = max(0, deadline.timeIntervalSince(now))
        let progress = totalDuration > 0 ? max(0, min(1, 1.0 - (remaining / totalDuration))) : 0

        if remaining <= 0.05 {
            // Natural completion
            cleanup()
            status = .completed(totalDuration: totalDuration)
        } else {
            status = .running(totalDuration: totalDuration, remaining: remaining, progress: progress)
            isDisplayAwake = powerController.isDisplayAwakeActive
        }
    }

    /// Full teardown on droplet deactivation.
    public func deactivate() {
        stop()
    }

    private func startInternalTicker() {
        internalTimer?.cancel()
        internalTimer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] currentDate in
                self?.updateTick(now: currentDate)
            }
    }

    private func cleanup() {
        internalTimer?.cancel()
        internalTimer = nil
        deadline = nil
        pausedRemaining = nil
        powerController.endDisplayAwake()
        isDisplayAwake = false
    }

    /// Formats seconds into MM:SS or HH:MM:SS with monospaced digits.
    public static func formatCountdown(_ seconds: TimeInterval) -> String {
        let totalSec = max(0, Int(ceil(seconds)))
        let hours = totalSec / 3600
        let minutes = (totalSec % 3600) / 60
        let secs = totalSec % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
}

