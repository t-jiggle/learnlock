package com.tezjmc.learnlock

/**
 * In-process singleton that holds the current screen-time grant so both
 * AppMonitorService and LearnLockAccessibilityService read the same state
 * without needing IPC.
 */
object ScreenTimeState {
    @Volatile var hasScreenTime: Boolean = false
    @Volatile var expiresAt: Long = 0L

    /** Returns true if screen time is currently valid (granted and not expired). */
    fun isActive(): Boolean {
        if (!hasScreenTime) return false
        if (expiresAt > 0L && System.currentTimeMillis() > expiresAt) {
            hasScreenTime = false
            expiresAt = 0L
            return false
        }
        return true
    }

    fun update(hasTime: Boolean, expires: Long) {
        hasScreenTime = hasTime
        expiresAt = expires
    }
}
