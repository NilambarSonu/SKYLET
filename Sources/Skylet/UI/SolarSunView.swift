//
//  SolarSunView.swift
//  Skylet
//
//  Custom Solar Instrument & Visual Focus Timer
//  Quiet Precision. Instant Intelligence.
//

import SwiftUI
import SkyletCore

/// An elegant custom-drawn Solar Instrument representing the active focus session.
/// The solar core represents energy and presence; the radial beams represent the session duration,
/// gracefully receding clockwise as time elapses.
public struct SolarSunView: View {
    let status: FocusTimerStatus
    let diameter: CGFloat
    let showAura: Bool

    public init(status: FocusTimerStatus, diameter: CGFloat = 72, showAura: Bool = true) {
        self.status = status
        self.diameter = diameter
        self.showAura = showAura
    }

    private let beamCount: Int = 12

    // Elapsed progress from 0.0 (just started) to 1.0 (completed)
    private var progress: Double {
        switch status {
        case .idle:
            return 0.0
        case .running(_, _, let prog), .paused(_, _, let prog):
            return max(0.0, min(1.0, prog))
        case .completed:
            return 1.0
        @unknown default:
            return 0.0
        }
    }

    public var body: some View {
        ZStack {
            // Ambient Solar Glow / Halo
            if showAura {
                ambientGlow
            }

            // Radial Solar Beams (The Visual Timer)
            solarBeams

            // Central Solar Core
            solarCore
        }
        .frame(width: diameter, height: diameter)
    }

    // MARK: - Ambient Solar Glow

    @ViewBuilder
    private var ambientGlow: some View {
        switch status {
        case .idle:
            Circle()
                .fill(
                    RadialGradient(
                        colors: [SkyletTheme.solarGlow.opacity(0.15), Color.clear],
                        center: .center,
                        startRadius: diameter * 0.15,
                        endRadius: diameter * 0.50
                    )
                )

        case .running:
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            SkyletTheme.solarGold.opacity(0.25),
                            SkyletTheme.solarCore.opacity(0.10),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: diameter * 0.15,
                        endRadius: diameter * 0.52
                    )
                )
                .scaleEffect(1.04)
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: status.isRunning)

        case .paused:
            Circle()
                .fill(
                    RadialGradient(
                        colors: [SkyletTheme.statusDelayed.opacity(0.18), Color.clear],
                        center: .center,
                        startRadius: diameter * 0.15,
                        endRadius: diameter * 0.46
                    )
                )

        case .completed:
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            SkyletTheme.statusLive.opacity(0.30),
                            SkyletTheme.solarGold.opacity(0.12),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: diameter * 0.18,
                        endRadius: diameter * 0.52
                    )
                )

        @unknown default:
            EmptyView()
        }
    }

    // MARK: - Central Solar Core

    private var coreDiameter: CGFloat {
        diameter * 0.46
    }

    @ViewBuilder
    private var solarCore: some View {
        ZStack {
            switch status {
            case .idle:
                // Dormant gentle golden-amber sun
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                SkyletTheme.solarGold.opacity(0.85),
                                SkyletTheme.solarCore.opacity(0.80)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white.opacity(0.20), lineWidth: 1)
                    )

                // Subdued center glyph indicating ready state
                Image(systemName: "sun.max")
                    .font(.system(size: coreDiameter * 0.46, weight: .semibold))
                    .foregroundStyle(Color.black.opacity(0.65))

            case .running:
                // Energized vibrant sun with specular highlight and inner depth
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                SkyletTheme.solarFlare,
                                SkyletTheme.solarGold,
                                SkyletTheme.solarCore
                            ],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: coreDiameter
                        )
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
                    )
                    .shadow(color: SkyletTheme.solarGold.opacity(0.4), radius: 4, x: 0, y: 1)

                // Atmospheric focus ring
                Circle()
                    .stroke(SkyletTheme.skyBlue.opacity(0.55), lineWidth: 1.5)
                    .frame(width: coreDiameter * 0.70, height: coreDiameter * 0.70)

                // Inner focal spark
                Circle()
                    .fill(Color.white.opacity(0.90))
                    .frame(width: coreDiameter * 0.22, height: coreDiameter * 0.22)

            case .paused:
                // Calm, paused amber core
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                SkyletTheme.statusDelayed,
                                SkyletTheme.solarCore.opacity(0.85)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                    )

                // Pause glyph
                Image(systemName: "pause.fill")
                    .font(.system(size: coreDiameter * 0.42, weight: .bold))
                    .foregroundStyle(Color.black.opacity(0.70))

            case .completed:
                // Serene completion sun (golden emerald dawn)
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                SkyletTheme.statusLive,
                                SkyletTheme.solarGold
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white.opacity(0.40), lineWidth: 1)
                    )
                    .shadow(color: SkyletTheme.statusLive.opacity(0.4), radius: 5, x: 0, y: 1)

                // Radiant checkmark
                Image(systemName: "checkmark")
                    .font(.system(size: coreDiameter * 0.48, weight: .bold))
                    .foregroundStyle(Color.black.opacity(0.75))

            @unknown default:
                EmptyView()
            }
        }
        .frame(width: coreDiameter, height: coreDiameter)
    }

    // MARK: - Radial Solar Beams (The Visual Timer)

    private var solarBeams: some View {
        ZStack {
            ForEach(0..<beamCount, id: \.self) { index in
                solarBeam(at: index)
            }
        }
    }

    private func solarBeam(at index: Int) -> some View {
        // Angle: index 0 is at 12 o'clock (-90 degrees), going clockwise
        let angleDegrees = Double(index) * (360.0 / Double(beamCount)) - 90.0

        // Sub-progress for this specific beam
        let segmentDuration = 1.0 / Double(beamCount)
        let segmentStart = Double(index) * segmentDuration
        let segmentEnd = segmentStart + segmentDuration

        let beamState: (lengthFactor: CGFloat, opacity: Double, color: Color)

        switch status {
        case .idle:
            // In idle, all beams are visible at resting length and soft golden opacity
            beamState = (lengthFactor: 0.85, opacity: 0.45, color: SkyletTheme.solarGold)

        case .running, .paused:
            if progress <= segmentStart {
                // Not yet reached: beam is fully extended and active
                beamState = (
                    lengthFactor: 1.0,
                    opacity: status.isPaused ? 0.65 : 1.0,
                    color: status.isPaused ? SkyletTheme.statusDelayed : SkyletTheme.solarRayActive
                )
            } else if progress < segmentEnd {
                // Currently elapsing: beam is shortening and fading
                let elapsedInSegment = (progress - segmentStart) / segmentDuration
                let remainingInSegment = 1.0 - elapsedInSegment
                let len = 0.35 + 0.65 * CGFloat(remainingInSegment)
                let op = 0.20 + 0.80 * remainingInSegment
                beamState = (
                    lengthFactor: len,
                    opacity: op,
                    color: status.isPaused ? SkyletTheme.statusDelayed : SkyletTheme.solarRayActive
                )
            } else {
                // Already elapsed: beam sits as a subtle dormant track
                beamState = (
                    lengthFactor: 0.30,
                    opacity: 0.12,
                    color: Color.white
                )
            }

        case .completed:
            // At completion, all beams have dissolved, leaving faint quiet stars
            beamState = (lengthFactor: 0.25, opacity: 0.08, color: SkyletTheme.statusLive)

        @unknown default:
            beamState = (lengthFactor: 0.5, opacity: 0.3, color: .white)
        }

        // Geometry for beam dimensions
        let coreRadius = coreDiameter / 2.0
        let maxBeamLength = (diameter / 2.0) - coreRadius - 2.0
        let actualBeamLength = max(3.0, maxBeamLength * beamState.lengthFactor)
        let beamThickness: CGFloat = max(2.0, diameter * 0.045)
        let innerOffset = coreRadius + 2.5 + (actualBeamLength / 2.0)

        return Capsule()
            .fill(beamState.color)
            .opacity(beamState.opacity)
            .frame(width: actualBeamLength, height: beamThickness)
            .offset(x: innerOffset)
            .rotationEffect(.degrees(angleDegrees))
            .animation(.linear(duration: 0.25), value: progress)
    }
}
