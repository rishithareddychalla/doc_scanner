// lib/screens/document_detail_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/scanned_document.dart';
import '../services/document_storage_service.dart';
import 'reorder_screen.dart';

class DocumentDetailScreen extends StatefulWidget {
  final String documentId;
  const DocumentDetailScreen({super.key, required this.documentId});

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  int _currentPage = 0;
  late PageController _pageController;

  ScannedDocument? _doc;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _doc = DocumentStorageService().getById(widget.documentId);
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

  Future<void> _addPage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _doc!.imageFiles.add(File(pickedFile.path));
        DocumentStorageService().updateDocument(_doc!);
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
                    DocumentStorageService().updateDocument(_doc!);
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
        const SnackBar(
          content: Text('Cannot delete the last page.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_doc == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(_doc!.title),
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
                DocumentStorageService().updateDocument(_doc!);
              });
            }
          } else if (index == 2) {
            _deletePage();
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.add_a_photo),
            label: 'Add Page',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.reorder),
            label: 'Reorder',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.delete),
            label: 'Delete',
          ),
        ],
      ),
    );
  }
}
