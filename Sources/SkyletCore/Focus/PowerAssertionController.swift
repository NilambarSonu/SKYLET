//
//  PowerAssertionController.swift
//  SkyletCore
//

import Foundation

/// Protocol abstracting macOS power activity assertions to allow deterministic testing.
public protocol PowerAssertionControlling: AnyObject, Sendable {
    var isDisplayAwakeActive: Bool { get }
    @discardableResult
    func beginDisplayAwake(reason: String) -> Bool
    func endDisplayAwake()
}

/// Standard macOS power assertion controller using public ProcessInfo activity API.
public final class MacOSPowerAssertionController: PowerAssertionControlling, @unchecked Sendable {
    private let lock = NSLock()
    private var currentActivity: (any NSObjectProtocol)?

    public init() {}

    public var isDisplayAwakeActive: Bool {
        lock.lock()
        defer { lock.unlock() }
        return currentActivity != nil
    }

    @discardableResult
    public func beginDisplayAwake(reason: String = "Skylet focus session") -> Bool {
        lock.lock()
        defer { lock.unlock() }

        // If an activity is already held, do not duplicate
        if currentActivity != nil {
            return true
        }

        let activity = ProcessInfo.processInfo.beginActivity(
            options: .idleDisplaySleepDisabled,
            reason: reason
        )
        self.currentActivity = activity
        return true
    }

    public func endDisplayAwake() {
        lock.lock()
        defer { lock.unlock() }

        guard let activity = currentActivity else { return }
        ProcessInfo.processInfo.endActivity(activity)
        self.currentActivity = nil
    }

    deinit {
        endDisplayAwake()
    }
}

