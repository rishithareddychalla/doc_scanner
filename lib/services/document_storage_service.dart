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
    required List<File> imageFiles,
    String? suggestedTitle, required String title,
  }) {
    final doc = ScannedDocument(
      id: _uuid.v4(),
      title: suggestedTitle ?? 'Scan ${DateTime.now().toIso8601String()}',
      imageFiles: imageFiles,
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

  ScannedDocument? renameDocument(String id, String newTitle) {
    final doc = getById(id);
    if (doc == null) {
      return null;
    }
    final index = _documents.indexOf(doc);
    final newDoc = ScannedDocument(
      id: doc.id,
      title: newTitle,
      imageFiles: doc.imageFiles,
      createdAt: doc.createdAt,
    );
    _documents[index] = newDoc;
    return newDoc;
  }

  void updateDocument(ScannedDocument doc) {
    final index = _documents.indexWhere((d) => d.id == doc.id);
    if (index != -1) {
      _documents[index] = doc;
    }
  }
}
