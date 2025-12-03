import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/scanned_document.dart';

class PdfService {
  static final PdfService _instance = PdfService._internal();
  factory PdfService() => _instance;
  PdfService._internal();

  Future<String> saveDocumentAsPdf(ScannedDocument document) async {
    try {
      print('🔧 Starting PDF generation...');

      // Request storage permission
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        throw Exception('Storage permission denied');
      }
      print('✅ Storage permission granted');

      // Create PDF document
      final pdf = pw.Document();

      print('📄 Processing ${document.imageFiles.length} page(s)');

      // Add each page to PDF
      for (int i = 0; i < document.imageFiles.length; i++) {
        print('📄 Processing page ${i + 1}/${document.imageFiles.length}');

        final imageFile = document.imageFiles[i];
        final imageBytes = await imageFile.readAsBytes();
        print('📊 Image ${i + 1} size: ${imageBytes.length} bytes');

        final image = pw.MemoryImage(imageBytes);

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain));
            },
          ),
        );
      }

      print('✅ All pages added to PDF');

      // Get documents directory
      Directory? directory;
      try {
        directory = await getApplicationDocumentsDirectory();
        print('📁 Using app documents directory: ${directory.path}');
      } catch (e) {
        directory = await getExternalStorageDirectory();
        if (directory != null) {
          print('📁 Using external storage directory: ${directory.path}');
        }
      }

      if (directory == null) {
        throw Exception('No storage directory available');
      }

      // Create PDFs subdirectory
      final pdfDirectory = Directory('${directory.path}/PDFs');
      if (!await pdfDirectory.exists()) {
        await pdfDirectory.create(recursive: true);
        print('📁 Created PDF directory: ${pdfDirectory.path}');
      }

      // Generate filename with timestamp to avoid conflicts
      final timestamp = DateTime.now();
      final formattedDate =
          '${timestamp.month}${timestamp.day}${timestamp.year}';
      final formattedTime =
          '${timestamp.hour}${timestamp.minute}${timestamp.second}';
      final filename =
          '${document.title.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_')}_${formattedDate}_$formattedTime.pdf';
      final filePath = '${pdfDirectory.path}/$filename';

      print('💾 Saving PDF to: $filePath');

      // Save PDF to file
      final pdfBytes = await pdf.save();
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      print('📊 PDF size: ${pdfBytes.length} bytes');
      print('✅ PDF saved successfully! Size: ${pdfBytes.length} bytes');

      return filePath;
    } catch (e) {
      print('❌ PDF generation failed: $e');
      rethrow;
    }
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      try {
        // For Android 13+ (API 33+), we don't need storage permission for app-specific directories
        return true;
      } catch (e) {
        print('Storage permission error: $e');
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    }
    return true; // iOS doesn't need explicit storage permission for app directories
  }
}
