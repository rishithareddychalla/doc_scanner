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
    final totalCount = documentCount + pdfCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // Modern Header with Gradient
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Text(
                'My Documents',
                style: TextStyle(
                  color: Colors.grey[900],
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF2563EB).withOpacity(0.1),
                      const Color(0xFF3B82F6).withOpacity(0.05),
                      Colors.white,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -50,
                      right: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF2563EB).withOpacity(0.1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Stats and Filter Section
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Row
                  Row(
                    children: [
                      _buildStatCard(
                        icon: Icons.folder_rounded,
                        count: totalCount,
                        label: 'Total Items',
                        color: const Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        icon: Icons.description_rounded,
                        count: documentCount,
                        label: 'Documents',
                        color: const Color(0xFF10B981),
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        icon: Icons.picture_as_pdf_rounded,
                        count: pdfCount,
                        label: 'PDFs',
                        color: const Color(0xFFEF4444),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildModernFilterChip(
                          'all',
                          'All',
                          Icons.grid_view_rounded,
                          totalCount,
                        ),
                        const SizedBox(width: 10),
                        _buildModernFilterChip(
                          'documents',
                          'Documents',
                          Icons.description_rounded,
                          documentCount,
                        ),
                        const SizedBox(width: 10),
                        _buildModernFilterChip(
                          'pdfs',
                          'PDFs',
                          Icons.picture_as_pdf_rounded,
                          pdfCount,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content Grid
          items.isEmpty
              ? SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(),
                )
              : SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.72,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
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

                      return const SizedBox();
                    }, childCount: items.length),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required int count,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernFilterChip(
    String filter,
    String label,
    IconData icon,
    int count,
  ) {
    final isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.grey[100],
          borderRadius: BorderRadius.circular(25),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.25)
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    String title;
    String subtitle;
    IconData icon;
    Color iconColor;

    switch (_selectedFilter) {
      case 'documents':
        title = 'No Documents Yet';
        subtitle = 'Start scanning documents to build your library';
        icon = Icons.document_scanner_rounded;
        iconColor = const Color(0xFF10B981);
        break;
      case 'pdfs':
        title = 'No PDFs Yet';
        subtitle = 'Create your first PDF from scanned documents';
        icon = Icons.picture_as_pdf_rounded;
        iconColor = const Color(0xFFEF4444);
        break;
      default:
        title = 'Welcome to Doc Scanner';
        subtitle = 'Scan documents or create PDFs to get started';
        icon = Icons.folder_open_rounded;
        iconColor = const Color(0xFF2563EB);
    }

    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 80, color: iconColor),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.add_circle_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Start Scanning',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
