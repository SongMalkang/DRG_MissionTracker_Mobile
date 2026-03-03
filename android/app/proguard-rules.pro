# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# android_alarm_manager_plus
-keep class dev.fluttercommunity.plus.androidalarmmanager.** { *; }

# flutter_local_notifications
-keep class com.dexterous.** { *; }

# home_widget
-keep class es.antonborri.home_widget.** { *; }

# Google Play Core (Flutter 엔진 내부 참조 — 미사용 클래스 경고 억제)
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# Attributes
-keepattributes *Annotation*
-keepattributes Signature
