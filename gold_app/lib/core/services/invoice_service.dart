import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../features/auth/data/models/user_model.dart';
import '../../features/order/data/models/order_model.dart';
import '../utils/formatters.dart';

class InvoiceService {
  static Map<String, dynamic> calculateInvoiceDetails({
    required double basePrice,
    required double weight,
    double? gstRateOverride,
  }) {
    final subtotal = basePrice * weight;
    final taxableAmount = subtotal;
    final gstRate = gstRateOverride ?? 0.03;
    final gstAmount = taxableAmount * gstRate;
    final totalAmount = taxableAmount + gstAmount;

    return {
      'invoiceNumber': 'RG-${DateTime.now().millisecondsSinceEpoch}',
      'subtotal': subtotal,
      'gstAmount': gstAmount,
      'totalAmount': totalAmount,
    };
  }

  static Future<void> generateAndPreviewInvoice(OrderModel order, {UserModel? user}) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0),
        build: (pw.Context context) {
          return pw.Column(
            children: [
              _buildHeader(),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 0),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(height: 20),
                    _buildInvoiceTitle(),
                    pw.SizedBox(height: 20),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildInvoiceMetadata(order, user),
                        _buildQrPlaceholder(),
                      ],
                    ),
                    pw.SizedBox(height: 30),
                    _buildBilledTo(user),
                    pw.SizedBox(height: 30),
                    _buildProductTable(order),
                    pw.SizedBox(height: 20),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildPaymentDetails(order),
                        _buildSummaryAndStamp(order),
                      ],
                    ),
                    pw.SizedBox(height: 40),
                    _buildFooter(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Invoice_${order.invoiceNo ?? order.id}.pdf',
    );
  }

  static pw.Widget _buildHeader() {
    return pw.Container(
      height: 140,
      width: double.infinity,
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFF1A1A1A),
      ),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            'ROYAL GOLD TRADERS',
            style: pw.TextStyle(
              color: PdfColor.fromInt(0xFFC5A059),
              fontSize: 28,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            '123 Gold Market Road, Bangalore - 560001  |  +91 98765 43210',
            style: pw.TextStyle(color: PdfColors.white, fontSize: 8),
          ),
          pw.Text(
            'GSTIN: 29AABCR1234J1ZJ  |  PAN: ABCR1234J  |  State Code: 29',
            style: pw.TextStyle(color: PdfColors.white, fontSize: 8),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInvoiceTitle() {
    return pw.Center(
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Container(width: 40, height: 1, color: PdfColors.grey400),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10),
            child: pw.Text(
              'GST INVOICE / ADVANCE RECEIPT',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
          pw.Container(width: 40, height: 1, color: PdfColors.grey400),
        ],
      ),
    );
  }

  static pw.Widget _buildInvoiceMetadata(OrderModel order, UserModel? user) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _metaRow('Invoice No:', order.invoiceNo ?? 'RGT/2026/0001'),
        _metaRow('Date:', DateFormat('dd/MM/yyyy').format(order.createdAt)),
        _metaRow('Place of Supply:', 'Karnataka'),
        _metaRow('Customer ID:', user?.id.substring(0, 8).toUpperCase() ?? 'CUST12345'),
      ],
    );
  }

  static pw.Widget _metaRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 80, child: pw.Text(label, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700))),
          pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static pw.Widget _buildQrPlaceholder() {
    return pw.Column(
      children: [
        pw.Container(
          width: 80,
          height: 80,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
          ),
          child: pw.Center(child: pw.Text('QR CODE', style: const pw.TextStyle(fontSize: 8))),
        ),
        pw.SizedBox(height: 4),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          color: PdfColors.black,
          child: pw.Text('SCAN TO PAY', style: const pw.TextStyle(color: PdfColors.white, fontSize: 7)),
        ),
      ],
    );
  }

  static pw.Widget _buildBilledTo(UserModel? user) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 2),
          decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400))),
          child: pw.Text('Billed To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ),
        pw.SizedBox(height: 8),
        pw.Text(user?.name ?? 'Rahul Sharma', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        pw.Text('Phone: ${user?.phone ?? '9876543210'}', style: const pw.TextStyle(fontSize: 10)),
        pw.Text('Address: 56, Lakeview Street, Bangalore, Karnataka - 560038', style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }

  static pw.Widget _buildProductTable(OrderModel order) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FixedColumnWidth(40),
        1: const pw.FlexColumnWidth(),
        2: const pw.FixedColumnWidth(60),
        3: const pw.FixedColumnWidth(80),
        4: const pw.FixedColumnWidth(80),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.black),
          children: [
            _tableHeader('Sr.'),
            _tableHeader('Description'),
            _tableHeader('Qty'),
            _tableHeader('Rate'),
            _tableHeader('Amount'),
          ],
        ),
        pw.TableRow(
          children: [
            _tableCell('1.'),
            _tableCell(order.productName),
            _tableCell(order.quantity.toString()),
            _tableCell(Formatters.currency(order.price / order.quantity)),
            _tableCell(Formatters.currency(order.price)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _tableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(text, style: pw.TextStyle(color: PdfColors.yellow, fontWeight: pw.FontWeight.bold, fontSize: 9)),
    );
  }

  static pw.Widget _tableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 9)),
    );
  }

  static pw.Widget _buildSummaryAndStamp(OrderModel order) {
    final taxable = order.price;
    final cgst = taxable * 0.015;
    final sgst = taxable * 0.015;
    final total = taxable + cgst + sgst;
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        _summaryRow('Taxable Amount:', taxable),
        _summaryRow('CGST @ 1.5%:', cgst),
        _summaryRow('SGST @ 1.5%:', sgst),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: pw.BoxDecoration(color: PdfColors.black),
          child: pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text('Grand Total:', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(width: 20),
              pw.Text(Formatters.currency(total), style: pw.TextStyle(color: PdfColors.yellow, fontWeight: pw.FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
        pw.SizedBox(height: 20),
        _buildStamp(),
      ],
    );
  }

  static pw.Widget _summaryRow(String label, double value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.SizedBox(width: 100, child: pw.Text(label, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700))),
          pw.SizedBox(width: 20),
          pw.Text(Formatters.currency(value), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static pw.Widget _buildStamp() {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.green700, width: 2),
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Text(
        'ADVANCE RECEIVED',
        style: pw.TextStyle(
          color: PdfColors.green700,
          fontSize: 12,
        ),
      ),
    );
  }

  static pw.Widget _buildPaymentDetails(OrderModel order) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Payment Mode: Online', style: const pw.TextStyle(fontSize: 10)),
        pw.Text('Transaction Ref. No: ${order.paymentId ?? 'UPI1234567890'}', style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey400),
        pw.Text('This is a system-generated invoice.', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        pw.Text('www.royalgoldtraders.com  |  Customer Care: +91 98765 43210', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('ORIGINAL FOR CUSTOMER', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500)),
            pw.Text('DUPLICATE FOR OFFICE', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500)),
          ],
        ),
      ],
    );
  }
}
