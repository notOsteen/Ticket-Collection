import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ticket_collection/models/ticket_data.dart';

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

  final pdf = pw.Document();
  final date = DateFormat('dd-MM-yyyy').format(DateTime.now());

  // Calculate total tickets sold and total amount collected
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

  pdf.addPage(
    pw.Page(
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("Today's Collections - $date",
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
                ...savedDataList.map((e) {
                  bool isOddRow = savedDataList.indexOf(e) % 2 != 0;
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: isOddRow
                          ? const PdfColor(243 / 255, 243 / 255, 243 / 255)
                          : const PdfColor(255 / 255, 255 / 255, 255 / 255),
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8.0),
                        child: pw.Text(e.startTicket),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8.0),
                        child: pw.Text(e.endTicket),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8.0),
                        child: pw.Text(
                          e.amount,
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8.0),
                        child: pw.Text(
                          e.count.toString(),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8.0),
                        child: pw.Text(
                          e.total,
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 20),
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
          ],
        );
      },
    ),
  );

  try {
    final downloadsDir = Directory('/storage/emulated/0/Download');
    final filePath = '${downloadsDir.path}/ticket_collection_$date.pdf';
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
