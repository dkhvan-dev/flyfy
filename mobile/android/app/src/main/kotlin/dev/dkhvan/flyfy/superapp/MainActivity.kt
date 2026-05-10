package dev.dkhvan.flyfy.superapp

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.database.Cursor
import android.net.Uri
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "flyfy/clipboard_media"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "readImage" -> result.success(readImageFromClipboard())
                else -> result.notImplemented()
            }
        }
    }

    private fun readImageFromClipboard(): Map<String, Any?>? {
        val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        val clip = clipboard.primaryClip ?: return null
        if (clip.itemCount == 0) return null

        for (index in 0 until clip.itemCount) {
            val item = clip.getItemAt(index)
            val uri = item.uri ?: textUri(item) ?: continue
            val contentType = contentResolver.getType(uri) ?: continue
            if (!contentType.startsWith("image/")) continue

            val bytes = contentResolver.openInputStream(uri)?.use { input ->
                input.readBytes()
            } ?: continue
            if (bytes.isEmpty()) continue

            return mapOf(
                "bytes" to bytes,
                "contentType" to contentType,
                "name" to (displayName(uri) ?: fallbackName(contentType))
            )
        }
        return null
    }

    private fun textUri(item: ClipData.Item): Uri? {
        val raw = item.text?.toString()?.trim() ?: return null
        return runCatching { Uri.parse(raw) }.getOrNull()
            ?.takeIf { it.scheme == "content" || it.scheme == "file" }
    }

    private fun displayName(uri: Uri): String? {
        var cursor: Cursor? = null
        return try {
            cursor = contentResolver.query(
                uri,
                arrayOf(OpenableColumns.DISPLAY_NAME),
                null,
                null,
                null
            )
            if (cursor != null && cursor.moveToFirst()) {
                val column = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if (column >= 0) cursor.getString(column) else null
            } else {
                null
            }
        } catch (_: Exception) {
            null
        } finally {
            cursor?.close()
        }
    }

    private fun fallbackName(contentType: String): String {
        val ext = when (contentType.lowercase()) {
            "image/jpeg" -> "jpg"
            "image/png" -> "png"
            "image/gif" -> "gif"
            "image/webp" -> "webp"
            "image/heic" -> "heic"
            "image/heif" -> "heif"
            else -> "img"
        }
        return "clipboard_${System.currentTimeMillis()}.$ext"
    }
}
