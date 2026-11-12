package com.sobra.app.sobra_app

import android.annotation.TargetApi
import android.app.Activity
import android.os.Build
import android.view.View
import android.window.SplashScreenView
import io.flutter.plugin.common.MethodChannel

/** Keeps the same animated system surface visible until the ready Flutter frame. */
@TargetApi(Build.VERSION_CODES.S)
class StartupSplash(private val activity: Activity) {
    private var view: SplashScreenView? = null
    private var snapshot: Map<String, Any?>? = null
    private var pendingSnapshot: MethodChannel.Result? = null
    private var released = false

    fun install() {
        activity.splashScreen.setOnExitAnimationListener { splash ->
            view = splash
            val icon = splash.iconView
            val position = IntArray(2)
            val origin = IntArray(2)
            icon?.getLocationOnScreen(position)
            activity.findViewById<View>(android.R.id.content).getLocationOnScreen(origin)
            val density = activity.resources.displayMetrics.density
            // Android expands the foreground 1.5x; XML insets leave half for the art.
            val size = (icon?.width ?: 0) * .75 / density
            snapshot = if (icon != null && size > 0) mapOf(
                "centerX" to (position[0] - origin[0] + icon.width / 2.0) / density,
                "centerY" to (position[1] - origin[1] + icon.height / 2.0) / density,
                "size" to size,
                "startedAt" to splash.iconAnimationStart?.toEpochMilli(),
            ) else null
            pendingSnapshot?.success(snapshot)
            pendingSnapshot = null
            if (released) remove()
        }
    }

    fun read(result: MethodChannel.Result) {
        if (view != null || released) {
            result.success(snapshot)
        } else {
            pendingSnapshot?.success(null)
            pendingSnapshot = result
        }
    }

    fun release() {
        released = true
        pendingSnapshot?.success(null)
        pendingSnapshot = null
        // Flutter sends this after its destination/error frame has been built.
        // Remove on the following vsync so the surface underneath is ready.
        activity.window.decorView.postOnAnimation { remove() }
    }

    private fun remove() {
        view?.remove()
        view = null
    }

    fun close() {
        pendingSnapshot?.success(null)
        pendingSnapshot = null
        remove()
    }
}
