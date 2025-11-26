// lib/screens/scan_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../widgets/primary_button.dart';
import 'document_detail_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<bool> _requestPermissions(ImageSource source) async {
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      return status.isGranted;
    } else {
      // For gallery access
      final status = await Permission.photos.request();
      if (status.isDenied) {
        // Try storage permission for older Android versions
        final storageStatus = await Permission.storage.request();
        return storageStatus.isGranted;
      }
      return status.isGranted;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    // Request permissions first
    final hasPermission = await _requestPermissions(source);

    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              source == ImageSource.camera
                  ? 'Camera permission is required to take photos'
                  : 'Storage permission is required to access gallery',
            ),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => openAppSettings(),
            ),
          ),
        );
      }
      return;
    }

    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 95,
      );
      if (picked != null && mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => DocumentDetailScreen.newDocument(
              imageFiles: [File(picked.path)],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Text(
                'Tap "Camera" or "Gallery" to start.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: 'Camera',
                    icon: Icons.camera_alt_outlined,
                    onPressed: () => _pickImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    label: 'Gallery',
                    icon: Icons.photo_library_outlined,
                    onPressed: () => _pickImage(ImageSource.gallery),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
