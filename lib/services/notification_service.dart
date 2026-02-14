import 'package:flutter/services.dart';

/// Bridges Flutter ↔ Android [TimerForegroundService] via a [MethodChannel].
///
/// All public methods are fire-and-forget on the Dart side.
/// The native service owns the notification lifecycle and updates.
///
/// ### Reverse callback
///
/// When the user taps a notification action button (Pause / Resume / Stop)
/// the native service calls back into Flutter through the same channel.
/// Register [onServiceAction] **before** calling [init] to receive these
/// callbacks while the app is in the foreground.
///
/// If the Flutter engine is detached (app killed), the callback is silently
/// dropped — the ViewModel should sync state in `onAppResumed()`.
class NotificationService {
  static const _channel =
      MethodChannel('com.example.test_project/timer_notification');

  /// Called when the native service handles a notification-button action.
  ///
  /// Parameters:
  /// - [action]: `"paused"` | `"resumed"` | `"stopped"`
  /// - [remainingMillis]: milliseconds left at the moment the action fired
  /// - [isPaused]: current pause state of the service
  static void Function(String action, int remainingMillis, bool isPaused)?
      onServiceAction;

  /// Wire up the reverse-call handler. Call once at app startup (in `main()`).
  static void init() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onServiceAction') {
        final args = Map<String, dynamic>.from(call.arguments as Map);
        onServiceAction?.call(
          args['action'] as String,
          (args['remainingMillis'] as num).toInt(),
          args['isPaused'] as bool,
        );
      }
    });
  }

  // ─── Commands → native service ─────────────────────────────────────

  /// Show the foreground notification and start the countdown.
  ///
  /// [endTimeMillis] — absolute timestamp (ms since epoch) when the timer
  /// reaches zero.
  /// [mode] — one of `"focus"`, `"shortBreak"`, `"longBreak"`.
  ///          Used by native code to pick accent colour and icon.
  static Future<void> start({
    required int endTimeMillis,
    String title = 'Pomodoro',
    String mode = 'focus',
  }) async {
    try {
      await _channel.invokeMethod('startTimerNotification', {
        'endTimeMillis': endTimeMillis,
        'title': title,
        'mode': mode,
      });
    } on PlatformException catch (_) {
      // Notification permission denied or service not available — non-fatal.
    }
  }

  /// Update the notification to show "Paused" and stop the ticker.
  static Future<void> pause({required int remainingMillis}) async {
    try {
      await _channel.invokeMethod('pauseTimerNotification', {
        'remainingMillis': remainingMillis,
      });
    } on PlatformException catch (_) {}
  }

  /// Resume the countdown from a new [endTimeMillis].
  static Future<void> resume({required int endTimeMillis}) async {
    try {
      await _channel.invokeMethod('resumeTimerNotification', {
        'endTimeMillis': endTimeMillis,
      });
    } on PlatformException catch (_) {}
  }

  /// Remove the notification and stop the foreground service.
  static Future<void> stop() async {
    try {
      await _channel.invokeMethod('stopTimerNotification');
    } on PlatformException catch (_) {}
  }

  /// Request POST_NOTIFICATIONS permission (Android 13+).
  /// On older versions this is a no-op.
  static Future<void> requestPermission() async {
    try {
      await _channel.invokeMethod('requestNotificationPermission');
    } on PlatformException catch (_) {}
  }
}
