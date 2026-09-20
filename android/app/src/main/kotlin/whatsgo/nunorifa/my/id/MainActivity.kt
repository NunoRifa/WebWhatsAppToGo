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
import android.net.Uri
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.FileProvider
import java.io.File

class MainActivity: FlutterActivity() {
    private val CHANNEL = "whatsgo.nunorifa.my.id/app"
    private val MESSAGE_CHANNEL_ID = "whatsgo_messages_channel"
    private val DOWNLOAD_CHANNEL_ID = "whatsgo_downloads_channel"
    private val FILE_PROVIDER_AUTHORITY = "whatsgo.nunorifa.my.id.fileprovider"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Enable WebView debugging in debug mode if needed
        WebView.setWebContentsDebuggingEnabled(true)
        createNotificationChannels()
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager: NotificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            // Messages Channel (High priority heads-up)
            val msgChannel = NotificationChannel(
                MESSAGE_CHANNEL_ID,
                "Pesan Masuk WhatsGo",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifikasi saat ada pesan WhatsApp baru masuk"
                enableVibration(true)
                enableLights(true)
            }
            notificationManager.createNotificationChannel(msgChannel)

            // Downloads Channel (Default priority with open action)
            val downloadChannel = NotificationChannel(
                DOWNLOAD_CHANNEL_ID,
                "Unduhan WhatsGo",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Notifikasi saat unduhan media atau dokumen selesai"
                enableVibration(true)
            }
            notificationManager.createNotificationChannel(downloadChannel)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "moveTaskToBack" -> {
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
                "showDownloadNotification" -> {
                    val filePath = call.argument<String>("filePath") ?: ""
                    val fileName = call.argument<String>("fileName") ?: "Berkas"
                    val mimeType = call.argument<String>("mimeType") ?: "*/*"

                    showNativeDownloadNotification(filePath, fileName, mimeType)
                    result.success(true)
                }
                "openFileDirectly" -> {
                    val filePath = call.argument<String>("filePath") ?: ""
                    val mimeType = call.argument<String>("mimeType") ?: "*/*"

                    openFileWithProvider(filePath, mimeType)
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
            e.printStackTrace()
        }
    }

    private fun showNativeDownloadNotification(filePath: String, fileName: String, mimeType: String) {
        val file = File(filePath)
        if (!file.exists()) return

        try {
            val fileUri: Uri = FileProvider.getUriForFile(this, FILE_PROVIDER_AUTHORITY, file)
            val viewIntent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(fileUri, mimeType)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }

            val notificationId = (filePath.hashCode() and 0x7FFFFFFF) % 10000 + 5000
            val pendingIntent = PendingIntent.getActivity(
                this,
                notificationId,
                viewIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val iconRes = applicationInfo.icon.takeIf { it != 0 } ?: android.R.drawable.stat_sys_download_done

            val builder = NotificationCompat.Builder(this, DOWNLOAD_CHANNEL_ID)
                .setSmallIcon(iconRes)
                .setContentTitle("Unduhan Selesai")
                .setContentText(fileName)
                .setSubText("Download/WhatsGo")
                .setContentIntent(pendingIntent)
                .setAutoCancel(true)
                .addAction(
                    android.R.drawable.ic_menu_view,
                    "Buka Berkas",
                    pendingIntent
                )

            val notificationManager = NotificationManagerCompat.from(this)
            notificationManager.notify(notificationId, builder.build())
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun openFileWithProvider(filePath: String, mimeType: String) {
        val file = File(filePath)
        if (!file.exists()) return

        try {
            val fileUri: Uri = FileProvider.getUriForFile(this, FILE_PROVIDER_AUTHORITY, file)
            val viewIntent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(fileUri, mimeType)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(viewIntent)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
