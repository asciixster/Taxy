package pt.taxy.app.dm3irs

import android.content.Context
import android.net.Uri
import android.security.KeyChain
import android.view.WindowManager
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors
import pt.taxy.app.MainActivity
import pt.taxy.app.efatura.CipherCertificateStore
import pt.taxy.app.efatura.RuntimeBridgeException
import pt.taxy.app.efatura.SecureCredentialStore

internal class Dm3IrsHistoryBridge(private val activity: MainActivity) {
    private val executor = Executors.newSingleThreadExecutor()
    private val credentials = SecureCredentialStore(activity.applicationContext)
    private val cipherCertificates = CipherCertificateStore(activity.applicationContext)
    private val preferences = activity.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
    private val client = Dm3IrsNativeClient(
        activity.applicationContext,
        credentials,
        cipherCertificates,
        alias = { preferences.getString(CLIENT_ALIAS, null) },
    )
    private var channel: MethodChannel? = null
    private var pendingCertificateResult: MethodChannel.Result? = null
    private val certificateLauncher: ActivityResultLauncher<Array<String>> =
        activity.registerForActivityResult(ActivityResultContracts.OpenDocument()) { uri ->
            val pending = pendingCertificateResult ?: return@registerForActivityResult
            pendingCertificateResult = null
            if (uri == null) {
                pending.success(false)
                return@registerForActivityResult
            }
            executor.execute {
                try {
                    val bytes = activity.contentResolver.openInputStream(uri)?.use { it.readBytes() }
                        ?: throw RuntimeBridgeException("NOT_CONFIGURED", "Não foi possível ler o certificado público.")
                    try {
                        cipherCertificates.save(bytes)
                    } finally {
                        bytes.fill(0)
                    }
                    activity.runOnUiThread { pending.success(true) }
                } catch (error: RuntimeBridgeException) {
                    activity.runOnUiThread { pending.error(error.code, error.safeMessage, null) }
                } catch (_: Exception) {
                    activity.runOnUiThread { pending.error("NOT_CONFIGURED", "Não foi possível usar o certificado público.", null) }
                }
            }
        }

    fun attach(messenger: BinaryMessenger) {
        channel = MethodChannel(messenger, CHANNEL).also { it.setMethodCallHandler(::handle) }
    }

    fun detach() {
        channel?.setMethodCallHandler(null)
        channel = null
        pendingCertificateResult?.error("SERVICE_UNAVAILABLE", "A seleção foi interrompida.", null)
        pendingCertificateResult = null
        executor.shutdownNow()
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getReadiness" -> result.success(readiness())
            "saveCredentials" -> background(result) {
                val nif = call.argument<String>("nif").orEmpty()
                val password = call.argument<String>("password").orEmpty().toCharArray()
                try {
                    credentials.save(nif, password)
                } finally {
                    password.fill('\u0000')
                }
                null
            }
            "selectClientIdentity" -> selectClientIdentity(result)
            "selectCipherCertificate" -> selectCipherCertificate(result)
            "loadHistory" -> background(result) {
                val sourceYear = call.argument<Int>("sourceYear")
                if (sourceYear != 2024) throw RuntimeBridgeException("UNKNOWN_TEMPLATE", "Apenas o histórico de 2024 foi validado.")
                client.history2024()
            }
            "setScreenSecure" -> {
                val enabled = call.argument<Boolean>("enabled") == true
                if (enabled) activity.window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                else activity.window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                result.success(null)
            }
            "clear" -> background(result) {
                credentials.clear()
                null
            }
            else -> result.notImplemented()
        }
    }

    private fun readiness(): Map<String, Boolean> = mapOf(
        "hasCredentials" to credentials.hasCredentials(),
        "hasClientIdentity" to preferences.contains(CLIENT_ALIAS),
        "hasCipherCertificate" to cipherCertificates.hasCertificate(),
    )

    private fun selectClientIdentity(result: MethodChannel.Result) {
        KeyChain.choosePrivateKeyAlias(
            activity,
            { alias ->
                if (alias == null) result.success(false)
                else {
                    preferences.edit().putString(CLIENT_ALIAS, alias).apply()
                    result.success(true)
                }
            },
            arrayOf("RSA"),
            null,
            Uri.parse(Dm3IrsProtocol.ENDPOINT),
            preferences.getString(CLIENT_ALIAS, null),
        )
    }

    private fun selectCipherCertificate(result: MethodChannel.Result) {
        if (pendingCertificateResult != null) {
            result.error("SERVICE_UNAVAILABLE", "Já existe uma seleção em curso.", null)
            return
        }
        pendingCertificateResult = result
        certificateLauncher.launch(arrayOf("application/x-x509-ca-cert", "application/pkix-cert", "*/*"))
    }

    private fun background(result: MethodChannel.Result, operation: () -> Any?) {
        executor.execute {
            try {
                val value = operation()
                activity.runOnUiThread { result.success(value) }
            } catch (error: RuntimeBridgeException) {
                activity.runOnUiThread { result.error(error.code, error.safeMessage, null) }
            } catch (_: IllegalArgumentException) {
                activity.runOnUiThread { result.error("AUTH_ERROR", "Os dados fornecidos não são válidos.", null) }
            } catch (_: Throwable) {
                activity.runOnUiThread { result.error("SERVICE_UNAVAILABLE", "Não foi possível consultar o IRS anterior.", null) }
            }
        }
    }

    private companion object {
        const val CHANNEL = "pt.taxy.app/dm3irs_history"
        const val PREFERENCES = "taxy_dm3irs_history_v1"
        const val CLIENT_ALIAS = "client_alias"
    }
}
