package com.sobra.app.sobra_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import java.text.NumberFormat
import java.util.Locale
import kotlin.math.abs

class SobraCompactWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        appWidgetIds.forEach { id ->
            appWidgetManager.updateAppWidget(id, SobraWidgetUpdater.compact(context))
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        appWidgetManager.updateAppWidget(appWidgetId, SobraWidgetUpdater.compact(context))
    }
}

class SobraSummaryWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        appWidgetIds.forEach { id ->
            appWidgetManager.updateAppWidget(id, SobraWidgetUpdater.summary(context))
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        appWidgetManager.updateAppWidget(appWidgetId, SobraWidgetUpdater.summary(context))
    }
}

object SobraWidgetUpdater {
    const val PREFERENCES = "sobra_widget_data"

    private val progressIds = intArrayOf(
        R.id.progress_1,
        R.id.progress_2,
        R.id.progress_3,
        R.id.progress_4,
        R.id.progress_5,
        R.id.progress_6,
        R.id.progress_7,
        R.id.progress_8,
        R.id.progress_9,
        R.id.progress_10,
    )

    fun updateAll(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        val compact = manager.getAppWidgetIds(
            ComponentName(context, SobraCompactWidgetProvider::class.java),
        )
        val summary = manager.getAppWidgetIds(
            ComponentName(context, SobraSummaryWidgetProvider::class.java),
        )
        compact.forEach { manager.updateAppWidget(it, compact(context)) }
        summary.forEach { manager.updateAppWidget(it, summary(context)) }
    }

    fun compact(context: Context): RemoteViews {
        val preferences = preferences(context)
        val hasData = preferences.getBoolean("hasData", false)
        return RemoteViews(context.packageName, R.layout.sobra_widget_compact).apply {
            setTextViewText(
                R.id.today_amount,
                if (hasData) money(preferences.getLong("todayRemainingCentavos", 0L)) else "\$—",
            )
            setTextViewText(
                R.id.days_remaining,
                if (hasData) days(preferences.getInt("daysRemaining", 0)) else "Abre Sobra",
            )
            applyProgress(this, if (hasData) preferences.getInt("progressSegments", 0) else 0)
            applyMotionPreference(this, preferences.getBoolean("reducedMotion", false))
            setOnClickPendingIntent(R.id.widget_root, launch(context, "home", 100))
        }
    }

    fun summary(context: Context): RemoteViews {
        val preferences = preferences(context)
        val hasData = preferences.getBoolean("hasData", false)
        return RemoteViews(context.packageName, R.layout.sobra_widget_summary).apply {
            setTextViewText(
                R.id.today_amount,
                if (hasData) money(preferences.getLong("todayRemainingCentavos", 0L)) else "\$—",
            )
            setTextViewText(
                R.id.days_remaining,
                if (hasData) days(preferences.getInt("daysRemaining", 0)) else "Abre Sobra",
            )
            setTextViewText(
                R.id.total_budget,
                if (hasData) money(preferences.getLong("totalBudgetCentavos", 0L)) else "\$—",
            )
            setTextViewText(
                R.id.total_spent,
                if (hasData) money(preferences.getLong("totalSpentCentavos", 0L)) else "\$—",
            )
            applyProgress(this, if (hasData) preferences.getInt("progressSegments", 0) else 0)
            applyMovement(this, preferences, 1, hasData)
            applyMovement(this, preferences, 2, hasData)
            applyMotionPreference(this, preferences.getBoolean("reducedMotion", false))
            setOnClickPendingIntent(R.id.widget_root, launch(context, "home", 200))
            setOnClickPendingIntent(R.id.register_button, launch(context, "register", 201))
        }
    }

    private fun preferences(context: Context): SharedPreferences =
        context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)

    private fun applyProgress(views: RemoteViews, value: Int) {
        val filled = value.coerceIn(0, progressIds.size)
        progressIds.forEachIndexed { index, id ->
            views.setInt(
                id,
                "setBackgroundResource",
                if (index < filled) R.drawable.widget_progress_filled
                else R.drawable.widget_progress_empty,
            )
        }
    }

    private fun applyMotionPreference(views: RemoteViews, reducedMotion: Boolean) {
        views.setViewVisibility(
            R.id.cat_motion,
            if (reducedMotion) View.GONE else View.VISIBLE,
        )
        views.setViewVisibility(
            R.id.cat_static,
            if (reducedMotion) View.VISIBLE else View.GONE,
        )
    }

    private fun applyMovement(
        views: RemoteViews,
        preferences: SharedPreferences,
        index: Int,
        hasData: Boolean,
    ) {
        val rowId = if (index == 1) R.id.movement_1 else R.id.movement_2
        val titleId = if (index == 1) R.id.movement_1_title else R.id.movement_2_title
        val amountId = if (index == 1) R.id.movement_1_amount else R.id.movement_2_amount
        val iconId = if (index == 1) R.id.movement_1_icon else R.id.movement_2_icon
        val count = if (hasData) preferences.getInt("movementCount", 0) else 0
        if (index > count) {
            views.setViewVisibility(rowId, View.GONE)
            return
        }

        val kind = preferences.getString("movement${index}Kind", "expense") ?: "expense"
        val amount = preferences.getLong("movement${index}AmountCentavos", 0L)
        val (icon, background) = when (kind) {
            "income" -> "+" to R.drawable.widget_icon_income
            "adjustment" -> "=" to R.drawable.widget_icon_adjustment
            "health" -> "+" to R.drawable.widget_icon_health
            else -> "−" to R.drawable.widget_icon_expense
        }
        views.setViewVisibility(rowId, View.VISIBLE)
        views.setTextViewText(titleId, preferences.getString("movement${index}Title", "") ?: "")
        views.setTextViewText(amountId, signedMoney(amount))
        views.setTextViewText(iconId, icon)
        views.setInt(iconId, "setBackgroundResource", background)
    }

    private fun launch(context: Context, destination: String, requestCode: Int): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            putExtra(MainActivity.EXTRA_DESTINATION, destination)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        return PendingIntent.getActivity(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun days(value: Int): String = if (value == 1) "1 día" else "$value días"

    private fun signedMoney(centavos: Long): String = when {
        centavos > 0 -> "+${money(centavos)}"
        centavos < 0 -> "−${money(abs(centavos))}"
        else -> money(0)
    }

    private fun money(centavos: Long): String {
        val negative = centavos < 0
        val absolute = abs(centavos)
        val whole = absolute / 100
        val decimal = absolute % 100
        val grouped = NumberFormat.getIntegerInstance(Locale.US).format(whole)
        val fraction = if (decimal == 0L) "" else ".${decimal.toString().padStart(2, '0')}"
        return "${if (negative) "−" else ""}\$$grouped$fraction"
    }
}
