package com.romantic.alarm.romantic_alarm

import android.content.Context
import org.json.JSONArray

/**
 * Mirrors the set of currently-scheduled alarms in native SharedPreferences
 * (a *different* key/file than Flutter's own `shared_preferences` plugin
 * storage, intentionally — this is an internal bookkeeping store solely
 * for AlarmManager + BootReceiver, not read directly by Dart code).
 *
 * Why this exists: after a device reboot, all AlarmManager alarms are
 * cleared by the OS. [BootReceiver] needs to know what to re-schedule
 * *without* needing the Flutter engine to spin up. Keeping a lightweight
 * native copy makes that possible and instant.
 */
class NativeAlarmStore(context: Context) {

    private val prefs =
        context.getSharedPreferences("native_alarm_store", Context.MODE_PRIVATE)

    companion object {
        private const val KEY_ALARMS = "scheduled_alarms_json"
    }

    fun saveAlarm(alarm: NativeAlarmData) {
        val all = loadAll().toMutableMap()
        all[alarm.id] = alarm
        persist(all)
    }

    fun removeAlarm(id: String) {
        val all = loadAll().toMutableMap()
        all.remove(id)
        persist(all)
    }

    fun getAlarm(id: String): NativeAlarmData? = loadAll()[id]

    fun loadAll(): Map<String, NativeAlarmData> {
        val raw = prefs.getString(KEY_ALARMS, null) ?: return emptyMap()
        val result = mutableMapOf<String, NativeAlarmData>()
        try {
            val arr = JSONArray(raw)
            for (i in 0 until arr.length()) {
                val data = NativeAlarmData.fromJson(arr.getJSONObject(i))
                result[data.id] = data
            }
        } catch (e: Exception) {
            // Corrupt store; reset rather than crash.
            return emptyMap()
        }
        return result
    }

    private fun persist(all: Map<String, NativeAlarmData>) {
        val arr = JSONArray()
        all.values.forEach { arr.put(it.toJson()) }
        prefs.edit().putString(KEY_ALARMS, arr.toString()).apply()
    }
}
