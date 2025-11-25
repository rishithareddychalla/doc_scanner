// lib/services/document_storage_service.dart
import 'dart:io';
import 'package:uuid/uuid.dart';
import '../models/scanned_document.dart';

class DocumentStorageService {
  DocumentStorageService._internal();
  static final DocumentStorageService _instance =
      DocumentStorageService._internal();
  factory DocumentStorageService() => _instance;

  final _uuid = const Uuid();

  final List<ScannedDocument> _documents = [];

  List<ScannedDocument> getAllDocuments() {
    // Later: load from DB
    return List.unmodifiable(_documents.reversed);
  }

  ScannedDocument addDocument({
    required File imageFile,
    String? suggestedTitle,
  }) {
    final doc = ScannedDocument(
      id: _uuid.v4(),
      title: suggestedTitle ?? 'Scan ${DateTime.now().toIso8601String()}',
      imageFile: imageFile,
      createdAt: DateTime.now(),
    );
    _documents.add(doc);
    return doc;
  }

  ScannedDocument? getById(String id) {
    try {
      return _documents.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  void deleteDocument(String id) {
    _documents.removeWhere((d) => d.id == id);
  }
}
