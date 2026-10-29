//
//  SkyletDroplet.swift
//  Skylet
//

import Combine
import SwiftUI
import DroppyKit
import SkyletCore

/// Skylet: Native DroppyKit utility combining currency intelligence (instant INR conversion)
/// and a display-awake focus timer for macOS.
@MainActor
public final class SkyletDroplet: NSObject, ObservableObject, Droplet {
    /// Must equal `DroppyDropletID` in Info.plist and `id` in `droplet.json`.
    public nonisolated static let id: DropletID = "skylet"

    private var host: DropletHost?
    private var cancellables = Set<AnyCancellable>()
    private let activitySubject = CurrentValueSubject<LiveActivityState?, Never>(nil)

    public let timerEngine: FocusTimerEngine
    public let rateService: CurrencyRateService

    @Published public var selectedMode: SkyletMode = .currency

    public override init() {
        self.timerEngine = FocusTimerEngine()
        self.rateService = CurrencyRateService()
        super.init()
    }

    // MARK: - Lifecycle

    public func activate(host: DropletHost) throws {
        self.host = host
        host.log.info("Skylet activated")

        // Observe Focus Timer state to publish Live Activity updates
        timerEngine.$status
            .sink { [weak self] status in
                guard let self = self else { return }
                self.handleTimerStatusChange(status)
            }
            .store(in: &cancellables)
    }

    public func deactivate() {
        // Full teardown: stop timer, release power assertions, clear live activity, release host.
        timerEngine.deactivate()
        cancellables.removeAll()
        activitySubject.send(nil)
        host = nil
    }

    private func handleTimerStatusChange(_ status: FocusTimerStatus) {
        switch status {
        case .running(_, let remaining, _):
            let formatted = FocusTimerEngine.formatCountdown(remaining)
            activitySubject.send(
                LiveActivityState(
                    priority: 250,
                    accessibilityTitle: "Skylet focus timer: \(formatted)",
                    isInteractive: false
                )
            )
        case .paused(_, let remaining, _):
            let formatted = FocusTimerEngine.formatCountdown(remaining)
            activitySubject.send(
                LiveActivityState(
                    priority: 200,
                    accessibilityTitle: "Skylet timer paused: \(formatted)",
                    isInteractive: false
                )
            )
        case .idle, .completed:
            activitySubject.send(nil)
        @unknown default:
            activitySubject.send(nil)
        }
    }
}

// MARK: - ShelfWidgetProviding

extension SkyletDroplet: ShelfWidgetProviding {
    public var widgetDescriptors: [ShelfWidgetDescriptor] {
        [
            ShelfWidgetDescriptor(
                id: "skylet",
                title: "Skylet",
                systemImage: "sparkles",
                layoutTraits: ShelfWidgetLayoutTraits(
                    preferredSoloWidth: 420,
                    preferredPairedWidth: 210,
                    contentHeight: .fixed(160)
                ),
                searchKeywords: [
                    "currency", "converter", "inr", "rupee",
                    "focus", "timer", "display", "awake"
                ]
            )
        ]
    }

    public func makeWidgetView(_ id: ShelfWidgetID, context: ShelfWidgetContext) -> AnyView {
        AnyView(SkyletRootView(droplet: self, context: context))
    }
}

// MARK: - LiveActivityProviding

extension SkyletDroplet: LiveActivityProviding {
    public var liveActivityState: AnyPublisher<LiveActivityState?, Never> {
        activitySubject.eraseToAnyPublisher()
    }

    public func makeCompactLeading() -> AnyView {
        AnyView(
            HStack(spacing: 3) {
                Image(systemName: timerEngine.isDisplayAwake ? "sun.max.fill" : "timer")
                    .font(.system(size: DroppyLiveActivityMetrics.iconSize, weight: .semibold))
                    .foregroundStyle(SkyletTheme.skyBlue)
            }
        )
    }

    public func makeCompactTrailing() -> AnyView {
        AnyView(
            Text(currentCountdownText)
                .font(.system(size: DroppyLiveActivityMetrics.labelFontSize, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(AdaptiveColors.notchSurfacePrimaryText)
        )
    }

    public func makeExpanded(context: LiveActivityContext) -> AnyView {
        AnyView(EmptyView())
    }

    private var currentCountdownText: String {
        FocusTimerEngine.formatCountdown(timerEngine.status.remainingSeconds)
    }
}

