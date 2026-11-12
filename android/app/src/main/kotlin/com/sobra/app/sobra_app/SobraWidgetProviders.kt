package com.sobra.app.sobra_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Rect
import android.graphics.RectF
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import java.text.NumberFormat
import java.util.Locale
import kotlin.math.abs
import org.json.JSONObject

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
        // Absent from every payload written before the budget could be left
        // unanswered, and those users had answered it.
        val hasBudget = preferences.getBoolean("hasBudget", true)
        // The day's room is a slice of the budget. With no budget there is no
        // slice, and a confident "0" would read as a day already spent.
        val showsMoney = hasData && hasBudget
        return RemoteViews(context.packageName, R.layout.sobra_widget_compact).apply {
            setTextViewText(
                R.id.today_label,
                if (hasData && hasBudget) todayLabel(context, preferences, short = true)
                else openApp(context, preferences),
            )
            setTextViewText(
                R.id.today_amount,
                if (showsMoney) todayAmount(preferences) else noAmount(preferences),
            )
            setTextViewText(R.id.currency_code, currencyCode(preferences))
            setViewVisibility(R.id.currency_code, if (showsMoney) View.VISIBLE else View.GONE)
            applyCharacter(context, this, preferences.getString("characterId", null), summary = false)
            applyMotionPreference(this, preferences.getBoolean("reducedMotion", false))
            setOnClickPendingIntent(R.id.widget_root, launch(context, "home", 100))
        }
    }

    fun summary(context: Context): RemoteViews {
        val preferences = preferences(context)
        val hasData = preferences.getBoolean("hasData", false)
        // Absent from every payload written before the budget could be left
        // unanswered, and those users had answered it.
        val hasBudget = preferences.getBoolean("hasBudget", true)
        // The day's room is a slice of the budget. With no budget there is no
        // slice, and a confident "0" would read as a day already spent.
        val showsMoney = hasData && hasBudget
        val overCycleBudget = showsMoney &&
            preferences.getBoolean("overCycleBudget", false)
        return RemoteViews(context.packageName, R.layout.sobra_widget_summary).apply {
            setTextViewText(R.id.today_label, todayLabel(context, preferences))
            setTextViewText(
                R.id.today_amount,
                if (showsMoney) todayAmount(preferences) else noAmount(preferences),
            )
            setTextViewText(R.id.currency_code, currencyCode(preferences))
            setViewVisibility(R.id.currency_code, if (showsMoney) View.VISIBLE else View.GONE)
            setTextViewText(
                R.id.cycle_progress_label,
                copy(preferences, "cycleProgressText")
                    ?: context.getString(R.string.widget_cycle_progress),
            )
            setTextViewText(
                R.id.days_remaining,
                if (hasData) days(context, preferences) else openApp(context, preferences),
            )
            applyProgress(
                this,
                if (showsMoney) preferences.getInt("progressSegments", 0) else 0,
                danger = overCycleBudget,
            )
            applyCharacter(context, this, preferences.getString("characterId", null), summary = true)
            applyMotionPreference(this, preferences.getBoolean("reducedMotion", false))
            val register = copy(preferences, "registerExpenseText")
                ?: context.getString(R.string.widget_register_expense)
            setTextViewText(R.id.register_button, "+  $register")
            setContentDescription(R.id.register_button, register)
            setOnClickPendingIntent(R.id.widget_root, launch(context, "home", 200))
            setOnClickPendingIntent(R.id.register_button, launch(context, "register", 201))
        }
    }

    private fun preferences(context: Context): SharedPreferences =
        context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)

    private fun applyProgress(
        views: RemoteViews,
        value: Int,
        danger: Boolean,
    ) {
        val filled = value.coerceIn(0, progressIds.size)
        progressIds.forEachIndexed { index, id ->
            views.setInt(
                id,
                "setBackgroundResource",
                when {
                    index >= filled -> R.drawable.widget_progress_empty
                    danger -> R.drawable.widget_progress_danger
                    else -> R.drawable.widget_progress_filled
                },
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

    private fun applyCharacter(
        context: Context,
        views: RemoteViews,
        characterId: String?,
        summary: Boolean,
    ) {
        if (applyCostume(context, views, characterId, summary)) return
        // The native widget cannot load Flutter's sprite sheets. These four
        // frames are exported from each character's idle sheet by
        // tool/export_android_widget_characters.py.
        val frames = when (characterId) {
            "poodle" -> intArrayOf(
                R.drawable.widget_poodle_1, R.drawable.widget_poodle_2,
                R.drawable.widget_poodle_3, R.drawable.widget_poodle_4,
            )
            "schnauzer" -> intArrayOf(
                R.drawable.widget_schnauzer_1, R.drawable.widget_schnauzer_2,
                R.drawable.widget_schnauzer_3, R.drawable.widget_schnauzer_4,
            )
            "guinea-pig" -> intArrayOf(
                R.drawable.widget_guinea_pig_1, R.drawable.widget_guinea_pig_2,
                R.drawable.widget_guinea_pig_3, R.drawable.widget_guinea_pig_4,
            )
            else -> if (summary) intArrayOf(
                R.drawable.cat_saving_original_high,
                R.drawable.cat_saving_original_mid,
                R.drawable.cat_saving_original_drop,
                R.drawable.cat_saving_original_done,
                R.drawable.cat_saving_original_done,
            ) else intArrayOf(
                R.drawable.widget_michi_1, R.drawable.widget_michi_2,
                R.drawable.widget_michi_3, R.drawable.widget_michi_4,
            )
        }
        val frameIds = intArrayOf(
            R.id.character_frame_1, R.id.character_frame_2,
            R.id.character_frame_3, R.id.character_frame_4,
        )
        val description = context.getString(when (characterId) {
            "poodle" -> R.string.widget_poodle_description
            "schnauzer" -> R.string.widget_schnauzer_description
            "guinea-pig" -> R.string.widget_guinea_pig_description
            else -> R.string.widget_cat_description
        })
        frameIds.forEachIndexed { index, id ->
            views.setImageViewResource(id, frames[index])
            views.setContentDescription(id, description)
        }
        if (summary) {
            views.setImageViewResource(
                R.id.character_frame_5,
                if (frames.size == 5) frames[4] else frames[0],
            )
            views.setContentDescription(R.id.character_frame_5, description)
        }
        val staticFrame = if (characterId == null || characterId == "michi") {
            if (summary) frames.last() else frames.first()
        } else {
            frames.first()
        }
        views.setImageViewResource(R.id.cat_static, staticFrame)
        views.setContentDescription(R.id.cat_static, description)
    }

    // Read the same bundled atlas and crop metadata Flutter uses. No duplicate
    // full-resolution Android resources, and the binder receives only small
    // rendered frames. A failed/unknown pack falls back to the base companion.
    private var costumeLayouts: JSONObject? = null

    private fun applyCostume(
        context: Context,
        views: RemoteViews,
        characterId: String?,
        summary: Boolean,
    ): Boolean {
        if (characterId == null) return false
        val preferences = preferences(context)
        if (preferences.getString("costumeId", "") != "autumn-2026-$characterId") {
            return false
        }
        return try {
            val layouts = costumeLayouts ?: context.assets.open(
                "flutter_assets/assets/costumes/autumn_2026/motion_v2/layout.json",
            ).bufferedReader().use { JSONObject(it.readText()) }.also { costumeLayouts = it }
            val layout = layouts.optJSONObject(characterId)
                ?.optJSONObject(if (summary) "positive" else "idle") ?: return false
            val poses = layout.getJSONArray("sources")
            val targets = layout.getJSONArray("targets")
            val options = BitmapFactory.Options().apply { inSampleSize = 2 }
            val source = context.assets.open(
                "flutter_assets/${layout.getString("asset")}",
            ).use { BitmapFactory.decodeStream(it, null, options) } ?: return false
            // Sample actual drawn motion, including eyelids and paws. The
            // native widget no longer stretches a single stationary pose.
            val indices = if (summary) intArrayOf(0, 3, 6, 9, 11)
                else intArrayOf(0, 3, 5, 7)
            val frames = indices.map { index ->
                val pose = poses.getJSONArray(index)
                val target = targets.getJSONArray(index)
                val src = Rect(
                    (pose.getDouble(0) * source.width).toInt().coerceIn(0, source.width - 1),
                    (pose.getDouble(1) * source.height).toInt().coerceIn(0, source.height - 1),
                    ((pose.getDouble(0) + pose.getDouble(2)) * source.width).toInt().coerceIn(1, source.width),
                    ((pose.getDouble(1) + pose.getDouble(3)) * source.height).toInt().coerceIn(1, source.height),
                )
                Bitmap.createBitmap(128, 144, Bitmap.Config.ARGB_8888).also { bitmap ->
                    Canvas(bitmap).drawBitmap(
                        source, src,
                        RectF(
                            target.getDouble(0).toFloat() * .4f,
                            target.getDouble(1).toFloat() * .4f,
                            (target.getDouble(0) + target.getDouble(2)).toFloat() * .4f,
                            (target.getDouble(1) + target.getDouble(3)).toFloat() * .4f,
                        ),
                        Paint().apply { isFilterBitmap = false },
                    )
                }
            }
            source.recycle()
            val description = preferences.getString("characterDescription", null)
                ?.takeIf { it.isNotBlank() } ?: characterId
            val ids = intArrayOf(
                R.id.character_frame_1, R.id.character_frame_2,
                R.id.character_frame_3, R.id.character_frame_4,
            )
            ids.forEachIndexed { index, id ->
                views.setImageViewBitmap(id, frames[index])
                views.setContentDescription(id, description)
            }
            if (summary) {
                views.setImageViewBitmap(R.id.character_frame_5, frames.last())
                views.setContentDescription(R.id.character_frame_5, description)
            }
            views.setImageViewBitmap(R.id.cat_static, frames.first())
            views.setContentDescription(R.id.cat_static, description)
            true
        } catch (_: Exception) {
            false
        }
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

    /**
     * A word the app wrote in the language chosen in Ajustes, or null before
     * the app has run once, when the caller falls back to the resource string,
     * which follows the phone instead.
     */
    private fun copy(preferences: SharedPreferences, key: String): String? =
        preferences.getString(key, null)?.takeIf { it.isNotEmpty() }

    // Over budget the figure is the cycle's deficit, not the day's room.
    private fun todayLabel(
        context: Context,
        preferences: SharedPreferences,
        short: Boolean = false,
    ): String {
        val overCycleBudget = preferences.getBoolean("hasData", false) &&
            preferences.getBoolean("hasBudget", true) &&
            preferences.getBoolean("overCycleBudget", false)
        return if (overCycleBudget && short) {
            copy(preferences, "cycleBalanceShortText")
                ?: context.getString(R.string.widget_cycle_balance_short)
        } else if (overCycleBudget) {
            copy(preferences, "cycleBalanceText")
                ?: context.getString(R.string.widget_cycle_balance)
        } else if (short) {
            copy(preferences, "todayLeftShortText")
                ?: context.getString(R.string.widget_today_remaining_short)
        } else {
            copy(preferences, "todayLeftText")
                ?: context.getString(R.string.widget_today_remaining)
        }
    }

    private fun openApp(context: Context, preferences: SharedPreferences): String =
        copy(preferences, "openAppText") ?: context.getString(R.string.widget_open_app)

    private fun days(context: Context, preferences: SharedPreferences): String {
        val count = preferences.getInt("daysRemaining", 0)
        return copy(preferences, "daysRemainingText")
            ?: context.resources.getQuantityString(R.plurals.widget_days, count, count)
    }

    // The app writes the figure in the user's currency, sign and separators
    // included. Only a payload saved before it did falls back to the old
    // Mexican-peso rendering, until the app next opens and re-sends.
    private fun todayAmount(preferences: SharedPreferences): String =
        preferences.getString("todayRemainingText", null)?.takeIf { it.isNotEmpty() }
            ?: money(preferences.getLong("todayRemainingCentavos", 0L))

    private fun noAmount(preferences: SharedPreferences): String =
        preferences.getString("noAmountText", null)?.takeIf { it.isNotEmpty() } ?: "\$—"

    private fun currencyCode(preferences: SharedPreferences): String =
        preferences.getString("currencyCode", null)?.takeIf { it.isNotEmpty() } ?: "MXN"

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
