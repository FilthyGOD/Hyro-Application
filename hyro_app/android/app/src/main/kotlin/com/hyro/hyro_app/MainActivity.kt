package com.hyro.hyro_app

import io.flutter.embedding.android.FlutterFragmentActivity
import android.os.Bundle
import androidx.activity.enableEdgeToEdge

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Habilitar edge-to-edge ANTES de super.onCreate()
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
    }
}

