package com.romantic.alarm.romantic_alarm

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import android.os.IBinder
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import androidx.core.app.NotificationCompat

/**
 * Foreground service responsible for actually playing the alarm sound on
 * loop and triggering vibration, independent of whatever UI state
 * [MainActivity]'s ringing UI / Flutter is in. Running as a foreground service (with
 * mediaPlayback type) means Android won't kill audio mid-ring.
 *
 * The service is stopped either by the user dismissing/snoozing (via the
 * MethodChannel -> [AlarmSchedulerPlugin] -> this service), or by a new
 * alarm firing and replacing it.
 */
class AlarmRingingService : Service() {

    private var mediaPlayer: MediaPlayer? = null
    private var vibrator: Vibrator? = null

    companion object {
        const val CHANNEL_ID = "romantic_alarm_ringing_channel"
        const val NOTIFICATION_ID = 1001

        const val ACTION_STOP = "com.romantic.alarm.romantic_alarm.ACTION_STOP_RINGING"

        @Volatile
        var isRinging: Boolean = false
            private set

        @Volatile
        var currentAlarmId: String? = null
            private set
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannelIfNeeded()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopRinging()
            return START_NOT_STICKY
        }

        val alarmId = intent?.getStringExtra(AlarmReceiver.EXTRA_ALARM_ID)
        val label = intent?.getStringExtra(AlarmReceiver.EXTRA_LABEL) ?: "Wake up, my love"
        val shouldVibrate = intent?.getBooleanExtra(AlarmReceiver.EXTRA_VIBRATE, true) ?: true
        val soundAssetPath = intent?.getStringExtra(AlarmReceiver.EXTRA_SOUND_ASSET_PATH)

        currentAlarmId = alarmId
        isRinging = true

        startForeground(NOTIFICATION_ID, buildNotification(label))
        startSound(soundAssetPath)
        if (shouldVibrate) startVibration()

        return START_STICKY
    }

    private fun startSound(assetPath: String?) {
        stopSoundOnly()
        try {
            mediaPlayer = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )

                val resolvedPath = assetPath ?: "assets/sounds/alarm_sound.mp3"
                val assetManager = applicationContext.assets
                // Flutter bundles pubspec assets inside the APK under
                // "flutter_assets/<original_path>". FlutterLoader resolves
                // this lookup key, and (unlike the old FlutterMain API) it
                // works correctly even with no active FlutterEngine, as
                // long as it's initialized first.
                val flutterLoader = io.flutter.embedding.engine.loader.FlutterLoader()
                if (!flutterLoader.initialized()) {
                    flutterLoader.startInitialization(applicationContext)
                    flutterLoader.ensureInitializationComplete(applicationContext, null)
                }
                val key = flutterLoader.getLookupKeyForAsset(resolvedPath)
                val afd = assetManager.openFd(key)
                setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                isLooping = true
                setVolume(1.0f, 1.0f)
                prepare()
                start()
            }
        } catch (e: Exception) {
            // If the custom sound can't be loaded for any reason, fall back
            // to the system default alarm sound so the alarm is never
            // silent.
            try {
                val fallbackUri = android.media.RingtoneManager.getDefaultUri(
                    android.media.RingtoneManager.TYPE_ALARM
                )
                mediaPlayer = MediaPlayer().apply {
                    setAudioAttributes(
                        AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_ALARM)
                            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                            .build()
                    )
                    setDataSource(applicationContext, fallbackUri)
                    isLooping = true
                    prepare()
                    start()
                }
            } catch (inner: Exception) {
                // Give up silently rather than crash the receiver chain.
            }
        }
    }

    private fun startVibration() {
        vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vm = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
            vm.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }

        val pattern = longArrayOf(0, 800, 600) // wait, vibrate, pause
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val effect = VibrationEffect.createWaveform(pattern, 0) // repeat from index 0
            vibrator?.vibrate(effect)
        } else {
            @Suppress("DEPRECATION")
            vibrator?.vibrate(pattern, 0)
        }
    }

    private fun buildNotification(label: String) =
        NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Love Alarms 💕")
            .setContentText(label.ifEmpty { "Your alarm is ringing" })
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setOngoing(true)
            .setFullScreenIntent(buildFullScreenPendingIntent(), true)
            .build()

    private fun buildFullScreenPendingIntent(): PendingIntent {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_NO_USER_ACTION
            putExtra(AlarmReceiver.EXTRA_ALARM_ID, currentAlarmId)
            putExtra(MainActivity.EXTRA_LAUNCHED_FROM_ALARM, true)
        }
        return PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun createNotificationChannelIfNeeded() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(NotificationManager::class.java)
            val existing = manager.getNotificationChannel(CHANNEL_ID)
            if (existing == null) {
                val channel = NotificationChannel(
                    CHANNEL_ID,
                    "Alarm Ringing",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Shows while a romantic alarm is ringing"
                    setSound(null, null) // service plays sound manually via MediaPlayer
                    enableVibration(false) // service handles vibration manually
                }
                manager.createNotificationChannel(channel)
            }
        }
    }

    private fun stopSoundOnly() {
        mediaPlayer?.apply {
            try {
                if (isPlaying) stop()
                release()
            } catch (e: Exception) {
                // Ignore.
            }
        }
        mediaPlayer = null
    }

    fun stopRinging() {
        stopSoundOnly()
        vibrator?.cancel()
        vibrator = null
        isRinging = false
        currentAlarmId = null
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    override fun onDestroy() {
        stopSoundOnly()
        vibrator?.cancel()
        isRinging = false
        currentAlarmId = null
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
