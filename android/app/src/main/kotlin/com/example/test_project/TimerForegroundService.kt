package com.example.test_project

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.Color
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat

/**
 * Foreground service that displays an ongoing notification with a countdown timer.
 *
 * ## Notification update frequency
 *
 * The notification refreshes every [UPDATE_INTERVAL_MS] (2 000 ms).
 *
 * Why 2 seconds?
 *   • 1 s  — most "live" feel but doubles the number of notify() calls.
 *            On some OEMs Android may throttle updates faster than ~1 s.
 *   • 2 s  — responsive enough for a visible countdown while cutting wake-ups in half.
 *            This is the recommended sweet-spot for a timer display.
 *   • 5–10 s — too laggy; the user sees stale values on the lock screen.
 *
 * The displayed remaining time is always recalculated from the absolute
 * [endTimeMillis] timestamp, so even if an update is delayed or skipped the
 * value shown is never wrong — only slightly stale.
 *
 * ## Battery impact
 *
 * Each notify() call is lightweight (no sound / vibration thanks to
 * setOnlyAlertOnce + setSilent). The main cost is the ~500 µs binder
 * transaction to NotificationManager. At 2 s cadence this is negligible.
 */
class TimerForegroundService : Service() {

    companion object {
        const val ACTION_START  = "com.example.test_project.ACTION_START"
        const val ACTION_PAUSE  = "com.example.test_project.ACTION_PAUSE"
        const val ACTION_RESUME = "com.example.test_project.ACTION_RESUME"
        const val ACTION_STOP   = "com.example.test_project.ACTION_STOP"
        const val ACTION_SKIP   = "com.example.test_project.ACTION_SKIP"

        const val EXTRA_END_TIME  = "endTimeMillis"
        const val EXTRA_REMAINING = "remainingMillis"
        const val EXTRA_TITLE     = "title"
        const val EXTRA_MODE      = "mode"

        const val CHANNEL_ID      = "timer_channel"
        const val NOTIFICATION_ID = 1001

        /** See class KDoc for the rationale behind 2 000 ms. */
        const val UPDATE_INTERVAL_MS = 2_000L

        // ─── Mode‑specific colours (match the Flutter app) ──────────
        //  Focus:       #E8533E  (coral red)
        //  Short Break: #3ECE8E  (green)
        //  Long Break:  #3ECE8E  (green)
        private const val COLOR_FOCUS       = 0xFFE8533E.toInt()
        private const val COLOR_SHORT_BREAK = 0xFF3ECE8E.toInt()
        private const val COLOR_LONG_BREAK  = 0xFF3ECE8E.toInt()
    }

    private val handler = Handler(Looper.getMainLooper())
    private var endTimeMillis: Long = 0L
    private var remainingMillis: Long = 0L
    private var isPaused = false
    private var title = "Pomodoro"
    private var mode  = "focus"

    // ─── Ticker ─────────────────────────────────────────────────────────

    private val tickRunnable: Runnable = object : Runnable {
        override fun run() {
            if (isPaused) return
            remainingMillis = endTimeMillis - System.currentTimeMillis()
            if (remainingMillis <= 0) {
                showFinishedNotification()
                handler.postDelayed({ stopSelfClean() }, 5_000)
                return
            }
            updateNotification()
            handler.postDelayed(this, UPDATE_INTERVAL_MS)
        }
    }

    // ─── Service lifecycle ──────────────────────────────────────────────

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START  -> handleStart(intent)
            ACTION_PAUSE  -> handlePause(intent)
            ACTION_RESUME -> handleResume(intent)
            ACTION_SKIP   -> handleSkip()
            ACTION_STOP   -> stopSelfClean()
        }
        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        handler.removeCallbacks(tickRunnable)
        super.onDestroy()
    }

    // ─── Command handlers ───────────────────────────────────────────────

    private fun handleStart(intent: Intent) {
        endTimeMillis = intent.getLongExtra(EXTRA_END_TIME, 0L)
        title = intent.getStringExtra(EXTRA_TITLE) ?: "Pomodoro"
        mode  = intent.getStringExtra(EXTRA_MODE) ?: "focus"
        isPaused = false
        remainingMillis = (endTimeMillis - System.currentTimeMillis()).coerceAtLeast(0)

        val notification = buildNotification()
        if (Build.VERSION.SDK_INT >= 34) {
            startForeground(
                NOTIFICATION_ID, notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }

        handler.removeCallbacks(tickRunnable)
        handler.postDelayed(tickRunnable, UPDATE_INTERVAL_MS)
        notifyFlutter("started")
    }

    private fun handlePause(intent: Intent) {
        isPaused = true
        val explicit = intent.getLongExtra(EXTRA_REMAINING, -1L)
        remainingMillis = if (explicit >= 0) explicit
                          else (endTimeMillis - System.currentTimeMillis()).coerceAtLeast(0)
        handler.removeCallbacks(tickRunnable)
        updateNotification()
        notifyFlutter("paused")
    }

    private fun handleResume(intent: Intent) {
        val explicit = intent.getLongExtra(EXTRA_END_TIME, -1L)
        endTimeMillis = if (explicit > 0) explicit
                        else System.currentTimeMillis() + remainingMillis
        isPaused = false
        remainingMillis = (endTimeMillis - System.currentTimeMillis()).coerceAtLeast(0)

        handler.removeCallbacks(tickRunnable)
        handler.postDelayed(tickRunnable, UPDATE_INTERVAL_MS)
        updateNotification()
        notifyFlutter("resumed")
    }

    private fun handleSkip() {
        // Stop the ticker; Flutter will advance to the next session and either
        // restart us with a new mode or stop us.
        handler.removeCallbacks(tickRunnable)
        notifyFlutter("skipRequested")
    }

    private fun stopSelfClean() {
        handler.removeCallbacks(tickRunnable)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        notifyFlutter("stopped")
        stopSelf()
    }

    // ─── Mode helpers ───────────────────────────────────────────────────

    /** Returns the ARGB accent colour matching the current [mode]. */
    private fun modeColor(): Int = when (mode) {
        "shortBreak" -> COLOR_SHORT_BREAK
        "longBreak"  -> COLOR_LONG_BREAK
        else         -> COLOR_FOCUS
    }

    /** Small emoji prefix for the notification title. */
    private fun modeIcon(): String = when (mode) {
        "shortBreak" -> "\u2615"   // ☕
        "longBreak"  -> "\uD83C\uDF3F"  // 🌿
        else         -> "\uD83C\uDFAF"  // 🎯
    }

    /** Human-readable sub-text shown below the main content. */
    private fun modeSubText(): String = when (mode) {
        "shortBreak" -> "Short break"
        "longBreak"  -> "Long break"
        else         -> "Stay focused"
    }

    // ─── Notification helpers ───────────────────────────────────────────

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Timer",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Ongoing timer countdown"
                setShowBadge(false)
            }
            getSystemService(NotificationManager::class.java)
                .createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification {
        val timeText = formatTime(remainingMillis)
        val contentText = if (isPaused) "\u23F8\uFE0F  Paused — $timeText remaining"
                          else "\u23F1\uFE0F  $timeText remaining"

        // Tap the notification → bring the app to the foreground
        val openIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val openPending = PendingIntent.getActivity(
            this, 0, openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val accentColor = modeColor()
        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("${modeIcon()}  $title")
            .setContentText(contentText)
            .setSubText(modeSubText())
            .setSmallIcon(android.R.drawable.ic_menu_recent_history)
            .setColor(accentColor)              // tints icon + accent areas
            .setColorized(true)                 // applies colour to background on supported devices
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setSilent(true)
            .setContentIntent(openPending)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setCategory(NotificationCompat.CATEGORY_PROGRESS)

        // ── Action buttons (Android supports up to 3) ────────────────
        if (!isPaused) {
            builder.addAction(
                android.R.drawable.ic_media_pause, "Pause",
                makeServicePendingIntent(ACTION_PAUSE, requestCode = 1)
            )
        } else {
            builder.addAction(
                android.R.drawable.ic_media_play, "Resume",
                makeServicePendingIntent(ACTION_RESUME, requestCode = 2)
            )
        }
        builder.addAction(
            android.R.drawable.ic_media_next, "Skip",
            makeServicePendingIntent(ACTION_SKIP, requestCode = 4)
        )
        builder.addAction(
            android.R.drawable.ic_menu_close_clear_cancel, "Stop",
            makeServicePendingIntent(ACTION_STOP, requestCode = 3)
        )

        return builder.build()
    }

    /** Creates a PendingIntent that delivers a command to this service. */
    private fun makeServicePendingIntent(action: String, requestCode: Int): PendingIntent {
        val intent = Intent(this, TimerForegroundService::class.java).apply {
            this.action = action
        }
        return PendingIntent.getService(
            this, requestCode, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun updateNotification() {
        getSystemService(NotificationManager::class.java)
            .notify(NOTIFICATION_ID, buildNotification())
    }

    private fun showFinishedNotification() {
        val accentColor = modeColor()
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("\u2705  $title")
            .setContentText("Timer finished! Well done.")
            .setSmallIcon(android.R.drawable.ic_menu_recent_history)
            .setColor(accentColor)
            .setOngoing(false)
            .setAutoCancel(true)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .build()

        getSystemService(NotificationManager::class.java)
            .notify(NOTIFICATION_ID, notification)
    }

    // ─── Flutter callback (best-effort) ─────────────────────────────────

    private fun notifyFlutter(action: String) {
        try {
            Handler(Looper.getMainLooper()).post {
                MainActivity.timerChannel?.invokeMethod(
                    "onServiceAction",
                    mapOf(
                        "action" to action,
                        "remainingMillis" to remainingMillis,
                        "isPaused" to isPaused
                    )
                )
            }
        } catch (_: Exception) { }
    }

    // ─── Formatting ─────────────────────────────────────────────────────

    private fun formatTime(millis: Long): String {
        val totalSec = (millis / 1000).coerceAtLeast(0)
        return String.format("%02d:%02d", totalSec / 60, totalSec % 60)
    }
}
