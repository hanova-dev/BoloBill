import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/di/providers.dart';
import 'data/local/database/app_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // No explicit FirebaseOptions: the Google Services Gradle plugin
  // (android/app/google-services.json) configures the native default
  // FirebaseApp at build time on Android, which firebase_core picks up here.
  await Firebase.initializeApp();

  final database = await AppDatabase.open();

  runApp(ProviderScope(
    overrides: [appDatabaseProvider.overrideWithValue(database)],
    child: const BoloBillApp(),
  ));
}
