// lib/screens/document_list_screen.dart
import 'package:docscanner/models/scanned_document.dart';
import 'package:flutter/material.dart';
import '../services/document_storage_service.dart';
import '../widgets/document_grid_tile.dart';
import 'document_detail_screen.dart';

class DocumentListScreen extends StatefulWidget {
  const DocumentListScreen({super.key});

  @override
  State<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends State<DocumentListScreen> {
  final _storage = DocumentStorageService();

  Future<void> _renameDocument(ScannedDocument doc) async {
    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: doc.title);
        return AlertDialog(
          title: const Text('Rename Document'),
          content: TextField(
            controller: controller,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Rename'),
            ),
          ],
        );
      },
    );

    if (newName != null && newName.isNotEmpty) {
      _storage.renameDocument(doc.id, newName);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final docs = _storage.getAllDocuments();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanned documents'),
      ),
      body: docs.isEmpty
          ? const Center(
              child: Text('No documents yet. Scan something!'),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 0.75,
              ),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                return DocumentGridTile(
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
                  onRename: () => _renameDocument(doc),
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
