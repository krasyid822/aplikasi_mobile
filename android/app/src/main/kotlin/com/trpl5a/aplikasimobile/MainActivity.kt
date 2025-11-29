package com.trpl5a.aplikasimobile

import android.app.DownloadManager
import android.content.Context
import android.content.Intent
import android.net.wifi.WifiManager
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

		// Provide basic network info (SSID + IP) via a separate channel
		MethodChannel(
			flutterEngine.dartExecutor.binaryMessenger,
			"proyek_uas/network"
		).setMethodCallHandler { call, result ->
			when (call.method) {
				"getWifiInfo" -> {
					try {
						val wm = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
						val info = wm.connectionInfo
						var ssid: String? = info?.ssid
						if (ssid != null && ssid.startsWith("\"") && ssid.endsWith("\"")) {
							ssid = ssid.substring(1, ssid.length - 1)
						}
						val ipInt = info?.ipAddress ?: 0
						val ip = String.format(
							"%d.%d.%d.%d",
							ipInt and 0xff,
							ipInt shr 8 and 0xff,
							ipInt shr 16 and 0xff,
							ipInt shr 24 and 0xff
						)
						val map: MutableMap<String, String> = HashMap()
						map["ssid"] = ssid ?: ""
						map["ip"] = ip
						result.success(map)
					} catch (e: Exception) {
						result.error("WIFI_ERROR", e.message, null)
					}
				}
				else -> result.notImplemented()
			}
		}
	}
}
