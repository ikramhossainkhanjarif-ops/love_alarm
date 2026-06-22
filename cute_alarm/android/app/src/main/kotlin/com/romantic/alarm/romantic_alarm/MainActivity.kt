package com.romantic.alarm.romantic_alarm

import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * Single Activity for the whole app (normal launches AND alarm-triggered
 * full-screen launches). Using one Activity/engine keeps things simple:
 * no duplicate Dart VMs, no juggling state between two FlutterActivities.
 *
 * When launched with [EXTRA_LAUNCHED_FROM_ALARM], we apply lock-screen /
 * turn-screen-on window flags so the alarm UI reliably appears even while
 * the device is locked, then let the Dart side read the same extras via
 * `getInitialAlarmPayload()` to navigate straight to the ringing route.
 *
 * `launchMode="singleTask"` (see AndroidManifest) means if the app is
 * already running, Android delivers a new Intent via [onNewIntent] rather
 * than creating a second instance — important because an alarm can fire
 * while the user is already browsing the alarm list.
 */
class MainActivity : FlutterActivity() {

    companion object {
        const val EXTRA_LAUNCHED_FROM_ALARM = "extra_launched_from_alarm"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (intent?.getBooleanExtra(EXTRA_LAUNCHED_FROM_ALARM, false) == true) {
            applyShowOverLockScreenFlags()
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (intent.getBooleanExtra(EXTRA_LAUNCHED_FROM_ALARM, false)) {
            applyShowOverLockScreenFlags()
            AlarmSchedulerPlugin.attachInitialPayloadFromIntent(intent)
            AlarmSchedulerPlugin.notifyAlarmFiredIfEngineReady(intent)
        }
    }

    private fun applyShowOverLockScreenFlags() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
            val keyguardManager =
                getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
            keyguardManager.requestDismissKeyguard(this, null)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                        WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                        WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
            )
        }
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(AlarmSchedulerPlugin())
        AlarmSchedulerPlugin.attachInitialPayloadFromIntent(intent)
    }
}
