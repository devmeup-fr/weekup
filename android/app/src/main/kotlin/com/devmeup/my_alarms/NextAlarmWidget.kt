package com.devmeup.my_alarms

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import java.util.Calendar

/**
 * Widget « Prochaine alarme ». L'app enregistre les prochaines sonneries
 * (horodatage + libellés déjà traduits) ; le widget affiche la première encore
 * à venir, ce qui le garde juste même si l'app n'est pas rouverte.
 */
class NextAlarmWidget : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val now = System.currentTimeMillis()
        val next = try {
            val entries = JSONArray(widgetData.getString("entries", "[]"))
            (0 until entries.length())
                .map { entries.getJSONObject(it) }
                .firstOrNull { it.getLong("t") > now }
        } catch (e: Exception) {
            null
        }

        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.next_alarm_widget)
            views.setTextViewText(
                R.id.widget_header,
                widgetData.getString("header", "Prochaine alarme"),
            )

            if (next == null) {
                views.setViewVisibility(R.id.widget_time, View.GONE)
                views.setViewVisibility(R.id.widget_label, View.GONE)
                views.setTextViewText(
                    R.id.widget_day,
                    widgetData.getString("empty", "Aucune alarme active"),
                )
            } else {
                views.setViewVisibility(R.id.widget_time, View.VISIBLE)
                views.setTextViewText(R.id.widget_time, next.getString("time"))
                views.setTextViewText(R.id.widget_day, dayLabel(next, widgetData))
                val label = next.optString("label")
                views.setViewVisibility(
                    R.id.widget_label,
                    if (label.isEmpty()) View.GONE else View.VISIBLE,
                )
                views.setTextViewText(R.id.widget_label, label)
            }

            views.setOnClickPendingIntent(
                R.id.widget_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
            )
            appWidgetManager.updateAppWidget(id, views)
        }
    }

    /** « Aujourd'hui », « Demain » ou la date déjà formatée par l'app. */
    private fun dayLabel(entry: org.json.JSONObject, data: SharedPreferences): String {
        val today = Calendar.getInstance()
        val day = Calendar.getInstance().apply { timeInMillis = entry.getLong("t") }
        val tomorrow = Calendar.getInstance().apply { add(Calendar.DAY_OF_YEAR, 1) }
        fun same(a: Calendar, b: Calendar) =
            a.get(Calendar.YEAR) == b.get(Calendar.YEAR) &&
                a.get(Calendar.DAY_OF_YEAR) == b.get(Calendar.DAY_OF_YEAR)
        return when {
            same(day, today) -> data.getString("today", null) ?: entry.getString("day")
            same(day, tomorrow) -> data.getString("tomorrow", null) ?: entry.getString("day")
            else -> entry.getString("day")
        }
    }
}
