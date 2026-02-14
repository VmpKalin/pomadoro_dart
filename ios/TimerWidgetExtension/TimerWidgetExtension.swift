// TimerWidgetExtension.swift
// Widget Extension entry point — renders the Live Activity on the
// lock screen and Dynamic Island with mode‑specific theming.

import WidgetKit
import SwiftUI
import ActivityKit

// MARK: - Entry point

@main
struct TimerWidgetExtensionBundle: WidgetBundle {
    var body: some Widget {
        TimerLiveActivity()
    }
}

// MARK: - Live Activity widget

struct TimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerAttributes.self) { context in
            // ── Lock-screen / notification banner ─────────────────────
            TimerLockScreenView(context: context)

        } dynamicIsland: { context in
            let accent = context.attributes.accentColor

            return DynamicIsland {
                // ── Expanded ─────────────────────────────────────────
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Image(systemName: context.attributes.modeIcon)
                            .font(.caption)
                            .foregroundColor(accent)
                        Text(context.attributes.timerName)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.white)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    timerText(for: context)
                        .font(.title2.monospacedDigit().weight(.medium))
                        .foregroundColor(context.state.isPaused ? .orange : accent)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text(context.attributes.modeSubtitle)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                        if context.state.isPaused {
                            Label("PAUSED", systemImage: "pause.fill")
                                .font(.caption2.weight(.bold))
                                .foregroundColor(.orange)
                        }
                    }
                }

            } compactLeading: {
                // ── Compact pill (left) ──────────────────────────────
                Image(systemName: context.attributes.modeIcon)
                    .font(.caption2)
                    .foregroundColor(context.state.isPaused ? .orange : accent)

            } compactTrailing: {
                // ── Compact pill (right) ─────────────────────────────
                timerText(for: context)
                    .font(.caption.monospacedDigit().weight(.medium))
                    .foregroundColor(context.state.isPaused ? .orange : accent)

            } minimal: {
                // ── Minimal (single glyph) ───────────────────────────
                Image(systemName: context.attributes.modeIcon)
                    .font(.caption2)
                    .foregroundColor(context.state.isPaused ? .orange : accent)
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func timerText(for context: ActivityViewContext<TimerAttributes>) -> some View {
        if context.state.isPaused {
            Text(Self.formatTime(context.state.remainingSeconds))
        } else {
            Text(timerInterval: Date.now...context.state.endTime,
                 countsDown: true)
        }
    }

    private static func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: - Lock-screen view

struct TimerLockScreenView: View {
    let context: ActivityViewContext<TimerAttributes>

    private var accent: Color { context.attributes.accentColor }
    private var gradient: [Color] { context.attributes.backgroundGradient }

    var body: some View {
        VStack(spacing: 10) {
            // ── Top row: icon + labels + countdown ───────────────────
            HStack(spacing: 0) {
                // Left: mode icon + labels
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        // Glowing icon circle
                        ZStack {
                            Circle()
                                .fill(accent.opacity(0.2))
                                .frame(width: 28, height: 28)
                            Image(systemName: context.attributes.modeIcon)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(accent)
                        }

                        Text(context.attributes.timerName)
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(.white)
                    }

                    if context.state.isPaused {
                        Label("PAUSED", systemImage: "pause.fill")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule().fill(Color.orange.opacity(0.15))
                            )
                    } else {
                        Text(context.attributes.modeSubtitle)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.5))
                    }
                }

                Spacer()

                // Right: large countdown
                VStack(alignment: .trailing, spacing: 2) {
                    if context.state.isPaused {
                        Text(Self.formatTime(context.state.remainingSeconds))
                            .font(.system(size: 34, weight: .light, design: .monospaced))
                            .foregroundColor(.orange)
                    } else {
                        Text(timerInterval: Date.now...context.state.endTime,
                             countsDown: true)
                            .font(.system(size: 34, weight: .light, design: .monospaced))
                            .foregroundColor(accent)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }

            // ── Bottom row: action buttons ────────────────────────────
            HStack(spacing: 10) {
                // Pause / Resume button
                Link(destination: URL(string: "pomodorotimer://toggle")!) {
                    HStack(spacing: 5) {
                        Image(systemName: context.state.isPaused
                              ? "play.fill" : "pause.fill")
                            .font(.caption2.weight(.semibold))
                        Text(context.state.isPaused ? "Resume" : "Pause")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundColor(context.state.isPaused ? accent : .white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        Capsule().fill(
                            context.state.isPaused
                                ? accent.opacity(0.2)
                                : Color.white.opacity(0.12)
                        )
                    )
                }

                // Skip to next session button
                Link(destination: URL(string: "pomodorotimer://skip")!) {
                    HStack(spacing: 5) {
                        Image(systemName: "forward.fill")
                            .font(.caption2.weight(.semibold))
                        Text("Skip")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        Capsule().fill(Color.white.opacity(0.08))
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .activityBackgroundTint(Color(red: 0.06, green: 0.06, blue: 0.07))
    }

    private static func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}
