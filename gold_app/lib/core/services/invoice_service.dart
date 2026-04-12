import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../../features/auth/data/models/user_model.dart';
import '../../features/order/data/models/order_model.dart';
import '../utils/formatters.dart';

class InvoiceService {
  static const PdfColor goldColor = PdfColor.fromInt(0xFFC8992A);
  static const PdfColor paperColor = PdfColor.fromInt(0xFFFFF9EB);

  static final Map<String, pw.MemoryImage> _imageCache = {};

  static Future<pw.Document> _buildInvoiceDoc(OrderModel order, UserModel? user) async {
    final font = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();
    final fontHindi = await PdfGoogleFonts.notoSansDevanagariRegular();
    
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: font,
        bold: fontBold,
        fontFallback: [fontHindi],
      ),
    );

    final bisLogo = await _loadAssetImage('assets/images/BIS.webp');
    final isoLogo = await _loadAssetImage('assets/images/ISO.webp');
    final brandLogo = await _loadAssetImage('assets/images/Royal_Gold_Traders.webp');
    final stampLogo = await _loadAssetImage('assets/images/stamps_logo.webp');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(12),
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              // 1. Background Paper Layer
              pw.Container(
                width: double.infinity,
                height: double.infinity,
                color: paperColor,
              ),
              // 2. Logo Watermark (Middle)
              if (brandLogo != null) _buildLogoWatermark(brandLogo),
              // 3. Status Watermark (Over Logo)
              _buildStatusWatermark(order.status),
              // 4. Content (Transparent container)
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 0.5),
                ),
                child: pw.Column(
                  children: [
                    _buildMainHeader(bisLogo, isoLogo, brandLogo),
                    _buildMetaInfoGrid(order),
                    _buildCustomerTransactionHeader(),
                    _buildCustomerSection(user, order),
                    _buildMainItemTable(order),
                    _buildSummaryTripleBlock(order),
                    _buildFinePrint(fontHindi),
                   _buildBankDetailsGrid(),
                    _buildFooterArea(stampLogo),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
    return pdf;
  }

  static pw.Widget _buildMainHeader(pw.MemoryImage? bis, pw.MemoryImage? iso, pw.MemoryImage? brand) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(12),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('ROYAL GOLD', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.Text('TRADERS', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.Row(
            children: [
              if (bis != null) pw.Image(bis, width: 80, height: 60),
              pw.SizedBox(width: 15),
              if (iso != null) pw.Image(iso, width: 55, height: 55),
            ],
          ),
          if (brand != null) pw.Image(brand, width: 70),
        ],
      ),
    );
  }

  static pw.Widget _buildMetaInfoGrid(OrderModel order) {
    return pw.Container(
      decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(width: 0.5), bottom: pw.BorderSide(width: 0.5))),
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _gridRow('State / राज्य', 'BIHAR'),
              _gridRow('State Code', '10'),
              _gridRow('GSTIN / जीएसटी', '10ADJPI8137N1ZE'),
              _gridRow('Address', '2ND FLOOR, B-19, P.C. COLONY,'),
              _gridRow('', 'NEAR LOHIYA NAGAR PARK, KANKARBAGH,'),
              _gridRow('', 'PATNA, BIHAR 800020.'),
              _gridRow('Phone', '9065415619'),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              _gridRow('BIS Cert.', 'HM/C-5390544515'),
              _gridRow('PAN / पैन', 'ADJPI8137N'),
              _gridRow('Bill No. / बिल सं.', order.id.substring(0, 8).toUpperCase(), bold: true),
              _gridRow('Bill Date / दिनांक', DateFormat('dd/MM/yyyy h:mm a').format(order.createdAt)),
              _gridRow('Due Date / नियत तिथि', DateFormat('dd/MM/yyyy').format(order.createdAt.add(const Duration(days: 15)))),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _gridRow(String label, String value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 1),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          if (label.isNotEmpty) pw.Text('$label : ', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
          pw.Text(value, style: pw.TextStyle(fontSize: 7, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }

  static pw.Widget _buildCustomerTransactionHeader() {
    return pw.Container(
      color: PdfColors.white,
      width: double.infinity,
      padding: const pw.EdgeInsets.only(left: 10, top: 4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(children: [
            _diamondBullet(),
            pw.Text('CUSTOMER TRANSACTIONS', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
          ]),
          pw.Text('• ORIGINAL FOR RECIPIENT', style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey700)),
        ],
      ),
    );
  }

  static pw.Widget _buildCustomerSection(UserModel? user, OrderModel order) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _custRow('Name / नाम', user?.name ?? 'Nidhi Kumari Ray'),
              _custRow('Mobile / मोबाइल', user?.phone ?? '9142345733'),
              _custRow('Address / पता', user?.address ?? 'Piparakothi, Motihaari'),
              _custRow('Place of Supply / आपूर्ति स्थान', 'BIHAR'),
              _custRow('Ref No. / संदर्भ संख्या', order.id.substring(0, 6).toUpperCase()),
              _custRow('Rate/gram / दर/ग्राम', '${Formatters.currency(order.price / order.quantity)} (24 CT)'),
              _custRow('Attended By / परिचारक', 'NA'),
              _custRow('Contact No. / संपर्क नंबर', 'NA'),
            ],
          ),
          pw.Container(
            width: 70,
            height: 70,
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
            child: pw.Center(
              child: pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(),
                data: 'https://royalgold.app/verify/${order.id}',
                width: 60,
                height: 60,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _custRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 130, child: pw.Text('$label :', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold))),
          pw.Text(value, style: const pw.TextStyle(fontSize: 7)),
        ],
      ),
    );
  }

  static pw.Widget _buildMainItemTable(OrderModel order) {
    final subtotal = order.price;
    return pw.Container(
      decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(width: 0.5), bottom: pw.BorderSide(width: 0.5))),
      child: pw.Table(
        border: const pw.TableBorder(verticalInside: pw.BorderSide(width: 0.5), bottom: pw.BorderSide(width: 0.5)),
        columnWidths: {
          0: const pw.FixedColumnWidth(25), // sl
          1: const pw.FixedColumnWidth(40), // HSN
          2: const pw.FlexColumnWidth(),   // Desc
          3: const pw.FixedColumnWidth(25), // Qty
          4: const pw.FixedColumnWidth(35), // GrossWt
          5: const pw.FixedColumnWidth(60), // Stone/Other
          6: const pw.FixedColumnWidth(35), // NetWt
          7: const pw.FixedColumnWidth(45), // Metal Value
          8: const pw.FixedColumnWidth(30), // VADD %
          9: const pw.FixedColumnWidth(50), // Gross Amount
        },
        children: [
          // Header Row 1
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: goldColor),
            children: [
              _headerCell('sl. No.'),
              _headerCell('HSN Code'),
              _headerCell('Item Description / Purity'),
              _headerCell('Qty'),
              _headerCell('Gross Weight'),
              _headerCell('Stone/Other Material'),
              _headerCell('Net Weight'),
              _headerCell('Metal Value'),
              _headerCell('VADD %'),
              _headerCell('Gross Amount'),
            ],
          ),
          // Data Row
          pw.TableRow(
            children: [
              _dataCell('1'),
              _dataCell('711319'),
              _dataCell('${order.productName} (24 CT)'),
              _dataCell(order.quantity.toString()),
              _dataCell(order.weight.toStringAsFixed(3)),
              _dataCell('0.000 / 0.00'),
              _dataCell(order.weight.toStringAsFixed(3)),
              _dataCell(order.discountedValue.toStringAsFixed(2)),
              _dataCell('6.00'),
              _dataCell((order.discountedValue + order.makingChargesValue).toStringAsFixed(2)),
            ],
          ),
          // Total Row
          pw.TableRow(
            children: [
              _dataCell('Total', bold: true),
              _dataCell(''),
              _dataCell(''),
              _dataCell(order.quantity.toString(), bold: true),
              _dataCell(order.weight.toStringAsFixed(3), bold: true),
              _dataCell(''),
              _dataCell(order.weight.toStringAsFixed(3), bold: true),
              _dataCell(order.discountedValue.toStringAsFixed(2), bold: true),
              _dataCell(''),
              _dataCell((order.discountedValue + order.makingChargesValue).toStringAsFixed(2), bold: true),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _headerCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(2),
      child: pw.Center(child: pw.Text(text, style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
    );
  }

  static pw.Widget _dataCell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(3),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 7, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal), textAlign: pw.TextAlign.center),
    );
  }

  static pw.Widget _buildSummaryTripleBlock(OrderModel order) {
    final taxable = order.discountedValue + order.makingChargesValue;
    final cgst = order.cgst;
    final sgst = order.sgst;
    final total = order.total;

    return pw.Padding(
      padding: const pw.EdgeInsets.all(10),
      child: pw.Row(
        children: [
          // Invoice Summary
          pw.Expanded(
            child: _summaryTable('INVOICE SUMMARY', [
              ['Gold Value', order.discountedValue.toStringAsFixed(2)],
              ['Making Charges', order.makingChargesValue.toStringAsFixed(2)],
              ['Taxable Amount', taxable.toStringAsFixed(2)],
              ['CGST 1.50%', cgst.toStringAsFixed(2)],
              ['SGST 1.50%', sgst.toStringAsFixed(2)],
              ['Invoice Total', total.toStringAsFixed(2)],
            ], highlightLast: true),
          ),
          pw.SizedBox(width: 10),
          // Settlement Summary
          pw.Expanded(
            child: _summaryTable('SETTLEMENT SUMMARY', [
              ['Invoice Total', total.toStringAsFixed(2)],
              ['Paid Amount', total.toStringAsFixed(2)],
              ['Due Amount', '0.00'],
            ], showBlue: true),
          ),
          pw.SizedBox(width: 10),
          // Mode of Payment
          pw.Expanded(
            child: _summaryTable('MODE OF PAYMENT', [
              ['ROUND_OFF', '0.00'],
              ['ONLINE', total.toStringAsFixed(2)],
            ]),
          ),
        ],
      ),
    );
  }

  static pw.Widget _summaryTable(String title, List<List<String>> rows, {bool highlightLast = false, bool showBlue = false}) {
    return pw.Table(
      border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(2),
              child: pw.Center(child: pw.Text(title, style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold))),
            ),
            pw.SizedBox(),
          ],
        ),
        ...rows.map((row) {
          final isLast = row == rows.last && highlightLast;
          final isBlue = showBlue && row[0] == 'Paid Amount';
          return pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(2),
                child: pw.Text(row[0], style: pw.TextStyle(fontSize: 6, color: isBlue ? PdfColors.blue : PdfColors.black)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(2),
                child: pw.Text(row[1], style: pw.TextStyle(fontSize: 6, fontWeight: isLast ? pw.FontWeight.bold : pw.FontWeight.normal), textAlign: pw.TextAlign.right),
              ),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildFinePrint(pw.Font fontHindi) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            color: PdfColors.grey100,
            width: double.infinity,
            padding: const pw.EdgeInsets.all(4),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Amount in words (शब्दों में राशि): Only Rupees Example...', style: pw.TextStyle(fontSize: 7, fontFallback: [fontHindi])),
                pw.Text('Total : ---', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text('Effective value addition(MC) after discount : 6.00%', style: const pw.TextStyle(fontSize: 5.5)),
          pw.Text('Except for 999 Gold items & ornaments below 2 grams, Price inclusive of Hallmarking Charges at Rs 45/- per piece.', style: const pw.TextStyle(fontSize: 5.5)),
          pw.SizedBox(height: 4),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(width: 8, height: 8, decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5))),
              pw.SizedBox(width: 4),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'I hereby consent to receive messages via WhatsApp, SMS or other social media platforms and also receive calls in my mobile number provided in this invoice.',
                      style: const pw.TextStyle(fontSize: 5.5),
                    ),
                    pw.Text(
                      'मैं इसके द्वारा इस चालान में दिए गए मोबाइल नंबर पर व्हाट्सएप, एसएमएस या अन्य सोशल मीडिया प्लेटफॉर्म के माध्यम से संदेश और कॉल प्राप्त करने की सहमति देता हूं।',
                      style: pw.TextStyle(fontSize: 5.5, fontFallback: [fontHindi]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildBankDetailsGrid() {
    return pw.Container(
      margin: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
      child: pw.Column(
        children: [
          pw.Container(
            width: double.infinity,
            color: PdfColor.fromInt(0x1AC8992A),
            padding: const pw.EdgeInsets.all(2),
            child: pw.Row(children: [
              _diamondBullet(),
              pw.Text('BANK & PAYMENT DETAILS / बैंक और भुगतान विवरण', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
            ]),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _bankRow('Account Name', 'ROYAL GOLD TRADERS'),
                      _bankRow('Account No.', '00000045030556376'),
                      _bankRow('MICR Code', '800002020'),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _bankRow('Bank & Branch', 'SBI, PATNA MAIN BRANCH'),
                      _bankRow('IFSC Code', 'SBIN0009005'),
                      _bankRow('GSTIN', '10ADJPI8137N1ZE'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _bankRow(String label, String value) {
    return pw.Row(
      children: [
        pw.SizedBox(width: 70, child: pw.Text('$label :', style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold))),
        pw.Text(value, style: const pw.TextStyle(fontSize: 6.5)),
      ],
    );
  }

  static pw.Widget _buildFooterArea(pw.MemoryImage? brandStamp) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(15),
      child: pw.Stack(
        alignment: pw.Alignment.center,
        children: [
          // Purple Stamp Placeholder
          pw.Positioned(
            left: 50,
            child: pw.Transform.rotate(
              angle: -0.1,
              child: pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColor.fromInt(0xFF800080), width: 1.5),
                ),
                child: pw.Column(
                  children: [
                    pw.Text('ITEM BOOKED', style: pw.TextStyle(color: PdfColor.fromInt(0xFF800080), fontWeight: pw.FontWeight.bold, fontSize: 8)),
                    pw.Text('DELIVER IN 15 DAYS', style: pw.TextStyle(color: PdfColor.fromInt(0xFF800080), fontWeight: pw.FontWeight.bold, fontSize: 8)),
                  ],
                ),
              ),
            ),
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Column(
                children: [
                  pw.SizedBox(height: 30),
                  pw.Text('Customer Signature', style: const pw.TextStyle(fontSize: 7)),
                  pw.Text('ग्राहक के हस्ताक्षर', style: const pw.TextStyle(fontSize: 6)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  if (brandStamp != null) pw.Image(brandStamp, width: 60),
                  pw.SizedBox(height: 4),
                  pw.Text('Authorised Signatory', style: const pw.TextStyle(fontSize: 7)),
                  pw.Text('for ROYAL GOLD TRADERS', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _diamondBullet() {
    return pw.Container(
      margin: const pw.EdgeInsets.only(right: 5),
      width: 4,
      height: 4,
      decoration: const pw.BoxDecoration(
        color: goldColor,
        shape: pw.BoxShape.rectangle,
      ),
      child: pw.Transform.rotate(angle: 0.785, child: pw.SizedBox()), // 45 degrees
    );
  }

  static Future<void> generateAndPreviewInvoice(OrderModel order, {UserModel? user}) async {
    final pdf = await _buildInvoiceDoc(order, user);
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save(), name: 'Invoice_${order.id}.pdf');
  }

  static Future<void> downloadInvoice(OrderModel order, {UserModel? user}) async {
    final pdf = await _buildInvoiceDoc(order, user);
    final bytes = await pdf.save();
    final fileName = 'Invoice_${order.id}.pdf';
    
    if (kIsWeb) {
      // Trigger a direct browser download without the share dialog
      await Printing.sharePdf(
        bytes: bytes, 
        filename: fileName,
      );
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      await OpenFilex.open(file.path);
    }
  }

  static Future<pw.MemoryImage> _loadAssetImage(String path) async {
    if (_imageCache.containsKey(path)) return _imageCache[path]!;
    final data = await rootBundle.load(path);
    final image = pw.MemoryImage(data.buffer.asUint8List());
    _imageCache[path] = image;
    return image;
  }

  static pw.Widget _buildLogoWatermark(pw.MemoryImage logo) {
    return pw.Center(
      child: pw.Opacity(
        opacity: 0.15,
        child: pw.Image(logo, width: 450),
      ),
    );
  }

  static pw.Widget _buildStatusWatermark(String status) {
    if (status.isEmpty) return pw.SizedBox();
    return pw.Center(
      child: pw.Transform.rotate(
        angle: -0.5,
        child: pw.Text(
          status.toUpperCase(),
          style: pw.TextStyle(fontSize: 80, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0x33BBBBBB)),
        ),
      ),
    );
  }
}
