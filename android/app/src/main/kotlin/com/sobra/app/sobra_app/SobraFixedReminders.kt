package com.sobra.app.sobra_app

import android.Manifest
import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import org.json.JSONArray
import org.json.JSONObject

/**
 * Reminders before a fixed expense is due.
 *
 * Flutter plans and words every reminder; this side only keeps the alarms and
 * posts what fires. The plan is kept in preferences so a reboot, which clears
 * every alarm, can put them back without waiting for the app to open.
 *
 * Alarms are inexact on purpose. A bill reminder a few minutes after 9:00 is
 * as good as one at 9:00, and exact alarms need a permission that Google Play
 * reserves for alarm clocks and calendars.
 */
object SobraFixedReminders {
    const val CHANNEL_ID = "sobra_fixed_payments"
    private const val PREFERENCES = "sobra_fixed_reminders"
    private const val KEY_PLAN = "plan"
    private const val ACTION_FIRE = "com.sobra.app.FIXED_REMINDER"
    private const val EXTRA_ID = "id"

    fun needsRuntimePermission(context: Context): Boolean =
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED

    /** Whether a reminder posted now would be seen. */
    fun canNotify(context: Context): Boolean {
        createChannel(context)
        if (needsRuntimePermission(context)) return false
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

    /** Replaces every pending reminder with [plan]. */
    fun schedule(context: Context, plan: List<*>) {
        val reminders = JSONArray()
        for (item in plan) {
            val map = item as? Map<*, *> ?: continue
            val id = (map["id"] as? Number)?.toInt() ?: continue
            val at = (map["at"] as? Number)?.toLong() ?: continue
            reminders.put(
                JSONObject()
                    .put("id", id)
                    .put("at", at)
                    .put("title", map["title"] as? String ?: "")
                    .put("body", map["body"] as? String ?: ""),
            )
        }
        cancelAll(context)
        preferences(context).edit().putString(KEY_PLAN, reminders.toString()).apply()
        arm(context, reminders)
    }

    /** Puts the saved alarms back after a reboot or an app update. */
    fun restore(context: Context) = arm(context, saved(context))

    /** Posts the reminder with [id], if it is still planned. */
    fun fire(context: Context, id: Int) {
        val reminders = saved(context)
        val remaining = JSONArray()
        var due: JSONObject? = null
        for (index in 0 until reminders.length()) {
            val reminder = reminders.getJSONObject(index)
            if (reminder.getInt("id") == id) due = reminder else remaining.put(reminder)
        }
        preferences(context).edit().putString(KEY_PLAN, remaining.toString()).apply()
        if (due == null || !canNotify(context)) return
        post(context, id, due.optString("title"), due.optString("body"))
    }

    private fun arm(context: Context, reminders: JSONArray) {
        val alarms = context.getSystemService(AlarmManager::class.java) ?: return
        val now = System.currentTimeMillis()
        for (index in 0 until reminders.length()) {
            val reminder = reminders.getJSONObject(index)
            val at = reminder.getLong("at")
            // A reminder whose moment passed while the phone was off is
            // dropped rather than fired late in a burst after boot.
            if (at <= now) continue
            alarms.setAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                at,
                alarmIntent(context, reminder.getInt("id")),
            )
        }
    }

    private fun cancelAll(context: Context) {
        val alarms = context.getSystemService(AlarmManager::class.java) ?: return
        val reminders = saved(context)
        for (index in 0 until reminders.length()) {
            alarms.cancel(alarmIntent(context, reminders.getJSONObject(index).getInt("id")))
        }
    }

    private fun post(context: Context, id: Int, title: String, body: String) {
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context)
        }
        val open = Intent(context, MainActivity::class.java).apply {
            putExtra(MainActivity.EXTRA_DESTINATION, "budget")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        builder
            .setSmallIcon(R.drawable.cat_peek_open)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(Notification.BigTextStyle().bigText(body))
            .setContentIntent(
                PendingIntent.getActivity(
                    context,
                    id,
                    open,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                ),
            )
            .setCategory(Notification.CATEGORY_REMINDER)
            .setColor(0xFF0E7A72.toInt())
            .setAutoCancel(true)
        manager(context).notify(id, builder.build())
    }

    private fun alarmIntent(context: Context, id: Int): PendingIntent =
        PendingIntent.getBroadcast(
            context,
            id,
            Intent(context, SobraFixedReminderReceiver::class.java).apply {
                action = ACTION_FIRE
                putExtra(EXTRA_ID, id)
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

    /**
     * The channel's sound and vibration are Android's defaults, set once.
     * After this call creates it the channel belongs to the user: they can
     * silence it from system settings without touching quick entry, which
     * lives on its own silent channel.
     */
    private fun createChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            context.getString(R.string.fixed_channel_name),
            NotificationManager.IMPORTANCE_DEFAULT,
        ).apply {
            description = context.getString(R.string.fixed_channel_description)
            enableVibration(true)
            setShowBadge(true)
        }
        manager(context).createNotificationChannel(channel)
    }

    private fun saved(context: Context): JSONArray =
        try {
            JSONArray(preferences(context).getString(KEY_PLAN, "[]"))
        } catch (error: org.json.JSONException) {
            JSONArray()
        }

    private fun manager(context: Context): NotificationManager =
        context.getSystemService(NotificationManager::class.java)

    private fun preferences(context: Context) =
        context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)

    internal fun isFire(intent: Intent) = intent.action == ACTION_FIRE

    internal fun idOf(intent: Intent) = intent.getIntExtra(EXTRA_ID, -1)
}

/** Posts a reminder when its alarm goes off, and re-arms them after boot. */
class SobraFixedReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when {
            SobraFixedReminders.isFire(intent) ->
                SobraFixedReminders.fire(context, SobraFixedReminders.idOf(intent))
            intent.action == Intent.ACTION_BOOT_COMPLETED ||
                intent.action == Intent.ACTION_MY_PACKAGE_REPLACED ->
                SobraFixedReminders.restore(context)
        }
    }
}
