import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'domain/providers/auth_provider.dart';
import 'domain/providers/theme_provider.dart';
import 'domain/providers/garden_provider.dart';
import 'package:gimnasio_emocional/domain/services/notification_service.dart';
import 'domain/services/sound_service.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'domain/services/analytics_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await initializeDateFormatting('es_ES', null);
  await initializeDateFormatting('en_US', null);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Caché local de Firestore también en web (en Android/iOS viene activa):
  // RoutesService la usa para no volver a descargar el contenido de las rutas.
  if (kIsWeb) {
    FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
  }

  // Crashlytics: errores de Flutter y de la plataforma. No existe en web, y en
  // debug no se envía nada (los errores ya se ven en la consola).
  if (!kIsWeb) {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }
  await AnalyticsService.instance.initialize();

   await NotificationService.instance.initialize();
  await SoundService.instance.initialize();
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('es'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('es'),
      startLocale: const Locale('es'),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => GardenProvider()),
        ],
        child: const LumenApp(),
      ),
    ),
  );
}
