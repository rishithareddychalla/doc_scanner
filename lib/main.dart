// lib/main.dart
import 'package:flutter/material.dart';
import 'core/app_theme.dart';
import 'screens/home_screen.dart';
import 'services/document_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive storage
  await DocumentStorageService().initialize();

  // TODO: Initialize Hive / DB / Firebase etc. here later.

  runApp(const DocScannerApp());
}

class DocScannerApp extends StatelessWidget {
  const DocScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Doc Scanner',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const HomeScreen(),
    );
  }
}
