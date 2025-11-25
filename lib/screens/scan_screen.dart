// lib/screens/scan_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/document_storage_service.dart';
import '../widgets/primary_button.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<File> _previewImages = [];
  bool _isSaving = false;
  final _storage = DocumentStorageService();

  Future<void> _pickFromCamera() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 95,
    );
    if (picked != null) {
      setState(() {
        _previewImages.add(File(picked.path));
      });
    }
  }

  Future<void> _pickFromGallery() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
    );
    if (picked != null) {
      setState(() {
        _previewImages.add(File(picked.path));
      });
    }
  }

  Future<void> _saveDocument() async {
    if (_previewImages.isEmpty) return;

    setState(() {
      _isSaving = true;
    });

    // TODO: Do filters, cropping, perspective fix before saving
    _storage.addDocument(imageFiles: _previewImages);

    setState(() {
      _isSaving = false;
      _previewImages.clear();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document saved')),
      );
    }
  }

  Widget _buildPreview() {
    if (_previewImages.isEmpty) {
      return const Center(child: Text('No pages added yet'));
    }

    return ListView.builder(
      itemCount: _previewImages.length,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _previewImages[index],
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Text('Page ${index + 1}'),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _previewImages.removeAt(index);
                    });
                  },
                  icon: const Icon(Icons.delete_outline),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _previewImages.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: _previewImages.isEmpty
                  ? Center(
                      child: Text(
                        'No preview yet.\nTap "Camera" or "Gallery" to start.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    )
                  : _buildPreview(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: 'Camera',
                    icon: Icons.camera_alt_outlined,
                    onPressed: _pickFromCamera,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    label: 'Gallery',
                    icon: Icons.photo_library_outlined,
                    onPressed: _pickFromGallery,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (hasImage)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _saveDocument,
                  icon: _isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_isSaving ? 'Saving...' : 'Save Document'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
