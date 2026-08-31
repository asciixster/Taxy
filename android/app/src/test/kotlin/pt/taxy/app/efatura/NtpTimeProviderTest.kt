package pt.taxy.app.efatura

import java.nio.ByteBuffer
import java.time.Instant
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith

class NtpTimeProviderTest {
    @Test
    fun `valid correlated response converts to UTC instant`() {
        val request = ByteArray(48).also {
            it[0] = ((4 shl 3) or 3).toByte()
            ByteBuffer.wrap(it, 40, 8).putInt(3_976_000_000L.toInt()).putInt(0)
        }
        val response = ByteArray(48).also {
            it[0] = ((4 shl 3) or 4).toByte()
            it[1] = 2
            request.copyInto(it, 24, 40, 48)
            ByteBuffer.wrap(it, 32, 8).putInt(3_976_000_001L.toInt()).putInt(0)
            ByteBuffer.wrap(it, 40, 8).putInt(3_976_000_002L.toInt()).putInt(0)
        }
        assertEquals(
            Instant.ofEpochSecond(3_976_000_002L - 2_208_988_800L),
            NtpTimeProvider().parse(response, request),
        )
    }

    @Test
    fun `uncorrelated and malformed packets fail closed`() {
        val request = ByteArray(48)
        val response = ByteArray(48).also {
            it[0] = ((4 shl 3) or 4).toByte()
            it[1] = 2
        }
        assertFailsWith<NtpException> { NtpTimeProvider().parse(response, request) }
        assertFailsWith<NtpException> { NtpTimeProvider().parse(ByteArray(47), request) }
    }
}
