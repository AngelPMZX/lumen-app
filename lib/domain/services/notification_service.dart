import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../data/models/win_back.dart';

/// Servicio singleton de notificaciones locales.
/// Maneja recordatorios del usuario y notificaciones de cosecha de jardín.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void>? _ready;

  static const int _harvestNotificationId = 2000;
  static const int _streakNotificationId = 3000;
  static const int _commitmentNotificationId = 4000;
  static const int _weeklySummaryNotificationId = 5000;
  static const int _winBackFirstId = 6000;
  static const int _winBackSecondId = 6001;

  // ═══════════════════════════════════════════════════════════════════════════
  // INICIALIZACIÓN
  // ═══════════════════════════════════════════════════════════════════════════

  /// Se puede llamar desde varios sitios y desde el arranque sin bloquear la
  /// primera pantalla: siempre es la misma inicialización, y todo lo que
  /// programa o cancela algo la espera antes de tocar el plugin.
  Future<void> initialize() => _ready ??= _initialize();

  Future<void> _initialize() async {
    // Cargar base de datos de zonas horarias
    tz.initializeTimeZones();

    // ⭐ CRÍTICO: configurar tz.local con la zona horaria REAL del dispositivo.
    // Sin esto, tz.local puede caer en UTC y las notificaciones programadas
    // se disparan a la hora incorrecta (bug: notificación 6h antes en México).
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      debugPrint('🌍 Timezone configured: $timeZoneName');
    } catch (e) {
      debugPrint('⚠️ Could not set timezone, using default: $e');
    }

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

    debugPrint('✅ NotificationService initialized');
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PERMISOS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<bool> requestAllPermissions() async {
    await initialize();

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation
        <AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      final notifGranted =
          await androidPlugin.requestNotificationsPermission() ?? false;
      debugPrint('📱 Notifications permission granted: $notifGranted');

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

    debugPrint('📅 Scheduling ONE-OFF for: $scheduledDate (now: $now)');

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
    await initialize();
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

    debugPrint('📅 Scheduling WEEKLY (day $weekday) for: $scheduledDate (now: $now)');

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
  // RETO DE LECCIÓN — una sola vez, al día siguiente
  // ═══════════════════════════════════════════════════════════════════════════
  /// Recordatorio único para el día siguiente (no se repite): pregunta por el
  /// micro-reto que el usuario eligió en una lección.
  Future<void> scheduleCommitmentReminder({
    required String title,
    required String body,
    int hour = 10,
    int minute = 0,
  }) async {
    await initialize();

    final now = tz.TZDateTime.now(tz.local);
    final tomorrow = now.add(const Duration(days: 1));
    final scheduledDate = tz.TZDateTime(
      tz.local,
      tomorrow.year, tomorrow.month, tomorrow.day,
      hour, minute,
    );

    await _plugin.zonedSchedule(
      _commitmentNotificationId,
      title,
      body,
      scheduledDate,
      _notificationDetails(
        channelId: 'lesson_commitment',
        channelName: 'Retos de lecciones',
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'commitment:check',
    );
  }

  /// Cada domingo a las 19:00: "tu resumen semanal está listo". Idempotente:
  /// reprogramarlo con el mismo id reemplaza el anterior.
  Future<void> scheduleWeeklySummaryReminder({
    required String title,
    required String body,
  }) async {
    await initialize();

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, 19);
    while (scheduled.weekday != DateTime.sunday || scheduled.isBefore(now)) {
      scheduled = tz.TZDateTime(
          tz.local, scheduled.year, scheduled.month, scheduled.day + 1, 19);
    }

    await _plugin.zonedSchedule(
      _weeklySummaryNotificationId,
      title,
      body,
      scheduled,
      _notificationDetails(
        channelId: 'weekly_summary',
        channelName: 'Resumen semanal',
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: 'summary:weekly',
    );
  }

  Future<void> cancelCommitmentReminder() async {
    await initialize();
    await _plugin.cancel(_commitmentNotificationId);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // VOLVER A LUMEN
  // ═══════════════════════════════════════════════════════════════════════════

  /// Dos avisos suaves por si pasan días sin abrir la app: a los 3 y a los 14.
  /// **Se reprograman cada vez que se abre Lumen**, así que solo suenan si de
  /// verdad se alejó. Después del segundo, silencio.
  Future<void> scheduleWinBackReminders({
    required String firstTitle,
    required String firstBody,
    required String secondTitle,
    required String secondBody,
  }) async {
    await initialize();
    await cancelWinBackReminders();

    final now = tz.TZDateTime.now(tz.local);
    for (final (id, days, title, body) in [
      (_winBackFirstId, WinBack.firstDays, firstTitle, firstBody),
      (_winBackSecondId, WinBack.secondDays, secondTitle, secondBody),
    ]) {
      final when = WinBack.dateFor(now, days);
      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          tz.TZDateTime(tz.local, when.year, when.month, when.day, when.hour),
          _notificationDetails(importance: Importance.defaultImportance),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'win_back',
        );
      } catch (e) {
        debugPrint('Win-back schedule error: $e');
      }
    }
  }

  Future<void> cancelWinBackReminders() async {
    await initialize();
    await _plugin.cancel(_winBackFirstId);
    await _plugin.cancel(_winBackSecondId);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TEST — enviar una notificación INMEDIATA para debug
  // ═══════════════════════════════════════════════════════════════════════════

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