import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Servicio singleton de notificaciones locales.
/// Maneja recordatorios del usuario y notificaciones de cosecha de jardín.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const int _harvestNotificationId = 2000;
  static const int _streakNotificationId = 3000;

  // ═══════════════════════════════════════════════════════════════════════════
  // INICIALIZACIÓN
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _initialized = true;
    debugPrint('✅ NotificationService initialized');
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PERMISOS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Pide TODOS los permisos necesarios en Android/iOS.
  /// Llamar antes de programar cualquier recordatorio.
  /// Retorna true si el usuario aceptó (al menos el permiso básico de notificaciones).
  Future<bool> requestAllPermissions() async {
    await initialize();

        final androidPlugin = _plugin.resolvePlatformSpecificImplementation
        <AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      // 1. Permiso de notificaciones (Android 13+ / API 33+)
      final notifGranted =
          await androidPlugin.requestNotificationsPermission() ?? false;
      debugPrint('📱 Notifications permission granted: $notifGranted');

      // 2. Permiso de alarmas exactas (Android 12+ / API 31+)
      // Sin esto, zonedSchedule con exactAllowWhileIdle falla silenciosamente.
      final exactAlarmGranted =
          await androidPlugin.requestExactAlarmsPermission() ?? false;
      debugPrint('⏰ Exact alarms permission granted: $exactAlarmGranted');

      return notifGranted;
    }

        final iosPlugin = _plugin.resolvePlatformSpecificImplementation
        <IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      final granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true;
  }

  /// Alias mantenido por compatibilidad con código antiguo.
  /// Prefiere requestAllPermissions() para pedir también SCHEDULE_EXACT_ALARM.
  Future<bool> requestPermissions() => requestAllPermissions();

  // ═══════════════════════════════════════════════════════════════════════════
  // RECORDATORIOS DE USUARIO
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> scheduleReminder({
    required String reminderId,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required List<int> repeatDays,
  }) async {
    await initialize();
    await cancelReminder(reminderId);

    if (repeatDays.isEmpty) {
      await _scheduleOnce(
        id: _idFromReminderId(reminderId, 0),
        title: title,
        body: body,
        hour: hour,
        minute: minute,
        payload: 'reminder:$reminderId',
      );
    } else {
      for (final day in repeatDays) {
        await _scheduleWeekly(
          id: _idFromReminderId(reminderId, day),
          title: title,
          body: body,
          hour: hour,
          minute: minute,
          weekday: day,
          payload: 'reminder:$reminderId',
        );
      }
    }
  }

  Future<void> cancelReminder(String reminderId) async {
    await initialize();
    for (int day = 0; day <= 7; day++) {
      await _plugin.cancel(_idFromReminderId(reminderId, day));
    }
  }

  Future<void> cancelAllReminders() async {
    await initialize();
    await _plugin.cancelAll();
  }

  // ── Una sola vez ──────────────────────────────────────────────────────────

  Future<void> _scheduleOnce({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year, now.month, now.day,
      hour, minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  // ── Semanal ───────────────────────────────────────────────────────────────

  Future<void> _scheduleWeekly({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required int weekday,
    String? payload,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    int daysUntil = (weekday - now.weekday + 7) % 7;

    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year, now.month, now.day + daysUntil,
      hour, minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: payload,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COSECHA PENDIENTE
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> showHarvestReadyNotification({
    String title = '🌾 ¡Tu jardín te necesita!',
    String body =
        'Tienes plantas listas para cosechar. Entra y recoge tus recompensas.',
  }) async {
    await initialize();
    await _plugin.show(
      _harvestNotificationId,
      title,
      body,
      _notificationDetails(
        channelId: 'garden_harvest',
        channelName: 'Cosecha del jardín',
      ),
      payload: 'garden:harvest',
    );
  }

  Future<void> scheduleHarvestReminder({
    required int hour,
    required int minute,
    String title = '🌾 ¡Plantas listas para cosechar!',
    String body =
        'Tus plantas están maduras. Entra a Lumen y recoge tus semillas.',
  }) async {
    await initialize();

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year, now.month, now.day,
      hour, minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _harvestNotificationId,
      title,
      body,
      scheduledDate,
      _notificationDetails(
        channelId: 'garden_harvest',
        channelName: 'Cosecha del jardín',
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'garden:harvest',
    );
  }

  Future<void> cancelHarvestReminder() async {
    await initialize();
    await _plugin.cancel(_harvestNotificationId);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RACHA EN RIESGO
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> scheduleStreakReminderAt({
    int hour = 20,
    int minute = 0,
    String title = '🔥 ¡Tu racha está en riesgo!',
    String body =
        'No olvides hacer tu check-in diario en Lumen para mantener tu racha.',
  }) async {
    await initialize();

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year, now.month, now.day,
      hour, minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _streakNotificationId,
      title,
      body,
      scheduledDate,
      _notificationDetails(
        channelId: 'streak_reminder',
        channelName: 'Racha diaria',
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'streak:reminder',
    );
  }

  Future<void> cancelStreakReminder() async {
    await initialize();
    await _plugin.cancel(_streakNotificationId);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TEST — enviar una notificación INMEDIATA para debug
  // ═══════════════════════════════════════════════════════════════════════════

  /// Muestra una notificación de prueba INMEDIATA. Útil para verificar
  /// que los permisos y canales están correctos antes de probar programadas.
  Future<void> showTestNotification() async {
    await initialize();
    await _plugin.show(
      9999,
      '🧪 Prueba de notificación',
      'Si ves esto, las notificaciones funcionan correctamente en tu dispositivo.',
      _notificationDetails(),
      payload: 'test',
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  NotificationDetails _notificationDetails({
    String channelId = 'lumen_reminders',
    String channelName = 'Recordatorios de Lumen',
    Importance importance = Importance.high,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        importance: importance,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        styleInformation: const BigTextStyleInformation(''),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  int _idFromReminderId(String reminderId, int day) {
    final hash = reminderId.hashCode.abs() % 900 + 1000;
    return hash + day;
  }
}