package com.trpl5a.aplikasimobile

import android.app.DownloadManager
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		MethodChannel(
			flutterEngine.dartExecutor.binaryMessenger,
			"proyek_uas/open_folder"
		).setMethodCallHandler { call, result ->
			when (call.method) {
				"openDownloadsFolderAndroid" -> {
					try {
						val intent = Intent(DownloadManager.ACTION_VIEW_DOWNLOADS)
						intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
						startActivity(intent)
						result.success(true)
					} catch (e: Exception) {
						result.error("ACTIVITY_ERROR", e.message, null)
					}
				}
				else -> result.notImplemented()
			}
		}
	}
}
