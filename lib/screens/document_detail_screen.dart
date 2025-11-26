// lib/screens/document_detail_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
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
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: _doc!.imageFiles[_currentPage].path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Edit Page',
          toolbarColor: Colors.deepOrange,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          activeControlsWidgetColor: Colors.deepOrange,
          dimmedLayerColor: Colors.black54,
          statusBarLight: false,
          cropFrameColor: Colors.deepOrange,
          cropGridColor: Colors.white,
        ),
        IOSUiSettings(title: 'Edit Page', minimumAspectRatio: 1.0),
      ],
    );

    if (croppedFile != null) {
      setState(() {
        _doc!.imageFiles[_currentPage] = File(croppedFile.path);
        if (!_isNewDocument) {
          DocumentStorageService().updateDocument(_doc!);
        }
      });
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
