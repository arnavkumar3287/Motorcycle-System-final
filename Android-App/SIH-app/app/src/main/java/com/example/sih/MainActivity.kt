package com.example.sih

import android.content.res.AssetFileDescriptor
import android.os.Bundle
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import org.tensorflow.lite.Interpreter
import java.io.FileInputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.channels.FileChannel

class MainActivity : AppCompatActivity() {

    private lateinit var tfliteInterpreter: Interpreter
    private lateinit var txtShiftCue: TextView
    private lateinit var txtRPM: TextView
    private lateinit var txtGear: TextView
    private lateinit var txtLoad: TextView
    private lateinit var txtTargetRPM: TextView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        txtShiftCue = findViewById(R.id.txtShiftCue)
        txtRPM = findViewById(R.id.txtRPM)
        txtGear = findViewById(R.id.txtGear)
        txtLoad = findViewById(R.id.txtLoad)
        txtTargetRPM = findViewById(R.id.txtTargetRPM)

        // 1. Initialize TFLite Model from Assets
        try {
            tfliteInterpreter = Interpreter(loadModelFile())
        } catch (e: Exception) {
            e.printStackTrace()
            txtShiftCue.text = "Model Load Error"
        }

        // 2. Simulate incoming real-time telemetry frame (Test Execution)
        // In production, these variables will ingest live data packets from your ELM327 Bluetooth service
        val currentEngineLoad = 65.0f  // %
        val currentThrottle = 45.0f    // %
        val roadIncline = 2.0f         // degrees
        val currentGear = 3.0f         // gear position
        val currentRpm = 5800.0f       // RPM

        processTelemetryFrame(currentEngineLoad, currentThrottle, roadIncline, currentGear, currentRpm)
    }

    private fun loadModelFile(): ByteBuffer {
        val fileDescriptor: AssetFileDescriptor = assets.openFd("cep_shift_model.tflite")
        val inputStream = FileInputStream(fileDescriptor.fileDescriptor)
        val fileChannel = inputStream.channel
        val startOffset = fileDescriptor.startOffset
        val declaredLength = fileDescriptor.declaredLength
        return fileChannel.map(FileChannel.MapMode.READ_ONLY, startOffset, declaredLength)
    }

    private fun processTelemetryFrame(load: Float, throttle: Float, incline: Float, gear: Float, rpm: Float) {
        // Prepare input array matching model shape [1, 4]
        val inputArray = arrayOf(floatArrayOf(load, throttle, incline, gear))
        val outputArray = Array(1) { FloatArray(1) }

        // Run local model inference
        tfliteInterpreter.run(inputArray, outputArray)
        val predictedOptimalRpm = outputArray[0][0]

        // Apply 250 RPM hysteresis buffer logic
        val hudSignal = evaluateHysteresisBuffer(rpm, predictedOptimalRpm, gear.toInt(), load)

        // Update UI Dashboard Cues
        txtRPM.text = "RPM: ${rpm.toInt()}"
        txtGear.text = "GEAR: ${gear.toInt()}"
        txtLoad.text = "${load.toInt()}%"
        txtTargetRPM.text = "${predictedOptimalRpm.toInt()} RPM"

        when (hudSignal) {
            1 -> {
                txtShiftCue.text = "🔼 SHIFT UP"
                txtShiftCue.setTextColor(android.graphics.Color.parseColor("#00FF66")) // Green
            }
            -1 -> {
                txtShiftCue.text = "🔽 SHIFT DOWN"
                txtShiftCue.setTextColor(android.graphics.Color.parseColor("#FF3333")) // Red
            }
            else -> {
                txtShiftCue.text = "🟢 HOLD GEAR"
                txtShiftCue.setTextColor(android.graphics.Color.parseColor("#3399FF")) // Blue
            }
        }
    }

    private fun evaluateHysteresisBuffer(currentRpm: Float, optimalRpm: Float, gear: Int, load: Float): Int {
        val bufferRpm = 250.0f

        // 1. Upshift: Current RPM exceeds the AI's dynamic target
        return if (currentRpm > (optimalRpm + bufferRpm) && gear < 6) {
            1
            // 2. Downshift: Engine is lugging (Low RPM under heavy mechanical load)
        } else if (currentRpm < 2500.0f && load > 50.0f && gear > 1) {
            -1
            // 3. Hold Gear: Cruising or accelerating toward the optimal shift point
        } else {
            0
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        if (::tfliteInterpreter.isInitialized) {
            tfliteInterpreter.close()
        }
    }
}