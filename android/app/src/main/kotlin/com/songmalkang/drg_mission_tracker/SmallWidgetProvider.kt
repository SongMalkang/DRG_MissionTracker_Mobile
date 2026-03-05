package com.songmalkang.drg_mission_tracker

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class SmallWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_small)

            val title = widgetData.getString("widget_title", "BOSCO TERMINAL") ?: "BOSCO TERMINAL"
            val count = widgetData.getInt("widget_double_xp_count", 0)
            val epoch = widgetData.getLong("widget_next_rotation_epoch", 0L)
            val rotation = if (epoch > 0) {
                val diff = (epoch - System.currentTimeMillis()) / 1000
                if (diff > 0) {
                    val mm = (diff / 60).toString().padStart(2, '0')
                    val ss = (diff % 60).toString().padStart(2, '0')
                    "$mm:$ss"
                } else "00:00"
            } else "--:--"
            val noXpText = widgetData.getString("widget_no_double_xp", "No Double XP") ?: "No Double XP"

            views.setTextViewText(R.id.widget_title, title)
            views.setTextViewText(
                R.id.widget_xp_status,
                if (count > 0) "Double XP: $count" else noXpText
            )
            views.setTextViewText(R.id.widget_rotation, rotation)

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
