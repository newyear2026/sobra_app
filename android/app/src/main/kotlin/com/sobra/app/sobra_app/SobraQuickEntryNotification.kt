package com.sobra.app.sobra_app

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Rect
import android.graphics.Typeface
import android.os.Build
import android.util.TypedValue
import android.widget.RemoteViews
import kotlin.math.ceil
import kotlin.math.roundToInt

/** The opt-in notification that keeps Income and Expense one tap away. */
object SobraQuickEntryNotification {
    private const val CHANNEL_ID = "sobra_quick_entry"
    private const val NOTIFICATION_ID = 260911
    private const val PREFERENCES = "sobra_quick_entry"
    private const val KEY_ENABLED = "enabled"
    private const val KEY_QUESTION = "question"
    private const val KEY_INCOME = "income"
    private const val KEY_EXPENSE = "expense"
    private const val LABEL_COLOR = 0xFFFFF8E8.toInt()
    private const val INCOME_INK = 0xFF0B6660.toInt()
    private const val EXPENSE_INK = 0xFFA63A25.toInt()
    private const val HANGUL_FONT_ASSET = "flutter_assets/assets/fonts/SobraHangul-Bold.ttf"

    fun needsRuntimePermission(context: Context): Boolean =
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED

    fun isEnabled(context: Context): Boolean {
        createChannel(context)
        return preferences(context).getBoolean(KEY_ENABLED, false) && canPost(context)
    }

    /** Returns the resulting enabled state, not whether the call succeeded. */
    fun setEnabled(context: Context, enabled: Boolean): Boolean {
        if (!enabled) {
            preferences(context).edit().putBoolean(KEY_ENABLED, false).apply()
            manager(context).cancel(NOTIFICATION_ID)
            return false
        }

        createChannel(context)
        if (!canPost(context)) {
            preferences(context).edit().putBoolean(KEY_ENABLED, false).apply()
            manager(context).cancel(NOTIFICATION_ID)
            return false
        }

        preferences(context).edit().putBoolean(KEY_ENABLED, true).apply()
        show(context)
        return true
    }

    fun updateCopy(context: Context, arguments: Map<*, *>) {
        fun text(key: String, fallback: Int): String =
            (arguments[key] as? String)?.takeIf { it.isNotBlank() }
                ?: context.getString(fallback)

        preferences(context).edit()
            .putString(KEY_QUESTION, text(KEY_QUESTION, R.string.quick_entry_question))
            .putString(KEY_INCOME, text(KEY_INCOME, R.string.quick_entry_income))
            .putString(KEY_EXPENSE, text(KEY_EXPENSE, R.string.quick_entry_expense))
            .apply()

        if (isEnabled(context)) show(context)
    }

    fun restore(context: Context) {
        if (isEnabled(context)) show(context)
    }

    private fun show(context: Context) {
        if (!preferences(context).getBoolean(KEY_ENABLED, false) || !canPost(context)) return
        val copy = preferences(context)
        val question = copy.getString(
            KEY_QUESTION,
            context.getString(R.string.quick_entry_question),
        )!!
        val income = copy.getString(
            KEY_INCOME,
            context.getString(R.string.quick_entry_income),
        )!!
        val expense = copy.getString(
            KEY_EXPENSE,
            context.getString(R.string.quick_entry_expense),
        )!!

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context)
        }

        builder
            // Android owns this small, monochrome status/header mark, and the
            // lock screen adds the launcher icon itself, so our content view
            // carries no artwork of its own.
            .setSmallIcon(R.drawable.cat_peek_open)
            .setContentTitle(context.getString(R.string.app_name))
            .setContentText(question)
            .setContentIntent(destination(context, "home", 300))
            .setCategory(Notification.CATEGORY_REMINDER)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setColor(0xFF0E7A72.toInt())
            .setShowWhen(false)
            .setOnlyAlertOnce(true)
            .setOngoing(true)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            // A custom content area is the only part of a lock-screen
            // notification an application can art-direct. Android still owns
            // the outer card, app header and accessibility affordances.
            builder
                .setStyle(Notification.DecoratedCustomViewStyle())
                .setCustomContentView(
                    collapsedView(context, income, expense),
                )
                .setCustomBigContentView(
                    expandedView(context, question, income, expense),
                )
        } else {
            // Older Android releases do not consistently decorate custom
            // layouts, so the native template is the safer readable fallback.
            builder
                .setLargeIcon(
                    BitmapFactory.decodeResource(
                        context.resources,
                        R.mipmap.ic_launcher,
                    ),
                )
                .setStyle(Notification.BigTextStyle().bigText(question))
                .addAction(action(context, "＋ $income", "register_income", 301))
                .addAction(action(context, "－ $expense", "register_expense", 302))
        }

        manager(context).notify(NOTIFICATION_ID, builder.build())
    }

    private fun collapsedView(
        context: Context,
        income: String,
        expense: String,
    ): RemoteViews =
        RemoteViews(context.packageName, R.layout.notification_quick_entry_collapsed).apply {
            setImageViewBitmap(
                R.id.quick_entry_income_label,
                pixelLabel(context, income, 16f, INCOME_INK),
            )
            setImageViewBitmap(
                R.id.quick_entry_expense_label,
                pixelLabel(context, expense, 16f, EXPENSE_INK),
            )
            setContentDescription(R.id.quick_entry_income, income)
            setContentDescription(R.id.quick_entry_expense, expense)
            setOnClickPendingIntent(
                R.id.quick_entry_root,
                destination(context, "home", 303),
            )
            setOnClickPendingIntent(
                R.id.quick_entry_income,
                destination(context, "register_income", 307),
            )
            setOnClickPendingIntent(
                R.id.quick_entry_expense,
                destination(context, "register_expense", 308),
            )
        }

    private fun expandedView(
        context: Context,
        question: String,
        income: String,
        expense: String,
    ): RemoteViews =
        RemoteViews(context.packageName, R.layout.notification_quick_entry_expanded).apply {
            setTextViewText(R.id.quick_entry_question, question)
            setImageViewBitmap(
                R.id.quick_entry_income_label,
                pixelLabel(context, income, 18f, INCOME_INK),
            )
            setImageViewBitmap(
                R.id.quick_entry_expense_label,
                pixelLabel(context, expense, 18f, EXPENSE_INK),
            )
            setContentDescription(R.id.quick_entry_income, income)
            setContentDescription(R.id.quick_entry_expense, expense)
            setOnClickPendingIntent(
                R.id.quick_entry_root,
                destination(context, "home", 304),
            )
            setOnClickPendingIntent(
                R.id.quick_entry_income,
                destination(context, "register_income", 305),
            )
            setOnClickPendingIntent(
                R.id.quick_entry_expense,
                destination(context, "register_expense", 306),
            )
        }

    /**
     * SystemUI inflates our layout with its own fonts, so an app font set on a
     * TextView is ignored. Drawing the label here keeps the pixel face; the
     * button's content description still carries the text for TalkBack.
     */
    private fun pixelLabel(
        context: Context,
        label: String,
        sizeSp: Float,
        shadowColor: Int,
    ): Bitmap {
        val metrics = context.resources.displayMetrics
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            textSize = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_SP, sizeSp, metrics)
            typeface = labelTypeface(context, label)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && typeface != Typeface.DEFAULT_BOLD) {
                fontVariationSettings = "'wght' 700"
            }
        }
        // Centre the cap height rather than the ink, so "Expense" (with its
        // descender) sits on the same line as "Income" beside the glyph.
        fun bounds(text: String) = Rect().also { paint.getTextBounds(text, 0, text.length, it) }
        val cap = -bounds(if (hangul(label)) "가" else "H").top
        val descent = bounds("gjpqy").bottom.coerceAtLeast(0)
        val shadow = metrics.density.roundToInt().coerceAtLeast(1)
        val bitmap = Bitmap.createBitmap(
            (ceil(paint.measureText(label)).toInt() + shadow).coerceAtLeast(1),
            (cap + 2 * descent + shadow).coerceAtLeast(1),
            Bitmap.Config.ARGB_8888,
        )
        bitmap.density = metrics.densityDpi
        val baseline = (descent + cap).toFloat()
        Canvas(bitmap).apply {
            paint.color = shadowColor
            drawText(label, shadow.toFloat(), baseline + shadow, paint)
            paint.color = LABEL_COLOR
            drawText(label, 0f, baseline, paint)
        }
        return bitmap
    }

    /** Pixelify has no Hangul, so Korean copy borrows the app's own pixel face. */
    private fun labelTypeface(context: Context, label: String): Typeface =
        runCatching {
            if (hangul(label)) {
                Typeface.createFromAsset(context.assets, HANGUL_FONT_ASSET)
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.resources.getFont(R.font.pixelify_sans)
            } else {
                null
            }
        }.getOrNull() ?: Typeface.DEFAULT_BOLD

    private fun hangul(text: String): Boolean = text.any { it in '\uAC00'..'\uD7A3' }

    private fun action(
        context: Context,
        title: String,
        destination: String,
        requestCode: Int,
    ): Notification.Action {
        val builder = Notification.Action.Builder(
            0,
            title,
            destination(context, destination, requestCode),
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            builder.setAuthenticationRequired(true)
        }
        return builder.build()
    }

    private fun destination(
        context: Context,
        destination: String,
        requestCode: Int,
    ): PendingIntent {
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

    private fun createChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            context.getString(R.string.quick_entry_channel_name),
            NotificationManager.IMPORTANCE_DEFAULT,
        ).apply {
            description = context.getString(R.string.quick_entry_channel_description)
            enableVibration(false)
            setSound(null, null)
            setShowBadge(false)
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
        }
        manager(context).createNotificationChannel(channel)
    }

    private fun canPost(context: Context): Boolean {
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

    private fun manager(context: Context): NotificationManager =
        context.getSystemService(NotificationManager::class.java)

    private fun preferences(context: Context) =
        context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
}

/** Restores the opted-in shortcut after a reboot or application update. */
class SobraQuickEntryReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (
            intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == Intent.ACTION_MY_PACKAGE_REPLACED
        ) {
            SobraQuickEntryNotification.restore(context)
        }
    }
}
