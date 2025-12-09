// lib/screens/pdf_viewer_screen.dart
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/scanned_document.dart';
import '../services/document_storage_service.dart';
class PdfViewerScreen extends StatefulWidget {
  final SavedPdf pdf;

  const PdfViewerScreen({super.key, required this.pdf});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}
class _PdfViewerScreenState extends State<PdfViewerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pdf.title),
        actions: [
          IconButton(
            onPressed: _sharePdf,
            icon: const Icon(Icons.share),
            tooltip: 'Share PDF',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'print':
                  _printPdf();
                  break;
                case 'rename':
                  _renamePdf();
                  break;
                case 'delete':
                  _deletePdf();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'print',
                child: Row(
                  children: [
                    Icon(Icons.print, size: 18),
                    SizedBox(width: 8),
                    Text('Print'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'rename',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18),
                    SizedBox(width: 8),
                    Text('Rename'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Column(
        children: [
          // PDF Info Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.picture_as_pdf,
                      color: Colors.red.shade600,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.pdf.title,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Created: ${DateFormat.yMMMd().add_jm().format(widget.pdf.createdAt)}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildInfoChip(
                      icon: Icons.description,
                      label: '${widget.pdf.pageCount} pages',
                      color: Colors.blue.shade600,
                    ),
                    _buildInfoChip(
                      icon: Icons.storage,
                      label: widget.pdf.formattedFileSize,
                      color: Colors.green.shade600,
                    ),
                    _buildInfoChip(
                      icon: Icons.file_present,
                      label: 'PDF Format',
                      color: Colors.red.shade600,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // PDF Viewer Section
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: PdfPreview(
                build: (format) async {
                  return await widget.pdf.file.readAsBytes();
                },
                allowSharing: false,
                allowPrinting: false,
                canChangePageFormat: false,
                canChangeOrientation: false,
                canDebug: false,
                actions: const [],
                scrollViewDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sharePdf() async {
    try {
      await Share.shareXFiles([
        XFile(widget.pdf.filePath),
      ], text: '${widget.pdf.title} - PDF Document');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sharing PDF: $e')));
      }
    }
  }

  Future<void> _printPdf() async {
    try {
      final pdfBytes = await widget.pdf.file.readAsBytes();
      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name: widget.pdf.title,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error printing PDF: $e')));
      }
    }
  }

  Future<void> _renamePdf() async {
    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: widget.pdf.title);
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
      await DocumentStorageService().renamePdf(widget.pdf.id, newName);
      setState(() {
        widget.pdf.title = newName;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF renamed successfully')),
        );
      }
    }
  }

  Future<void> _deletePdf() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete PDF'),
        content: Text('Are you sure you want to delete "${widget.pdf.title}"?'),
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
        await DocumentStorageService().deletePdf(widget.pdf.id);

        // Delete the actual file
        if (await widget.pdf.file.exists()) {
          await widget.pdf.file.delete();
        }

        if (mounted) {
          Navigator.of(context).pop(true); // Return true to indicate deletion
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
}
