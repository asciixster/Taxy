package pt.taxy.app.efatura

import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress
import java.nio.ByteBuffer
import java.time.Instant

internal class NtpTimeProvider(
    private val host: String = "time.cloudflare.com",
    private val timeoutMillis: Int = 3000,
) {
    fun now(): Instant {
        val request = ByteArray(PACKET_SIZE)
        request[0] = ((4 shl 3) or 3).toByte()
        writeTimestamp(request, 40, System.currentTimeMillis())
        val response = ByteArray(512)
        DatagramSocket().use { socket ->
            socket.soTimeout = timeoutMillis
            socket.send(DatagramPacket(request, request.size, InetAddress.getByName(host), 123))
            val packet = DatagramPacket(response, response.size)
            socket.receive(packet)
            return parse(response.copyOf(packet.length), request)
        }
    }

    internal fun parse(response: ByteArray, request: ByteArray): Instant {
        if (response.size < PACKET_SIZE || response.size % 4 != 0) {
            throw NtpException("Malformed NTP response")
        }
        val leap = response[0].toInt().ushr(6) and 0x03
        val version = response[0].toInt().ushr(3) and 0x07
        val mode = response[0].toInt() and 0x07
        val stratum = response[1].toInt() and 0xff
        if (leap == 3 || version !in 3..4 || mode != 4 || stratum !in 1..15) {
            throw NtpException("Invalid NTP server response")
        }
        if (!response.copyOfRange(24, 32).contentEquals(request.copyOfRange(40, 48))) {
            throw NtpException("Uncorrelated NTP response")
        }
        val seconds = unsignedInt(response, 40)
        val fraction = unsignedInt(response, 44)
        if (seconds < NTP_UNIX_EPOCH_SECONDS) throw NtpException("Invalid NTP timestamp")
        val millis = (seconds - NTP_UNIX_EPOCH_SECONDS) * 1000L +
            ((fraction * 1000L) ushr 32)
        return Instant.ofEpochMilli(millis)
    }

    private fun writeTimestamp(output: ByteArray, offset: Int, unixMillis: Long) {
        val unixSeconds = Math.floorDiv(unixMillis, 1000L)
        val remainder = Math.floorMod(unixMillis, 1000L)
        val fraction = (remainder shl 32) / 1000L
        ByteBuffer.wrap(output, offset, 8)
            .putInt((unixSeconds + NTP_UNIX_EPOCH_SECONDS).toInt())
            .putInt(fraction.toInt())
    }

    private fun unsignedInt(input: ByteArray, offset: Int): Long =
        ByteBuffer.wrap(input, offset, 4).int.toLong() and 0xffff_ffffL

    private companion object {
        const val PACKET_SIZE = 48
        const val NTP_UNIX_EPOCH_SECONDS = 2_208_988_800L
    }
}

internal class NtpException(message: String) : Exception(message)
