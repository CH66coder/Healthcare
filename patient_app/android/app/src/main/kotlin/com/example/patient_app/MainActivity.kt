package com.example.patient_app

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.patient_app/sos_widget"
    private var sosLaunch = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Check if launched from SOS widget
        if (intent?.action == "SOS_WIDGET_CLICKED") {
            sosLaunch = true
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (intent.action == "SOS_WIDGET_CLICKED") {
            // App already running — notify Flutter directly
            flutterEngine?.dartExecutor?.binaryMessenger?.let {
                MethodChannel(it, CHANNEL).invokeMethod("launchSOS", null)
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "checkSOSLaunch") {
                    result.success(sosLaunch)
                    sosLaunch = false // reset after reading
                } else {
                    result.notImplemented()
                }
            }
    }
}