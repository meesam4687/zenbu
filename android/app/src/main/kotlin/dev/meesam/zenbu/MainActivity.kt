package dev.meesam.zenbu

import android.app.PendingIntent
import android.app.PictureInPictureParams
import android.app.RemoteAction
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.res.Configuration
import android.graphics.drawable.Icon
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import android.util.Rational
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.ArrayList

class MainActivity : FlutterActivity() {
    private val CHANNEL = "zenbu/pip"
    private var isVideoPlaying = false
    private var channel: MethodChannel? = null

    private val ACTION_PLAY_PAUSE = "dev.meesam.zenbu.ACTION_PLAY_PAUSE"
    private val ACTION_REWIND = "dev.meesam.zenbu.ACTION_REWIND"
    private val ACTION_FORWARD = "dev.meesam.zenbu.ACTION_FORWARD"

    private val pipReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent == null) return
            when (intent.action) {
                ACTION_PLAY_PAUSE -> {
                    channel?.invokeMethod("onPipPlayPausePressed", null)
                }
                ACTION_REWIND -> {
                    channel?.invokeMethod("onPipRewindPressed", null)
                }
                ACTION_FORWARD -> {
                    channel?.invokeMethod("onPipForwardPressed", null)
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val filter = IntentFilter().apply {
            addAction(ACTION_PLAY_PAUSE)
            addAction(ACTION_REWIND)
            addAction(ACTION_FORWARD)
        }
        if (Build.VERSION.SDK_INT >= 34) {
            registerReceiver(pipReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(pipReceiver, filter)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        try {
            unregisterReceiver(pipReceiver)
        } catch (_: Exception) {}
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        channel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "setVideoPlaying" -> {
                    isVideoPlaying = call.argument<Boolean>("isPlaying") ?: false
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        updatePipParams(isVideoPlaying)
                    }
                    result.success(null)
                }
                "isInPip" -> {
                    result.success(if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) isInPictureInPictureMode else false)
                }
                "enterPip" -> {
                    enterPipMode()
                    result.success(true)
                }
                "installApk" -> {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        try {
                            installApk(path)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("INSTALL_FAILED", e.message, e.toString())
                        }
                    } else {
                        result.error("INVALID_PATH", "Path is null", null)
                    }
                }
                "showDownloadingNotification" -> {
                    val progress = call.argument<Int>("progress") ?: 0
                    showDownloadingNotification(progress)
                    result.success(null)
                }
                "dismissDownloadingNotification" -> {
                    dismissDownloadingNotification()
                    result.success(null)
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun installApk(filePath: String) {
        val file = java.io.File(filePath)
        if (!file.exists()) {
            throw java.io.FileNotFoundException("APK file not found at: $filePath")
        }

        val intent = Intent(Intent.ACTION_VIEW)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val apkUri = androidx.core.content.FileProvider.getUriForFile(
                this,
                "$packageName.fileprovider",
                file
            )
            intent.setDataAndType(apkUri, "application/vnd.android.package-archive")
        } else {
            intent.setDataAndType(android.net.Uri.fromFile(file), "application/vnd.android.package-archive")
        }
        startActivity(intent)
    }

    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S && isVideoPlaying) {
            enterPipMode()
        }
    }

    private fun enterPipMode() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            updatePipParams(isVideoPlaying)
            enterPictureInPictureMode()
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            enterPictureInPictureMode()
        }
    }

    private fun updatePipParams(isPlaying: Boolean) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val actions = ArrayList<RemoteAction>()

            val rewindIntent = PendingIntent.getBroadcast(
                this, 1, Intent(ACTION_REWIND).setPackage(packageName), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            val rewindIcon = Icon.createWithResource(this, android.R.drawable.ic_media_rew)
            val rewindAction = RemoteAction(rewindIcon, "Rewind 10s", "Rewind 10s", rewindIntent)
            actions.add(rewindAction)

            val playPauseIntent = PendingIntent.getBroadcast(
                this, 2, Intent(ACTION_PLAY_PAUSE).setPackage(packageName), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            val playPauseIcon = if (isPlaying) {
                Icon.createWithResource(this, android.R.drawable.ic_media_pause)
            } else {
                Icon.createWithResource(this, android.R.drawable.ic_media_play)
            }
            val playPauseAction = RemoteAction(playPauseIcon, if (isPlaying) "Pause" else "Play", if (isPlaying) "Pause" else "Play", playPauseIntent)
            actions.add(playPauseAction)

            val forwardIntent = PendingIntent.getBroadcast(
                this, 3, Intent(ACTION_FORWARD).setPackage(packageName), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            val forwardIcon = Icon.createWithResource(this, android.R.drawable.ic_media_ff)
            val forwardAction = RemoteAction(forwardIcon, "Forward 10s", "Forward 10s", forwardIntent)
            actions.add(forwardAction)

            val builder = PictureInPictureParams.Builder()
                .setAspectRatio(Rational(16, 9))
                .setActions(actions)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                builder.setAutoEnterEnabled(isPlaying)
            }

            setPictureInPictureParams(builder.build())
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N && isInPictureInPictureMode) {
            val reorderIntent = Intent(this, MainActivity::class.java)
            reorderIntent.flags = Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
            startActivity(reorderIntent)
        }
    }

    override fun onPictureInPictureModeChanged(isInPictureInPictureMode: Boolean, newConfig: Configuration) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        channel?.invokeMethod("onPipModeChanged", isInPictureInPictureMode)
    }

    private val NOTIFICATION_ID = 1001
    private val CHANNEL_ID = "zenbu_update_channel"

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "App Updates"
            val descriptionText = "Notifications for app updates and downloads"
            val importance = NotificationManager.IMPORTANCE_LOW
            val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                description = descriptionText
            }
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun showDownloadingNotification(progress: Int) {
        createNotificationChannel()
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) != android.content.pm.PackageManager.PERMISSION_GRANTED) {
                requestPermissions(arrayOf(android.Manifest.permission.POST_NOTIFICATIONS), 1002)
                return
            }
        }

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            Notification.Builder(this)
        }
        
        val intent = Intent(Intent.ACTION_VIEW, android.net.Uri.parse("zenbu://update")).apply {
            setPackage(packageName)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        }
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        builder.setContentTitle("Downloading Zenbu Update")
            .setContentText("Downloading... $progress%")
            .setSmallIcon(android.R.drawable.stat_sys_download)
            .setOngoing(true)
            .setProgress(100, progress, false)
            .setOnlyAlertOnce(true)
            .setContentIntent(pendingIntent)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            builder.setForegroundServiceBehavior(Notification.FOREGROUND_SERVICE_IMMEDIATE)
        }

        notificationManager.notify(NOTIFICATION_ID, builder.build())
    }

    private fun dismissDownloadingNotification() {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.cancel(NOTIFICATION_ID)
    }

}
