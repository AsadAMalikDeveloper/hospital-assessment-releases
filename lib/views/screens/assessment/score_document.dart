// import 'package:flutter/material.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';
//
// class PdfGenerator {
//   final List<Map<String, dynamic>> data;
//   final int rowsPerPage;
//
//   PdfGenerator({required this.data, this.rowsPerPage = 25});
//
//   Future<void> generatePdf(BuildContext context) async {
//     final pdf = pw.Document();
//
//     int totalPages = (data.length / rowsPerPage).ceil();
//
//     for (int page = 0; page < totalPages; page++) {
//       pdf.addPage(
//         pw.Page(
//           pageFormat: PdfPageFormat.a4.copyWith(
//               marginTop: 20, marginLeft: 20, marginRight: 20,marginBottom: 20),
//           // Adjusting the margins
//           build: (pw.Context context) {
//             List<pw.TableRow> tableRows = [];
//             tableRows.add(
//               pw.TableRow(children: [
//                 _buildHeaderCell('Serial #'),
//                 _buildHeaderCell('Description'),
//                 _buildHeaderCell('Response'),
//                 _buildHeaderCell('Max Marks'),
//                 _buildHeaderCell('Achieved'),
//               ]),
//             );
//
//             // Add rows for the current page
//             for (int i = page * rowsPerPage;
//                 i < (page + 1) * rowsPerPage && i < data.length;
//                 i++) {
//               tableRows.add(_buildDataRow(data[i],i));
//             }
//
//             // Add grand total row on the last page
//             if (page == totalPages - 1) {
//               tableRows.add(
//                 pw.TableRow(children: [
//                   pw.Container(
//                       child: _buildHeaderCell('Grand Total'),
//                       color: PdfColors.green),
//                   pw.Container(
//                       child: _buildHeaderCell('___________'),
//                       color: PdfColors.green),
//                   pw.Container(
//                       child: _buildHeaderCell('___________'), color: PdfColors.green),
//                   pw.Container(
//                       child: _buildHeaderCell(
//                           _calculateTotal(data, 'max_marks').toString()),
//                       color: PdfColors.green),
//                   pw.Container(
//                       child: _buildHeaderCell(
//                           _calculateTotal(data, 'achieved').toString()),
//                       color: PdfColors.green),
//                 ]),
//               );
//             }
//
//             return pw.Column(
//               crossAxisAlignment: pw.CrossAxisAlignment.start,
//               children: [
//                 page==0?pw.Text('Hospital Assessment Report',
//                     style: pw.TextStyle(
//                         fontSize: 18, fontWeight: pw.FontWeight.bold)):pw.SizedBox(),
//                 pw.SizedBox(height: 10),
//                 pw.Table(
//                   border: pw.TableBorder.all(),
//                   children: tableRows,
//                 ),
//               ],
//             );
//           },
//         ),
//       );
//     }
//
//     await Printing.layoutPdf(
//         onLayout: (PdfPageFormat format) async => pdf.save());
//   }
//
//   pw.Widget _buildHeaderCell(String text) {
//     return pw.Container(
//       padding: pw.EdgeInsets.all(8),
//       child: pw.Text(text, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
//     );
//   }
//
//   pw.TableRow _buildDataRow(Map<String, dynamic> item, int index) {
//     return pw.TableRow(children: [
//       pw.Container(
//         padding: pw.EdgeInsets.all(8),
//         child: pw.Text(('${index+1}'),style: pw.TextStyle(fontSize: 8,fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.left),
//       ),
//       pw.Container(
//         padding: pw.EdgeInsets.all(8),
//         child: pw.Text(item['description'], textAlign: pw.TextAlign.left),
//       ),
//       pw.Container(
//         padding: pw.EdgeInsets.all(8),
//         child:
//             pw.Text(item['response'] ?? 'N/A', textAlign: pw.TextAlign.center),
//       ),
//       pw.Container(
//         padding: pw.EdgeInsets.all(8),
//         child: pw.Text(item['max_marks'].toString(),
//             textAlign: pw.TextAlign.center),
//       ),
//       pw.Container(
//         padding: pw.EdgeInsets.all(8),
//         child: pw.Text(item['achieved'].toString(),
//             textAlign: pw.TextAlign.center),
//       ),
//     ]);
//   }
//
//   double _calculateTotal(List<Map<String, dynamic>> data, String field) {
//     return data.fold(0, (sum, item) {
//       return sum + (double.tryParse(item[field].toString()) ?? 0);
//     });
//   }
// }
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfGenerator {
  final List<Map<String, dynamic>> data;
  final int rowsPerPage;

  PdfGenerator({required this.data, this.rowsPerPage = 20});

  Future<void> generatePdf(BuildContext context) async {
    final pdf = pw.Document();

    int totalPages = (data.length / rowsPerPage).ceil();

    for (int page = 0; page < totalPages; page++) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.copyWith(
            marginTop: 20,
            marginLeft: 20,
            marginRight: 20,
            marginBottom: 10, // Reduced bottom margin
          ),
          build: (pw.Context context) {
            List<pw.TableRow> tableRows = [];
            tableRows.add(
              pw.TableRow(children: [
                _buildHeaderCell('Serial #'),
                _buildHeaderCell('Description'),
                _buildHeaderCell('Response'),
                _buildHeaderCell('Max Marks'),
                _buildHeaderCell('Achieved'),
              ]),
            );

            // Add rows for the current page
            for (int i = page * rowsPerPage;
            i < (page + 1) * rowsPerPage && i < data.length;
            i++) {
              tableRows.add(_buildDataRow(data[i], i));
            }

            // Add grand total row on the last page
            if (page == totalPages - 1) {
              tableRows.add(
                pw.TableRow(children: [
                  pw.Container(
                      child: _buildHeaderCell('Grand Total'),
                      color: PdfColors.green),
                  pw.Container(
                      child: _buildHeaderCell(''),
                      color: PdfColors.green),
                  pw.Container(
                      child: _buildHeaderCell('')),
                  pw.Container(
                      child: _buildHeaderCell(
                          _calculateTotal(data, 'max_marks').toString()),
                      color: PdfColors.green),
                  pw.Container(
                      child: _buildHeaderCell(
                          _calculateTotal(data, 'achieved').toString()),
                      color: PdfColors.green),
                ]),
              );
            }

            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (page == 0)
                  pw.Text('Hospital Assessment Report',
                      style: pw.TextStyle(
                          fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: tableRows,
                ),
              ],
            );
          },
        ),
      );
    }

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
  }

  pw.Widget _buildHeaderCell(String text) {
    return pw.Container(
      padding: pw.EdgeInsets.symmetric(vertical: 5, horizontal: 8), // Reduced padding
      child: pw.Text(text,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
    );
  }

  pw.TableRow _buildDataRow(Map<String, dynamic> item, int index) {
    return pw.TableRow(children: [
      pw.Container(
        padding: pw.EdgeInsets.symmetric(vertical: 5, horizontal: 8), // Reduced padding
        child: pw.Text(
          '${index + 1}',
          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          textAlign: pw.TextAlign.left,
        ),
      ),
      pw.Container(
        padding: pw.EdgeInsets.symmetric(vertical: 5, horizontal: 8), // Reduced padding
        child: pw.Text(item['description'], textAlign: pw.TextAlign.left),
      ),
      pw.Container(
        padding: pw.EdgeInsets.symmetric(vertical: 5, horizontal: 8), // Reduced padding
        child: pw.Text(item['response'] ?? 'N/A', textAlign: pw.TextAlign.center),
      ),
      pw.Container(
        padding: pw.EdgeInsets.symmetric(vertical: 5, horizontal: 8), // Reduced padding
        child: pw.Text(item['max_marks'].toString(),
            textAlign: pw.TextAlign.center),
      ),
      pw.Container(
        padding: pw.EdgeInsets.symmetric(vertical: 5, horizontal: 8), // Reduced padding
        child: pw.Text(item['achieved'].toString(),
            textAlign: pw.TextAlign.center),
      ),
    ]);
  }

  pw.TableRow _buildGrandTotalCell(String text) {
    return pw.TableRow(children: [
      pw.Container(
        color: PdfColors.green,
        padding: pw.EdgeInsets.symmetric(vertical: 5, horizontal: 8), // Reduced padding
        child: pw.Text(text,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
      ),
      pw.Container(
        color: PdfColors.green,
        padding: pw.EdgeInsets.symmetric(vertical: 5, horizontal: 8), // Reduced padding
        child: pw.Text('',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
      ),
      pw.Container(
        color: PdfColors.green,
        padding: pw.EdgeInsets.symmetric(vertical: 5, horizontal: 8), // Reduced padding
        child: pw.Text('',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
      ),
      pw.Container(
        color: PdfColors.green,
        padding: pw.EdgeInsets.symmetric(vertical: 5, horizontal: 8), // Reduced padding
        child: pw.Text(_calculateTotal(data, 'max_marks').toString(),
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
      ),
      pw.Container(
        color: PdfColors.green,
        padding: pw.EdgeInsets.symmetric(vertical: 5, horizontal: 8), // Reduced padding
        child: pw.Text(_calculateTotal(data, 'achieved').toString(),
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
      ),
    ]);
  }

  double _calculateTotal(List<Map<String, dynamic>> data, String field) {
    return data.fold(0, (sum, item) {
      return sum + (double.tryParse(item[field].toString()) ?? 0);
    });
  }
}
