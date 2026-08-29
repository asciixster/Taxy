package pt.taxy.app

import android.content.Intent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.android.FlutterActivity
import pt.taxy.app.efatura.EfaturaRuntimeBridge

class MainActivity : FlutterActivity() {
    private var efaturaBridge: EfaturaRuntimeBridge? = null

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

        efaturaBridge = EfaturaRuntimeBridge(
            this,
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "pt.taxy.app/efatura"),
        )
    }

    @Deprecated("Deprecated in Android")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (efaturaBridge?.onActivityResult(requestCode, resultCode, data) == true) return
        super.onActivityResult(requestCode, resultCode, data)
    }

    override fun onDestroy() {
        efaturaBridge?.dispose()
        efaturaBridge = null
        super.onDestroy()
    }
}
