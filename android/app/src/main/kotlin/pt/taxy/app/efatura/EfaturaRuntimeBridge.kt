package pt.taxy.app.efatura

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.security.KeyChain
import android.view.WindowManager
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

internal class EfaturaRuntimeBridge(
    private val activity: Activity,
    private val channel: MethodChannel,
) : MethodChannel.MethodCallHandler {
    private val applicationContext = activity.applicationContext
    private val executor: ExecutorService = Executors.newSingleThreadExecutor()
    private val credentials = SecureCredentialStore(applicationContext)
    private val cipherCertificates = CipherCertificateStore(applicationContext)
    private val preferences = applicationContext.getSharedPreferences(
        "taxy_efatura_runtime_v1",
        Context.MODE_PRIVATE,
    )
    private val client = FactIntWsNativeClient(
        applicationContext,
        credentials,
        cipherCertificates,
        alias = { preferences.getString(CLIENT_ALIAS, null) },
    )
    private var pendingCipherResult: MethodChannel.Result? = null

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getReadiness" -> result.success(readiness())
            "saveCredentials" -> background(result) {
                val nif = call.argument<String>("nif").orEmpty()
                val password = call.argument<String>("password").orEmpty().toCharArray()
                try {
                    credentials.save(nif, password)
                    null
                } finally {
                    password.fill('\u0000')
                }
            }
            "clearCredentials" -> background(result) {
                credentials.clear()
                null
            }
            "selectClientIdentity" -> selectClientIdentity(result)
            "selectCipherCertificate" -> selectCipherCertificate(result)
            "setScreenSecure" -> {
                val enabled = call.arguments as? Boolean ?: false
                if (enabled) {
                    activity.window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                } else {
                    activity.window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                }
                result.success(null)
            }
            "loadOverview" -> background(result) { client.overview() }
            "loadPendingInvoices" -> background(result) { client.pendingInvoices() }
            "loadSectorInvoices" -> background(result) {
                val sector = call.argument<String>("sectorCode").orEmpty()
                client.sectorInvoices(sector)
            }
            else -> result.notImplemented()
        }
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != CIPHER_CERTIFICATE_REQUEST) return false
        val pending = pendingCipherResult ?: return true
        pendingCipherResult = null
        if (resultCode != Activity.RESULT_OK || data?.data == null) {
            pending.success(false)
            return true
        }
        val uri = data.data!!
        executor.execute {
            try {
                val bytes = applicationContext.contentResolver.openInputStream(uri)?.use { it.readBytes() }
                    ?: throw RuntimeBridgeException(
                        "RUNTIME_NOT_CONFIGURED",
                        "Não foi possível ler a chave pública selecionada.",
                    )
                try {
                    cipherCertificates.save(bytes)
                } finally {
                    bytes.fill(0)
                }
                activity.runOnUiThread { pending.success(true) }
            } catch (error: RuntimeBridgeException) {
                activity.runOnUiThread {
                    pending.error(error.code, error.safeMessage, null)
                }
            } catch (_: Exception) {
                activity.runOnUiThread {
                    pending.error(
                        "RUNTIME_NOT_CONFIGURED",
                        "Não foi possível usar a chave pública selecionada.",
                        null,
                    )
                }
            }
        }
        return true
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        executor.shutdownNow()
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
                if (alias == null) {
                    result.success(false)
                } else {
                    preferences.edit().putString(CLIENT_ALIAS, alias).apply()
                    result.success(true)
                }
            },
            arrayOf("RSA"),
            null,
            Uri.parse(FactIntWsProtocol.ENDPOINT),
            preferences.getString(CLIENT_ALIAS, null),
        )
    }

    private fun selectCipherCertificate(result: MethodChannel.Result) {
        if (pendingCipherResult != null) {
            result.error(
                "RUNTIME_NOT_CONFIGURED",
                "Já existe uma seleção de certificado em curso.",
                null,
            )
            return
        }
        pendingCipherResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "application/x-x509-ca-cert"
            putExtra(Intent.EXTRA_MIME_TYPES, arrayOf("application/x-x509-ca-cert", "application/pkix-cert", "*/*"))
        }
        activity.startActivityForResult(intent, CIPHER_CERTIFICATE_REQUEST)
    }

    private fun background(
        result: MethodChannel.Result,
        operation: () -> Any?,
    ) {
        executor.execute {
            try {
                val value = operation()
                activity.runOnUiThread { result.success(value) }
            } catch (error: RuntimeBridgeException) {
                activity.runOnUiThread {
                    result.error(error.code, error.safeMessage, null)
                }
            } catch (_: IllegalArgumentException) {
                activity.runOnUiThread {
                    result.error(
                        "PARSING_ERROR",
                        "Os dados fornecidos não têm um formato válido.",
                        null,
                    )
                }
            } catch (_: Exception) {
                activity.runOnUiThread {
                    result.error(
                        "UNKNOWN_RESPONSE",
                        "Não foi possível concluir a consulta e-Fatura.",
                        null,
                    )
                }
            }
        }
    }

    private companion object {
        const val CLIENT_ALIAS = "client_alias"
        const val CIPHER_CERTIFICATE_REQUEST = 7307
    }
}
