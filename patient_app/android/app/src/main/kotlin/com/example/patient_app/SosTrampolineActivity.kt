package com.example.patient_app

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.util.Log

// Transparent activity that launches MainActivity with SOS flag
// then immediately finishes itself
class SosTrampolineActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d("SosWidget", "Trampoline activity fired!")

        // Launch MainActivity with SOS flag
        val intent = Intent(this, MainActivity::class.java).apply {
            action = "SOS_WIDGET_CLICKED"
            putExtra("launch_sos", true)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        startActivity(intent)
        finish() // close immediately
    }
}