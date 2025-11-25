// lib/models/scanned_document.dart
import 'dart:io';

class ScannedDocument {
  final String id;
  final String title;
  final File imageFile; // later you can store path instead of File
  final DateTime createdAt;

  ScannedDocument({
    required this.id,
    required this.title,
    required this.imageFile,
    required this.createdAt,
  });
}
