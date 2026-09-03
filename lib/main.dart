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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await initializeDateFormatting('es_ES', null);
  await initializeDateFormatting('en_US', null);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
   await NotificationService.instance.initialize();
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
