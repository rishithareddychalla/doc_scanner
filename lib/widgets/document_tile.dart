// lib/widgets/document_tile.dart
import 'package:flutter/material.dart';
import '../models/scanned_document.dart';

class DocumentTile extends StatelessWidget {
  final ScannedDocument doc;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const DocumentTile({
    super.key,
    required this.doc,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.description_outlined),
      title: Text(
        doc.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${doc.createdAt}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: onDelete,
      ),
      onTap: onTap,
    );
  }
}
