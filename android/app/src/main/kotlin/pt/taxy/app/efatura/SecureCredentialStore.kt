package pt.taxy.app.efatura

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import java.nio.ByteBuffer
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

internal data class StoredCredentials(val nif: String, val password: CharArray) {
    fun clear() = password.fill('\u0000')
}

internal class SecureCredentialStore(context: Context) {
    private val preferences = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
    private val keyStore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }

    fun save(nif: String, password: CharArray) {
        require(NIF.matches(nif)) { "Invalid credential format" }
        require(password.isNotEmpty()) { "Invalid credential format" }
        val passwordBytes = password.concatToString().toByteArray(Charsets.UTF_8)
        try {
            preferences.edit()
                .putString(NIF_ENTRY, encrypt(NIF_ENTRY, nif.toByteArray(Charsets.US_ASCII)))
                .putString(PASSWORD_ENTRY, encrypt(PASSWORD_ENTRY, passwordBytes))
                .apply()
        } finally {
            passwordBytes.fill(0)
        }
    }

    fun load(): StoredCredentials? {
        val encryptedNif = preferences.getString(NIF_ENTRY, null) ?: return null
        val encryptedPassword = preferences.getString(PASSWORD_ENTRY, null) ?: return null
        val nifBytes = decrypt(NIF_ENTRY, encryptedNif)
        val passwordBytes = decrypt(PASSWORD_ENTRY, encryptedPassword)
        return try {
            val nif = nifBytes.toString(Charsets.US_ASCII)
            if (!NIF.matches(nif)) throw SecurityException("Stored credentials are invalid")
            StoredCredentials(nif, passwordBytes.toString(Charsets.UTF_8).toCharArray())
        } finally {
            nifBytes.fill(0)
            passwordBytes.fill(0)
        }
    }

    fun hasCredentials(): Boolean =
        preferences.contains(NIF_ENTRY) && preferences.contains(PASSWORD_ENTRY)

    fun clear() {
        preferences.edit().remove(NIF_ENTRY).remove(PASSWORD_ENTRY).apply()
    }

    private fun key(): SecretKey {
        (keyStore.getKey(KEY_ALIAS, null) as? SecretKey)?.let { return it }
        val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
        generator.init(
            KeyGenParameterSpec.Builder(
                KEY_ALIAS,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT,
            )
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256)
                .setUserAuthenticationRequired(false)
                .build(),
        )
        return generator.generateKey()
    }

    private fun encrypt(field: String, plaintext: ByteArray): String {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, key())
        cipher.updateAAD(field.toByteArray(Charsets.US_ASCII))
        val ciphertext = cipher.doFinal(plaintext)
        val output = ByteBuffer.allocate(1 + cipher.iv.size + ciphertext.size)
            .put(cipher.iv.size.toByte())
            .put(cipher.iv)
            .put(ciphertext)
            .array()
        ciphertext.fill(0)
        return Base64.encodeToString(output, Base64.NO_WRAP)
    }

    private fun decrypt(field: String, encoded: String): ByteArray {
        val input = Base64.decode(encoded, Base64.NO_WRAP)
        if (input.isEmpty()) throw SecurityException("Stored credentials are invalid")
        val buffer = ByteBuffer.wrap(input)
        val ivLength = buffer.get().toInt() and 0xff
        if (ivLength !in 12..16 || buffer.remaining() <= ivLength) {
            throw SecurityException("Stored credentials are invalid")
        }
        val iv = ByteArray(ivLength).also(buffer::get)
        val ciphertext = ByteArray(buffer.remaining()).also(buffer::get)
        return try {
            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            cipher.init(Cipher.DECRYPT_MODE, key(), GCMParameterSpec(128, iv))
            cipher.updateAAD(field.toByteArray(Charsets.US_ASCII))
            cipher.doFinal(ciphertext)
        } finally {
            input.fill(0)
            ciphertext.fill(0)
            iv.fill(0)
        }
    }

    private companion object {
        val NIF = Regex("^\\d{9}$")
        const val PREFERENCES = "taxy_efatura_secure_v1"
        const val KEY_ALIAS = "taxy_efatura_credentials_v1"
        const val NIF_ENTRY = "nif"
        const val PASSWORD_ENTRY = "password"
    }
}
