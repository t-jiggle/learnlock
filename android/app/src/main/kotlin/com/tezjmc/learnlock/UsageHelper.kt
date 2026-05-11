package com.tezjmc.learnlock

import android.app.usage.UsageStatsManager
import android.content.Context
import java.util.Calendar

object UsageHelper {
    fun getTodayUsageSeconds(context: Context): Int {
        val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val cal = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val stats = usm.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            cal.timeInMillis,
            System.currentTimeMillis()
        )
        val totalMs = stats
            ?.filter { it.packageName != context.packageName }
            ?.sumOf { it.totalTimeInForeground }
            ?: 0L
        return (totalMs / 1000).toInt()
    }
}
