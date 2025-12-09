// lib/widgets/document_grid_tile.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/scanned_document.dart';

class DocumentGridTile extends StatelessWidget {
  final ScannedDocument doc;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const DocumentGridTile({
    super.key,
    required this.doc,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

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
            Flexible(
              flex: 3,
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 100),
                decoration: BoxDecoration(
                  image: doc.imageFiles.isNotEmpty
                      ? DecorationImage(
                          image: FileImage(doc.imageFiles.first),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: doc.imageFiles.isEmpty
                    ? const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 48,
                          color: Colors.grey,
                        ),
                      )
                    : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 6.0, 0.0, 0.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      doc.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onSelected: (value) {
                      if (value == 'rename') {
                        onRename();
                      } else if (value == 'delete') {
                        onDelete();
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'rename',
                            child: Text('Rename'),
                          ),
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                        ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 2.0, 8.0, 6.0),
              child: Text(
                DateFormat.yMMMd().format(doc.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                    ),
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
