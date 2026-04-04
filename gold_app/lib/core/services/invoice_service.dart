import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../constants/app_constants.dart';
import '../../features/order/data/models/order_model.dart';

class InvoiceService {
  static String generateInvoiceNumber() {
    final now = DateTime.now();
    final formatter = DateFormat('yyyyMMdd');
    final randomDigits = (1000 + (now.millisecondsSinceEpoch % 9000)).toString();
    return 'RG-${formatter.format(now)}-$randomDigits';
  }

  static Map<String, dynamic> calculateInvoiceDetails({
    required double basePrice,
    required double weight,
    double? commissionOverride,
    double? gstRateOverride,
  }) {
    final subtotal = basePrice * weight;
    final commissionRate = commissionOverride ?? 2.5; 
    final commissionAmount = subtotal * (commissionRate / 100);
    final taxableAmount = subtotal + commissionAmount;
    final currentGstRate = gstRateOverride ?? AppConstants.gstRate;
    final gstAmount = taxableAmount * currentGstRate;
    final totalAmount = taxableAmount + gstAmount;

    return {
      'invoiceNumber': generateInvoiceNumber(),
      'date': DateTime.now().toIso8601String(),
      'basePricePerGram': basePrice,
      'weight': weight,
      'subtotal': subtotal,
      'commissionRate': commissionRate,
      'commissionAmount': commissionAmount,
      'taxableAmount': taxableAmount,
      'gstRate': currentGstRate * 100,
      'gstAmount': gstAmount,
      'totalAmount': totalAmount,
    };
  }
  
  static Future<void> generateAndPreviewInvoice(OrderModel order, {double? gstRate}) async {
    final pdf = pw.Document();
    
    // Calculate details
    final details = calculateInvoiceDetails(
      basePrice: order.price,
      weight: order.weight,
      gstRateOverride: gstRate,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('ROYAL GOLD', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.amber)),
                        pw.Text('Premium Bullion Trading', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('INVOICE', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                        pw.Text('No: ${details['invoiceNumber']}', style: pw.TextStyle(fontSize: 12)),
                        pw.Text('Date: ${DateFormat('dd MMM yyyy').format(DateTime.now())}', style: pw.TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 40),
                
                // Customer Section
                pw.Text('Bill To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('Valued Customer', style: pw.TextStyle(fontSize: 14)),
                pw.Text('Order ID: ${order.id}'),
                pw.SizedBox(height: 40),
                
                // Table
                pw.TableHelper.fromTextArray(
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration: pw.BoxDecoration(color: PdfColors.amber900),
                  cellHeight: 30,
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.center,
                    2: pw.Alignment.centerRight,
                    3: pw.Alignment.centerRight,
                  },
                  headers: ['Description', 'Weight', 'Base Price', 'Total'],
                  data: [
                    [
                      order.productName,
                      '${order.weight} g',
                      NumberFormat.currency(locale: 'en_IN', symbol: 'Rs.').format(order.price),
                      NumberFormat.currency(locale: 'en_IN', symbol: 'Rs.').format(details['subtotal']),
                    ],
                  ],
                ),
                pw.SizedBox(height: 20),
                
                // Summary Section
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        _SummaryRow('Subtotal', details['subtotal']),
                        _SummaryRow('GST (3%)', details['gstAmount']),
                        pw.Divider(color: PdfColors.amber, thickness: 2),
                        pw.Text(
                          'Total Amount: ${NumberFormat.currency(locale: 'en_IN', symbol: 'Rs.').format(details['totalAmount'])}',
                          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.amber900),
                        ),
                      ],
                    ),
                  ],
                ),
                
                pw.Spacer(),
                
                // Footer
                pw.Divider(),
                pw.Text('Terms and Conditions', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('1. All sales of gold are final and non-refundable.', style: pw.TextStyle(fontSize: 10)),
                pw.Text('2. Prices are based on live market rates at the time of purchase.', style: pw.TextStyle(fontSize: 10)),
                pw.Text('3. This is a computer-generated invoice and does not require a signature.', style: pw.TextStyle(fontSize: 10)),
                pw.SizedBox(height: 10),
                pw.Center(child: pw.Text('Thank you for choosing Royal Gold.', style: pw.TextStyle(fontStyle: pw.FontStyle.italic))),
              ],
            ),
          );
        },
      ),
    );

    if (kIsWeb) {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'invoice_${order.id}.pdf',
      );
    } else {
      // For mobile/desktop, we can still use printing or save to file
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'invoice_${order.id}.pdf',
      );
    }
  }

  static pw.Widget _SummaryRow(String label, double amount) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text('$label: ', style: pw.TextStyle(color: PdfColors.grey700)),
          pw.Text(NumberFormat.currency(locale: 'en_IN', symbol: 'Rs.').format(amount)),
        ],
      ),
    );
  }
}
