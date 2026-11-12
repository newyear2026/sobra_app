package com.sobra.app.sobra_app

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.os.Build
import org.json.JSONArray
import org.json.JSONObject

/**
 * The seasonal gift's last-day reminder.
 *
 * Flutter decides whether it is owed and words it; this side keeps the one
 * alarm and posts it. Like [SobraFixedReminders] the plan lives in
 * preferences so a reboot can re-arm it, and the alarm is inexact.
 *
 * It has a channel of its own so that turning gifts off in system settings
 * never silences a rent reminder, and it never asks for notification
 * permission: a phone that has not granted it simply does not get this.
 */
object SobraSeasonalReminder {
    const val CHANNEL_ID = "sobra_news"
    private const val NOTIFICATION_ID = 20261103
    private const val PREFERENCES = "sobra_seasonal_reminder"
    private const val KEY_PLAN = "plan"
    private const val ACTION_FIRE = "com.sobra.app.SEASONAL_REMINDER"
    private const val ICON_SIZE = 192

    /** Replaces the planned reminder with [plan]. */
    fun schedule(context: Context, plan: Map<*, *>) {
        val at = (plan["at"] as? Number)?.toLong() ?: return
        val saved = JSONObject()
            .put("at", at)
            .put("title", plan["title"] as? String ?: "")
            .put("body", plan["body"] as? String ?: "")
            .put("iconAsset", plan["iconAsset"] as? String ?: "")
            .put("iconSource", JSONArray((plan["iconSource"] as? List<*>) ?: emptyList<Any>()))
        preferences(context).edit().putString(KEY_PLAN, saved.toString()).apply()
        arm(context, saved)
    }

    /** Drops the plan, its alarm, and the notification if it is showing. */
    fun cancel(context: Context) {
        preferences(context).edit().remove(KEY_PLAN).apply()
        context.getSystemService(AlarmManager::class.java)?.cancel(alarmIntent(context))
        manager(context).cancel(NOTIFICATION_ID)
    }

    /** Puts the saved alarm back after a reboot or an app update. */
    fun restore(context: Context) {
        saved(context)?.let { arm(context, it) }
    }

    fun fire(context: Context) {
        val plan = saved(context) ?: return
        preferences(context).edit().remove(KEY_PLAN).apply()
        if (!canNotify(context)) return
        post(context, plan)
    }

    private fun canNotify(context: Context): Boolean {
        createChannel(context)
        if (SobraFixedReminders.needsRuntimePermission(context)) return false
        val manager = manager(context)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N && !manager.areNotificationsEnabled()) {
            return false
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = manager.getNotificationChannel(CHANNEL_ID)
            if (channel != null && channel.importance == NotificationManager.IMPORTANCE_NONE) {
                return false
            }
        }
        return true
    }

    private fun arm(context: Context, plan: JSONObject) {
        val at = plan.optLong("at")
        // Missed while the phone was off: the day may be over, so say nothing.
        if (at <= System.currentTimeMillis()) return
        context.getSystemService(AlarmManager::class.java)?.setAndAllowWhileIdle(
            AlarmManager.RTC_WAKEUP,
            at,
            alarmIntent(context),
        )
    }

    private fun post(context: Context, plan: JSONObject) {
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context)
        }
        // Home, where the gift banner sits on top.
        val open = Intent(context, MainActivity::class.java).apply {
            putExtra(MainActivity.EXTRA_DESTINATION, "home")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val body = plan.optString("body")
        builder
            .setSmallIcon(R.drawable.cat_peek_open)
            .setContentTitle(plan.optString("title"))
            .setContentText(body)
            .setStyle(Notification.BigTextStyle().bigText(body))
            .setContentIntent(
                PendingIntent.getActivity(
                    context,
                    NOTIFICATION_ID,
                    open,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                ),
            )
            .setCategory(Notification.CATEGORY_RECOMMENDATION)
            .setColor(0xFF0E7A72.toInt())
            .setAutoCancel(true)
        icon(context, plan)?.let { builder.setLargeIcon(it) }
        manager(context).notify(NOTIFICATION_ID, builder.build())
    }

    /** The companion's costume, cut out of its atlas; none if that fails. */
    private fun icon(context: Context, plan: JSONObject): Bitmap? =
        try {
            val source = plan.getJSONArray("iconSource")
            val atlas = context.assets.open("flutter_assets/${plan.getString("iconAsset")}").use {
                BitmapFactory.decodeStream(it)
            }
            val x = (source.getDouble(0) * atlas.width).toInt()
            val y = (source.getDouble(1) * atlas.height).toInt()
            val width = (source.getDouble(2) * atlas.width).toInt()
                .coerceAtMost(atlas.width - x)
            val height = (source.getDouble(3) * atlas.height).toInt()
                .coerceAtMost(atlas.height - y)
            val frame = Bitmap.createBitmap(atlas, x, y, width, height)
            // Square, frame centered, so Android's circle crop keeps the face.
            val side = maxOf(width, height)
            val square = Bitmap.createBitmap(side, side, Bitmap.Config.ARGB_8888)
            Canvas(square).drawBitmap(
                frame,
                ((side - width) / 2).toFloat(),
                ((side - height) / 2).toFloat(),
                null,
            )
            Bitmap.createScaledBitmap(square, ICON_SIZE, ICON_SIZE, true)
        } catch (error: Exception) {
            null
        }

    private fun alarmIntent(context: Context): PendingIntent =
        PendingIntent.getBroadcast(
            context,
            NOTIFICATION_ID,
            Intent(context, SobraSeasonalReminderReceiver::class.java).apply {
                action = ACTION_FIRE
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

    private fun createChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            context.getString(R.string.news_channel_name),
            NotificationManager.IMPORTANCE_DEFAULT,
        ).apply {
            description = context.getString(R.string.news_channel_description)
            setShowBadge(true)
        }
        manager(context).createNotificationChannel(channel)
    }

    private fun saved(context: Context): JSONObject? =
        try {
            preferences(context).getString(KEY_PLAN, null)?.let(::JSONObject)
        } catch (error: org.json.JSONException) {
            null
        }

    private fun manager(context: Context): NotificationManager =
        context.getSystemService(NotificationManager::class.java)

    private fun preferences(context: Context) =
        context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)

    internal fun isFire(intent: Intent) = intent.action == ACTION_FIRE
}

/** Posts the reminder when its alarm goes off, and re-arms it after boot. */
class SobraSeasonalReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when {
            SobraSeasonalReminder.isFire(intent) -> SobraSeasonalReminder.fire(context)
            intent.action == Intent.ACTION_BOOT_COMPLETED ||
                intent.action == Intent.ACTION_MY_PACKAGE_REPLACED ->
                SobraSeasonalReminder.restore(context)
        }
    }
}
