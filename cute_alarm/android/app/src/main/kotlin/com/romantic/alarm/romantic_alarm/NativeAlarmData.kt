package com.romantic.alarm.romantic_alarm

import org.json.JSONArray
import org.json.JSONObject

/**
 * Plain data holder mirroring the Dart `AlarmEntity`, persisted natively
 * in SharedPreferences so AlarmManager broadcasts (which can fire even
 * after the Flutter engine / Dart VM has been killed) have everything
 * they need to show the ringing screen and play sound without any Dart
 * code running.
 */
data class NativeAlarmData(
    val id: String,
    val hour: Int,
    val minute: Int,
    val label: String,
    val soundAssetPath: String,
    val vibrate: Boolean,
    val snoozeMinutes: Int,
    val isRepeating: Boolean,
    val repeatDays: List<Int>, // 1=Mon..7=Sun, ISO-8601
    val triggerAtMillis: Long
) {
    fun toJson(): JSONObject {
        val obj = JSONObject()
        obj.put("id", id)
        obj.put("hour", hour)
        obj.put("minute", minute)
        obj.put("label", label)
        obj.put("soundAssetPath", soundAssetPath)
        obj.put("vibrate", vibrate)
        obj.put("snoozeMinutes", snoozeMinutes)
        obj.put("isRepeating", isRepeating)
        obj.put("repeatDays", JSONArray(repeatDays))
        obj.put("triggerAtMillis", triggerAtMillis)
        return obj
    }

    companion object {
        fun fromJson(obj: JSONObject): NativeAlarmData {
            val daysArray = obj.optJSONArray("repeatDays") ?: JSONArray()
            val days = mutableListOf<Int>()
            for (i in 0 until daysArray.length()) {
                days.add(daysArray.getInt(i))
            }
            return NativeAlarmData(
                id = obj.getString("id"),
                hour = obj.getInt("hour"),
                minute = obj.getInt("minute"),
                label = obj.optString("label", ""),
                soundAssetPath = obj.optString(
                    "soundAssetPath",
                    "assets/sounds/alarm_sound.mp3"
                ),
                vibrate = obj.optBoolean("vibrate", true),
                snoozeMinutes = obj.optInt("snoozeMinutes", 5),
                isRepeating = obj.optBoolean("isRepeating", false),
                repeatDays = days,
                triggerAtMillis = obj.optLong("triggerAtMillis", 0L)
            )
        }

        /** Builds an instance from the raw MethodChannel argument map. */
        fun fromMethodCallArgs(args: Map<*, *>): NativeAlarmData {
            val repeatDaysRaw = (args["repeatDays"] as? List<*>)
                ?.mapNotNull { (it as? Number)?.toInt() }
                ?: emptyList()
            return NativeAlarmData(
                id = args["id"] as String,
                hour = (args["hour"] as Number).toInt(),
                minute = (args["minute"] as Number).toInt(),
                label = args["label"] as? String ?: "",
                soundAssetPath = args["soundAssetPath"] as? String
                    ?: "assets/sounds/alarm_sound.mp3",
                vibrate = args["vibrate"] as? Boolean ?: true,
                snoozeMinutes = (args["snoozeMinutes"] as? Number)?.toInt() ?: 5,
                isRepeating = args["isRepeating"] as? Boolean ?: false,
                repeatDays = repeatDaysRaw,
                triggerAtMillis = (args["triggerAtMillis"] as Number).toLong()
            )
        }
    }
}
