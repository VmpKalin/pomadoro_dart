// TimerLiveActivityManager.swift
// Flutter plugin that bridges MethodChannel calls to iOS ActivityKit.
//
// On iOS 16.2+ this starts / updates / ends a Live Activity that shows
// the Pomodoro countdown on the lock screen and Dynamic Island.
// On older iOS versions every call is a silent no-op.

import Foundation
import Flutter
import ActivityKit

class TimerLiveActivityManager: NSObject, FlutterPlugin {

    /// Type-erased reference to the current `Activity<TimerAttributes>`.
    /// Using `Any?` so we don't need `@available` on the stored property.
    private static var activityRef: Any? = nil

    /// Static channel reference so we can call back into Flutter from SceneDelegate.
    private static var channel: FlutterMethodChannel?

    // MARK: - FlutterPlugin registration

    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.example.test_project/timer_notification",
            binaryMessenger: registrar.messenger()
        )
        self.channel = channel
        let instance = TimerLiveActivityManager()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    // MARK: - URL action handling (called from SceneDelegate)

    /// Processes a deep-link URL from a Live Activity button tap.
    ///
    /// Expected hosts: `toggle`, `skip`.
    /// The action is forwarded to Flutter's ViewModel through the MethodChannel.
    static func handleURLAction(_ action: String) {
        let flutterAction: String
        switch action {
        case "toggle":
            flutterAction = "toggleRequested"
        case "skip":
            flutterAction = "skipRequested"
        default:
            return
        }

        channel?.invokeMethod("onServiceAction", arguments: [
            "action": flutterAction,
            "remainingMillis": 0,
            "isPaused": false,
        ])
    }

    // MARK: - Method call handler

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        // Live Activities require iOS 16.2+ (for ActivityContent API).
        // On older versions we silently succeed so Flutter code doesn't error.
        guard #available(iOS 16.2, *) else {
            result(nil)
            return
        }

        switch call.method {
        case "startTimerNotification":
            guard let args = call.arguments as? [String: Any],
                  let endTimeNum = args["endTimeMillis"] as? NSNumber,
                  let title = args["title"] as? String else {
                result(FlutterError(code: "ARGS", message: "Missing startTimer args", details: nil))
                return
            }
            let mode = args["mode"] as? String ?? "focus"
            doStart(endTimeMillis: endTimeNum.int64Value, title: title, mode: mode)
            result(nil)

        case "pauseTimerNotification":
            guard let args = call.arguments as? [String: Any],
                  let remainingNum = args["remainingMillis"] as? NSNumber else {
                result(FlutterError(code: "ARGS", message: "Missing pauseTimer args", details: nil))
                return
            }
            doPause(remainingMillis: remainingNum.int64Value)
            result(nil)

        case "resumeTimerNotification":
            guard let args = call.arguments as? [String: Any],
                  let endTimeNum = args["endTimeMillis"] as? NSNumber else {
                result(FlutterError(code: "ARGS", message: "Missing resumeTimer args", details: nil))
                return
            }
            doResume(endTimeMillis: endTimeNum.int64Value)
            result(nil)

        case "stopTimerNotification":
            doStop()
            result(nil)

        case "requestNotificationPermission":
            // No-op on iOS — Live Activities are toggled in Settings, not via runtime prompt.
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - ActivityKit operations (iOS 16.2+)

    @available(iOS 16.2, *)
    private func doStart(endTimeMillis: Int64, title: String, mode: String) {
        // Tear down any existing activity first.
        if let existing = Self.activityRef as? Activity<TimerAttributes> {
            Task { await existing.end(nil, dismissalPolicy: .immediate) }
            Self.activityRef = nil
        }

        let endTime = Date(timeIntervalSince1970: Double(endTimeMillis) / 1000.0)
        let remaining = max(0, Int(endTime.timeIntervalSinceNow))

        let attributes = TimerAttributes(timerName: title, timerMode: mode)
        let state = TimerAttributes.ContentState(
            endTime: endTime,
            isPaused: false,
            remainingSeconds: remaining
        )

        do {
            let content = ActivityContent(state: state,
                                          staleDate: endTime.addingTimeInterval(30))
            Self.activityRef = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil  // local-only, no push token
            )
        } catch {
            print("[TimerLiveActivity] Failed to start: \(error)")
        }
    }

    @available(iOS 16.2, *)
    private func doPause(remainingMillis: Int64) {
        guard let activity = Self.activityRef as? Activity<TimerAttributes> else { return }

        let remaining = max(0, Int(remainingMillis / 1000))
        let state = TimerAttributes.ContentState(
            // endTime is irrelevant while paused, but we keep a valid future date
            // so the UI never accidentally shows a negative value.
            endTime: Date().addingTimeInterval(Double(remaining)),
            isPaused: true,
            remainingSeconds: remaining
        )

        Task {
            await activity.update(
                ActivityContent(state: state, staleDate: nil)
            )
        }
    }

    @available(iOS 16.2, *)
    private func doResume(endTimeMillis: Int64) {
        guard let activity = Self.activityRef as? Activity<TimerAttributes> else { return }

        let endTime = Date(timeIntervalSince1970: Double(endTimeMillis) / 1000.0)
        let remaining = max(0, Int(endTime.timeIntervalSinceNow))

        let state = TimerAttributes.ContentState(
            endTime: endTime,
            isPaused: false,
            remainingSeconds: remaining
        )

        Task {
            await activity.update(
                ActivityContent(state: state,
                                staleDate: endTime.addingTimeInterval(30))
            )
        }
    }

    @available(iOS 16.2, *)
    private func doStop() {
        guard let activity = Self.activityRef as? Activity<TimerAttributes> else { return }
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        Self.activityRef = nil
    }
}
