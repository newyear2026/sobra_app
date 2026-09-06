package com.sobra.app.sobra_app

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var widgetChannel: MethodChannel? = null

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
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val destination = takePendingDestination() ?: return
        widgetChannel?.invokeMethod("openDestination", destination)
    }

    private fun saveWidgetData(arguments: Map<*, *>) {
        fun number(key: String): Long = (arguments[key] as? Number)?.toLong() ?: 0L
        fun text(key: String): String = arguments[key] as? String ?: ""

        getSharedPreferences(SobraWidgetUpdater.PREFERENCES, MODE_PRIVATE)
            .edit()
            .putBoolean("hasData", arguments["hasData"] as? Boolean ?: false)
            .putLong("todayRemainingCentavos", number("todayRemainingCentavos"))
            .putInt("daysRemaining", number("daysRemaining").toInt())
            .putLong("totalBudgetCentavos", number("totalBudgetCentavos"))
            .putLong("totalSpentCentavos", number("totalSpentCentavos"))
            .putInt("progressSegments", number("progressSegments").toInt())
            .putBoolean("reducedMotion", arguments["reducedMotion"] as? Boolean ?: false)
            .putInt("movementCount", number("movementCount").toInt())
            .putString("movement1Title", text("movement1Title"))
            .putLong("movement1AmountCentavos", number("movement1AmountCentavos"))
            .putString("movement1Kind", text("movement1Kind"))
            .putString("movement2Title", text("movement2Title"))
            .putLong("movement2AmountCentavos", number("movement2AmountCentavos"))
            .putString("movement2Kind", text("movement2Kind"))
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
    }
}
