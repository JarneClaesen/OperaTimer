package com.orchestratimer.orchestra_timer

import android.app.NotificationManager
import android.content.Context
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val dndChannel = "orchestra_timer/dnd"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, dndChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getCurrentInterruptionFilter" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                            result.success(nm.currentInterruptionFilter)
                        } else {
                            // INTERRUPTION_FILTER_ALL on older devices.
                            result.success(1)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
