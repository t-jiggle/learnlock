package com.tezjmc.learnlock

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Bundle
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat

/**
 * Full-screen activity shown on top of other apps when the child
 * attempts to use a blocked app without having completed their learning.
 * Launched by AppMonitorService; dismissed when screen time is granted.
 */
class LearningOverlayActivity : AppCompatActivity() {

    companion object {
        const val ACTION_DISMISS = "com.tezjmc.learnlock.DISMISS_OVERLAY"
    }

    private val dismissReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == ACTION_DISMISS) finish()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Keep screen on and show over lock screen
        window.addFlags(
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
        )

        setContentView(buildOverlayView())
        registerReceiver(dismissReceiver, IntentFilter(ACTION_DISMISS))
    }

    override fun onDestroy() {
        unregisterReceiver(dismissReceiver)
        super.onDestroy()
    }

    // Block back button so child can't dismiss
    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        // intentionally blocked
    }

    private fun buildOverlayView(): View {
        // Build the overlay UI programmatically so we don't need an extra layout file
        val ctx = this
        return android.widget.LinearLayout(ctx).apply {
            orientation = android.widget.LinearLayout.VERTICAL
            gravity = android.view.Gravity.CENTER
            setBackgroundColor(android.graphics.Color.parseColor("#F0EEFF"))
            setPadding(64, 64, 64, 64)

            addView(TextView(ctx).apply {
                text = "🎓"
                textSize = 72f
                gravity = android.view.Gravity.CENTER
            })

            addView(TextView(ctx).apply {
                text = "Time to Learn First!"
                textSize = 28f
                setTextColor(android.graphics.Color.parseColor("#1A1040"))
                gravity = android.view.Gravity.CENTER
                typeface = android.graphics.Typeface.DEFAULT_BOLD
                setPadding(0, 32, 0, 16)
            })

            addView(TextView(ctx).apply {
                text = "Complete your learning session to unlock screen time.\nYou can do it! 🌟"
                textSize = 18f
                setTextColor(android.graphics.Color.parseColor("#6B6080"))
                gravity = android.view.Gravity.CENTER
                setPadding(0, 0, 0, 48)
            })

            addView(Button(ctx).apply {
                text = "Start Learning! →"
                textSize = 18f
                setTextColor(android.graphics.Color.WHITE)
                setBackgroundColor(android.graphics.Color.parseColor("#6C63FF"))
                setPadding(64, 32, 64, 32)
                setOnClickListener {
                    // Launch LearnLock main activity
                    val intent = ctx.packageManager.getLaunchIntentForPackage(ctx.packageName)
                    intent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                    intent?.let { ctx.startActivity(it) }
                    finish()
                }
            })
        }
    }
}
