package pt.taxy.app

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.graphics.Matrix
import android.graphics.pdf.PdfRenderer
import android.media.ExifInterface
import android.net.Uri
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.FileProvider
import com.google.android.gms.tasks.Tasks
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.InputStream
import java.security.KeyStore
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import java.util.UUID
import java.util.concurrent.Executors
import javax.crypto.Cipher
import javax.crypto.CipherInputStream
import javax.crypto.CipherOutputStream
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

internal class SecureDocumentCaptureBridge(private val activity: MainActivity) {
    private val executor = Executors.newSingleThreadExecutor()
    private val secureDirectory = File(activity.filesDir, "secure_tax_documents")
    private val captureDirectory = File(activity.cacheDir, "secure_document_capture")
    private var channel: MethodChannel? = null
    private var pending: PendingCapture? = null

    private val photoLauncher: ActivityResultLauncher<Uri> =
        activity.registerForActivityResult(ActivityResultContracts.TakePicture()) { success ->
            val request = pending ?: return@registerForActivityResult
            if (!success) {
                request.cameraFile?.delete()
                completeCancelled(request)
            } else {
                process(request, Uri.fromFile(request.cameraFile))
            }
        }

    private val fileLauncher: ActivityResultLauncher<Array<String>> =
        activity.registerForActivityResult(ActivityResultContracts.OpenDocument()) { uri ->
            val request = pending ?: return@registerForActivityResult
            if (uri == null) completeCancelled(request) else process(request, uri)
        }

    init {
        secureDirectory.mkdirs()
        captureDirectory.mkdirs()
    }

    fun attach(messenger: BinaryMessenger) {
        channel = MethodChannel(messenger, CHANNEL).also { methodChannel ->
            methodChannel.setMethodCallHandler(::handle)
        }
        cleanupExpired()
    }

    fun detach() {
        channel?.setMethodCallHandler(null)
        channel = null
        pending?.result?.error("CAPTURE_INTERRUPTED", "Document capture interrupted", null)
        pending = null
        executor.shutdownNow()
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "takePhoto" -> startPhoto(call, result)
            "chooseFile" -> startFile(call, result)
            "preview" -> executor.execute { preview(call, result) }
            "delete", "confirm" -> executor.execute { delete(call, result) }
            "cleanupExpired" -> executor.execute {
                val count = cleanupExpired()
                activity.runOnUiThread { result.success(count) }
            }
            "clearTemporary" -> executor.execute {
                val count = deleteAll()
                activity.runOnUiThread { result.success(count) }
            }
            else -> result.notImplemented()
        }
    }

    private fun startPhoto(call: MethodCall, result: MethodChannel.Result) {
        val year = validYear(call, result) ?: return
        if (!reserve(result)) return
        val id = randomId()
        captureDirectory.mkdirs()
        val file = File(captureDirectory, "$id.jpg")
        if (!file.createNewFile()) {
            pending = null
            result.error("CAPTURE_FAILED", "Unable to prepare capture", null)
            return
        }
        val request = PendingCapture(id, year, result, file)
        pending = request
        val uri = FileProvider.getUriForFile(activity, "${activity.packageName}.document-provider", file)
        try {
            photoLauncher.launch(uri)
        } catch (_: RuntimeException) {
            file.delete()
            pending = null
            result.error("CAMERA_UNAVAILABLE", "Camera is unavailable", null)
        }
    }

    private fun startFile(call: MethodCall, result: MethodChannel.Result) {
        val year = validYear(call, result) ?: return
        if (!reserve(result)) return
        pending = PendingCapture(randomId(), year, result, null)
        try {
            fileLauncher.launch(arrayOf("application/pdf", "image/jpeg", "image/png"))
        } catch (_: RuntimeException) {
            pending = null
            result.error("PICKER_UNAVAILABLE", "File picker is unavailable", null)
        }
    }

    private fun reserve(result: MethodChannel.Result): Boolean {
        if (pending != null) {
            result.error("CAPTURE_IN_PROGRESS", "A capture is already in progress", null)
            return false
        }
        return true
    }

    private fun validYear(call: MethodCall, result: MethodChannel.Result): Int? {
        val year = call.argument<Int>("taxYear")
        if (year == null || year !in 2000..2100) {
            result.error("INVALID_TAX_YEAR", "Invalid tax year", null)
            return null
        }
        return year
    }

    private fun process(request: PendingCapture, uri: Uri?) {
        if (uri == null) {
            completeCancelled(request)
            return
        }
        executor.execute {
            try {
                val mediaType = detectMediaType(uri)
                val processed = when (mediaType) {
                    MediaType.PDF -> processPdf(uri, request.id)
                    MediaType.JPEG, MediaType.PNG -> processImage(uri, request.id, mediaType)
                }
                val response = mapOf(
                    "document" to mapOf(
                        "id" to request.id,
                        "taxYear" to request.taxYear,
                        "mediaType" to mediaType.dartName,
                        "pageCount" to processed.pageCount,
                        "createdAt" to utcNow(),
                        "state" to "reviewRequired",
                    ),
                    "recognizedText" to processed.recognizedText.take(MAX_OCR_TEXT),
                )
                activity.runOnUiThread {
                    pending = null
                    request.cameraFile?.delete()
                    request.result.success(response)
                }
            } catch (error: CaptureFailure) {
                deleteFiles(request.id)
                activity.runOnUiThread {
                    pending = null
                    request.cameraFile?.delete()
                    request.result.error(error.code, error.safeMessage, null)
                }
            } catch (_: Throwable) {
                deleteFiles(request.id)
                activity.runOnUiThread {
                    pending = null
                    request.cameraFile?.delete()
                    request.result.error("PROCESSING_FAILED", "Document processing failed safely", null)
                }
            }
        }
    }

    private fun processImage(uri: Uri, id: String, mediaType: MediaType): ProcessedDocument {
        enforceSize(uri)
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        activity.contentResolver.openInputStream(uri).use { stream ->
            BitmapFactory.decodeStream(stream, null, bounds)
        }
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0 ||
            bounds.outWidth > MAX_DIMENSION || bounds.outHeight > MAX_DIMENSION
        ) {
            throw CaptureFailure("INVALID_IMAGE", "The selected image is invalid")
        }
        val options = BitmapFactory.Options().apply {
            inSampleSize = sampleSize(bounds.outWidth, bounds.outHeight)
        }
        val decoded = activity.contentResolver.openInputStream(uri).use { stream ->
            BitmapFactory.decodeStream(stream, null, options)
        } ?: throw CaptureFailure("INVALID_IMAGE", "The selected image is invalid")
        val bitmap = orientImage(decoded, imageRotationDegrees(uri))
        if (bitmap !== decoded) decoded.recycle()
        try {
            // Re-encoding deliberately strips EXIF, including GPS metadata.
            val sanitized = ByteArrayOutputStream()
            val format = if (mediaType == MediaType.PNG) Bitmap.CompressFormat.PNG else Bitmap.CompressFormat.JPEG
            bitmap.compress(format, 92, sanitized)
            if (sanitized.size() > MAX_BYTES) {
                throw CaptureFailure("FILE_TOO_LARGE", "The selected file is too large")
            }
            encrypt(ByteArrayInputStream(sanitized.toByteArray()), rawFile(id), MAX_BYTES)
            val preview = thumbnail(bitmap)
            try {
                val bytes = ByteArrayOutputStream()
                preview.compress(Bitmap.CompressFormat.JPEG, 82, bytes)
                encrypt(ByteArrayInputStream(bytes.toByteArray()), previewFile(id), MAX_PREVIEW_BYTES)
            } finally {
                if (preview !== bitmap) preview.recycle()
            }
            val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
            val text = try {
                Tasks.await(recognizer.process(InputImage.fromBitmap(bitmap, 0))).text
            } finally {
                recognizer.close()
            }
            return ProcessedDocument(1, text)
        } finally {
            bitmap.recycle()
        }
    }

    private fun processPdf(uri: Uri, id: String): ProcessedDocument {
        enforceSize(uri)
        activity.contentResolver.openInputStream(uri).use { stream ->
            if (stream == null) throw CaptureFailure("READ_FAILED", "The selected file cannot be read")
            encrypt(stream, rawFile(id), MAX_BYTES)
        }
        val descriptor = activity.contentResolver.openFileDescriptor(uri, "r")
            ?: throw CaptureFailure("READ_FAILED", "The selected file cannot be read")
        descriptor.use { pfd ->
            PdfRenderer(pfd).use { renderer ->
                if (renderer.pageCount !in 1..MAX_PAGES) {
                    throw CaptureFailure("PAGE_LIMIT", "The PDF has too many pages")
                }
                val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
                try {
                    val text = StringBuilder()
                    for (index in 0 until renderer.pageCount) {
                        renderer.openPage(index).use { page ->
                            val width = minOf(MAX_RENDER_WIDTH, page.width)
                            val height = (page.height.toDouble() * width / page.width).toInt().coerceAtLeast(1)
                            val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                            try {
                                bitmap.eraseColor(Color.WHITE)
                                page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
                                text.append(Tasks.await(recognizer.process(InputImage.fromBitmap(bitmap, 0))).text)
                                text.append('\n')
                                if (index == 0) {
                                    val preview = thumbnail(bitmap)
                                    try {
                                        val bytes = ByteArrayOutputStream()
                                        preview.compress(Bitmap.CompressFormat.JPEG, 82, bytes)
                                        encrypt(ByteArrayInputStream(bytes.toByteArray()), previewFile(id), MAX_PREVIEW_BYTES)
                                    } finally {
                                        if (preview !== bitmap) preview.recycle()
                                    }
                                }
                            } finally {
                                bitmap.recycle()
                            }
                        }
                    }
                    return ProcessedDocument(renderer.pageCount, text.toString())
                } finally {
                    recognizer.close()
                }
            }
        }
    }

    private fun detectMediaType(uri: Uri): MediaType {
        val header = ByteArray(8)
        val count = activity.contentResolver.openInputStream(uri).use { stream ->
            stream?.read(header) ?: -1
        }
        if (count < 3) throw CaptureFailure("UNSUPPORTED_FILE", "Unsupported document format")
        val type = when {
            header.copyOfRange(0, 5).contentEquals("%PDF-".toByteArray()) -> MediaType.PDF
            header[0] == 0xFF.toByte() && header[1] == 0xD8.toByte() && header[2] == 0xFF.toByte() -> MediaType.JPEG
            header.contentEquals(byteArrayOf(0x89.toByte(), 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A)) -> MediaType.PNG
            else -> throw CaptureFailure("UNSUPPORTED_FILE", "Unsupported document format")
        }
        val declared = activity.contentResolver.getType(uri)
        if (declared != null && declared != "application/octet-stream" && declared != "*/*") {
            val allowed = when (type) {
                MediaType.PDF -> declared == "application/pdf"
                MediaType.JPEG -> declared == "image/jpeg" || declared == "image/jpg"
                MediaType.PNG -> declared == "image/png"
            }
            if (!allowed) throw CaptureFailure("MIME_MISMATCH", "Document type does not match its content")
        }
        return type
    }

    private fun enforceSize(uri: Uri) {
        var total = 0L
        activity.contentResolver.openInputStream(uri).use { stream ->
            if (stream == null) throw CaptureFailure("READ_FAILED", "The selected file cannot be read")
            val buffer = ByteArray(64 * 1024)
            while (true) {
                val read = stream.read(buffer)
                if (read < 0) break
                total += read
                if (total > MAX_BYTES) throw CaptureFailure("FILE_TOO_LARGE", "The selected file is too large")
            }
        }
    }

    private fun preview(call: MethodCall, result: MethodChannel.Result) {
        val id = validId(call.argument<String>("id"))
        if (id == null) {
            activity.runOnUiThread { result.error("INVALID_DOCUMENT_ID", "Invalid document reference", null) }
            return
        }
        try {
            val file = previewFile(id)
            val bytes = if (file.exists()) decrypt(file, MAX_PREVIEW_BYTES) else null
            activity.runOnUiThread { result.success(bytes) }
        } catch (_: Throwable) {
            activity.runOnUiThread { result.error("PREVIEW_FAILED", "Preview is unavailable", null) }
        }
    }

    private fun delete(call: MethodCall, result: MethodChannel.Result) {
        val id = validId(call.argument<String>("id"))
        if (id == null) {
            activity.runOnUiThread { result.error("INVALID_DOCUMENT_ID", "Invalid document reference", null) }
            return
        }
        deleteFiles(id)
        activity.runOnUiThread { result.success(null) }
    }

    private fun completeCancelled(request: PendingCapture) {
        pending = null
        request.result.success(null)
    }

    private fun cleanupExpired(): Int {
        val cutoff = System.currentTimeMillis() - TEMP_TTL_MS
        var deleted = 0
        secureDirectory.listFiles()?.forEach { file ->
            if (file.lastModified() < cutoff && file.delete()) deleted++
        }
        captureDirectory.listFiles()?.forEach { file ->
            if (file.lastModified() < cutoff && file.delete()) deleted++
        }
        return deleted
    }

    private fun deleteAll(): Int {
        var deleted = 0
        secureDirectory.listFiles()?.forEach { if (it.delete()) deleted++ }
        captureDirectory.listFiles()?.forEach { if (it.delete()) deleted++ }
        return deleted
    }

    private fun deleteFiles(id: String) {
        rawFile(id).delete()
        previewFile(id).delete()
    }

    private fun rawFile(id: String) = File(secureDirectory, "$id.document")
    private fun previewFile(id: String) = File(secureDirectory, "$id.preview")

    private fun validId(value: String?): String? =
        value?.takeIf { it.matches(Regex("^[a-f0-9]{32}$")) }

    private fun randomId(): String = UUID.randomUUID().toString().replace("-", "")

    private fun utcNow(): String =
        SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US).apply {
            timeZone = TimeZone.getTimeZone("UTC")
        }.format(Date())

    private fun sampleSize(width: Int, height: Int): Int {
        var sample = 1
        while (width / sample > MAX_RENDER_WIDTH || height / sample > MAX_RENDER_WIDTH) sample *= 2
        return sample
    }

    private fun thumbnail(bitmap: Bitmap): Bitmap {
        val scale = minOf(1.0, PREVIEW_WIDTH.toDouble() / bitmap.width)
        if (scale == 1.0) return bitmap
        return Bitmap.createScaledBitmap(
            bitmap,
            (bitmap.width * scale).toInt().coerceAtLeast(1),
            (bitmap.height * scale).toInt().coerceAtLeast(1),
            true,
        )
    }

    private fun imageRotationDegrees(uri: Uri): Int = try {
        activity.contentResolver.openInputStream(uri).use { stream ->
            if (stream == null) return@use 0
            when (
                ExifInterface(stream).getAttributeInt(
                    ExifInterface.TAG_ORIENTATION,
                    ExifInterface.ORIENTATION_NORMAL,
                )
            ) {
                ExifInterface.ORIENTATION_ROTATE_90,
                ExifInterface.ORIENTATION_TRANSPOSE -> 90
                ExifInterface.ORIENTATION_ROTATE_180,
                ExifInterface.ORIENTATION_FLIP_VERTICAL -> 180
                ExifInterface.ORIENTATION_ROTATE_270,
                ExifInterface.ORIENTATION_TRANSVERSE -> 270
                else -> 0
            }
        }
    } catch (_: Throwable) {
        0
    }

    private fun orientImage(bitmap: Bitmap, degrees: Int): Bitmap {
        if (degrees == 0) return bitmap
        return Bitmap.createBitmap(
            bitmap,
            0,
            0,
            bitmap.width,
            bitmap.height,
            Matrix().apply { postRotate(degrees.toFloat()) },
            true,
        )
    }

    private fun secretKey(): SecretKey {
        val store = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        val existing = store.getKey(KEY_ALIAS, null) as? SecretKey
        if (existing != null) return existing
        val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
        generator.init(
            KeyGenParameterSpec.Builder(
                KEY_ALIAS,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT,
            )
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256)
                .build(),
        )
        return generator.generateKey()
    }

    private fun encrypt(input: InputStream, destination: File, maximumBytes: Int) {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, secretKey())
        val temporary = File(destination.parentFile, "${destination.name}.tmp")
        var total = 0
        try {
            FileOutputStream(temporary).use { output ->
                output.write(FILE_MAGIC)
                output.write(cipher.iv.size)
                output.write(cipher.iv)
                CipherOutputStream(output, cipher).use { encrypted ->
                    val buffer = ByteArray(64 * 1024)
                    while (true) {
                        val read = input.read(buffer)
                        if (read < 0) break
                        total += read
                        if (total > maximumBytes) {
                            throw CaptureFailure("FILE_TOO_LARGE", "The selected file is too large")
                        }
                        encrypted.write(buffer, 0, read)
                    }
                }
            }
            if (destination.exists()) destination.delete()
            if (!temporary.renameTo(destination)) throw CaptureFailure("STORE_FAILED", "Secure storage failed")
        } finally {
            temporary.delete()
        }
    }

    private fun decrypt(source: File, maximumBytes: Int): ByteArray {
        FileInputStream(source).use { input ->
            val magic = ByteArray(FILE_MAGIC.size)
            if (input.read(magic) != magic.size || !magic.contentEquals(FILE_MAGIC)) {
                throw CaptureFailure("STORE_CORRUPTED", "Secure document is unavailable")
            }
            val ivLength = input.read()
            if (ivLength !in 12..16) throw CaptureFailure("STORE_CORRUPTED", "Secure document is unavailable")
            val iv = ByteArray(ivLength)
            if (input.read(iv) != ivLength) throw CaptureFailure("STORE_CORRUPTED", "Secure document is unavailable")
            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            cipher.init(Cipher.DECRYPT_MODE, secretKey(), GCMParameterSpec(128, iv))
            CipherInputStream(input, cipher).use { decrypted ->
                val output = ByteArrayOutputStream()
                val buffer = ByteArray(32 * 1024)
                while (true) {
                    val read = decrypted.read(buffer)
                    if (read < 0) break
                    if (output.size() + read > maximumBytes) {
                        throw CaptureFailure("PREVIEW_TOO_LARGE", "Preview is unavailable")
                    }
                    output.write(buffer, 0, read)
                }
                return output.toByteArray()
            }
        }
    }

    private data class PendingCapture(
        val id: String,
        val taxYear: Int,
        val result: MethodChannel.Result,
        val cameraFile: File?,
    )

    private data class ProcessedDocument(val pageCount: Int, val recognizedText: String)

    private enum class MediaType(val dartName: String) {
        PDF("pdf"),
        JPEG("jpeg"),
        PNG("png"),
    }

    private class CaptureFailure(val code: String, val safeMessage: String) : RuntimeException()

    companion object {
        private const val CHANNEL = "pt.taxy.app/document_capture"
        private const val KEY_ALIAS = "taxy_document_capture_aes_v1"
        private const val MAX_BYTES = 10 * 1024 * 1024
        private const val MAX_PREVIEW_BYTES = 2 * 1024 * 1024
        private const val MAX_PAGES = 10
        private const val MAX_DIMENSION = 20_000
        private const val MAX_RENDER_WIDTH = 2_000
        private const val PREVIEW_WIDTH = 1_000
        private const val MAX_OCR_TEXT = 200_000
        private const val TEMP_TTL_MS = 24L * 60L * 60L * 1000L
        private val FILE_MAGIC = "TAXYDOC1".toByteArray()
    }
}
