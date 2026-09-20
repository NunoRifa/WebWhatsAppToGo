package whatsgo.nunorifa.my.id

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Bundle
import android.os.Build
import android.webkit.WebView
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

class MainActivity: FlutterActivity() {
    private val CHANNEL = "whatsgo.nunorifa.my.id/app"
    private val MESSAGE_CHANNEL_ID = "whatsgo_messages_channel"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Enable WebView debugging in debug mode if needed
        WebView.setWebContentsDebuggingEnabled(true)
        createNotificationChannels()
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "Pesan Masuk WhatsGo"
            val descriptionText = "Notifikasi saat ada pesan WhatsApp baru masuk"
            val importance = NotificationManager.IMPORTANCE_HIGH
            val channel = NotificationChannel(MESSAGE_CHANNEL_ID, name, importance).apply {
                description = descriptionText
                enableVibration(true)
                enableLights(true)
            }
            val notificationManager: NotificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "moveTaskToBack" -> {
                    // Send app to background without killing process/WebSocket
                    moveTaskToBack(true)
                    result.success(true)
                }
                "showIncomingNotification" -> {
                    val title = call.argument<String>("title") ?: "WhatsGo"
                    val body = call.argument<String>("body") ?: "Pesan baru diterima"
                    val hidePreview = call.argument<Boolean>("hidePreview") ?: false

                    showNativeMessageNotification(title, body, hidePreview)
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun showNativeMessageNotification(title: String, body: String, hidePreview: Boolean) {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val pendingIntent: PendingIntent = PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val displayText = if (hidePreview) "Pesan baru diterima" else body
        val iconRes = applicationInfo.icon.takeIf { it != 0 } ?: android.R.drawable.stat_notify_chat

        val builder = NotificationCompat.Builder(this, MESSAGE_CHANNEL_ID)
            .setSmallIcon(iconRes)
            .setContentTitle(title)
            .setContentText(displayText)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_MESSAGE)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .setDefaults(NotificationCompat.DEFAULT_ALL)

        try {
            val notificationManager = NotificationManagerCompat.from(this)
            val notificationId = (title.hashCode() and 0x7FFFFFFF) % 10000 + 2000
            notificationManager.notify(notificationId, builder.build())
        } catch (e: SecurityException) {
            // Android 13+ permission not yet granted
            e.printStackTrace()
        }
    }
}
