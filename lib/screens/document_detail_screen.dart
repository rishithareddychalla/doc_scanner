// lib/screens/document_detail_screen.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:image/image.dart' as img;
import '../models/scanned_document.dart';
import '../services/document_storage_service.dart';
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
      _doc = ScannedDocument(
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

  void _saveDocument() {
    if (_isNewDocument) {
      DocumentStorageService().addDocument(
        imageFiles: _doc!.imageFiles,
        title: _doc!.title,
      );
      // Pop twice to go back to the document list screen
      Navigator.of(context)
        ..pop()
        ..pop();
    }
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
        // First add the image, then allow editing
        setState(() {
          _doc!.imageFiles.add(File(pickedFile.path));
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
                    _doc!.imageFiles.removeAt(_currentPage);
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

  @override
  Widget build(BuildContext context) {
    if (_doc == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(_doc!.title),
        actions: [
          if (_isNewDocument)
            IconButton(
              onPressed: _saveDocument,
              icon: const Icon(Icons.save_outlined),
              tooltip: 'Save document',
            ),
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
                return Image.file(_doc!.imageFiles[index]);
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
                    child: Image.file(_doc!.imageFiles[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        onTap: (index) async {
          if (index == 0) {
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
          } else if (index == 1) {
            final newImageList = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ReorderScreen(images: _doc!.imageFiles),
              ),
            );

            if (newImageList != null) {
              setState(() {
                _doc!.imageFiles.clear();
                _doc!.imageFiles.addAll(newImageList);
                if (!_isNewDocument) {
                  DocumentStorageService().updateDocument(_doc!);
                }
              });
            }
          } else if (index == 2) {
            _deletePage();
          } else if (index == 3) {
            _editCurrentPage();
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.add_a_photo),
            label: 'Add Page',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.reorder), label: 'Reorder'),
          BottomNavigationBarItem(icon: Icon(Icons.delete), label: 'Delete'),
          BottomNavigationBarItem(icon: Icon(Icons.edit), label: 'Edit'),
        ],
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
  bool _hasChanges = false;

  // Crop variables
  Rect? _cropRect;
  Size? _imageSize;
  bool _isCropping = false;
  final GlobalKey _imageKey = GlobalKey();

  void _applyFilter() {
    setState(() {
      _hasChanges = true;
    });
  }

  void _resetFilters() {
    setState(() {
      _brightness = 0.0;
      _contrast = 1.0;
      _hasChanges = false;
      _cropRect = null;
      _isCropping = false;
    });
  }

  void _startCropping() {
    setState(() {
      _isCropping = true;
      // Initialize crop rect to center 80% of image
      if (_imageSize != null) {
        final margin = _imageSize!.width * 0.1;
        _cropRect = Rect.fromLTWH(
          margin,
          margin,
          _imageSize!.width * 0.8,
          _imageSize!.height * 0.8,
        );
      }
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
          if (_cropRect != null && _imageSize != null) {
            // Calculate actual crop coordinates based on image dimensions
            final scaleX = originalImage.width / _imageSize!.width;
            final scaleY = originalImage.height / _imageSize!.height;

            final cropX = (_cropRect!.left * scaleX).round();
            final cropY = (_cropRect!.top * scaleY).round();
            final cropWidth = (_cropRect!.width * scaleX).round();
            final cropHeight = (_cropRect!.height * scaleY).round();

            processedImage = img.copyCrop(
              processedImage,
              x: cropX,
              y: cropY,
              width: cropWidth,
              height: cropHeight,
            );
          }

          // Apply brightness and contrast
          if (_brightness != 0.0) {
            processedImage = img.adjustColor(
              processedImage,
              brightness: _brightness,
            );
          }

          if (_contrast != 1.0) {
            processedImage = img.adjustColor(
              processedImage,
              contrast: _contrast,
            );
          }

          // Save the processed image back to the file
          final processedBytes = img.encodeJpg(processedImage, quality: 85);
          await widget.imageFile.writeAsBytes(processedBytes);

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
      colorFilter: ColorFilter.matrix([
        _contrast,
        0,
        0,
        0,
        _brightness * 255,
        0,
        _contrast,
        0,
        0,
        _brightness * 255,
        0,
        0,
        _contrast,
        0,
        _brightness * 255,
        0,
        0,
        0,
        1,
        0,
      ]),
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
        // Store the available size for crop calculations
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_imageSize == null) {
            setState(() {
              _imageSize = Size(constraints.maxWidth, constraints.maxHeight);
              if (_cropRect == null) {
                final margin = constraints.maxWidth * 0.1;
                _cropRect = Rect.fromLTWH(
                  margin,
                  margin * 2,
                  constraints.maxWidth * 0.8,
                  constraints.maxHeight * 0.6,
                );
              }
            });
          }
        });

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
            if (_cropRect != null) ...[
              // Top-left handle
              Positioned(
                left: _cropRect!.left - 10,
                top: _cropRect!.top - 10,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _cropRect = Rect.fromLTRB(
                        (_cropRect!.left + details.delta.dx).clamp(
                          0.0,
                          _cropRect!.right - 50,
                        ),
                        (_cropRect!.top + details.delta.dy).clamp(
                          0.0,
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
                          constraints.maxWidth,
                        ),
                        (_cropRect!.bottom + details.delta.dy).clamp(
                          _cropRect!.top + 50,
                          constraints.maxHeight,
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
                                    _hasChanges = true;
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
