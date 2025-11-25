// lib/models/scanned_document.dart
import 'dart:io';

class ScannedDocument {
  final String id;
  final String title;
  final List<File> imageFiles; // later you can store path instead of File
  final DateTime createdAt;

  ScannedDocument({
    required this.id,
    required this.title,
    required this.imageFiles,
    required this.createdAt,
  });
}
