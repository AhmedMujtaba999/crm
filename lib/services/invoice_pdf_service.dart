import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models.dart';

class InvoicePdfService {
  Future<List<int>> buildPdfBytes({
    required WorkItem item,
    required List<ServiceItem> services,
    bool includePhotos = true,

    // ✅ NEW
    List<String> beforePhotoPaths = const [],
    List<String> afterPhotoPaths = const [],
  }) async {
    final doc = pw.Document();

    final createdText = DateFormat('EEE, MMM d, y • h:mm a').format(item.createdAt);
    final completedText = item.completedAt == null
        ? null
        : DateFormat('EEE, MMM d, y • h:mm a').format(item.completedAt!);

    final photoBlocks = <_PhotoBlock>[];

    if (includePhotos) {
      int i = 1;
      for (final p in beforePhotoPaths) {
        final path = p.trim();
        if (path.isEmpty) continue;
        if (!File(path).existsSync()) continue;
        photoBlocks.add(_PhotoBlock(label: "Before $i", path: path));
        i++;
      }

      i = 1;
      for (final p in afterPhotoPaths) {
        final path = p.trim();
        if (path.isEmpty) continue;
        if (!File(path).existsSync()) continue;
        photoBlocks.add(_PhotoBlock(label: "After $i", path: path));
        i++;
      }
    }

    final photoWidgets = <pw.Widget>[];
    for (final pb in photoBlocks) {
      try {
        final bytes = await File(pb.path).readAsBytes();
        final mem = pw.MemoryImage(Uint8List.fromList(bytes));
        photoWidgets.add(
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            padding: const pw.EdgeInsets.all(6),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(pb.label, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 6),
                pw.ClipRRect(
                  horizontalRadius: 8,
                  verticalRadius: 8,
                  child: pw.Image(mem, fit: pw.BoxFit.cover, height: 180),
                ),
              ],
            ),
          ),
        );
      } catch (_) {
        // ignore broken image
      }
    }
final idStr = item.id.toString();
final shortId = idStr.length >= 6
    ? idStr.substring(0, 6).toUpperCase()
    : idStr.toUpperCase();


    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("Invoice", style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text("Work Item #$shortId", style: const pw.TextStyle(color: PdfColors.grey700)),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: pw.BoxDecoration(color: PdfColors.grey200, borderRadius: pw.BorderRadius.circular(10)),
                child: pw.Text(DateFormat('yyyy-MM-dd').format(DateTime.now())),
              ),
            ],
          ),

          pw.SizedBox(height: 14),

          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(10),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("Status: ${item.status}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 6),
                pw.Text("Activated: $createdText"),
                if (completedText != null) pw.Text("Completed: $completedText"),
              ],
            ),
          ),

          pw.SizedBox(height: 14),
          pw.Text("Customer Details", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Text(item.customerName, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.Text(item.phone),
          if (item.email.trim().isNotEmpty) pw.Text(item.email.trim()),
          if (item.address.trim().isNotEmpty) pw.Text(item.address.trim()),

          pw.SizedBox(height: 16),
          pw.Divider(),

          pw.Text("Services", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),

          services.isEmpty
              ? pw.Text("No services added.")
              : pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  columnWidths: {0: const pw.FlexColumnWidth(4), 1: const pw.FlexColumnWidth(2)},
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text("Service", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text("Amount", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                    ...services.map(
                      (s) => pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(s.name)),
                          pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text("\$${s.amount.toStringAsFixed(2)}")),
                        ],
                      ),
                    ),
                  ],
                ),

          pw.SizedBox(height: 14),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Row(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text("Total: ", style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                  pw.Text("\$${item.total.toStringAsFixed(2)}", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),
          ),

          if (includePhotos && photoWidgets.isNotEmpty) ...[
            pw.SizedBox(height: 18),
            pw.Text("Photos", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Wrap(
              spacing: 10,
              runSpacing: 10,
              children: photoWidgets
                  .map((w) => pw.SizedBox(width: (PdfPageFormat.a4.availableWidth - 10) / 2, child: w))
                  .toList(),
            ),
          ],
        ],
      ),
    );

    return doc.save();
  }
}

class _PhotoBlock {
  final String label;
  final String path;
  _PhotoBlock({required this.label, required this.path});
}
