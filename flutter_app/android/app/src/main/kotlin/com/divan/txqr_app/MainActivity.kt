package com.divan.txqr_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.divan.txqr/decoder"
    private var decoder: txqr.Decoder? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        decoder = txqr.Txqr.newDecoder()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "decode" -> {
                        val data = call.arguments as? String
                        if (data == null) {
                            result.error("INVALID_ARG", "data must be a String", null)
                            return@setMethodCallHandler
                        }
                        try {
                            decoder!!.decode(data)
                            result.success(null)
                        } catch (e: Exception) {
                            result.success(e.message)
                        }
                    }

                    "isCompleted" -> {
                        result.success(decoder!!.isCompleted)
                    }

                    "getData" -> {
                        result.success(decoder!!.data())
                    }

                    "getProgress" -> {
                        val progress = decoder!!.progress().toInt()
                        result.success(progress)
                    }

                    "getSpeed" -> {
                        result.success(decoder!!.speed())
                    }

                    "getTotalTime" -> {
                        result.success(decoder!!.totalTime())
                    }

                    "reset" -> {
                        decoder!!.reset()
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
    }
}
