// lib/services/document_storage_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/scanned_document.dart';

class DocumentStorageService {
  DocumentStorageService._internal();
  static final DocumentStorageService _instance =
      DocumentStorageService._internal();
  factory DocumentStorageService() => _instance;

  final _uuid = const Uuid();

  final List<ScannedDocument> _documents = [];
  final List<SavedPdf> _savedPdfs = [];

  List<ScannedDocument> getAllDocuments() {
    // Later: load from DB
    return List.unmodifiable(_documents.reversed);
  }

  ScannedDocument addDocument({
    required List<File> imageFiles,
    String? suggestedTitle,
    required String title,
  }) {
    final doc = ScannedDocument(
      id: _uuid.v4(),
      title: suggestedTitle ?? 'Scan ${DateTime.now().toIso8601String()}',
      imageFiles: imageFiles,
      createdAt: DateTime.now(),
    );
    _documents.add(doc);
    _saveDocuments();
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
    _saveDocuments();
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
    _saveDocuments();
    return newDoc;
  }

  void updateDocument(ScannedDocument doc) {
    final index = _documents.indexWhere((d) => d.id == doc.id);
    if (index != -1) {
      _documents[index] = doc;
      _saveDocuments();
    }
  }

  void _saveDocuments() {
    // Save to persistent storage (implementation can be added later)
  }

  // New PDF methods
  List<SavedPdf> getAllPdfs() => List.unmodifiable(_savedPdfs);

  void addPdf({
    required String title,
    required String filePath,
    required int pageCount,
    String? sourceDocumentId,
  }) {
    final pdf = SavedPdf(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      filePath: filePath,
      createdAt: DateTime.now(),
      sourceDocumentId: sourceDocumentId,
      pageCount: pageCount,
    );
    _savedPdfs.add(pdf);
    _savePdfs();
  }

  SavedPdf? getPdfById(String id) {
    try {
      return _savedPdfs.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  void deletePdf(String id) {
    _savedPdfs.removeWhere((p) => p.id == id);
    _savePdfs();
  }

  void renamePdf(String id, String newTitle) {
    final pdf = getPdfById(id);
    if (pdf != null) {
      final index = _savedPdfs.indexWhere((p) => p.id == id);
      if (index != -1) {
        _savedPdfs[index] = SavedPdf(
          id: pdf.id,
          title: newTitle,
          filePath: pdf.filePath,
          createdAt: pdf.createdAt,
          sourceDocumentId: pdf.sourceDocumentId,
          pageCount: pdf.pageCount,
        );
        _savePdfs();
      }
    }
  }

  void _savePdfs() {
    // Save to persistent storage (implementation can be added later)
  }
}
