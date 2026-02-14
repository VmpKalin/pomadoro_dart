package com.example.test_project

import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "com.example.test_project/timer_notification"
        private const val PERMISSION_REQUEST_CODE = 1001

        /**
         * Shared reference so [TimerForegroundService] can invoke methods on the
         * Flutter side (e.g. when a notification button is pressed).
         *
         * Set in [configureFlutterEngine], cleared in [onDestroy].
         */
        var timerChannel: MethodChannel? = null
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, CHANNEL
        )
        timerChannel = channel

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startTimerNotification" -> {
                    val endTime = (call.argument<Number>("endTimeMillis"))?.toLong() ?: 0L
                    val title   = call.argument<String>("title") ?: "Pomodoro"
                    val mode    = call.argument<String>("mode") ?: "focus"
                    ensureNotificationPermission()
                    startTimerService(TimerForegroundService.ACTION_START) {
                        putExtra(TimerForegroundService.EXTRA_END_TIME, endTime)
                        putExtra(TimerForegroundService.EXTRA_TITLE, title)
                        putExtra(TimerForegroundService.EXTRA_MODE, mode)
                    }
                    result.success(null)
                }

                "pauseTimerNotification" -> {
                    val remaining = (call.argument<Number>("remainingMillis"))?.toLong() ?: 0L
                    startTimerService(TimerForegroundService.ACTION_PAUSE) {
                        putExtra(TimerForegroundService.EXTRA_REMAINING, remaining)
                    }
                    result.success(null)
                }

                "resumeTimerNotification" -> {
                    val endTime = (call.argument<Number>("endTimeMillis"))?.toLong() ?: 0L
                    startTimerService(TimerForegroundService.ACTION_RESUME) {
                        putExtra(TimerForegroundService.EXTRA_END_TIME, endTime)
                    }
                    result.success(null)
                }

                "stopTimerNotification" -> {
                    startTimerService(TimerForegroundService.ACTION_STOP)
                    result.success(null)
                }

                "requestNotificationPermission" -> {
                    ensureNotificationPermission()
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        timerChannel = null
        super.onDestroy()
    }

    // ─── Helpers ────────────────────────────────────────────────────────

    /**
     * Sends a command to [TimerForegroundService].
     * Uses startForegroundService() on API 26+ so Android allows the
     * service to call startForeground() within its 5-second window.
     */
    private fun startTimerService(
        action: String,
        extras: (Intent.() -> Unit)? = null
    ) {
        val intent = Intent(this, TimerForegroundService::class.java).apply {
            this.action = action
            extras?.invoke(this)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    /**
     * Requests POST_NOTIFICATIONS permission on Android 13+ (API 33).
     * On older versions this is a no-op — notifications are allowed by default.
     */
    private fun ensureNotificationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(
                    this, android.Manifest.permission.POST_NOTIFICATIONS
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                requestPermissions(
                    arrayOf(android.Manifest.permission.POST_NOTIFICATIONS),
                    PERMISSION_REQUEST_CODE
                )
            }
        }
    }
}
