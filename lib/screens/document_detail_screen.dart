// lib/screens/document_detail_screen.dart
import 'package:flutter/material.dart';
import '../services/document_storage_service.dart';
import '../models/scanned_document.dart';

class DocumentDetailScreen extends StatefulWidget {
  final String documentId;
  const DocumentDetailScreen({super.key, required this.documentId});

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final doc =
        DocumentStorageService().getById(widget.documentId) as ScannedDocument?;

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
      body: PageView.builder(
        itemCount: doc.imageFiles.length,
        onPageChanged: (page) {
          setState(() {
            _currentPage = page;
          });
        },
        itemBuilder: (context, index) {
          return Image.file(doc.imageFiles[index]);
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          // TODO: implement actions
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.crop),
            label: 'Crop',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.rotate_90_degrees_ccw),
            label: 'Rotate',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.filter),
            label: 'Filter',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.delete_outline),
            label: 'Delete',
          ),
        ],
      ),
    );
  }
}
