// lib/screens/reorder_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';

class ReorderScreen extends StatefulWidget {
  final List<File> images;
  const ReorderScreen({super.key, required this.images});

  @override
  State<ReorderScreen> createState() => _ReorderScreenState();
}

class _ReorderScreenState extends State<ReorderScreen> {
  late List<File> _images;

  @override
  void initState() {
    super.initState();
    _images = List.from(widget.images);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reorder Pages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done),
            onPressed: () {
              Navigator.of(context).pop(_images);
            },
          ),
        ],
      ),
      body: ReorderableListView(
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) {
              newIndex -= 1;
            }
            final image = _images.removeAt(oldIndex);
            _images.insert(newIndex, image);
          });
        },
        children: [
          for (int i = 0; i < _images.length; i++)
            ListTile(
              key: ValueKey(_images[i].path),
              leading: Image.file(_images[i]),
              title: Text('Page ${i + 1}'),
            ),
        ],
      ),
    );
  }
}
