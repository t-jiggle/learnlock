package com.tezjmc.learnlock

import android.app.*
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat

/**
 * Foreground service that polls the UsageStatsManager every 2 seconds
 * to detect when the child opens a non-LearnLock app without screen time.
 * When blocked, it launches LearningOverlayActivity on top.
 */
class AppMonitorService : Service() {

    companion object {
        const val ACTION_START = "com.tezjmc.learnlock.START_MONITOR"
        const val ACTION_UPDATE_SCREEN_TIME = "com.tezjmc.learnlock.UPDATE_SCREEN_TIME"
        private const val CHANNEL_ID = "learnlock_monitor"
        private const val NOTIFICATION_ID = 1001
        private const val POLL_INTERVAL_MS = 2000L
    }

    private val handler = Handler(Looper.getMainLooper())
    private var hasScreenTime = false
    private var screenTimeExpiresAt = 0L
    private var childId = ""
    private var overlayVisible = false

    private val updateReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == ACTION_UPDATE_SCREEN_TIME) {
                hasScreenTime = intent.getBooleanExtra("hasScreenTime", false)
                screenTimeExpiresAt = intent.getLongExtra("expiresAt", 0L)
            }
        }
    }

    private val pollRunnable = object : Runnable {
        override fun run() {
            checkForegroundApp()
            handler.postDelayed(this, POLL_INTERVAL_MS)
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, buildNotification())
        registerReceiver(updateReceiver, IntentFilter(ACTION_UPDATE_SCREEN_TIME))
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        childId = intent?.getStringExtra("childId") ?: ""
        hasScreenTime = intent?.getBooleanExtra("hasScreenTime", false) ?: false
        screenTimeExpiresAt = intent?.getLongExtra("expiresAt", 0L) ?: 0L
        handler.post(pollRunnable)
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        handler.removeCallbacks(pollRunnable)
        unregisterReceiver(updateReceiver)
        super.onDestroy()
    }

    private fun checkForegroundApp() {
        // Auto-expire screen time
        if (hasScreenTime && screenTimeExpiresAt > 0 &&
            System.currentTimeMillis() > screenTimeExpiresAt) {
            hasScreenTime = false
            screenTimeExpiresAt = 0L
        }

        if (hasScreenTime) {
            // Screen time is valid — dismiss overlay if showing
            if (overlayVisible) dismissOverlay()
            return
        }

        val foreground = getForegroundPackage() ?: return
        if (foreground == packageName || foreground == "android" ||
            foreground.startsWith("com.android.")) {
            // LearnLock or system UI — don't block
            if (overlayVisible) dismissOverlay()
            return
        }

        // Child opened another app without screen time — show overlay
        if (!overlayVisible) showLearningOverlay()
    }

    private fun getForegroundPackage(): String? {
        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val now = System.currentTimeMillis()
        val events = usm.queryEvents(now - 5000, now)
        val event = UsageEvents.Event()
        var lastPackage: String? = null
        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            if (event.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND) {
                lastPackage = event.packageName
            }
        }
        return lastPackage
    }

    private fun showLearningOverlay() {
        overlayVisible = true
        val intent = Intent(this, LearningOverlayActivity::class.java).apply {
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_SINGLE_TOP
            )
        }
        startActivity(intent)
    }

    private fun dismissOverlay() {
        overlayVisible = false
        // Broadcast to overlay activity to close itself
        sendBroadcast(Intent(LearningOverlayActivity.ACTION_DISMISS))
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "LearnLock Monitor",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Keeps LearnLock running in the background"
                setShowBadge(false)
            }
            (getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
                .createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification {
        val pendingIntent = PendingIntent.getActivity(
            this, 0,
            packageManager.getLaunchIntentForPackage(packageName),
            PendingIntent.FLAG_IMMUTABLE
        )
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("LearnLock is active")
            .setContentText("Protecting screen time for your child")
            .setSmallIcon(android.R.drawable.ic_menu_info_details)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .build()
    }
}
