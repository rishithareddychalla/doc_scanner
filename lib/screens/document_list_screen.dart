// lib/screens/document_list_screen.dart
import 'package:flutter/material.dart';
import '../services/document_storage_service.dart';
import '../widgets/document_tile.dart';
import 'document_detail_screen.dart';

class DocumentListScreen extends StatefulWidget {
  const DocumentListScreen({super.key});

  @override
  State<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends State<DocumentListScreen> {
  final _storage = DocumentStorageService();

  @override
  Widget build(BuildContext context) {
    final docs = _storage.getAllDocuments();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Documents'),
      ),
      body: docs.isEmpty
          ? const Center(
              child: Text('No documents yet. Scan something!'),
            )
          : ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                return DocumentTile(
                  doc: doc,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            DocumentDetailScreen(documentId: doc.id),
                      ),
                    ).then((_) => setState(() {})); // Refresh after back
                  },
                  onDelete: () {
                    _storage.deleteDocument(doc.id);
                    setState(() {});
                  },
                );
              },
            ),
    );
  }
}
