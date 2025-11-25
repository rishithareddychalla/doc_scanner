// lib/screens/document_detail_screen.dart
import 'package:flutter/material.dart';
import '../services/document_storage_service.dart';
import '../models/scanned_document.dart';

class DocumentDetailScreen extends StatelessWidget {
  final String documentId;
  const DocumentDetailScreen({super.key, required this.documentId});

  @override
  Widget build(BuildContext context) {
    final doc =
        DocumentStorageService().getById(documentId) as ScannedDocument?;

    if (doc == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Document')),
        body: const Center(
          child: Text('Document not found'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(doc.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: implement share as PDF / image
            },
          ),
        ],
      ),
      body: Center(
        child: Image.file(doc.imageFile),
      ),
      // TODO: Add filters / crop / OCR buttons below
    );
  }
}
