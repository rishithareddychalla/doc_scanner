// lib/screens/document_list_screen.dart
import 'package:docscanner/models/scanned_document.dart';
import 'package:flutter/material.dart';
import '../services/document_storage_service.dart';
import '../widgets/document_grid_tile.dart';
import '../widgets/pdf_grid_tile.dart';
import 'document_detail_screen.dart';
import 'pdf_viewer_screen.dart';

class DocumentListScreen extends StatefulWidget {
  const DocumentListScreen({super.key});

  @override
  State<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends State<DocumentListScreen> {
  final _storage = DocumentStorageService();
  String _selectedFilter = 'all'; // 'all', 'documents', 'pdfs'

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
            decoration: const InputDecoration(
              labelText: 'Document name',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Rename'),
            ),
          ],
        );
      },
    );

    if (newName != null && newName.isNotEmpty) {
      await _storage.renameDocument(doc.id, newName);
      setState(() {});
    }
  }

  Future<void> _renamePdf(SavedPdf pdf) async {
    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: pdf.title);
        return AlertDialog(
          title: const Text('Rename PDF'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'PDF name',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Rename'),
            ),
          ],
        );
      },
    );

    if (newName != null && newName.isNotEmpty) {
      await _storage.renamePdf(pdf.id, newName);
      setState(() {});
    }
  }

  Future<void> _deletePdf(SavedPdf pdf) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete PDF'),
        content: Text('Are you sure you want to delete "${pdf.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Delete from storage
        await _storage.deletePdf(pdf.id);

        // Delete the actual file
        if (await pdf.file.exists()) {
          await pdf.file.delete();
        }

        setState(() {});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PDF deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting PDF: $e')));
        }
      }
    }
  }

  List<dynamic> _getFilteredItems() {
    switch (_selectedFilter) {
      case 'documents':
        return _storage.getAllDocuments();
      case 'pdfs':
        return _storage.getAllPdfs();
      default:
        return _storage.getAllItems();
    }
  }

  int _getDocumentCount() => _storage.getAllDocuments().length;
  int _getPdfCount() => _storage.getAllPdfs().length;

  @override
  Widget build(BuildContext context) {
    final items = _getFilteredItems();
    final documentCount = _getDocumentCount();
    final pdfCount = _getPdfCount();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Documents'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          'all',
                          'All (${documentCount + pdfCount})',
                          Icons.folder_outlined,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'documents',
                          'Documents ($documentCount)',
                          Icons.description_outlined,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'pdfs',
                          'PDFs ($pdfCount)',
                          Icons.picture_as_pdf_outlined,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: items.isEmpty
          ? _buildEmptyState()
          : GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 0.75,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];

                if (item is ScannedDocument) {
                  return DocumentGridTile(
                    doc: item,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              DocumentDetailScreen(documentId: item.id),
                        ),
                      ).then((_) => setState(() {}));
                    },
                    onRename: () => _renameDocument(item),
                    onDelete: () async {
                      await _storage.deleteDocument(item.id);
                      setState(() {});
                    },
                  );
                } else if (item is SavedPdf) {
                  return PdfGridTile(
                    pdf: item,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PdfViewerScreen(pdf: item),
                        ),
                      ).then((deleted) {
                        if (deleted == true) {
                          setState(() {});
                        }
                      });
                    },
                    onRename: () => _renamePdf(item),
                    onDelete: () => _deletePdf(item),
                  );
                }

                return const SizedBox(); // Fallback
              },
            ),
    );
  }

  Widget _buildFilterChip(String filter, String label, IconData icon) {
    final isSelected = _selectedFilter == filter;
    return FilterChip(
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = filter;
        });
      },
      avatar: Icon(icon, size: 18, color: isSelected ? Colors.white : null),
      label: Text(label),
      selectedColor: Theme.of(context).primaryColor,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : null,
        fontWeight: isSelected ? FontWeight.w600 : null,
      ),
    );
  }

  Widget _buildEmptyState() {
    String title;
    String subtitle;
    IconData icon;

    switch (_selectedFilter) {
      case 'documents':
        title = 'No documents yet';
        subtitle = 'Scan something to get started!';
        icon = Icons.document_scanner;
        break;
      case 'pdfs':
        title = 'No PDFs yet';
        subtitle = 'Create a PDF from your documents!';
        icon = Icons.picture_as_pdf;
        break;
      default:
        title = 'Nothing here yet';
        subtitle = 'Scan documents or create PDFs to get started!';
        icon = Icons.folder_open;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
