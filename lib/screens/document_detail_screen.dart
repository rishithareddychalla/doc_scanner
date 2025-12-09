// lib/screens/document_detail_screen.dart
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:image/image.dart' as img;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/scanned_document.dart';
import '../services/document_storage_service.dart';
import '../services/pdf_service.dart';
import 'reorder_screen.dart';

class DocumentDetailScreen extends StatefulWidget {
  final String? documentId;
  final List<File>? imageFiles;

  const DocumentDetailScreen({super.key, required this.documentId})
    : imageFiles = null;

  const DocumentDetailScreen.newDocument({super.key, required this.imageFiles})
    : documentId = null;

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  int _currentPage = 0;
  late PageController _pageController;

  // Tracks version bumps for images so widgets rebuild with updated files
  final Map<String, int> _imageVersions = {};

  ScannedDocument? _doc;
  bool _isNewDocument = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    if (widget.documentId != null) {
      _doc = DocumentStorageService().getById(widget.documentId!);
    } else if (widget.imageFiles != null) {
      _isNewDocument = true;
      _doc = ScannedDocument.fromFiles(
        id: DateTime.now().toIso8601String(),
        title: 'Scan ${DateFormat.yMd().add_jms().format(DateTime.now())}',
        imageFiles: widget.imageFiles!,
        createdAt: DateTime.now(),
      );
    }

    if (_doc == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pop();
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

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

  Future<void> _addPage(ImageSource source) async {
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
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        // First add the image path to imagePaths
        setState(() {
          _doc!.imagePaths.add(pickedFile.path);
          if (!_isNewDocument) {
            DocumentStorageService().updateDocument(_doc!);
          }
        });

        // Show option to edit the newly added page
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Page added! Tap Edit to crop or adjust.'),
              action: SnackBarAction(
                label: 'Edit Now',
                onPressed: () {
                  // Set current page to the newly added image
                  setState(() {
                    _currentPage = _doc!.imageFiles.length - 1;
                  });
                  _pageController.animateToPage(
                    _currentPage,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                  _editCurrentPage();
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  Future<void> _editCurrentPage() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) =>
          ImageEditDialog(imageFile: _doc!.imageFiles[_currentPage]),
    );

    if (result == true) {
      // Image was edited, refresh the UI
      final path = _doc!.imagePaths[_currentPage];

      // Clear any cached image bytes for this file so fresh data is shown
      await FileImage(File(path)).evict();

      _imageVersions[path] = (_imageVersions[path] ?? 0) + 1;
      setState(() {});
      if (!_isNewDocument) {
        DocumentStorageService().updateDocument(_doc!);
      }
    }
  }

  void _deletePage() {
    if (_doc!.imageFiles.length > 1) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Delete Page'),
            content: const Text('Are you sure you want to delete this page?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _doc!.imagePaths.removeAt(_currentPage);
                    if (_currentPage >= _doc!.imageFiles.length) {
                      _currentPage = _doc!.imageFiles.length - 1;
                    }
                    _pageController.jumpToPage(_currentPage);
                    if (!_isNewDocument) {
                      DocumentStorageService().updateDocument(_doc!);
                    }
                  });
                  Navigator.of(context).pop();
                },
                child: const Text('Delete'),
              ),
            ],
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete the last page.')),
      );
    }
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      // For Android 13+ (API 33+)
      try {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt >= 33) {
          // Android 13+ doesn't need storage permission for app-specific directories
          return true;
        } else {
          // For older Android versions
          final status = await Permission.storage.request();
          return status.isGranted;
        }
      } catch (e) {
        print('Device info error: $e');
        // Fallback: try to request storage permission
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    }
    return true; // iOS doesn't need explicit storage permission
  }

  Future<void> _saveCurrentImage() async {
    if (_doc == null || _doc!.imageFiles.isEmpty) return;

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Saving image...'),
            ],
          ),
        ),
      );

      // Request storage permission
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        throw Exception('Storage permission denied');
      }

      final currentImage = _doc!.imageFiles[_currentPage];

      // Get external storage directory
      Directory? directory;
      try {
        directory = await getExternalStorageDirectory();
        if (directory != null) {
          directory = Directory('${directory.path}/Pictures/DocumentScanner');
        }
      } catch (e) {
        // Fallback to app documents directory
        directory = await getApplicationDocumentsDirectory();
        directory = Directory('${directory.path}/SavedImages');
      }

      if (directory == null) {
        throw Exception('No storage directory available');
      }

      // Create directory if it doesn't exist
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'scan_page_${_currentPage + 1}_$timestamp.jpg';
      final savedFile = File('${directory.path}/$filename');

      // Copy the current image to the new location
      await currentImage.copy(savedFile.path);

      if (mounted) {
        Navigator.pop(context); // Dismiss loading

        // Show success dialog with options
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
            title: const Text('Image Saved!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Page ${_currentPage + 1} saved successfully.'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.folder, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          filename,
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _shareCurrentImage();
                },
                icon: const Icon(Icons.share, size: 18),
                label: const Text('Share'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportDocument() async {
    if (_doc == null || _doc!.imageFiles.isEmpty) return;

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Exporting ${_doc!.imageFiles.length} pages...'),
            ],
          ),
        ),
      );

      // Request storage permission
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        throw Exception('Storage permission denied');
      }

      // Get external storage directory
      Directory? baseDirectory;
      try {
        baseDirectory = await getExternalStorageDirectory();
        if (baseDirectory != null) {
          baseDirectory = Directory(
            '${baseDirectory.path}/Documents/DocumentScanner',
          );
        }
      } catch (e) {
        // Fallback to app documents directory
        baseDirectory = await getApplicationDocumentsDirectory();
        baseDirectory = Directory('${baseDirectory.path}/ExportedDocuments');
      }

      if (baseDirectory == null) {
        throw Exception('No storage directory available');
      }

      // Create export directory for this document
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final sanitizedTitle = _doc!.title
          .replaceAll(RegExp(r'[^\w\s\-]'), '')
          .replaceAll(RegExp(r'\s+'), '_')
          .trim();
      final exportDirName = '${sanitizedTitle}_$timestamp';
      final exportDirectory = Directory('${baseDirectory.path}/$exportDirName');

      if (!await exportDirectory.exists()) {
        await exportDirectory.create(recursive: true);
      }

      // Copy all images to export directory
      final exportedFiles = <String>[];
      for (int i = 0; i < _doc!.imageFiles.length; i++) {
        final imageFile = _doc!.imageFiles[i];
        final filename = 'page_${i + 1}.jpg';
        final exportedFile = File('${exportDirectory.path}/$filename');

        await imageFile.copy(exportedFile.path);
        exportedFiles.add(filename);
      }

      if (mounted) {
        Navigator.pop(context); // Dismiss loading

        // Show success dialog with summary
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.folder_open, color: Colors.blue, size: 48),
            title: const Text('Document Exported!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${exportedFiles.length} pages exported successfully.'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.folder, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              exportDirName,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ...exportedFiles
                          .take(3)
                          .map(
                            (file) => Padding(
                              padding: const EdgeInsets.only(left: 24),
                              child: Text(
                                '• $file',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                      if (exportedFiles.length > 3)
                        Padding(
                          padding: const EdgeInsets.only(left: 24),
                          child: Text(
                            '• ... and ${exportedFiles.length - 3} more',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _shareDocument();
                },
                icon: const Icon(Icons.share, size: 18),
                label: const Text('Share All'),
              ),
            ],
          ),
        );

        // Show brief confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.folder, color: Colors.white),
                const SizedBox(width: 8),
                Text('${exportedFiles.length} pages exported'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting document: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveAsPdf() async {
    if (_doc == null || _doc!.imageFiles.isEmpty) return;

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Text('Creating PDF with ${_doc!.imageFiles.length} page(s)...'),
            ],
          ),
        ),
      );

      // Generate PDF
      final pdfPath = await PdfService().saveDocumentAsPdf(_doc!);

      // Save PDF info to Hive storage
      await DocumentStorageService().addPdf(
        title: _doc!.title,
        filePath: pdfPath,
        pageCount: _doc!.imageFiles.length,
        sourceDocumentId: _doc!.id,
      );

      if (mounted) {
        Navigator.pop(context); // Dismiss loading

        // Show success dialog with options
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 48),
            title: const Text('PDF Created & Saved!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Document saved as PDF with ${_doc!.imageFiles.length} page(s).',
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'PDF saved to your Documents list!',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.picture_as_pdf, size: 16, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          pdfPath.split('/').last,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  // Share the PDF
                  try {
                    await Share.shareXFiles([
                      XFile(pdfPath),
                    ], text: '${_doc!.title} - PDF Document');
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error sharing PDF: $e')),
                    );
                  }
                },
                icon: const Icon(Icons.share, size: 18),
                label: const Text('Share PDF'),
              ),
            ],
          ),
        );

        // Show brief confirmation with action to view PDFs
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.picture_as_pdf, color: Colors.white),
                const SizedBox(width: 8),
                Text('PDF saved! Find it in Documents tab.'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            action: SnackBarAction(
              label: 'View PDFs',
              textColor: Colors.white,
              onPressed: () {
                // Navigate to documents list and set filter to PDFs
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareCurrentImage() async {
    try {
      final currentImage = _doc!.imageFiles[_currentPage];
      await Share.shareXFiles([
        XFile(currentImage.path),
      ], text: 'Page ${_currentPage + 1} from ${_doc!.title}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sharing image: $e')));
      }
    }
  }

  Future<void> _shareDocument() async {
    try {
      final xFiles = _doc!.imageFiles.map((file) => XFile(file.path)).toList();

      await Share.shareXFiles(
        xFiles,
        text: '${_doc!.title} - ${_doc!.imageFiles.length} pages',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sharing document: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_doc == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(_doc!.title),
        actions: [
          // PDF Save button in top-right
          IconButton(
            onPressed: _saveAsPdf,
            icon: const Icon(Icons.save_outlined),
            tooltip: 'Save as PDF',
            color: Colors.red,
          ),
          // if (_isNewDocument)
          //   IconButton(
          //     onPressed: _saveDocument,
          //     icon: const Icon(Icons.save_outlined),
          //     tooltip: 'Save document',
          //   ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _doc!.imageFiles.length,
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                });
              },
              itemBuilder: (context, index) {
                final path = _doc!.imagePaths[index];
                final version = _imageVersions[path] ?? 0;
                return Image.file(
                  _doc!.imageFiles[index],
                  key: ValueKey('$path-$version'),
                );
              },
            ),
          ),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _doc!.imageFiles.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _currentPage == index
                            ? Colors.blue
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Image.file(
                      _doc!.imageFiles[index],
                      key: ValueKey(
                        '${_doc!.imagePaths[index]}-${_imageVersions[_doc!.imagePaths[index]] ?? 0}-thumb',
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) {
                    return Wrap(
                      children: <Widget>[
                        ListTile(
                          leading: const Icon(Icons.camera_alt),
                          title: const Text('Camera'),
                          onTap: () {
                            _addPage(ImageSource.camera);
                            Navigator.of(context).pop();
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.photo_library),
                          title: const Text('Gallery'),
                          onTap: () {
                            _addPage(ImageSource.gallery);
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
              icon: const Icon(Icons.add_a_photo),
              tooltip: 'Add Page',
            ),
            IconButton(
              onPressed: () async {
                final newImageList = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        ReorderScreen(images: _doc!.imageFiles),
                  ),
                );

                if (newImageList != null) {
                  final List<File> newFiles = List<File>.from(newImageList);
                  final newImagePaths = newFiles.map((f) => f.path).toList();
                  setState(() {
                    _doc!.imagePaths.clear();
                    _doc!.imagePaths.addAll(newImagePaths);
                    if (!_isNewDocument) {
                      DocumentStorageService().updateDocument(_doc!);
                    }
                  });
                }
              },
              icon: const Icon(Icons.reorder),
              tooltip: 'Reorder',
            ),
            IconButton(
              onPressed: _editCurrentPage,
              icon: const Icon(Icons.edit),
              tooltip: 'Edit',
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'save_image':
                    _saveCurrentImage();
                    break;
                  case 'export_doc':
                    _exportDocument();
                    break;
                  case 'save_pdf':
                    _saveAsPdf();
                    break;
                  case 'share_image':
                    _shareCurrentImage();
                    break;
                  case 'share_doc':
                    _shareDocument();
                    break;
                  case 'delete':
                    _deletePage();
                    break;
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(
                  value: 'save_image',
                  child: Row(
                    children: [
                      Icon(Icons.save, size: 18),
                      SizedBox(width: 8),
                      Text('Save Current Image'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'export_doc',
                  child: Row(
                    children: [
                      Icon(Icons.file_download, size: 18),
                      SizedBox(width: 8),
                      Text('Export Document'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'save_pdf',
                  child: Row(
                    children: [
                      Icon(Icons.picture_as_pdf, size: 18),
                      SizedBox(width: 8),
                      Text('Save as PDF'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'share_image',
                  child: Row(
                    children: [
                      Icon(Icons.share, size: 18),
                      SizedBox(width: 8),
                      Text('Share Current Image'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'share_doc',
                  child: Row(
                    children: [
                      Icon(Icons.share_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Share All Images'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete Page', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              icon: const Icon(Icons.more_vert),
              tooltip: 'More Options',
            ),
          ],
        ),
      ),
    );
  }
}

class ImageEditDialog extends StatefulWidget {
  final File imageFile;

  const ImageEditDialog({super.key, required this.imageFile});

  @override
  State<ImageEditDialog> createState() => _ImageEditDialogState();
}

class _ImageEditDialogState extends State<ImageEditDialog> {
  double _brightness = 0.0;
  double _contrast = 1.0;

  // Crop variables
  Rect? _cropRect;
  Rect? _renderedImageRect;
  ui.Image? _decodedImage;
  bool _isCropping = false;
  final GlobalKey _imageKey = GlobalKey();

  void _initializeCropRectIfNeeded() {
    // Lazily set an initial crop rect once we know the rendered image bounds.
    if (!_isCropping || _cropRect != null || _renderedImageRect == null) return;

    final width = _renderedImageRect!.width * 0.8;
    final height = _renderedImageRect!.height * 0.8;
    final left =
        _renderedImageRect!.left + (_renderedImageRect!.width - width) / 2;
    final top =
        _renderedImageRect!.top + (_renderedImageRect!.height - height) / 2;

    setState(() {
      _cropRect = Rect.fromLTWH(left, top, width, height);
    });
  }

  @override
  void initState() {
    super.initState();
    _loadImageDimensions();
  }

  Future<void> _loadImageDimensions() async {
    final data = await widget.imageFile.readAsBytes();
    final image = await decodeImageFromList(data);
    if (mounted) {
      setState(() {
        _decodedImage = image;
      });
    }
  }

  void _applyFilter() {
    setState(() {});
  }

  void _resetFilters() {
    setState(() {
      _brightness = 0.0;
      _contrast = 1.0;
      _cropRect = null;
      _isCropping = false;
    });
  }

  // Shared brightness/contrast matrix so the preview matches the saved result.
  List<double> _colorMatrix() {
    final bias = (_brightness * 255) + 128 * (1 - _contrast);
    return [
      _contrast,
      0,
      0,
      0,
      bias,
      0,
      _contrast,
      0,
      0,
      bias,
      0,
      0,
      _contrast,
      0,
      bias,
      0,
      0,
      0,
      1,
      0,
    ];
  }

  // Applies brightness/contrast directly to the image pixels.
  img.Image _applyBrightnessContrast(img.Image image) {
    if (_brightness == 0.0 && _contrast == 1.0) return image;

    final bias = (_brightness * 255) + 128 * (1 - _contrast);
    final c = _contrast;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final a = pixel.a;

        int r = (pixel.r * c + bias).clamp(0, 255).round();
        int g = (pixel.g * c + bias).clamp(0, 255).round();
        int b = (pixel.b * c + bias).clamp(0, 255).round();

        image.setPixelRgba(x, y, r, g, b, a);
      }
    }

    return image;
  }

  void _startCropping() {
    setState(() {
      _isCropping = true;
    });

    // Wait for the crop view to lay out so we know the rendered image bounds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCropRectIfNeeded();
    });
  }

  Future<void> _applyChanges() async {
    try {
      if (_cropRect != null || _brightness != 0.0 || _contrast != 1.0) {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Processing image...'),
              ],
            ),
          ),
        );

        // Load the original image
        final imageBytes = await widget.imageFile.readAsBytes();
        img.Image? originalImage = img.decodeImage(imageBytes);

        if (originalImage != null) {
          img.Image processedImage = originalImage;

          // Apply crop if specified
          if (_cropRect != null && _renderedImageRect != null) {
            // Calculate scale based on rendered image vs original image
            final scale = originalImage.width / _renderedImageRect!.width;

            // Map crop rect to relative to rendered image
            final relativeLeft = _cropRect!.left - _renderedImageRect!.left;
            final relativeTop = _cropRect!.top - _renderedImageRect!.top;

            // Calculate actual crop coordinates
            final cropX = (relativeLeft * scale).round();
            final cropY = (relativeTop * scale).round();
            final cropWidth = (_cropRect!.width * scale).round();
            final cropHeight = (_cropRect!.height * scale).round();

            // Ensure we don't go out of bounds (due to rounding)
            final safeX = cropX.clamp(0, originalImage.width);
            final safeY = cropY.clamp(0, originalImage.height);
            final safeWidth = (safeX + cropWidth > originalImage.width)
                ? originalImage.width - safeX
                : cropWidth;
            final safeHeight = (safeY + cropHeight > originalImage.height)
                ? originalImage.height - safeY
                : cropHeight;

            // Guard against zero-size crops (e.g., when handles reach edges)
            if (safeWidth > 0 && safeHeight > 0) {
              processedImage = img.copyCrop(
                processedImage,
                x: safeX,
                y: safeY,
                width: safeWidth,
                height: safeHeight,
              );
            } else {
              // Skip crop to avoid corrupt output
              _cropRect = null;
            }
          }

          // Apply brightness and contrast together so the saved image
          // matches the on-screen preview.
          processedImage = _applyBrightnessContrast(processedImage);

          // Save the processed image back to the file (atomic replace to avoid corrupt reads)
          final processedBytes = img.encodeJpg(processedImage, quality: 85);
          final tempFile = File('${widget.imageFile.path}.tmp');
          await tempFile.writeAsBytes(processedBytes, flush: true);
          await tempFile.copy(widget.imageFile.path);
          await tempFile.delete().catchError((_) => tempFile);

          // Bust any cached image so the updated file shows immediately
          final provider = FileImage(widget.imageFile);
          await provider.evict();

          if (mounted) {
            Navigator.of(context).pop(); // Close loading dialog
            Navigator.of(context).pop(true); // Close edit dialog with success
          }
        } else {
          throw Exception('Failed to decode image');
        }
      } else {
        Navigator.of(context).pop(false);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog if open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing image: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildFilterView() {
    return ColorFiltered(
      colorFilter: ColorFilter.matrix(_colorMatrix()),
      child: Image.file(
        widget.imageFile,
        key: _imageKey,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }

  Widget _buildCropView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate rendered image rect
        if (_decodedImage != null) {
          final double containerAspectRatio =
              constraints.maxWidth / constraints.maxHeight;
          final double imageAspectRatio =
              _decodedImage!.width / _decodedImage!.height;

          double renderedWidth;
          double renderedHeight;

          if (containerAspectRatio > imageAspectRatio) {
            // Container is wider than image, image constrained by height
            renderedHeight = constraints.maxHeight;
            renderedWidth = renderedHeight * imageAspectRatio;
          } else {
            // Container is taller than image, image constrained by width
            renderedWidth = constraints.maxWidth;
            renderedHeight = renderedWidth / imageAspectRatio;
          }

          final double offsetX = (constraints.maxWidth - renderedWidth) / 2;
          final double offsetY = (constraints.maxHeight - renderedHeight) / 2;

          _renderedImageRect = Rect.fromLTWH(
            offsetX,
            offsetY,
            renderedWidth,
            renderedHeight,
          );

          // Initialize crop rect once we know where the image is rendered
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _initializeCropRectIfNeeded();
          });
        }

        return Stack(
          children: [
            // Background image
            Positioned.fill(
              child: Image.file(
                widget.imageFile,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
              ),
            ),

            // Crop overlay
            if (_cropRect != null)
              Positioned.fill(
                child: CustomPaint(painter: CropOverlayPainter(_cropRect!)),
              ),

            // Crop handles
            if (_cropRect != null && _renderedImageRect != null) ...[
              // Top-left handle
              Positioned(
                left: _cropRect!.left - 10,
                top: _cropRect!.top - 10,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _cropRect = Rect.fromLTRB(
                        (_cropRect!.left + details.delta.dx).clamp(
                          _renderedImageRect!.left,
                          _cropRect!.right - 50,
                        ),
                        (_cropRect!.top + details.delta.dy).clamp(
                          _renderedImageRect!.top,
                          _cropRect!.bottom - 50,
                        ),
                        _cropRect!.right,
                        _cropRect!.bottom,
                      );
                    });
                  },
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 2),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom-right handle
              Positioned(
                left: _cropRect!.right - 10,
                top: _cropRect!.bottom - 10,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _cropRect = Rect.fromLTRB(
                        _cropRect!.left,
                        _cropRect!.top,
                        (_cropRect!.right + details.delta.dx).clamp(
                          _cropRect!.left + 50,
                          _renderedImageRect!.right,
                        ),
                        (_cropRect!.bottom + details.delta.dy).clamp(
                          _cropRect!.top + 50,
                          _renderedImageRect!.bottom,
                        ),
                      );
                    });
                  },
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 2),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(8),
      child: Container(
        width: double.maxFinite,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Edit Image',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!_isCropping)
                        IconButton(
                          onPressed: _startCropping,
                          icon: const Icon(Icons.crop, size: 20),
                          tooltip: 'Crop',
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                        ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        icon: const Icon(Icons.close, size: 20),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Image preview
            Expanded(
              flex: 3,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _isCropping ? _buildCropView() : _buildFilterView(),
                ),
              ),
            ),

            // Controls
            Flexible(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(12),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isCropping) ...[
                        // Crop controls
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  setState(() {
                                    _isCropping = false;
                                    _cropRect = null;
                                  });
                                },
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _isCropping = false;
                                  });
                                },
                                child: const Text(
                                  'Apply',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        // Filter controls - only show if enough space
                        if (MediaQuery.of(context).size.height > 650) ...[
                          // Brightness slider
                          SizedBox(
                            height: 40,
                            child: Row(
                              children: [
                                const Icon(Icons.brightness_6, size: 16),
                                const SizedBox(width: 4),
                                const SizedBox(
                                  width: 60,
                                  child: Text(
                                    'Brightness',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ),
                                Expanded(
                                  child: Slider(
                                    value: _brightness,
                                    min: -0.5,
                                    max: 0.5,
                                    divisions: 20,
                                    onChanged: (value) {
                                      setState(() {
                                        _brightness = value;
                                      });
                                      _applyFilter();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Contrast slider
                          SizedBox(
                            height: 40,
                            child: Row(
                              children: [
                                const Icon(Icons.contrast, size: 16),
                                const SizedBox(width: 4),
                                const SizedBox(
                                  width: 60,
                                  child: Text(
                                    'Contrast',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ),
                                Expanded(
                                  child: Slider(
                                    value: _contrast,
                                    min: 0.5,
                                    max: 2.0,
                                    divisions: 30,
                                    onChanged: (value) {
                                      setState(() {
                                        _contrast = value;
                                      });
                                      _applyFilter();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 8),

                        // Quick filter buttons
                        SizedBox(
                          height: 36,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _FilterButton(
                                label: 'Original',
                                onPressed: _resetFilters,
                              ),
                              const SizedBox(width: 4),
                              _FilterButton(
                                label: 'High Contrast',
                                onPressed: () {
                                  setState(() {
                                    _brightness = 0.0;
                                    _contrast = 1.5;
                                  });
                                  _applyFilter();
                                },
                              ),
                              const SizedBox(width: 4),
                              _FilterButton(
                                label: 'Brighten',
                                onPressed: () {
                                  setState(() {
                                    _brightness = 0.2;
                                    _contrast = 1.2;
                                  });
                                  _applyFilter();
                                },
                              ),
                              const SizedBox(width: 4),
                              _FilterButton(
                                label: 'Document',
                                onPressed: () {
                                  setState(() {
                                    _brightness = 0.1;
                                    _contrast = 1.4;
                                  });
                                  _applyFilter();
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton(
                                onPressed: _applyChanges,
                                child: const Text('Apply'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CropOverlayPainter extends CustomPainter {
  final Rect cropRect;

  CropOverlayPainter(this.cropRect);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    // Draw darkened areas outside crop rect
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, cropRect.top), paint);
    canvas.drawRect(
      Rect.fromLTWH(0, cropRect.top, cropRect.left, cropRect.height),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        cropRect.right,
        cropRect.top,
        size.width - cropRect.right,
        cropRect.height,
      ),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        cropRect.bottom,
        size.width,
        size.height - cropRect.bottom,
      ),
      paint,
    );

    // Draw crop rect border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRect(cropRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _FilterButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _FilterButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: const Size(0, 32),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}
