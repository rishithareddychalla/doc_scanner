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
  File? _previewImage;
  bool _isSaving = false;
  final _storage = DocumentStorageService();

  Future<void> _pickFromCamera() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 95,
    );
    if (picked != null) {
      setState(() {
        _previewImage = File(picked.path);
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
        _previewImage = File(picked.path);
      });
    }
  }

  Future<void> _saveDocument() async {
    if (_previewImage == null) return;

    setState(() {
      _isSaving = true;
    });

    // TODO: Do filters, cropping, perspective fix before saving
    _storage.addDocument(imageFile: _previewImage!);

    setState(() {
      _isSaving = false;
      _previewImage = null;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _previewImage != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (hasImage)
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    _previewImage!,
                    fit: BoxFit.contain,
                  ),
                ),
              )
            else
              Expanded(
                child: Center(
                  child: Text(
                    'No preview yet.\nTap "Camera" or "Gallery" to start.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
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
