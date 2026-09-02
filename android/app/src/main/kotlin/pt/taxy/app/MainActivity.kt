package pt.taxy.app

import android.view.WindowManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    private var screenProtectionChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
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
        screenProtectionChannel?.setMethodCallHandler(null)
        screenProtectionChannel = null
        super.onDestroy()
    }
}
