import 'dart:ui' show PlatformDispatcher;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/app_log.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    logAppError(
      'Uncaught Flutter framework error',
      details.exception,
      details.stack ?? StackTrace.current,
    );
  };
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    logAppError('Uncaught asynchronous application error', error, stackTrace);
    return false;
  };

  logAppInfo('Application startup: initializing Firebase.');
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error, stackTrace) {
    logAppError('Firebase initialization failed', error, stackTrace);
    rethrow;
  }
  logAppInfo('Firebase initialization completed.');
  runApp(PrioritasTugasApp());
}
