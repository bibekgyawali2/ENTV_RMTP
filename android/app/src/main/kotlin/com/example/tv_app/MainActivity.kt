package com.example.tv_app

import android.content.Context
import android.media.AudioManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.tv_app/audio"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            if (call.method == "setMicrophoneMute") {
                val mute = call.argument<Boolean>("mute") ?: false
                audioManager.isMicrophoneMute = mute
                result.success(null)
            } else if (call.method == "isMicrophoneMute") {
                result.success(audioManager.isMicrophoneMute)
            } else {
                result.notImplemented()
            }
        }
    }
}
