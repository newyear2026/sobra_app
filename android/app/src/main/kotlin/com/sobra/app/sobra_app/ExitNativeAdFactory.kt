package com.sobra.app.sobra_app

import android.content.Context
import android.util.Log
import android.view.ViewGroup
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin
import io.flutter.plugins.googlemobileads.NativeAdFactory
import io.flutter.plugins.googlemobileads.nativetemplates.FlutterNativeTemplateStyle

/** Keeps video creatives out of the 100dp template, which has no MediaView. */
class ExitNativeAdFactory(
    private val context: Context,
    engine: FlutterEngine,
) : NativeAdFactory {
    private class Request {
        var ad: NativeAd? = null
        var compatible = false
    }

    private val requests = mutableMapOf<String, Request>()
    private val channel = MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)

    init {
        GoogleMobileAdsPlugin.registerNativeAdFactory(engine, FACTORY_ID, this)
        channel.setMethodCallHandler { call, result ->
            val token = call.arguments as? String
            if (token == null) {
                result.error("INVALID_REQUEST", "An exit ad request token is required.", null)
            } else {
                when (call.method) {
                    "prepare" -> {
                        requests.remove(token)?.ad?.destroy()
                        requests[token] = Request()
                        result.success(null)
                    }
                    "isCompatible" -> result.success(requests[token]?.compatible == true)
                    "dispose" -> {
                        requests.remove(token)?.ad?.destroy()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?,
    ): NativeAdView {
        val token = customOptions?.get("requestToken") as? String
        val request = requests[token]
        // The Dart timeout may have disposed this request before SDK completion.
        if (request == null) {
            nativeAd.destroy()
            return NativeAdView(context)
        }
        request.ad = nativeAd
        if (nativeAd.mediaContent?.hasVideoContent() == true) {
            Log.i("SobraExitAds", "Skipped video creative: small template has no MediaView")
            nativeAd.destroy()
            request.ad = null
            return NativeAdView(context)
        }

        val style = customOptions?.get("templateStyle") as? FlutterNativeTemplateStyle
        if (style == null) {
            nativeAd.destroy()
            request.ad = null
            return NativeAdView(context)
        }
        val template = style.asTemplateView(context)
        template.setNativeAd(nativeAd)
        val view = template.nativeAdView
        (view.parent as? ViewGroup)?.removeView(view)
        request.compatible = true
        Log.i("SobraExitAds", "Accepted non-video creative for small template")
        return view
    }

    fun close(engine: FlutterEngine) {
        channel.setMethodCallHandler(null)
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(engine, FACTORY_ID)
        requests.values.forEach { it.ad?.destroy() }
        requests.clear()
    }

    companion object {
        private const val CHANNEL = "com.sobra.app/exit_native_ads"
        private const val FACTORY_ID = "sobra_exit_small"
    }
}
