// TimerAttributes.swift
// Shared between the Runner app and TimerWidgetExtension.
// Compile this file in BOTH targets so ActivityKit can match the type.

import Foundation
import ActivityKit
import SwiftUI

/// Defines the data model for the Pomodoro timer Live Activity.
@available(iOS 16.1, *)
struct TimerAttributes: ActivityAttributes {
    /// Mode label — stays constant for the lifetime of one activity (e.g. "FOCUS").
    var timerName: String
    /// One of "focus", "shortBreak", "longBreak" — drives colour theming.
    var timerMode: String

    /// Mutable state that changes on start / pause / resume.
    struct ContentState: Codable, Hashable {
        /// Absolute date when the timer reaches zero (used for `Text(timerInterval:)`).
        var endTime: Date
        /// Whether the timer is currently paused.
        var isPaused: Bool
        /// Remaining seconds — used to render a static value when paused.
        var remainingSeconds: Int
    }
}

// MARK: - Mode‑aware colour palette

/// Colours that match the Flutter app:
///   Focus:       #E8533E  (coral red)
///   Short Break: #3ECE8E  (green)
///   Long Break:  #3ECE8E  (green)
@available(iOS 16.1, *)
extension TimerAttributes {

    /// Primary accent colour for the current mode.
    var accentColor: Color {
        switch timerMode {
        case "shortBreak", "longBreak":
            return Color(red: 0.243, green: 0.808, blue: 0.557) // #3ECE8E
        default:
            return Color(red: 0.910, green: 0.325, blue: 0.243) // #E8533E
        }
    }

    /// Softer tint used for backgrounds / glows.
    var accentTint: Color {
        accentColor.opacity(0.18)
    }

    /// Darker background that works well on the lock screen.
    var backgroundGradient: [Color] {
        switch timerMode {
        case "shortBreak", "longBreak":
            return [
                Color(red: 0.06, green: 0.14, blue: 0.10),  // dark green
                Color(red: 0.04, green: 0.08, blue: 0.06),
            ]
        default:
            return [
                Color(red: 0.16, green: 0.07, blue: 0.06),  // dark red
                Color(red: 0.08, green: 0.04, blue: 0.04),
            ]
        }
    }

    /// SF Symbol name for the mode.
    var modeIcon: String {
        switch timerMode {
        case "shortBreak": return "cup.and.saucer.fill"
        case "longBreak":  return "leaf.fill"
        default:           return "flame.fill"
        }
    }

    /// Short motivational subtitle.
    var modeSubtitle: String {
        switch timerMode {
        case "shortBreak": return "Take a breather"
        case "longBreak":  return "You've earned it"
        default:           return "Stay focused"
        }
    }
}
