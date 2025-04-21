import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ticket_collection/gen/assets.gen.dart';
import 'package:ticket_collection/models/ticket_data.dart';
import 'package:flutter/services.dart' show rootBundle;

Future<void> downloadPdf(
  BuildContext context,
  List<TicketData> savedDataList,
) async {
  final messenger = ScaffoldMessenger.of(context);

  if (!await requestStoragePermission()) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Permission denied. Cannot save PDF.')),
    );
    return;
  }

  final imageBytes = await rootBundle.load(Assets.logo.path);
  final logo = pw.MemoryImage(imageBytes.buffer.asUint8List());

  final pdf = pw.Document();
  final date = DateFormat('dd-MM-yyyy').format(DateTime.now());

  int totalTicketsSold = savedDataList.fold<int>(
    0,
    (sum, item) =>
        sum +
        (int.tryParse(item.endTicket) ?? 0) -
        (int.tryParse(item.startTicket) ?? 0),
  );

  double totalAmountCollected = savedDataList.fold<double>(
    0.0,
    (sum, item) => sum + (double.tryParse(item.total) ?? 0.0),
  );

  const rowsPerPage = 20;
  final totalPages = (savedDataList.length / rowsPerPage).ceil();

  int serialNumber = 1;

  for (int pageIndex = 0; pageIndex < totalPages; pageIndex++) {
    final chunk =
        savedDataList.skip(pageIndex * rowsPerPage).take(rowsPerPage).toList();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              pw.Positioned.fill(
                child: pw.Center(
                  child: pw.Opacity(
                    opacity: 0.1,
                    child: pw.Image(logo, width: 300),
                  ),
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(date,
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: const PdfColor(13 / 255, 71 / 255, 161 / 255),
                      )),
                  pw.SizedBox(height: 20),
                  pw.Table(
                    border: pw.TableBorder.all(
                      color: const PdfColor(189 / 255, 189 / 255, 189 / 255),
                      width: 0.5,
                    ),
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(
                          color: PdfColor(13 / 255, 71 / 255, 161 / 255),
                        ),
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8.0),
                            child: pw.Text('S.No',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    color: const PdfColor(
                                        255 / 255, 255 / 255, 255 / 255))),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8.0),
                            child: pw.Text('Start',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    color: const PdfColor(
                                        255 / 255, 255 / 255, 255 / 255))),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8.0),
                            child: pw.Text('End',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    color: const PdfColor(
                                        255 / 255, 255 / 255, 255 / 255))),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8.0),
                            child: pw.Text('Amount',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    color: const PdfColor(
                                        255 / 255, 255 / 255, 255 / 255))),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8.0),
                            child: pw.Text('Count',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    color: const PdfColor(
                                        255 / 255, 255 / 255, 255 / 255))),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8.0),
                            child: pw.Text('Total',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    color: const PdfColor(
                                        255 / 255, 255 / 255, 255 / 255))),
                          ),
                        ],
                      ),
                      ...chunk.map((e) {
                        final rowIndex = serialNumber++;
                        return pw.TableRow(
                          decoration: null,
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8.0),
                              child: pw.Text('$rowIndex',
                                  textAlign: pw.TextAlign.center),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8.0),
                              child: pw.Text(e.startTicket,
                                  textAlign: pw.TextAlign.center),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8.0),
                              child: pw.Text(e.endTicket,
                                  textAlign: pw.TextAlign.center),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8.0),
                              child: pw.Text(e.amount,
                                  textAlign: pw.TextAlign.center),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8.0),
                              child: pw.Text(e.count.toString(),
                                  textAlign: pw.TextAlign.center),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8.0),
                              child: pw.Text(e.total,
                                  textAlign: pw.TextAlign.center),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                  pw.SizedBox(height: 20),
                  if (pageIndex == totalPages - 1) ...[
                    pw.Divider(),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          "Total Tickets Sold: $totalTicketsSold",
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          "Total Amount Collected: ${totalAmountCollected.toStringAsFixed(2)}",
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ]
                ],
              ),
              pw.Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Align(
                      alignment: pw.Alignment.center,
                      child: pw.Text('Forum For Justice',
                          style: pw.TextStyle(
                              fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Align(
                      alignment: pw.Alignment.centerRight,
                      child: pw.Text('Page ${pageIndex + 1} of $totalPages',
                          style: const pw.TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  try {
    final downloadsDir =
        Directory('/storage/emulated/0/Download/ticket_calculator');

    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }

    final filePath = '${downloadsDir.path}/$date.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    messenger.showSnackBar(
      SnackBar(
        content: Text('PDF saved to: $filePath'),
        action: SnackBarAction(
          label: 'Open',
          onPressed: () {
            _openPDF(filePath);
          },
        ),
      ),
    );
  } catch (e) {
    log(e.toString());
    messenger.showSnackBar(
      const SnackBar(content: Text('Failed to save PDF')),
    );
  }
}

Future<bool> requestStoragePermission() async {
  if (Platform.isAndroid) {
    final status = await Permission.manageExternalStorage.status;
    if (status.isGranted) return true;

    final result = await Permission.manageExternalStorage.request();
    return result.isGranted;
  }
  return false;
}

Future<void> _openPDF(String filePath) async {
  try {
    await OpenFilex.open(filePath);
  } catch (e) {
    debugPrint("Error opening file: $e");
  }
}
