import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  await StorageService.init();

  // Wire up the reverse MethodChannel handler so the native foreground
  // service can notify Flutter when notification buttons are pressed.
  NotificationService.init();

  runApp(const PomodoroApp());
}
