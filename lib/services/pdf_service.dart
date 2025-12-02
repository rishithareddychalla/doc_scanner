import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path/path.dart' as p;
import '../models/scanned_document.dart';

class PdfService {
  Future<String> saveDocumentAsPdf(ScannedDocument doc) async {
    final pdf = pw.Document();

    for (final imageFile in doc.imageFiles) {
      final imageBytes = await imageFile.readAsBytes();
      final image = pw.MemoryImage(imageBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(image),
            );
          },
        ),
      );
    }

    final directory = await getApplicationDocumentsDirectory();

    // Sanitize title for filename
    var sanitizedTitle = doc.title.replaceAll(RegExp(r'[^\w\s\-]'), '').trim();
    if (sanitizedTitle.isEmpty) {
      sanitizedTitle = 'scan_document';
    }

    final filename = '$sanitizedTitle.pdf';
    final file = File(p.join(directory.path, filename));

    await file.writeAsBytes(await pdf.save());
    return file.path;
  }
}
