package com.trpl5a.aplikasimobile

import android.app.DownloadManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.net.wifi.WifiManager
import android.provider.OpenableColumns
import android.app.Activity
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream
import java.io.OutputStream
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

		private var pendingFilePickerResult: MethodChannel.Result? = null
		private val FILE_PICKER_REQUEST_CODE = 0x1234

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

		// Native file picker that streams selected file into app cache and returns a local path
		MethodChannel(
			flutterEngine.dartExecutor.binaryMessenger,
			"proyek_uas/filepicker"
		).setMethodCallHandler { call, result ->
			when (call.method) {
				"openFileAndCopyToCache" -> {
					if (pendingFilePickerResult != null) {
						result.error("ALREADY_PICKING", "A file pick is already in progress", null)
						return@setMethodCallHandler
					}
					try {
						pendingFilePickerResult = result
						val intent = Intent(Intent.ACTION_OPEN_DOCUMENT)
						intent.addCategory(Intent.CATEGORY_OPENABLE)
						intent.type = "*/*"
						intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
						startActivityForResult(intent, FILE_PICKER_REQUEST_CODE)
					} catch (e: Exception) {
						pendingFilePickerResult = null
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

	// Handle result from the native file picker: stream URI into a cached file and return path
	override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
		super.onActivityResult(requestCode, resultCode, data)
		if (requestCode == FILE_PICKER_REQUEST_CODE) {
			val pending = pendingFilePickerResult
			pendingFilePickerResult = null
			if (resultCode != Activity.RESULT_OK || data == null) {
				pending?.success(null)
				return
			}
			val uri: Uri? = data.data
			if (uri == null) {
				pending?.error("NO_URI", "No file selected", null)
				return
			}
			try {
				// Get display name
				var name = "file"
				contentResolver.query(uri, null, null, null, null)?.use { cursor ->
					val nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
					if (cursor.moveToFirst() && nameIndex != -1) {
						name = cursor.getString(nameIndex)
					}
				}
				val cacheFile = File(cacheDir, "picked_")
				// ensure unique filename
				val outFile = File(cacheDir, "picked_${System.currentTimeMillis()}_${name}")
				contentResolver.openInputStream(uri).use { input: InputStream? ->
					if (input == null) throw Exception("Unable to open input stream")
					FileOutputStream(outFile).use { output: OutputStream ->
						val buf = ByteArray(8192)
						var len: Int
						while (input.read(buf).also { len = it } > 0) {
							output.write(buf, 0, len)
						}
						output.flush()
					}
				}
				// Return the local file path to Dart
				pending?.success(outFile.absolutePath)
			} catch (e: Exception) {
				pending?.error("COPY_FAILED", e.message, null)
			}
		}
	}
}
