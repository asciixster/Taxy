package pt.taxy.app

import android.view.WindowManager
import android.os.Bundle
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    private var screenProtectionChannel: MethodChannel? = null
    private lateinit var documentCaptureBridge: SecureDocumentCaptureBridge

    override fun onCreate(savedInstanceState: Bundle?) {
        documentCaptureBridge = SecureDocumentCaptureBridge(this)
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        documentCaptureBridge.attach(flutterEngine.dartExecutor.binaryMessenger)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "pt.taxy.app/storage")
            .setMethodCallHandler { call, result ->
                if (call.method == "getAppDataPath") {
                    result.success(filesDir.absolutePath)
                } else {
                    result.notImplemented()
                }
            }

        screenProtectionChannel =
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "pt.taxy.app/efatura")
                .also { channel ->
                    channel.setMethodCallHandler { call, result ->
                        if (call.method != "setScreenSecure") {
                            result.notImplemented()
                            return@setMethodCallHandler
                        }
                        val enabled = call.arguments as? Boolean ?: false
                        if (enabled) {
                            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        } else {
                            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        }
                        result.success(null)
                    }
                }
    }

    override fun onDestroy() {
        documentCaptureBridge.detach()
        screenProtectionChannel?.setMethodCallHandler(null)
        screenProtectionChannel = null
        super.onDestroy()
    }
}
