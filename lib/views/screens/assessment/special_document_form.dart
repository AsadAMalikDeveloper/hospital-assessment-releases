import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';

import '../../../models/special_document_model.dart';

Future<void> getSpecialDocumentPDF(SpecialDocumentModel dataModel) async {
  final permissionStatus = await (Platform.isAndroid
      ? Permission.accessMediaLocation.status
      : Permission.photos.status);
  if (permissionStatus.isDenied) {
    Platform.isAndroid
        ? Permission.accessMediaLocation.request()
        : Permission.photos.request();
  } else if (permissionStatus.isPermanentlyDenied) {
    await openAppSettings();
  } else {
    // Load your image or icon
    final iconImage = await rootBundle
        .load("assets/images/state_life_logo.png"); // Adjust the path
    final backgroundImage = await rootBundle
        .load("assets/images/state_life_logo.png"); // Adjust path

    final pdf = pw.Document();
// Decode images for use in the PDF
    final icon = pw.MemoryImage(iconImage.buffer.asUint8List());
    final background = pw.MemoryImage(backgroundImage.buffer.asUint8List());
    final data = [
      [
        '1',
        'Hospital found Functional (If "Yes" clear Video evidence should be provided)',
        '',
        '',
        ''
      ],
      [
        '2',
        'Registration with Health Care Commission as a hospital',
        '',
        '',
        ''
      ],
      ['3', 'Accessibility\n(Yes, if below points are "Yes")', '', '', ''],
      ['', 'a) Motorable road', '', '', ''],
      [
        '',
        'b) Ramp or functional bed Elevator 24 hr\'s Service (elevator having Generator Support)',
        '',
        '',
        ''
      ],
      [
        '4',
        '24/7 Emergency Services available\n(Yes, if below points are "Yes")',
        '',
        '',
        ''
      ],
      ['', 'a) On Duty Medical Officer available', '', '', ''],
      ['5', 'Emergency Services at Ground Floor', '', '', ''],
      [
        '6',
        'Availability of in-house Pharmacy\n(if "Yes" these drugs shall be available at the stock e.g., adrenaline, atropine,calcium gluconate, magnesium sulfate, Solu cortef, avil, Decadron, salbutamol, aminophylline, haemacel)',
        '',
        '',
        ''
      ],
      [
        '7',
        'Availability of in-house Laboratory\n(if "Yes" Baseline investigations shall be available e.g., CBC, RFTS, electrolytes, Urine R/E, FBS, RBS, ESR, HBS/HCV, BT & CT)',
        '',
        '',
        ''
      ],
      [
        '8',
        'At least 3 Specialties available (Except Category D Districts)',
        '',
        '',
        ''
      ],
      [
        '',
        'Consultants Clinics available as evidence & Admission record',
        '',
        '',
        ''
      ],
      [
        '',
        'a) General Surgery & Allied Surgery (Eye, ENT, Ortho Urology, Etc.)',
        '',
        '',
        ''
      ],
      ['', 'b) Gynecology (Yes, if below point are "Yes")', '', '', ''],
      ['', 'i) Functional labor room', '', '', ''],
      ['', 'ii) WMO Available', '', '', ''],
      ['', 'iii) Gynecologist available (On call)', '', '', ''],
      ['', 'c) Medicine & Allied', '', '', ''],
      ['9', 'Availability of Operation Theatre (OT)', '', '', ''],
      ['', 'a) Anesthesia machine available', '', '', ''],
      [
        '',
        'b) Is OT Functional (Mark "Yes" if OT record is provided)',
        '',
        '',
        ''
      ],
      ['', 'Mark "Yes" if OT record is provided', '', '', ''],
      [
        '10',
        'Expired Medication/Disposables\n(Evidence should be collected along with Expiry form duly Signed and Stamped by the hospital)',
        '',
        '',
        ''
      ],
      [
        '',
        'a) In the Shelf\'s of non-expiry medicines at Pharmacy',
        '',
        '',
        ''
      ],
      ['', 'b) Operation Theater (OT)', '', '', ''],
      ['', 'c) ICU/CCU/NICU', '', '', ''],
      ['', 'd) Emergency Room', '', '', ''],
      ['', 'e) Labor Room', '', '', ''],
      [
        '11',
        'The hospital is having Number of hospital specific functional Beds available.\n(The total beds number of below departments be mentioned in the blank (Mark "Yes" if the hospital qualifies the prescribed number of beds approved for the district by the Government of KP)',
        '',
        '',
        ''
      ],
      ['', 'a) Emergency Room Beds', '', '', ''],
      ['', 'b) Wards Beds', '', '', ''],
      ['', 'c) ICU/CCU Beds', '', '', ''],
    ];

// Add the first page with the header
    pdf.addPage(pw.MultiPage(
      build: (context) {
        List<pw.Widget> content = [];

        content.add(
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.center, children: [
          pw.Align(
            alignment: pw.Alignment.topCenter,
            child: pw.Image(
              icon,
              width: 100, // Adjust icon size as needed
              height: 100,
            ),
          )
        ]));
        // Add header for the report
        content.add(
          pw.Container(
            color: PdfColors.blue50,
            alignment: pw.Alignment.center,
            padding: const pw.EdgeInsets.all(10),
            child: pw.Text(
              'Basic Assessment Criteria (Critical Criteria)',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ),
        );
        content.add(pw.SizedBox(height: 20));
        // Table: split across pages if it overflows
        const int chunkSize = 10; // Define the number of rows per page
        for (int i = 0; i < data.length; i += chunkSize) {
          final chunkData = data.sublist(
              i, (i + chunkSize > data.length) ? data.length : i + chunkSize);

          content.add(
            pw.TableHelper.fromTextArray(
              headers: i == 0
                  ? ['Sr.', 'Points', 'Yes', 'No', 'Remarks']
                  : ['', '', '', '', ''],
              data: chunkData,
              columnWidths: {
                0: pw.FixedColumnWidth(30),
                1: pw.FlexColumnWidth(4),
                2: pw.FixedColumnWidth(35),
                3: pw.FixedColumnWidth(30),
                4: pw.FlexColumnWidth(2),
              },
              cellHeight: 40,
              cellPadding: pw.EdgeInsets.all(5),
              headerPadding: pw.EdgeInsets.all(5),
              headerStyle: i == 0
                  ? pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    )
                  : pw.TextStyle(),
              headerDecoration: i == 0
                  ? pw.BoxDecoration(color: PdfColors.blue)
                  : pw.BoxDecoration(),
            ),
          );

          content.add(pw.SizedBox(height: 20));
        }
        content.add(pw.SizedBox(height: 20));
        content.add(pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Note: Hospital Must provide documentary evidence for all above qualifying points.',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(
              'I, the undersigned, confirm and agree with the hospital assessment process and evaluation',
              style: pw.TextStyle(
                fontSize: 10,
              ),
            ),
            pw.SizedBox(height: 80), // Add some spacing
            pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Hospital Stamp and Signature:',
                    style: pw.TextStyle(
                      fontSize: 12,
                    ),
                  ),
                  pw.Text(
                    'Assessment Done By:',
                    style: pw.TextStyle(
                      fontSize: 12,
                    ),
                  ),
                ]),

            pw.SizedBox(height: 40),

            // Add signature lines
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '__________________________',
                      style: pw.TextStyle(fontSize: 12),
                    ),
                    pw.Text(
                      'Hospital\'s Focal Person Name',
                      style: pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '________________________________',
                      style: pw.TextStyle(fontSize: 12),
                    ),
                    pw.Text(
                      'Name',
                      style: pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ));

        content.add(pw.SizedBox(height: 80));
        // Add additional sections (BED, STAFF)
        dataModel.SECTIONS!.forEach((section) {
          final bedItems = dataModel.BED!
              .where((bed) => bed.section_id == section.section_id)
              .toList();
          final staffItems = dataModel.STAFF!
              .where((staff) => staff.section_id == section.section_id)
              .toList();

          // Add Section Header
          content.add(
            pw.Container(
              color: PdfColors.grey300,
              alignment: pw.Alignment.center,
              padding: const pw.EdgeInsets.all(10),
              child: pw.Text(
                section.section_name ?? "",
                style:
                    pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
            ),
          );

          content.add(pw.SizedBox(height: 10));

          // Add Questions
          if (section.questions != null && section.questions!.isNotEmpty) {
            for (final question in section.questions!) {
              if (question.question_type == 'files') continue;

              content.add(
                pw.Text(
                  'Question: ${question.question ?? 'N/A'}',
                  style: pw.TextStyle(fontSize: 14),
                ),
              );

              if (question.question_type == 'radio') {
                for (int optIndex = 0;
                    optIndex < (question.options ?? []).length;
                    optIndex++) {
                  final option = question.options![optIndex];
                  content.add(
                    pw.Text(
                      '${optIndex + 1}. ${option.option_description ?? 'N/A'}',
                      style: pw.TextStyle(fontSize: 11),
                    ),
                  );
                }

                content.add(
                  pw.Text(
                    'GIVEN: ${question.selected ?? 'N/A'}',
                    style: pw.TextStyle(
                        fontSize: 10, fontWeight: pw.FontWeight.bold),
                  ),
                );
              } else if (question.question_type == 'text') {
                content.add(
                  pw.Text(
                    'ANSWER: ${question.selected ?? 'N/A'}',
                    style: pw.TextStyle(
                        fontSize: 11, fontWeight: pw.FontWeight.bold),
                  ),
                );
              }

              content.add(pw.SizedBox(height: 10));
            }
          }
          content.add(pw.SizedBox(height: 20));
          // Add BED Items
          if (bedItems.isNotEmpty) {
            for (final bed in bedItems) {
              content.add(
                pw.Text(
                  bed.question ?? 'N/A',
                  style: pw.TextStyle(
                      fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
              );

              content.add(
                pw.TableHelper.fromTextArray(
                  headers: ['Male', 'Female'],
                  data: [
                    [
                      bed.male.toString(),
                      bed.female.toString(),
                    ]
                  ],
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  cellAlignment: pw.Alignment.centerLeft,
                ),
              );

              content.add(pw.SizedBox(height: 10));
            }
          }
          content.add(pw.SizedBox(height: 20));
          // Add STAFF Items
          if (staffItems.isNotEmpty) {
            for (final staff in staffItems) {
              content.add(
                pw.Text(
                  staff.question ?? 'N/A',
                  style: pw.TextStyle(
                      fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
              );

              content.add(
                pw.TableHelper.fromTextArray(
                  headers: ['Full Time', 'Part Time'],
                  data: [
                    [
                      staff.full_time.toString(),
                      staff.part_time.toString(),
                    ]
                  ],
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  cellAlignment: pw.Alignment.centerLeft,
                ),
              );

              content.add(pw.SizedBox(height: 10));
            }
          }
        });
        content.add(pw.SizedBox(height: 10));

        return content;
      },
      // header: (context) {
      //   return context.pageNumber == 0
      //       ? pw.Align(
      //           alignment: pw.Alignment.topCenter,
      //           child: pw.Image(
      //             icon,
      //             width: 50, // Adjust icon size as needed
      //             height: 50,
      //           ),
      //         )
      //       : pw.SizedBox();
      // },
      footer: (context) {
        return pw.Align(
          alignment: pw.Alignment.bottomRight,
          child: pw.Text(
            'Page ${context.pageNumber} out of ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
        );
      },
      pageTheme: pw.PageTheme(buildBackground: (context) {
        return pw.Center(
          child: pw.Opacity(
            opacity: 0.2, // Set opacity to create a blur-like effect
            child: pw.Image(
              background,
              fit: pw.BoxFit.cover,
              width: 300, // Adjust as needed
              height: 300, // Adjust as needed
            ),
          ),
        );
      }),
    ));

    ///
//     for (int i = 0; i < dataModel.SECTIONS!.length; i++) {
//       final section = dataModel.SECTIONS![i]; //sections[i];
//       final bedItems = dataModel.BED!
//           .where((bed) => bed.section_id == section.section_id)
//           .toList();
//       final staffItems = dataModel.STAFF!
//           .where((staff) => staff.section_id == section.section_id)
//           .toList();
//       // Check if there are questions in the section
//       if (section.questions != null && section.questions!.isNotEmpty) {
//         const int questionsPerPage = 15;
//         int totalPages = (section.questions!.length / questionsPerPage).ceil();
//
//         for (int page = 0; page < totalPages; page++) {
//           final int start = page * questionsPerPage;
//           final int end = (start + questionsPerPage > section.questions!.length)
//               ? section.questions!.length
//               : start + questionsPerPage;
//
//           final List<pw.Widget> children = [
//             // Section Header with background and centered
//             pw.Container(
//               color: PdfColors.grey300,
//               alignment: pw.Alignment.center,
//               padding: const pw.EdgeInsets.all(10),
//               child: pw.Text(
//                 section.section_name ?? "",
//                 style:
//                     pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
//               ),
//             ),
//             pw.SizedBox(height: 10),
//             // Add some spacing after the section header
//             pw.Text('Page ${page + 1} of $totalPages',
//                 style: pw.TextStyle(fontSize: 10)),
//           ];
//
//           bool hasContent =
//               false; // Track whether there's any valid content to display
//
//           for (int j = start; j < end; j++) {
//             final question = section.questions![j];
//
//             // Check if question_type is null or matches 'files' and skip those questions
//             if (question.question_type == null ||
//                 question.question_type == 'files') {
//               continue; // Skip this question if it's a file
//             }
//
//             // If we have valid content, mark hasContent as true
//             hasContent = true;
//
//             // Display for 'radio' type (MCQs)
//             if (question.question_type == 'radio') {
//               final options = question.options ?? [];
//
//               // Add the question text
//               children.add(pw.Text(
//                 'Question ${(j + 1)}: ${question.question ?? 'N/A'}',
//                 style: pw.TextStyle(fontSize: 14),
//               ));
//
//               // Loop through options and display them with different colors
//               for (int optIndex = 0; optIndex < options.length; optIndex++) {
//                 final option = options[optIndex];
//                 final optionColor = _getOptionColor(
//                     optIndex); // Function to get unique color per option
//
//                 children.add(pw.Text(
//                   '${optIndex + 1}. ${option.option_description ?? 'N/A'}',
//                   style: pw.TextStyle(
//                     fontSize: 11,
//                     color: optionColor,
//                   ),
//                 ));
//               }
//
//               // Display the selected answer in BOLD with | BOLD |
//               children.add(
//                 pw.Text(
//                   'GIVEN:  ${question.selected ?? 'N/A'} ',
//                   style: pw.TextStyle(
//                     fontSize: 10,
//                     fontWeight: pw.FontWeight.bold,
//                   ),
//                 ),
//               );
//             }
//
//             // Display for 'text' type
//             else if (question.question_type == 'text') {
//               children.add(pw.Text(
//                 'Question ${(j + 1)}: ${question.question ?? 'N/A'}',
//                 style: pw.TextStyle(fontSize: 14),
//               ));
//               children.add(
//                 pw.Text(
//                   'ANSWER: ${question.selected ?? 'N/A'} ',
//                   style: pw.TextStyle(
//                     fontSize: 11,
//                     fontWeight: pw.FontWeight.bold,
//                   ),
//                 ),
//               );
//             }
//           }
//
//           // Only add the page if we have content
//           if (hasContent) {
//             pdf.addPage(pw.Page(
//               build: (context) {
//                 return pw.Column(
//                   crossAxisAlignment: pw.CrossAxisAlignment.start,
//                   children: children,
//                 );
//               },
//             ));
//           }
//         }
//       } else if (bedItems.isNotEmpty) {
//         // Loop through sections
//         // Loop through sections
//         if (bedItems[0].section_id == section.section_id) {
//           const int questionsPerPage =
//               10; // Define how many questions per page (adjust as needed)
//
//           // Calculate the total number of pages needed
//           int totalPages = (bedItems.length / questionsPerPage).ceil();
//
//           for (int page = 0; page < totalPages; page++) {
//             final int start = page * questionsPerPage;
//             final int end = (start + questionsPerPage > bedItems.length)
//                 ? bedItems.length
//                 : start + questionsPerPage;
//
//             pdf.addPage(pw.Page(
//               build: (context) {
//                 return pw.Column(
//                   crossAxisAlignment: pw.CrossAxisAlignment.start,
//                   children: [
//                     // Section Header with background and centered
//                     pw.Container(
//                       color: PdfColors.grey300,
//                       alignment: pw.Alignment.center,
//                       padding: const pw.EdgeInsets.all(10),
//                       child: pw.Text(
//                         section.section_name ?? "",
//                         style: pw.TextStyle(
//                             fontSize: 18, fontWeight: pw.FontWeight.bold),
//                       ),
//                     ),
//                     pw.SizedBox(height: 10),
//                     // Add some spacing after the section header
//
//                     // Loop through the BED items for the current page
//                     ...List.generate(end - start, (i) {
//                       final bed = bedItems[start + i];
//                       return pw.Column(
//                         crossAxisAlignment: pw.CrossAxisAlignment.start,
//                         children: [
//                           // Question Text
//                           pw.Text(
//                             bed.question ?? 'N/A',
//                             style: pw.TextStyle(
//                                 fontSize: 12, fontWeight: pw.FontWeight.bold),
//                           ),
//
//                           // Table with Male and Female
//                           pw.TableHelper.fromTextArray(
//                             headers: ['Male', 'Female'],
//                             data: [
//                               [
//                                 bed.male.toString(),
//                                 bed.female.toString(),
//                               ]
//                             ],
//                             headerStyle:
//                                 pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                             cellAlignment: pw.Alignment.centerLeft,
//                           ),
//                           pw.SizedBox(height: 10), // Space between entries
//                         ],
//                       );
//                     }),
//
//                     // Add pagination info (optional)
//                     pw.SizedBox(height: 20),
//                     pw.Text('Page ${page + 1} of $totalPages',
//                         style: pw.TextStyle(fontSize: 10)),
//                   ],
//                 );
//               },
//             ));
//           }
//         }
//       } else if (staffItems.isNotEmpty) {
//         if (staffItems[0].section_id == section.section_id) {
//           const int questionsPerPage =
//               10; // Define how many questions per page (adjust as needed)
//
//           // Calculate the total number of pages needed
//           int totalPages = (staffItems.length / questionsPerPage).ceil();
//
//           for (int page = 0; page < totalPages; page++) {
//             final int start = page * questionsPerPage;
//             final int end = (start + questionsPerPage > staffItems.length)
//                 ? staffItems.length
//                 : start + questionsPerPage;
//
//             pdf.addPage(pw.Page(
//               build: (context) {
//                 return pw.Column(
//                   crossAxisAlignment: pw.CrossAxisAlignment.start,
//                   children: [
//                     // Section Header with background and centered
//                     pw.Container(
//                       color: PdfColors.grey300,
//                       alignment: pw.Alignment.center,
//                       padding: const pw.EdgeInsets.all(10),
//                       child: pw.Text(
//                         section.section_name ?? "",
//                         style: pw.TextStyle(
//                             fontSize: 18, fontWeight: pw.FontWeight.bold),
//                       ),
//                     ),
//                     pw.SizedBox(height: 10),
//                     // Add some spacing after the section header
//
//                     // Loop through the BED items for the current page
//                     ...List.generate(end - start, (i) {
//                       final staff = staffItems[start + i];
//                       return pw.Column(
//                         crossAxisAlignment: pw.CrossAxisAlignment.start,
//                         children: [
//                           // Question Text
//                           pw.Text(
//                             staff.question ?? 'N/A',
//                             style: pw.TextStyle(
//                                 fontSize: 12, fontWeight: pw.FontWeight.bold),
//                           ),
//
//                           // Table with Male and Female
//                           pw.TableHelper.fromTextArray(
//                             headers: ['Full Time', 'Part Time'],
//                             data: [
//                               [
//                                 staff.full_time.toString(),
//                                 staff.part_time.toString(),
//                               ]
//                             ],
//                             headerStyle:
//                                 pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                             cellAlignment: pw.Alignment.centerLeft,
//                           ),
//                           pw.SizedBox(height: 10), // Space between entries
//                         ],
//                       );
//                     }),
//
//                     // Add pagination info (optional)
//                     pw.SizedBox(height: 20),
//                     pw.Text('Page ${page + 1} of $totalPages',
//                         style: pw.TextStyle(fontSize: 10)),
//                   ],
//                 );
//               },
//             ));
//           }
//         }
//       } else {
//         // Handle sections with no questions
//         pdf.addPage(pw.Page(
//           build: (context) {
//             return pw.Column(
//               crossAxisAlignment: pw.CrossAxisAlignment.start,
//               children: [
//                 pw.Text('${section.section_name} (No questions available)',
//                     style: pw.TextStyle(fontSize: 18)),
//               ],
//             );
//           },
//         ));
//       }
//     }
    ///
    final directory = await (Platform.isAndroid
        ? getExternalStorageDirectory()
        : getTemporaryDirectory());
    final Uint8List bytes = await pdf.save();
    final imagePath = '${directory!.path}/${'_special_document.pdf'}';
    await File(imagePath).writeAsBytes(bytes);
    OpenFile.open(imagePath);
  }
}

// Helper function to get a different color for each option
PdfColor _getOptionColor(int index) {
  final colors = [
    PdfColors.blue,
    PdfColors.green,
    PdfColors.red,
    PdfColors.orange,
    PdfColors.purple,
  ];

  // Cycle through colors if more than the length of the list
  return colors[index % colors.length];
}

pw.Widget createTable() {
  final baseColor = PdfColor.fromHex('#D9EAD3'); // Light green background color

  return pw.TableHelper.fromTextArray(
    headers: ['Sr.', 'Points', 'Yes', 'No', 'Remarks'],
    cellAlignment: pw.Alignment.centerLeft,
    cellStyle: pw.TextStyle(fontSize: 12),
    headerStyle: pw.TextStyle(
        fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
    headerDecoration: pw.BoxDecoration(color: PdfColors.blueGrey),
    rowDecoration: pw.BoxDecoration(
      border: pw.Border(
        bottom: pw.BorderSide(width: 0.5, color: PdfColors.grey),
      ),
      color: baseColor,
    ),
    data: [
      [
        '1',
        'Hospital found Functional (If "Yes" clear Video evidence should be provided)',
        '',
        '',
        ''
      ],
      [
        '2',
        'Registration with Health Care Commission as a hospital',
        '',
        '',
        ''
      ],
      ['3', 'Accessibility', '', '', ''],
      ['3.1', 'Motorable road', '', '', ''],
      ['3.2', 'Ramp or functional bed Elevator 24 hr\'s Service', '', '', ''],
      ['3.3', 'Generator Support', '', '', ''],
      ['4', '24/7 Emergency Services available', '', '', ''],
      ['4.1', 'On Duty Medical Officer available', '', '', ''],
      ['5', 'Emergency Services at Ground Floor', '', '', ''],
      ['6', 'Availability of in-house Pharmacy', '', '', ''],
      ['7', 'Availability of in-house Laboratory', '', '', ''],
      [
        '8',
        'At least 3 Specialties available (Except Category D Districts)',
        '',
        '',
        ''
      ],
      [
        '8.1',
        'General Surgery & Allied Surgery (Eye, ENT, Ortho Urology, Etc.)',
        '',
        '',
        ''
      ],
      ['8.2', 'Gynecology', '', '', ''],
      ['8.2.1', 'Functional labor room', '', '', ''],
      ['8.2.2', 'WMO Available', '', '', ''],
      ['8.2.3', 'Gynecologist available (On call)', '', '', ''],
      ['8.3', 'Medicine & Allied', '', '', ''],
      ['9', 'Availability of Operation Theatre (OT)', '', '', ''],
      ['9.1', 'Anesthesia machine available', '', '', ''],
      [
        '9.2',
        'Is OT Functional (Mark "Yes" if OT record is provided)',
        '',
        '',
        ''
      ],
      ['10', 'Expired Medication/Disposables', '', '', ''],
      [
        '10.1',
        'In the Shelf\'s of non-expiry medicines at Pharmacy',
        '',
        '',
        ''
      ],
      ['10.2', 'Operation Theater (OT)', '', '', ''],
      ['10.3', 'ICU/CCU/NICU', '', '', ''],
      ['10.4', 'Emergency Room', '', '', ''],
      ['10.5', 'Labor Room', '', '', ''],
      [
        '11',
        'The hospital is having specific functional Beds available',
        '',
        '',
        ''
      ],
      ['11.1', 'Emergency Room Beds', '', '', ''],
      ['11.2', 'Wards Beds', '', '', ''],
      ['11.3', 'ICU/CCU Beds', '', '', ''],
    ],
    columnWidths: {
      0: pw.FixedColumnWidth(20),
      1: pw.FlexColumnWidth(4),
      2: pw.FixedColumnWidth(30),
      3: pw.FixedColumnWidth(30),
      4: pw.FlexColumnWidth(2),
    },
    cellHeight: 40,
    cellPadding: pw.EdgeInsets.all(5),
    headerPadding: pw.EdgeInsets.all(5),
  );
}

Future<void> openFile(String filePath) async {
  await OpenFile.open(filePath);
}
