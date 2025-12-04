// lib/services/document_storage_service.dart
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/scanned_document.dart';

class DocumentStorageService {
  DocumentStorageService._internal();
  static final DocumentStorageService _instance =
      DocumentStorageService._internal();
  factory DocumentStorageService() => _instance;

  final _uuid = const Uuid();

  // Hive boxes
  Box<ScannedDocument>? _documentsBox;
  Box<SavedPdf>? _pdfsBox;

  // Initialize Hive and open boxes
  Future<void> initialize() async {
    await Hive.initFlutter();

    // Register adapters if not already registered
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ScannedDocumentAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(SavedPdfAdapter());
    }

    // Open boxes
    _documentsBox = await Hive.openBox<ScannedDocument>('documents');
    _pdfsBox = await Hive.openBox<SavedPdf>('pdfs');
  }

  // Document methods
  List<ScannedDocument> getAllDocuments() {
    if (_documentsBox == null) return [];
    return _documentsBox!.values.toList().reversed.toList();
  }

  Future<ScannedDocument> addDocument({
    required List<File> imageFiles,
    required String title,
  }) async {
    if (_documentsBox == null) throw Exception('Storage not initialized');

    final doc = ScannedDocument.fromFiles(
      id: _uuid.v4(),
      title: title,
      imageFiles: imageFiles,
      createdAt: DateTime.now(),
    );

    await _documentsBox!.add(doc);
    return doc;
  }

  ScannedDocument? getById(String id) {
    if (_documentsBox == null) return null;
    try {
      return _documentsBox!.values.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteDocument(String id) async {
    if (_documentsBox == null) return;

    final docIndex = _documentsBox!.values.toList().indexWhere(
      (d) => d.id == id,
    );
    if (docIndex != -1) {
      await _documentsBox!.deleteAt(docIndex);
    }
  }

  Future<ScannedDocument?> renameDocument(String id, String newTitle) async {
    if (_documentsBox == null) return null;

    final doc = getById(id);
    if (doc == null) return null;

    doc.title = newTitle;
    await doc.save();
    return doc;
  }

  Future<void> updateDocument(ScannedDocument doc) async {
    if (_documentsBox == null) return;
    await doc.save();
  }

  // PDF methods
  List<SavedPdf> getAllPdfs() {
    if (_pdfsBox == null) return [];
    return _pdfsBox!.values.toList().reversed.toList();
  }

  Future<SavedPdf> addPdf({
    required String title,
    required String filePath,
    required int pageCount,
    String? sourceDocumentId,
  }) async {
    if (_pdfsBox == null) throw Exception('Storage not initialized');

    // Check if PDF with same file path already exists to prevent duplicates
    final existingPdf = _pdfsBox!.values
        .where((pdf) => pdf.filePath == filePath)
        .firstOrNull;
    if (existingPdf != null) {
      return existingPdf; // Return existing PDF instead of creating duplicate
    }

    // Get file size
    final file = File(filePath);
    final fileSize = await file.length();

    final pdf = SavedPdf(
      id: _uuid.v4(), // Use UUID instead of timestamp for better uniqueness
      title: title,
      filePath: filePath,
      createdAt: DateTime.now(),
      sourceDocumentId: sourceDocumentId,
      pageCount: pageCount,
      fileSize: fileSize,
    );

    await _pdfsBox!.add(pdf);
    return pdf;
  }

  SavedPdf? getPdfById(String id) {
    if (_pdfsBox == null) return null;
    try {
      return _pdfsBox!.values.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> deletePdf(String id) async {
    if (_pdfsBox == null) return;

    final pdfIndex = _pdfsBox!.values.toList().indexWhere((p) => p.id == id);
    if (pdfIndex != -1) {
      await _pdfsBox!.deleteAt(pdfIndex);
    }
  }

  Future<void> renamePdf(String id, String newTitle) async {
    if (_pdfsBox == null) return;

    final pdf = getPdfById(id);
    if (pdf != null) {
      pdf.title = newTitle;
      await pdf.save();
    }
  }

  // Combined list of all items (documents + PDFs) sorted by creation date
  List<dynamic> getAllItems() {
    final documents = getAllDocuments();
    final pdfs = getAllPdfs();

    final allItems = <dynamic>[...documents, ...pdfs];
    allItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return allItems;
  }

  // Close boxes when done
  Future<void> close() async {
    await _documentsBox?.close();
    await _pdfsBox?.close();
  }
}
