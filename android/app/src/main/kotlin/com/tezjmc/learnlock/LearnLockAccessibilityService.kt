package com.tezjmc.learnlock

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.view.accessibility.AccessibilityEvent

/**
 * Accessibility service that reacts instantly when a window changes to a
 * non-LearnLock app. Complements AppMonitorService (which polls every 2s)
 * by providing zero-delay interception — the child can't sneak into another
 * app before the overlay appears.
 *
 * Enabled by the parent once via Settings → Accessibility → LearnLock Monitor.
 */
class LearnLockAccessibilityService : AccessibilityService() {

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return

        val pkg = event.packageName?.toString() ?: return

        // Ignore LearnLock itself, system UI, and any launcher
        if (isAllowedPackage(pkg)) return

        if (!ScreenTimeState.isActive()) {
            showLearningOverlay()
        }
    }

    override fun onInterrupt() {}

    private fun isAllowedPackage(pkg: String): Boolean {
        return pkg == packageName ||
            pkg == "android" ||
            pkg.startsWith("com.android.") ||
            // Google system services — NOT user apps like YouTube or Chrome
            pkg == "com.google.android.gms" ||
            pkg == "com.google.android.gsf" ||
            pkg == "com.google.android.permissioncontroller" ||
            pkg == "com.google.android.ext.services" ||
            pkg.contains("launcher", ignoreCase = true) ||
            pkg.contains("systemui", ignoreCase = true)
    }

    private fun showLearningOverlay() {
        val intent = Intent(this, LearningOverlayActivity::class.java).apply {
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_SINGLE_TOP
            )
        }
        startActivity(intent)
    }
}
