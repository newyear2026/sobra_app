package com.sobra.app.sobra_app

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var widgetChannel: MethodChannel? = null
    private var pendingQuickEntryResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        widgetChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            WIDGET_CHANNEL,
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "updateWidgets" -> {
                        val arguments = call.arguments as? Map<*, *>
                        if (arguments == null) {
                            result.error("INVALID_PAYLOAD", "Widget data is missing.", null)
                        } else {
                            saveWidgetData(arguments)
                            SobraWidgetUpdater.updateAll(this)
                            result.success(null)
                        }
                    }
                    "getPendingDestination" -> result.success(takePendingDestination())
                    else -> result.notImplemented()
                }
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            QUICK_ENTRY_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getQuickEntryEnabled" -> result.success(
                    SobraQuickEntryNotification.isEnabled(this),
                )
                "setQuickEntryEnabled" -> {
                    val enabled = call.arguments as? Boolean
                    if (enabled == null) {
                        result.error("INVALID_VALUE", "Enabled must be a boolean.", null)
                    } else if (
                        enabled &&
                        Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
                        SobraQuickEntryNotification.needsRuntimePermission(this)
                    ) {
                        if (pendingQuickEntryResult != null) {
                            result.error(
                                "PERMISSION_PENDING",
                                "Notification permission is already being requested.",
                                null,
                            )
                        } else {
                            pendingQuickEntryResult = result
                            requestPermissions(
                                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                                QUICK_ENTRY_PERMISSION_REQUEST,
                            )
                        }
                    } else {
                        result.success(
                            SobraQuickEntryNotification.setEnabled(this, enabled),
                        )
                    }
                }
                "updateQuickEntryCopy" -> {
                    val arguments = call.arguments as? Map<*, *>
                    if (arguments == null) {
                        result.error("INVALID_PAYLOAD", "Quick-entry copy is missing.", null)
                    } else {
                        SobraQuickEntryNotification.updateCopy(this, arguments)
                        result.success(null)
                    }
                }
                else -> result.notImplemented()
            }
        }
        SobraQuickEntryNotification.restore(this)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val destination = takePendingDestination() ?: return
        widgetChannel?.invokeMethod("openDestination", destination)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != QUICK_ENTRY_PERMISSION_REQUEST) return
        val granted = grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED
        val enabled = granted && SobraQuickEntryNotification.setEnabled(this, true)
        pendingQuickEntryResult?.success(enabled)
        pendingQuickEntryResult = null
    }

    private fun saveWidgetData(arguments: Map<*, *>) {
        fun number(key: String): Long = (arguments[key] as? Number)?.toLong() ?: 0L
        fun text(key: String): String = arguments[key] as? String ?: ""

        getSharedPreferences(SobraWidgetUpdater.PREFERENCES, MODE_PRIVATE)
            .edit()
            .putBoolean("hasData", arguments["hasData"] as? Boolean ?: false)
            .putBoolean("hasBudget", arguments["hasBudget"] as? Boolean ?: true)
            .putLong("todayRemainingCentavos", number("todayRemainingCentavos"))
            .putString("todayRemainingText", text("todayRemainingText"))
            .putString("noAmountText", text("noAmountText"))
            .putString("currencyCode", text("currencyCode"))
            .putBoolean("overCycleBudget", arguments["overCycleBudget"] as? Boolean ?: false)
            .putInt("daysRemaining", number("daysRemaining").toInt())
            .putLong("totalBudgetCentavos", number("totalBudgetCentavos"))
            .putLong("totalSpentCentavos", number("totalSpentCentavos"))
            .putInt("progressSegments", number("progressSegments").toInt())
            .putBoolean("reducedMotion", arguments["reducedMotion"] as? Boolean ?: false)
            .putString("characterId", text("characterId"))
            .putInt("movementCount", number("movementCount").toInt())
            .putString("movement1Title", text("movement1Title"))
            .putLong("movement1AmountCentavos", number("movement1AmountCentavos"))
            .putString("movement1Kind", text("movement1Kind"))
            .putString("movement2Title", text("movement2Title"))
            .putLong("movement2AmountCentavos", number("movement2AmountCentavos"))
            .putString("movement2Kind", text("movement2Kind"))
            .putString("todayLeftText", text("todayLeftText"))
            .putString("todayLeftShortText", text("todayLeftShortText"))
            .putString("cycleBalanceText", text("cycleBalanceText"))
            .putString("cycleBalanceShortText", text("cycleBalanceShortText"))
            .putString("cycleProgressText", text("cycleProgressText"))
            .putString("openAppText", text("openAppText"))
            .putString("registerExpenseText", text("registerExpenseText"))
            .putString("daysRemainingText", text("daysRemainingText"))
            .apply()
    }

    private fun takePendingDestination(): String? {
        val destination = intent?.getStringExtra(EXTRA_DESTINATION)
        intent?.removeExtra(EXTRA_DESTINATION)
        return destination
    }

    companion object {
        const val EXTRA_DESTINATION = "sobra_destination"
        private const val WIDGET_CHANNEL = "com.sobra.app/widgets"
        private const val QUICK_ENTRY_CHANNEL = "com.sobra.app/quick_entry"
        private const val QUICK_ENTRY_PERMISSION_REQUEST = 2609
    }
}
