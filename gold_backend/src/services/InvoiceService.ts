import PDFDocument from 'pdfkit';
import QRCode from 'qrcode';
import { PrismaClient } from '@prisma/client';
import r2Service from './R2Service';
import { format } from 'date-fns';
import path from 'path';

const prisma = new PrismaClient();

class InvoiceService {
  private fontPath = path.join(process.cwd(), 'assets', 'fonts', 'NotoSansDevanagari-Regular.ttf');

  private numberToWords(num: number): string {
    const single_digit = ['', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine'];
    const double_digit = ['Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'];
    const below_hundred = ['Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'];
    
    if (num === 0) return 'Zero';
    
    const translate = (n: number): string => {
        let word = "";
        if (n < 10) {
            word = single_digit[n] + ' ';
        } else if (n < 20) {
            word = double_digit[n - 10] + ' ';
        } else if (n < 100) {
            let rem = translate(n % 10);
            word = below_hundred[Math.floor(n / 10) - 2] + ' ' + rem;
        } else if (n < 1000) {
            word = single_digit[Math.floor(n / 100)] + ' Hundred ' + translate(n % 100);
        } else if (n < 100000) {
            word = translate(Math.floor(n / 1000)).trim() + ' Thousand ' + translate(n % 1000);
        } else if (n < 10000000) {
            word = translate(Math.floor(n / 100000)).trim() + ' Lakh ' + translate(n % 100000);
        } else {
            word = translate(Math.floor(n / 10000000)).trim() + ' Crore ' + translate(n % 10000000);
        }
        return word;
    };
    
    return translate(Math.floor(num)).trim() + ' Rupees Only';
  }

  private registerFonts(doc: PDFKit.PDFDocument) {
    // We'll keep the font registration in case it's needed elsewhere, but use standard fonts for headers.
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

    // 1. Generate QR Code pointing directly to Cloudflare R2
    const fileName = `invoices/${order.invoiceNo?.replace(/\//g, '-') || order.id}.pdf`;
    const r2BaseUrl = process.env.R2_PUBLIC_URL?.endsWith('/') ? process.env.R2_PUBLIC_URL : `${process.env.R2_PUBLIC_URL}/`;
    const r2Url = `${r2BaseUrl}${fileName}`;
    
    const qrCodeDataUrl = await QRCode.toDataURL(r2Url, {
      margin: 1,
      width: 150,
      color: {
        dark: '#000000',
        light: '#FFFFFF',
      },
    });

    // 2. Create PDF Document
    const doc = new PDFDocument({ margin: 50 });
    const chunks: Buffer[] = [];

    doc.on('data', (chunk) => chunks.push(chunk));

    const pdfBuffer = await new Promise<Buffer>((resolve, reject) => {
      doc.on('end', () => resolve(Buffer.concat(chunks)));
      doc.on('error', reject);

      // --- HEADER & LOGO ---
      doc.fillColor('#D4AF37').font('Helvetica-Bold').fontSize(24).text('ROYAL GOLD TRADERS', { align: 'left' });
      doc.moveDown(0.2);
      doc.fillColor('#444444').font('Helvetica').fontSize(9).text('2nd Floor, B-19, P.C. Colony, Kankarbagh, Patna, Bihar 800020', { align: 'left' });
      doc.text('GSTIN: 10ADJPI8137N1ZE | PAN: ADJPI8137N | Phone: 9065415619', { align: 'left' });
      doc.moveDown();

      // --- INVOICE META ---
      doc.fillColor('#000000').font('Helvetica-Bold').fontSize(18).text('TAX INVOICE', 380, 50, { align: 'right' });
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
        `${Number(order.amount).toFixed(2)}`
      );
      this.generateHr(doc, itemPosition + 20);

      // --- SUMMARY ---
      const summaryTop = itemPosition + 40;
      doc.font('Helvetica-Bold').text('Summary', 350, summaryTop);
      this.generateHr(doc, summaryTop + 15);
      
      doc.font('Helvetica').fontSize(9);
      let currentY = summaryTop + 25;
      
      const rowHeight = 18;
      const drawSummaryRow = (label: string, value: string, isTotal = false) => {
        if (isTotal) doc.font('Helvetica-Bold').fontSize(10);
        doc.text(label, 350, currentY);
        doc.text(value, 460, currentY, { width: 90, align: 'right' });
        currentY += rowHeight;
        if (isTotal) doc.font('Helvetica').fontSize(9);
      };

      drawSummaryRow('Taxable Value:', `₹${Number(order.amount).toFixed(2)}`);
      drawSummaryRow('CGST (1.5%):', `₹${(Number(order.gst) / 2).toFixed(2)}`);
      drawSummaryRow('SGST (1.5%):', `₹${(Number(order.gst) / 2).toFixed(2)}`);
      this.generateHr(doc, currentY);
      currentY += 10;
      drawSummaryRow('Total Amount:', `₹${Number(order.total).toFixed(2)}`, true);
      
      currentY += 15;
      doc.font('Helvetica-Bold').fontSize(9).text('Amount Chargeable (in words):', 50, currentY);
      currentY += 12;
      doc.font('Helvetica-Oblique').fontSize(9).text(this.numberToWords(Number(order.total)), 50, currentY, { width: 500, align: 'left' });


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
    const fileName = `invoices/${order.invoiceNo?.replace(/\//g, '-') || order.id}.pdf`;
    await r2Service.uploadFile(pdfBuffer, fileName, 'application/pdf');

    // 4. Update DB - Store the direct Cloudflare R2 URL
    await prisma.order.update({
      where: { id: order.id },
      data: { invoiceUrl: r2Url },
    });

    console.log(`✅ Invoice generated and uploaded to R2: ${r2Url}`);
    return r2Url;
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
