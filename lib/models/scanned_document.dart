// lib/models/scanned_document.dart
import 'dart:io';

class ScannedDocument {
  final String id;
  String title;
  final List<File> imageFiles; // later you can store path instead of File
  final DateTime createdAt;

  ScannedDocument({
    required this.id,
    required this.title,
    required this.imageFiles,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'imageFiles': imageFiles.map((f) => f.path).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static ScannedDocument fromJson(Map<String, dynamic> json) {
    return ScannedDocument(
      id: json['id'],
      title: json['title'],
      imageFiles: (json['imageFiles'] as List)
          .map((path) => File(path as String))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

// New model for saved PDFs
class SavedPdf {
  final String id;
  final String title;
  final String filePath;
  final DateTime createdAt;
  final String? sourceDocumentId;
  final int pageCount;

  SavedPdf({
    required this.id,
    required this.title,
    required this.filePath,
    required this.createdAt,
    this.sourceDocumentId,
    required this.pageCount,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'filePath': filePath,
      'createdAt': createdAt.toIso8601String(),
      'sourceDocumentId': sourceDocumentId,
      'pageCount': pageCount,
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
    );
  }
}
