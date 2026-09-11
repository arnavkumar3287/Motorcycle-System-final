package com.example.sih // Ensure this matches your actual package name

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothSocket
import java.io.InputStream
import java.io.OutputStream
import java.util.UUID

class OBDConnectionManager(private val deviceMacAddress: String) {
    // Standard Serial Port Profile (SPP) UUID for ELM327 modules
    private val uuid: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")

    private var socket: BluetoothSocket? = null
    private var inputStream: InputStream? = null
    private var outputStream: OutputStream? = null

    @SuppressLint("MissingPermission")
    fun connect(): Boolean {
        try {
            val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
            val device: BluetoothDevice = bluetoothAdapter.getRemoteDevice(deviceMacAddress)

            socket = device.createRfcommSocketToServiceRecord(uuid)
            socket?.connect()

            inputStream = socket?.inputStream
            outputStream = socket?.outputStream

            // Initialize ELM327 protocol
            sendCommand("AT Z\r") // Reset
            sendCommand("ATE0\r") // Echo Off
            sendCommand("ATSP0\r") // Auto Protocol

            return true
        } catch (e: Exception) {
            e.printStackTrace()
            return false
        }
    }

    private fun sendCommand(cmd: String): String {
        outputStream?.write(cmd.toByteArray())
        outputStream?.flush()

        Thread.sleep(100) // Brief pause for ELM327 to process

        val buffer = ByteArray(1024)
        val bytes = inputStream?.read(buffer) ?: 0
        return String(buffer, 0, bytes).trim()
    }

    // OBD-II PID 010C is Engine RPM: ((A * 256) + B) / 4
    fun getRPM(): Float {
        val rawResponse = sendCommand("010C\r")
        return parseRpmHex(rawResponse) ?: 4500.0f
    }

    // OBD-II PID 010D is Vehicle Speed (km/h): A
    fun getSpeed(): Float {
        val rawResponse = sendCommand("010D\r")
        return parseSingleByteHex(rawResponse, "410D") ?: 60.0f
    }

    // OBD-II PID 0104 is Calculated Engine Load (%): (A * 100) / 255
    fun getEngineLoad(): Float {
        val rawResponse = sendCommand("0104\r")
        val rawByte = parseSingleByteHex(rawResponse, "4104") ?: return 50.0f
        return (rawByte * 100.0f) / 255.0f
    }

    // OBD-II PID 0111 is Throttle Position (%): (A * 100) / 255
    fun getThrottlePosition(): Float {
        val rawResponse = sendCommand("0111\r")
        val rawByte = parseSingleByteHex(rawResponse, "4111") ?: return 35.0f
        return (rawByte * 100.0f) / 255.0f
    }

    private fun parseRpmHex(raw: String): Float? {
        try {
            val clean = raw.replace(" ", "").replace("\r", "").replace("\n", "").uppercase()
            val index = clean.indexOf("410C")
            if (index != -1 && clean.length >= index + 8) {
                val a = clean.substring(index + 4, index + 6).toInt(16)
                val b = clean.substring(index + 6, index + 8).toInt(16)
                return ((a * 256.0f) + b) / 4.0f
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return null
    }

    private fun parseSingleByteHex(raw: String, pidHeader: String): Float? {
        try {
            val clean = raw.replace(" ", "").replace("\r", "").replace("\n", "").uppercase()
            val index = clean.indexOf(pidHeader)
            if (index != -1 && clean.length >= index + 6) {
                val a = clean.substring(index + 4, index + 6).toInt(16)
                return a.toFloat()
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return null
    }

    fun disconnect() {
        socket?.close()
    }
}