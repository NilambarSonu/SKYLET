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
    @Published public private(set) var latestConversion: CurrencyConversionResult?

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
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.publishAppropriateLiveActivity()
            }
            .store(in: &cancellables)
    }

    public func deactivate() {
        // Full teardown: stop timer, release power assertions, clear live activity, release host.
        timerEngine.deactivate()
        cancellables.removeAll()
        latestConversion = nil
        activitySubject.send(nil)
        host = nil
    }

    public func updateLatestConversion(_ result: CurrencyConversionResult) {
        self.latestConversion = result
        publishAppropriateLiveActivity()
    }

    private func publishAppropriateLiveActivity() {
        switch timerEngine.status {
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
            if let conv = latestConversion {
                let formattedTarget = CurrencyFormatter.format(amount: conv.targetAmount, currency: conv.targetCurrency)
                activitySubject.send(
                    LiveActivityState(
                        priority: 150,
                        accessibilityTitle: "Skylet conversion: \(conv.sourceAmount) \(conv.sourceCurrency.rawValue) = \(formattedTarget)",
                        isInteractive: false
                    )
                )
            } else {
                activitySubject.send(nil)
            }
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
                switch timerEngine.status {
                case .running, .paused:
                    Image(systemName: timerEngine.isDisplayAwake ? "sun.max.fill" : "timer")
                        .font(.system(size: DroppyLiveActivityMetrics.iconSize, weight: .semibold))
                        .foregroundStyle(SkyletTheme.skyBlue)
                case .idle, .completed:
                    if latestConversion != nil {
                        Image(systemName: "indianrupeesign.circle.fill")
                            .font(.system(size: DroppyLiveActivityMetrics.iconSize, weight: .semibold))
                            .foregroundStyle(SkyletTheme.skyBlue)
                    } else {
                        Image(systemName: "sparkles")
                            .font(.system(size: DroppyLiveActivityMetrics.iconSize, weight: .semibold))
                            .foregroundStyle(SkyletTheme.skyBlue)
                    }
                @unknown default:
                    EmptyView()
                }
            }
        )
    }

    public func makeCompactTrailing() -> AnyView {
        AnyView(
            Group {
                switch timerEngine.status {
                case .running, .paused:
                    Text(currentCountdownText)
                        .font(.system(size: DroppyLiveActivityMetrics.labelFontSize, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(AdaptiveColors.notchSurfacePrimaryText)
                case .idle, .completed:
                    if let conv = latestConversion {
                        Text(CurrencyFormatter.format(amount: conv.targetAmount, currency: conv.targetCurrency))
                            .font(.system(size: DroppyLiveActivityMetrics.labelFontSize, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(AdaptiveColors.notchSurfacePrimaryText)
                    } else {
                        EmptyView()
                    }
                @unknown default:
                    EmptyView()
                }
            }
        )
    }

    public func makeExpanded(context: LiveActivityContext) -> AnyView {
        AnyView(EmptyView())
    }

    private var currentCountdownText: String {
        FocusTimerEngine.formatCountdown(timerEngine.status.remainingSeconds)
    }
}

