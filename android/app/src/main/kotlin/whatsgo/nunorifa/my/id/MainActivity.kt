package whatsgo.nunorifa.my.id

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Bundle
import android.webkit.WebView

class MainActivity: FlutterActivity() {
    private val CHANNEL = "whatsgo.nunorifa.my.id/app"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Enable WebView debugging in debug mode if needed
        WebView.setWebContentsDebuggingEnabled(true)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "moveTaskToBack") {
                // Send app to background without killing process/WebSocket
                moveTaskToBack(true)
                result.success(true)
            } else {
                result.notImplemented()
            }
        }
    }
}
