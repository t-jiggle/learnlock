package com.tezjmc.learnlock

import android.app.AppOpsManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Process
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channel = "com.tezjmc.learnlock/app_control"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channel
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasUsageStatsPermission" ->
                    result.success(hasUsageStatsPermission())

                "requestUsageStatsPermission" -> {
                    startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                    result.success(null)
                }

                "hasOverlayPermission" ->
                    result.success(
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
                            Settings.canDrawOverlays(this)
                        else true
                    )

                "requestOverlayPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        startActivity(
                            Intent(
                                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                Uri.parse("package:${packageName}")
                            )
                        )
                    }
                    result.success(null)
                }

                "startMonitor" -> {
                    val childId = call.argument<String>("childId") ?: ""
                    val hasScreenTime = call.argument<Boolean>("hasScreenTime") ?: false
                    val expiresAt = call.argument<Long>("expiresAt") ?: 0L
                    ScreenTimeState.update(hasScreenTime, expiresAt)

                    val intent = Intent(this, AppMonitorService::class.java).apply {
                        putExtra("childId", childId)
                        putExtra("hasScreenTime", hasScreenTime)
                        putExtra("expiresAt", expiresAt)
                        action = AppMonitorService.ACTION_START
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
                    result.success(null)
                }

                "stopMonitor" -> {
                    stopService(Intent(this, AppMonitorService::class.java))
                    result.success(null)
                }

                "updateScreenTime" -> {
                    val hasScreenTime = call.argument<Boolean>("hasScreenTime") ?: false
                    val expiresAt = call.argument<Long>("expiresAt") ?: 0L
                    ScreenTimeState.update(hasScreenTime, expiresAt)
                    val intent = Intent(AppMonitorService.ACTION_UPDATE_SCREEN_TIME).apply {
                        putExtra("hasScreenTime", hasScreenTime)
                        putExtra("expiresAt", expiresAt)
                    }
                    sendBroadcast(intent)
                    result.success(null)
                }

                "hasAccessibilityPermission" -> {
                    val enabled = android.provider.Settings.Secure.getString(
                        contentResolver,
                        android.provider.Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
                    ) ?: ""
                    result.success(enabled.contains(packageName))
                }

                "requestAccessibilityPermission" -> {
                    startActivity(Intent(android.provider.Settings.ACTION_ACCESSIBILITY_SETTINGS))
                    result.success(null)
                }

                "getTodayUsageSeconds" -> {
                    result.success(UsageHelper.getTodayUsageSeconds(this))
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }
}
