import PDFDocument from 'pdfkit';
import QRCode from 'qrcode';
import { PrismaClient } from '@prisma/client';
import r2Service from './R2Service';
import { format } from 'date-fns';

import { format } from 'date-fns';
import path from 'path';

const prisma = new PrismaClient();

class InvoiceService {
  private fontPath = path.join(process.cwd(), 'assets', 'fonts', 'NotoSansDevanagari-Regular.ttf');

  private registerFonts(doc: PDFKit.PDFDocument) {
    doc.registerFont('Devanagari', this.fontPath);
  }

  /**
   * Generates a professional PDF invoice, uploads to R2, and updates the order
   * @param orderId The UUID of the order
   */
  async generateAndSyncInvoice(orderId: string): Promise<string> {
    console.log(`📄 Generating Invoice for Order: ${orderId}...`);

    const order = await prisma.order.findUnique({
      where: { id: orderId },
      include: {
        user: true,
        product: true,
      },
    });

    if (!order) throw new Error('Order not found');

    // 1. Generate QR Code pointing to the public URL
    // We calculate the URL beforehand: public_url/invoices/orderId.pdf
    const fileName = `invoices/${order.id}.pdf`;
    const publicUrl = `${process.env.R2_PUBLIC_URL}/${fileName}`;
    
    const qrCodeDataUrl = await QRCode.toDataURL(publicUrl, {
      color: {
        dark: '#000000',
        light: '#FFFFFF',
      },
      width: 150,
    });

    // 2. Create PDF Document
    const doc = new PDFDocument({ margin: 50 });
    this.registerFonts(doc);
    const chunks: Buffer[] = [];

    doc.on('data', (chunk) => chunks.push(chunk));

    const pdfBuffer = await new Promise<Buffer>((resolve, reject) => {
      doc.on('end', () => resolve(Buffer.concat(chunks)));
      doc.on('error', reject);

      // --- HEADER ---
      doc.fillColor('#D4AF37').font('Devanagari').fontSize(24).text('राजकीय गोल्ड', { align: 'right' });
      doc.font('Helvetica-Bold').fontSize(16).text('ROYAL GOLD', { align: 'right' });
      doc.fillColor('#444444').font('Helvetica').fontSize(10).text('Official Tax Invoice | आधिकारिक कर चालान', { align: 'right' });
      doc.moveDown();

      doc.fillColor('#000000').font('Helvetica-Bold').fontSize(20).text('INVOICE / चालान', 50, 50);
      doc.font('Helvetica').fontSize(10).text(`Number / संख्या: ${order.invoiceNo || 'N/A'}`);
      doc.text(`Date / दिनांक: ${format(new Date(order.createdAt), 'dd MMMM yyyy')}`);
      doc.moveDown();

      // --- BILLING INFO ---
      doc.fontSize(12).text('Billed To:', 50, 150);
      doc.fontSize(10).text(order.user.name);
      doc.text(order.user.phone);
      doc.text(order.user.email || '');
      doc.moveDown();

      // --- TABLE HEADER ---
      const tableTop = 250;
      doc.font('Devanagari');
      this.generateTableRow(doc, tableTop, 'विवरण (Description)', 'विवरण (Qty)', 'वजन (Weight)', 'राशि (Amount)');
      this.generateHr(doc, tableTop + 20);
      doc.font('Helvetica');

      // --- TABLE ROW ---
      const itemPosition = tableTop + 30;
      this.generateTableRow(
        doc,
        itemPosition,
        order.product?.name || 'Gold Coin',
        order.quantity.toString(),
        `${order.weight}g`,
        `₹${order.amount.toFixed(2)}`
      );
      this.generateHr(doc, itemPosition + 20);

      // --- TOTALS ---
      const subtotalPosition = itemPosition + 50;
      this.generateTableRow(doc, subtotalPosition, '', '', 'Subtotal', `₹${order.amount.toFixed(2)}`);
      
      const gstPosition = subtotalPosition + 20;
      this.generateTableRow(doc, gstPosition, '', '', 'GST (3%)', `₹${order.gst.toFixed(2)}`);

      const totalPosition = gstPosition + 25;
      doc.font('Helvetica-Bold');
      this.generateTableRow(doc, totalPosition, '', '', 'Total Payable', `₹${order.total.toFixed(2)}`);
      doc.font('Helvetica');

      // --- QR CODE & FOOTER ---
      doc.image(qrCodeDataUrl, 50, 550, { width: 100 });
      doc.fontSize(8).text('Scan to verify authenticity of this document.', 50, 660);

      doc.fontSize(10).text(
        'Thank you for your business. Terms and conditions apply.',
        50,
        700,
        { align: 'center', width: 500 }
      );

      doc.end();
    });

    // 3. Upload to R2
    await r2Service.uploadFile(pdfBuffer, fileName, 'application/pdf');

    // 4. Update DB
    await prisma.order.update({
      where: { id: order.id },
      data: { invoiceUrl: publicUrl },
    });

    console.log(`✅ Invoice generated and synced: ${publicUrl}`);
    return publicUrl;
  }

  private generateTableRow(doc: PDFKit.PDFDocument, y: number, item: string, qty: string, weight: string, total: string) {
    doc.fontSize(10)
      .text(item, 50, y)
      .text(qty, 200, y, { width: 90, align: 'right' })
      .text(weight, 300, y, { width: 90, align: 'right' })
      .text(total, 400, y, { width: 90, align: 'right' });
  }

  private generateHr(doc: PDFKit.PDFDocument, y: number) {
    doc.strokeColor('#aaaaaa')
      .lineWidth(1)
      .moveTo(50, y)
      .lineTo(550, y)
      .stroke();
  }
}

export default new InvoiceService();
