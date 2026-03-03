package com.songmalkang.drg_mission_tracker

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class MediumWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_medium)

            val title = widgetData.getString("widget_title", "BOSCO TERMINAL") ?: "BOSCO TERMINAL"
            val count = widgetData.getInt("widget_double_xp_count", 0)
            val rotation = widgetData.getString("widget_next_rotation", "--:--") ?: "--:--"
            val noXpText = widgetData.getString("widget_no_double_xp", "No Double XP") ?: "No Double XP"
            val missionSummary = widgetData.getString("widget_mission_summary", "") ?: ""

            views.setTextViewText(R.id.widget_title, title)
            views.setTextViewText(R.id.widget_rotation, rotation)
            views.setTextViewText(
                R.id.widget_xp_status,
                if (count > 0) "Double XP: $count" else noXpText
            )
            views.setTextViewText(
                R.id.widget_mission_list,
                if (missionSummary.isNotEmpty()) missionSummary else ""
            )

            // 탭 → 앱 열기
            val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            if (intent != null) {
                val pendingIntent = android.app.PendingIntent.getActivity(
                    context, 0, intent,
                    android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
