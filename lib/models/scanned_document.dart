// lib/models/scanned_document.dart
import 'dart:io';
import 'package:hive/hive.dart';

part 'scanned_document.g.dart';

@HiveType(typeId: 0)
class ScannedDocument extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  final List<String> imagePaths; // Store paths instead of File objects

  @HiveField(3)
  final DateTime createdAt;

  ScannedDocument({
    required this.id,
    required this.title,
    required this.imagePaths,
    required this.createdAt,
  });

  // Helper getter to convert paths to File objects
  List<File> get imageFiles => imagePaths.map((path) => File(path)).toList();

  // Helper method to create from File objects
  static ScannedDocument fromFiles({
    required String id,
    required String title,
    required List<File> imageFiles,
    required DateTime createdAt,
  }) {
    return ScannedDocument(
      id: id,
      title: title,
      imagePaths: imageFiles.map((f) => f.path).toList(),
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'imagePaths': imagePaths,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static ScannedDocument fromJson(Map<String, dynamic> json) {
    return ScannedDocument(
      id: json['id'],
      title: json['title'],
      imagePaths: List<String>.from(json['imagePaths']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

@HiveType(typeId: 1)
class SavedPdf extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  final String filePath;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final String? sourceDocumentId;

  @HiveField(5)
  final int pageCount;

  @HiveField(6)
  final int fileSize; // in bytes

  SavedPdf({
    required this.id,
    required this.title,
    required this.filePath,
    required this.createdAt,
    this.sourceDocumentId,
    required this.pageCount,
    required this.fileSize,
  });

  // Helper getter to get File object
  File get file => File(filePath);

  // Helper to get formatted file size
  String get formattedFileSize {
    if (fileSize < 1024) return '${fileSize}B';
    if (fileSize < 1024 * 1024)
      return '${(fileSize / 1024).toStringAsFixed(1)}KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'filePath': filePath,
      'createdAt': createdAt.toIso8601String(),
      'sourceDocumentId': sourceDocumentId,
      'pageCount': pageCount,
      'fileSize': fileSize,
    };
  }

  static SavedPdf fromJson(Map<String, dynamic> json) {
    return SavedPdf(
      id: json['id'],
      title: json['title'],
      filePath: json['filePath'],
      createdAt: DateTime.parse(json['createdAt']),
      sourceDocumentId: json['sourceDocumentId'],
      pageCount: json['pageCount'],
      fileSize: json['fileSize'] ?? 0,
    );
  }
}
