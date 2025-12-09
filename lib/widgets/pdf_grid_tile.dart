// lib/widgets/pdf_grid_tile.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/scanned_document.dart';

class PdfGridTile extends StatelessWidget {
  final SavedPdf pdf;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const PdfGridTile({
    super.key,
    required this.pdf,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  Future<void> _sharePdf() async {
    try {
      await Share.shareXFiles([
        XFile(pdf.filePath),
      ], text: '${pdf.title} - PDF Document');
    } catch (e) {
      // Handle error silently or show a snackbar
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // PDF Icon Section
            Flexible(
              flex: 3,
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 100),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.red.shade400, Colors.red.shade600],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.picture_as_pdf, size: 40, color: Colors.white),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${pdf.pageCount} ${pdf.pageCount == 1 ? 'page' : 'pages'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Title and Actions Section
            Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 6.0, 0.0, 0.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          pdf.title,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.picture_as_pdf,
                              size: 11,
                              color: Colors.red.shade400,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'PDF',
                              style: TextStyle(
                                color: Colors.red.shade400,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onSelected: (value) {
                      switch (value) {
                        case 'share':
                          _sharePdf();
                          break;
                        case 'rename':
                          onRename();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'share',
                            child: Row(
                              children: [
                                Icon(Icons.share, size: 18),
                                SizedBox(width: 8),
                                Text('Share'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'rename',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 18),
                                SizedBox(width: 8),
                                Text('Rename'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                  ),
                ],
              ),
            ),
            // Date Section
            Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 2.0, 8.0, 6.0),
              child: Text(
                DateFormat.yMMMd().format(pdf.createdAt),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
