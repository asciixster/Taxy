package pt.taxy.app.dm3irs

import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.pdf.PdfRenderer
import android.os.Build
import android.os.ParcelFileDescriptor
import android.system.Os
import android.system.OsConstants
import androidx.annotation.RequiresApi
import com.google.android.gms.tasks.Tasks
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions

internal object Dm3IrsPdfMemoryExtractor {
    private const val MAX_PDF_BYTES = 20 * 1024 * 1024
    private const val RENDER_WIDTH = 1800

    fun extract(pdfBytes: ByteArray): Dm3IrsHistoricalResult {
        if (pdfBytes.size !in 5..MAX_PDF_BYTES || !pdfBytes.copyOfRange(0, 5).contentEquals("%PDF-".toByteArray())) {
            throw InvalidDm3IrsDocument()
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) throw InvalidDm3IrsDocument()
        return extractSharedMemory(pdfBytes)
    }

    @RequiresApi(Build.VERSION_CODES.R)
    private fun extractSharedMemory(pdfBytes: ByteArray): Dm3IrsHistoricalResult {
        val memory = Os.memfd_create("taxy-dm3irs-session", 0)
        var descriptor: ParcelFileDescriptor? = null
        try {
            Os.ftruncate(memory, pdfBytes.size.toLong())
            var offset = 0
            while (offset < pdfBytes.size) {
                val written = Os.write(memory, pdfBytes, offset, pdfBytes.size - offset)
                if (written <= 0) throw InvalidDm3IrsDocument()
                offset += written
            }
            Os.lseek(memory, 0, OsConstants.SEEK_SET)
            descriptor = ParcelFileDescriptor.dup(memory)
            PdfRenderer(descriptor).use { renderer ->
                if (renderer.pageCount != 17) throw UnknownDm3IrsTemplate()
                val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
                try {
                    val pages = (0 until renderer.pageCount).map { index ->
                        renderer.openPage(index).use { page ->
                            val height = (page.height.toDouble() * RENDER_WIDTH / page.width).toInt().coerceAtLeast(1)
                            val bitmap = Bitmap.createBitmap(RENDER_WIDTH, height, Bitmap.Config.ARGB_8888)
                            try {
                                bitmap.eraseColor(Color.WHITE)
                                page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
                                val recognized = Tasks.await(recognizer.process(InputImage.fromBitmap(bitmap, 0)))
                                val tokens = recognized.textBlocks
                                    .flatMap { it.lines }
                                    .flatMap { it.elements }
                                    .mapNotNull { element ->
                                        val box = element.boundingBox ?: return@mapNotNull null
                                        RecognizedToken(
                                            text = element.text.trim(),
                                            left = box.left.toDouble() / bitmap.width,
                                            top = box.top.toDouble() / bitmap.height,
                                            right = box.right.toDouble() / bitmap.width,
                                            bottom = box.bottom.toDouble() / bitmap.height,
                                        )
                                    }
                                RecognizedPage(index + 1, bitmap.width, bitmap.height, tokens)
                            } finally {
                                bitmap.recycle()
                            }
                        }
                    }
                    return Dm3IrsStructuralParser.parse(pages)
                } finally {
                    recognizer.close()
                }
            }
        } finally {
            descriptor?.close()
            Os.close(memory)
        }
    }
}

internal class InvalidDm3IrsDocument : Exception()
