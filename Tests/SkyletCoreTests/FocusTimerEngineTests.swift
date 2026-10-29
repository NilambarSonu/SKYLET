//
//  FocusTimerEngineTests.swift
//  SkyletCoreTests
//

import XCTest
@testable import SkyletCore

final class MockPowerController: PowerAssertionControlling, @unchecked Sendable {
    var isDisplayAwakeActive: Bool = false
    var beginCount: Int = 0
    var endCount: Int = 0
    var shouldFail: Bool = false

    func beginDisplayAwake(reason: String) -> Bool {
        if shouldFail { return false }
        beginCount += 1
        isDisplayAwakeActive = true
        return true
    }

    func endDisplayAwake() {
        if isDisplayAwakeActive {
            endCount += 1
            isDisplayAwakeActive = false
        }
    }
}

@MainActor
final class FocusTimerEngineTests: XCTestCase {

    func testPresets() {
        XCTAssertEqual(FocusPreset.fifteen.durationSeconds, 900)
        XCTAssertEqual(FocusPreset.thirty.durationSeconds, 1800)
        XCTAssertEqual(FocusPreset.fortyFive.durationSeconds, 2700)
        XCTAssertEqual(FocusPreset.sixty.durationSeconds, 3600)
        XCTAssertEqual(FocusPreset.oneTwenty.durationSeconds, 7200)
    }

    func testCountdownFormatting() {
        XCTAssertEqual(FocusTimerEngine.formatCountdown(60), "01:00")
        XCTAssertEqual(FocusTimerEngine.formatCountdown(899), "14:59")
        XCTAssertEqual(FocusTimerEngine.formatCountdown(3600), "1:00:00")
        XCTAssertEqual(FocusTimerEngine.formatCountdown(3665), "1:01:05")
        XCTAssertEqual(FocusTimerEngine.formatCountdown(0), "00:00")
    }

    func testStartAndPreventDuplicateStart() {
        let mock = MockPowerController()
        let engine = FocusTimerEngine(powerController: mock)

        XCTAssertEqual(engine.status, .idle)
        XCTAssertFalse(engine.isDisplayAwake)

        engine.start(duration: 900)
        XCTAssertTrue(engine.status.isRunning)
        XCTAssertTrue(engine.isDisplayAwake)
        XCTAssertEqual(mock.beginCount, 1)

        // Starting again while running must NOT duplicate power assertions
        engine.start(duration: 900)
        XCTAssertEqual(mock.beginCount, 1)

        engine.stop()
        XCTAssertEqual(engine.status, .idle)
        XCTAssertFalse(engine.isDisplayAwake)
        XCTAssertEqual(mock.endCount, 1)
    }

    func testDeadlineCorrectnessAndSchedulingDelay() {
        let mock = MockPowerController()
        let engine = FocusTimerEngine(powerController: mock)

        let start = Date()
        engine.start(duration: 300) // 5 minutes

        // Advance 100 seconds
        let tick1 = start.addingTimeInterval(100)
        engine.updateTick(now: tick1)
        XCTAssertEqual(floor(engine.status.remainingSeconds), 200)

        // Advance another 150 seconds (simulate app being busy / scheduling delay)
        let tick2 = start.addingTimeInterval(250)
        engine.updateTick(now: tick2)
        XCTAssertEqual(floor(engine.status.remainingSeconds), 50)

        engine.stop()
    }

    func testPauseAndResume() {
        let mock = MockPowerController()
        let engine = FocusTimerEngine(powerController: mock)

        let start = Date()
        engine.start(duration: 600)
        XCTAssertTrue(engine.isDisplayAwake)

        // Advance 200s
        engine.updateTick(now: start.addingTimeInterval(200))
        XCTAssertEqual(floor(engine.status.remainingSeconds), 400)

        // Pause: power assertion must be released
        engine.pause()
        XCTAssertTrue(engine.status.isPaused)
        XCTAssertFalse(engine.isDisplayAwake)
        XCTAssertEqual(mock.endCount, 1)
        XCTAssertEqual(floor(engine.status.remainingSeconds), 400)

        // Resume: power assertion must be re-acquired
        engine.resume()
        XCTAssertTrue(engine.status.isRunning)
        XCTAssertTrue(engine.isDisplayAwake)
        XCTAssertEqual(mock.beginCount, 2)

        engine.stop()
    }

    func testNaturalCompletionReleasesPowerAssertion() {
        let mock = MockPowerController()
        let engine = FocusTimerEngine(powerController: mock)

        let start = Date()
        engine.start(duration: 60)
        XCTAssertTrue(mock.isDisplayAwakeActive)

        // Advance to 61s past deadline
        let completionDate = start.addingTimeInterval(61)
        engine.updateTick(now: completionDate)

        XCTAssertTrue(engine.status.isCompleted)
        XCTAssertFalse(engine.isDisplayAwake)
        XCTAssertFalse(mock.isDisplayAwakeActive)
        XCTAssertEqual(mock.endCount, 1)
    }

    func testPowerAssertionFailureTruthfulness() {
        let mock = MockPowerController()
        mock.shouldFail = true

        let engine = FocusTimerEngine(powerController: mock)
        engine.start(duration: 300)

        // UI state must truthfully reflect that assertion failed
        XCTAssertFalse(engine.isDisplayAwake)

        engine.stop()
    }

    func testDeactivationCleanup() {
        let mock = MockPowerController()
        let engine = FocusTimerEngine(powerController: mock)

        engine.start(duration: 1800)
        XCTAssertTrue(mock.isDisplayAwakeActive)

        engine.deactivate()
        XCTAssertEqual(engine.status, .idle)
        XCTAssertFalse(mock.isDisplayAwakeActive)
        XCTAssertEqual(mock.endCount, 1)
    }
}

