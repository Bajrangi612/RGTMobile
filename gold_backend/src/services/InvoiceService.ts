import PDFDocument from 'pdfkit';
import QRCode from 'qrcode';
import { PrismaClient } from '@prisma/client';
import r2Service from './R2Service';
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

      // --- HEADER & LOGO ---
      doc.fillColor('#D4AF37').font('Devanagari').fontSize(24).text('राजकीय गोल्ड ट्रेडर', { align: 'left' });
      doc.font('Helvetica-Bold').fontSize(16).text('ROYAL GOLD TRADERS', { align: 'left' });
      doc.fillColor('#444444').font('Helvetica').fontSize(8).text('2nd Floor, B-19, P.C. Colony, Kankarbagh, Patna, Bihar 800020', { align: 'left' });
      doc.text('GSTIN: 10ADJPI8137N1ZE | PAN: ADJPI8137N | Phone: 9065415619', { align: 'left' });
      doc.moveDown();

      // --- INVOICE META ---
      doc.fillColor('#000000').font('Helvetica-Bold').fontSize(18).text('TAX INVOICE / कर चालान', 380, 50, { align: 'right' });
      doc.font('Helvetica').fontSize(9).text(`Invoice No: ${order.invoiceNo || 'N/A'}`, { align: 'right' });
      doc.text(`Date: ${format(new Date(order.createdAt), 'dd/MM/yyyy h:mm a')}`, { align: 'right' });
      doc.text(`State: Bihar (10)`, { align: 'right' });
      doc.moveDown(2);

      // --- BILLING INFO ---
      const billingTop = 130;
      doc.fontSize(11).font('Helvetica-Bold').text('Customer Details / ग्राहक विवरण:', 50, billingTop);
      doc.fontSize(10).font('Helvetica').text(`Name: ${order.user.name}`);
      doc.text(`Phone: ${order.user.phone}`);
      doc.text(`Address: ${order.user.address || 'Address Not Provided'}`);
      doc.text(`Place of Supply: Bihar`);
      doc.moveDown();

      // --- TABLE ---
      const tableTop = 220;
      doc.font('Helvetica-Bold').fontSize(10);
      this.generateTableRow(doc, tableTop, 'Item / Purity', 'Qty', 'Weight', 'Amount (INR)');
      this.generateHr(doc, tableTop + 15);
      
      doc.font('Helvetica').fontSize(10);
      const itemPosition = tableTop + 30;
      this.generateTableRow(
        doc,
        itemPosition,
        `${order.product?.name || 'Gold Coin'} (24 CT)`,
        order.quantity.toString(),
        `${order.weight}g`,
        `${order.amount.toFixed(2)}`
      );
      this.generateHr(doc, itemPosition + 20);

      // --- SUMMARY ---
      const summaryTop = itemPosition + 40;
      doc.font('Helvetica-Bold').text('Summary / सारांश', 350, summaryTop);
      this.generateHr(doc, summaryTop + 15);
      
      doc.font('Helvetica').fontSize(9);
      let currentY = summaryTop + 25;
      
      const rowHeight = 18;
      const drawSummaryRow = (label: string, value: string, isTotal = false) => {
        if (isTotal) doc.font('Helvetica-Bold').fontSize(10);
        doc.text(label, 350, currentY);
        doc.text(value, 450, currentY, { width: 90, align: 'right' });
        currentY += rowHeight;
        if (isTotal) doc.font('Helvetica').fontSize(9);
      };

      drawSummaryRow('Taxable Value:', `₹${order.amount.toFixed(2)}`);
      drawSummaryRow('CGST (1.5%):', `₹${(order.gst / 2).toFixed(2)}`);
      drawSummaryRow('SGST (1.5%):', `₹${(order.gst / 2).toFixed(2)}`);
      this.generateHr(doc, currentY);
      currentY += 10;
      drawSummaryRow('Total Amount:', `₹${order.total.toFixed(2)}`, true);

      // --- BANK DETAILS ---
      const bankTop = 450;
      doc.fontSize(10).font('Helvetica-Bold').text('Bank & Payment Details:', 50, bankTop);
      doc.fontSize(8).font('Helvetica');
      doc.text('A/C Name: ROYAL GOLD TRADERS');
      doc.text('A/C No: 00000045030556376');
      doc.text('Bank: SBI, PATNA MAIN BRANCH');
      doc.text('IFSC: SBIN0009005');
      doc.moveDown();

      // --- QR CODE & AUTHENTICITY ---
      const qrTop = 550;
      doc.image(qrCodeDataUrl, 50, qrTop, { width: 90 });
      doc.fontSize(8).font('Helvetica').text('SCAN TO VERIFY DOCUMENT', 50, qrTop + 95);
      doc.text('Powered by Obsidian Elite Technology', 50, qrTop + 105);

      // --- SIGNATURES ---
      doc.fontSize(10).font('Helvetica-Bold').text('Authorised Signatory', 400, qrTop + 40);
      doc.fontSize(8).font('Helvetica').text('for ROYAL GOLD TRADERS', 400, qrTop + 55);
      doc.moveDown(4);
      doc.text('__________________________', 400, qrTop + 80);
      
      doc.fontSize(7).fillColor('#888888').text(
        'This is a computer-generated document and does not require a physical signature for validity under the IT Act 2000.',
        50,
        750,
        { align: 'center', width: 500 }
      );

      doc.end();

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
