package whatsgo.nunorifa.my.id

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import android.webkit.WebView

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Enable WebView debugging in debug mode if needed
        WebView.setWebContentsDebuggingEnabled(true)
    }
}

