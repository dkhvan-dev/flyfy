package kz.inflap

import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.database.Cursor
import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMuxer
import android.net.Uri
import android.provider.OpenableColumns
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.nio.ByteBuffer
import kotlin.math.max

class MainActivity : FlutterFragmentActivity() {
    companion object {
        private const val MIN_TRIM_SAMPLE_BUFFER_SIZE = 16 * 1024 * 1024
        private const val FILE_OPENER_AUTHORITY_SUFFIX = ".fileprovider"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "inflap/clipboard_media"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "readImage" -> result.success(readImageFromClipboard())
                else -> result.notImplemented()
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "inflap/video_tools"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "trimVideo" -> trimVideo(call, result)
                else -> result.notImplemented()
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "inflap/file_opener"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "openFile" -> openFile(call, result)
                else -> result.notImplemented()
            }
        }
    }

    private fun openFile(call: MethodCall, result: MethodChannel.Result) {
        val args = call.arguments as? Map<*, *>
        val path = (args?.get("path") as? String)?.trim()
        val contentType = (args?.get("contentType") as? String)
            ?.trim()
            ?.takeIf { it.isNotEmpty() }
            ?: "*/*"

        if (path.isNullOrBlank()) {
            result.success(fileOpenResult("file_not_found", "File path is empty"))
            return
        }

        val file = File(path)
        if (!file.exists() || !file.isFile) {
            result.success(fileOpenResult("file_not_found", "File does not exist"))
            return
        }

        try {
            val uri = FileProvider.getUriForFile(
                this,
                "${applicationContext.packageName}$FILE_OPENER_AUTHORITY_SUFFIX",
                file
            )
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, contentType)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                clipData = ClipData.newUri(contentResolver, file.name, uri)
            }
            startActivity(intent)
            result.success(fileOpenResult("done"))
        } catch (_: ActivityNotFoundException) {
            result.success(fileOpenResult("no_app", "No app can open this file"))
        } catch (error: Exception) {
            result.success(
                fileOpenResult(
                    "failed",
                    error.localizedMessage ?: "File open failed"
                )
            )
        }
    }

    private fun fileOpenResult(status: String, message: String? = null): Map<String, Any?> {
        return mapOf("status" to status, "message" to message)
    }

    private fun trimVideo(call: MethodCall, result: MethodChannel.Result) {
        val args = call.arguments as? Map<*, *>
        val inputPath = args?.get("inputPath") as? String
        val startMs = (args?.get("startMs") as? Number)?.toLong()
        val endMs = (args?.get("endMs") as? Number)?.toLong()

        if (inputPath.isNullOrBlank() || startMs == null || endMs == null || endMs <= startMs) {
            result.error("invalid_arguments", "Invalid video trim arguments", null)
            return
        }

        Thread {
            try {
                val outputPath = trimVideoFile(inputPath, startMs, endMs)
                runOnUiThread { result.success(outputPath) }
            } catch (error: Exception) {
                runOnUiThread {
                    result.error(
                        "trim_failed",
                        error.localizedMessage ?: "Video trim failed",
                        null
                    )
                }
            }
        }.start()
    }

    private fun trimVideoFile(inputPath: String, startMs: Long, endMs: Long): String {
        val inputFile = File(inputPath)
        if (!inputFile.exists()) {
            throw IllegalArgumentException("Input video does not exist")
        }

        val outputFile = File(cacheDir, "inflap_trimmed_${System.currentTimeMillis()}.mp4")
        val startUs = startMs * 1000
        val endUs = endMs * 1000
        val extractor = MediaExtractor()
        var muxer: MediaMuxer? = null
        var muxerStarted = false

        try {
            extractor.setDataSource(inputFile.absolutePath)
            muxer = MediaMuxer(
                outputFile.absolutePath,
                MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4
            )

            val trackIndexMap = mutableMapOf<Int, Int>()
            var maxBufferSize = MIN_TRIM_SAMPLE_BUFFER_SIZE

            for (index in 0 until extractor.trackCount) {
                val format = extractor.getTrackFormat(index)
                val mime = format.getString(MediaFormat.KEY_MIME) ?: continue
                if (!mime.startsWith("video/") && !mime.startsWith("audio/")) continue

                if (mime.startsWith("video/") && format.containsKey(MediaFormat.KEY_ROTATION)) {
                    muxer.setOrientationHint(format.getInteger(MediaFormat.KEY_ROTATION))
                }
                if (format.containsKey(MediaFormat.KEY_MAX_INPUT_SIZE)) {
                    maxBufferSize = max(maxBufferSize, format.getInteger(MediaFormat.KEY_MAX_INPUT_SIZE))
                }

                trackIndexMap[index] = muxer.addTrack(format)
            }

            if (trackIndexMap.isEmpty()) {
                throw IllegalStateException("No audio or video tracks found")
            }

            muxer.start()
            muxerStarted = true
            var samplesWritten = 0

            for ((sourceTrackIndex, targetTrackIndex) in trackIndexMap) {
                samplesWritten += writeSelectedTrack(
                    dataSource = inputFile.absolutePath,
                    sourceTrackIndex = sourceTrackIndex,
                    targetTrackIndex = targetTrackIndex,
                    muxer = muxer,
                    startUs = startUs,
                    endUs = endUs,
                    maxBufferSize = maxBufferSize
                )
            }

            if (samplesWritten == 0) {
                throw IllegalStateException("Trim range contains no samples")
            }

            muxer.stop()
            muxerStarted = false
            muxer.release()
            muxer = null
            return outputFile.absolutePath
        } catch (error: Exception) {
            outputFile.delete()
            throw error
        } finally {
            extractor.release()
            if (muxerStarted) {
                try {
                    muxer?.stop()
                } catch (_: Exception) {
                    outputFile.delete()
                }
            }
            muxer?.release()
        }
    }

    private fun writeSelectedTrack(
        dataSource: String,
        sourceTrackIndex: Int,
        targetTrackIndex: Int,
        muxer: MediaMuxer,
        startUs: Long,
        endUs: Long,
        maxBufferSize: Int
    ): Int {
        val trackExtractor = MediaExtractor()
        return try {
            trackExtractor.setDataSource(dataSource)
            trackExtractor.selectTrack(sourceTrackIndex)
            trackExtractor.seekTo(startUs, MediaExtractor.SEEK_TO_PREVIOUS_SYNC)

            val buffer = ByteBuffer.allocateDirect(maxBufferSize)
            val info = MediaCodec.BufferInfo()
            var firstSampleTimeUs: Long? = null
            var samplesWritten = 0

            while (true) {
                val sampleTimeUs = trackExtractor.sampleTime
                if (sampleTimeUs < 0 || sampleTimeUs > endUs) break

                buffer.clear()
                val sampleSize = trackExtractor.readSampleData(buffer, 0)
                if (sampleSize < 0) break
                if (sampleSize == 0) {
                    trackExtractor.advance()
                    continue
                }

                val baseSampleTimeUs = firstSampleTimeUs ?: sampleTimeUs
                    .also { firstSampleTimeUs = it }
                buffer.position(0)
                buffer.limit(sampleSize)
                info.set(
                    0,
                    sampleSize,
                    max(0L, sampleTimeUs - baseSampleTimeUs),
                    trackExtractor.sampleFlags
                )
                muxer.writeSampleData(targetTrackIndex, buffer, info)
                samplesWritten++
                trackExtractor.advance()
            }

            samplesWritten
        } finally {
            trackExtractor.release()
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
