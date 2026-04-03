package com.example.hospital_assessment_slic

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant
import android.util.Log

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        try {
            // Attempt to register all plugins automatically
            GeneratedPluginRegistrant.registerWith(flutterEngine)
        } catch (t: Throwable) {
            Log.e("MainActivity", "Plugin registration failed, attempting manual recovery", t)
            
            // If the automatic registration fails (e.g., due to FFmpegKit crash),
            // we manually register critical plugins like fluttertoast.
            try {
                flutterEngine.plugins.add(io.github.ponnamkarthik.toast.fluttertoast.FlutterToastPlugin())
            } catch (e: Exception) {
                Log.e("MainActivity", "Manual registration of FlutterToastPlugin failed", e)
            }
        }
    }
}
