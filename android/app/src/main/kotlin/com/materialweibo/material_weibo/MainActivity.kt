package com.materialweibo.material_weibo

import android.webkit.CookieManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.materialweibo/cookie"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "getCookie") {
                    val url = call.argument<String>("url")
                    if (url != null) {
                        val cookieManager = CookieManager.getInstance()
                        val cookie = cookieManager.getCookie(url)
                        result.success(cookie)
                    } else {
                        result.error("INVALID_ARGUMENT", "url is required", null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }
}
