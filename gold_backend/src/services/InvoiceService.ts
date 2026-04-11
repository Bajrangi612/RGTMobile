import PDFDocument from 'pdfkit';
import QRCode from 'qrcode';
import { PrismaClient } from '@prisma/client';
import r2Service from './R2Service';
import { format } from 'date-fns';
import path from 'path';

const prisma = new PrismaClient();

class InvoiceService {
  private fontRegular = path.join(process.cwd(), 'assets', 'fonts', 'NotoSansDevanagari-Regular.ttf');
  private logoRG = path.join(process.cwd(), 'assets', 'images', 'Royal_Gold_Traders.webp');
  private logoBIS = path.join(process.cwd(), 'assets', 'images', 'BIS.png');
  private logoISO = path.join(process.cwd(), 'assets', 'images', 'ISO.webp');
  private logoStamp = path.join(process.cwd(), 'assets', 'images', 'stamps_logo.png');

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

  /**
   * Generates a high-fidelity PDF invoice
   */
  async generateAndSyncInvoice(orderId: string): Promise<string> {
    const order = await prisma.order.findUnique({
      where: { id: orderId },
      include: { user: true, product: true },
    });

    if (!order) throw new Error('Order not found');

    // Idempotency: Return existing URL if already generated
    if (order.invoiceUrl) {
      console.log(`♻️ Invoice already exists for Order ${orderId}: ${order.invoiceUrl}`);
      return order.invoiceUrl;
    }

    console.log(`📄 Generating High-Fidelity Invoice for Order: ${orderId}...`);

    const fileName = `invoices/${order.invoiceNo?.replace(/\//g, '-') || order.id}.pdf`;
    const r2BaseUrl = process.env.R2_PUBLIC_URL?.endsWith('/') ? process.env.R2_PUBLIC_URL : `${process.env.R2_PUBLIC_URL}/`;
    const r2Url = `${r2BaseUrl}${fileName}`;
    
    const qrCodeDataUrl = await QRCode.toDataURL(r2Url, { margin: 1, width: 100 });

    const doc = new PDFDocument({ margin: 30, size: 'A4' });
    const chunks: Buffer[] = [];
    doc.on('data', (chunk) => chunks.push(chunk));

    const pdfBuffer = await new Promise<Buffer>((resolve, reject) => {
      doc.on('end', () => resolve(Buffer.concat(chunks)));
      doc.on('error', reject);

      // Register Font
      doc.registerFont('Noto', this.fontRegular);
      const headerColor = '#000000';
      const secondaryColor = '#555555';
      const accentColor = '#D4AF37';

      // --- LOGO & HEADER ---
      try {
        doc.image(this.logoRG, 460, 30, { width: 100 });
        doc.image(this.logoBIS, 410, 30, { width: 40 });
        doc.image(this.logoISO, 560, 30, { width: 40 }); // Outside margin? adjust
      } catch (e) {}

      // Left Header Content
      doc.fillColor(headerColor).font('Noto').fontSize(26).text('ROYAL GOLD', 30, 30);
      doc.text('TRADERS', 30, 60);

      doc.fontSize(8);
      let topMetaY = 100;
      const drawHeaderField = (label: string, value: string) => {
        doc.font('Noto').text(`${label} : `, 30, topMetaY, { continued: true });
        doc.font('Noto').text(value);
        topMetaY += 12;
      };

      drawHeaderField('State / राज्य', 'BIHAR');
      drawHeaderField('State Code', '10');
      drawHeaderField('GSTIN / जीएसटी आईएन', '10ADJPI8137N1ZE');
      drawHeaderField('Address', '2ND FLOOR, B-19, P.C. COLONY,');
      drawHeaderField('', '5 STAR LOVIYA NAGAR PARK, KANKARBAGH,');
      drawHeaderField('', 'PATNA, BIHAR 800020.');
      drawHeaderField('Phone', '9065415619');

      // Right Header Meta
      doc.fontSize(8);
      doc.text(`Bill Detail / बिल की जानकारी : 5191044315`, 400, 100, { align: 'right' });
      doc.text(`PAN / पैन सं : ADJPI8137N`, 400, 112, { align: 'right' });
      doc.text(`Bill No. / बिल सं : ${order.invoiceNo || 'N/A'}`, 400, 124, { align: 'right' });
      doc.text(`Bill Date / बिल तिथि : ${format(new Date(order.createdAt), 'dd/MM/yyyy h:mm a')}`, 400, 136, { align: 'right' });
      const deliveryDate = order.deliveryDate ? format(new Date(order.deliveryDate), 'dd/MM/yyyy') : 'N/A';
      doc.text(`Due Date / अतिंम तिथि : ${deliveryDate}`, 400, 148, { align: 'right' });

      // --- CUSTOMER SECTION ---
      doc.fontSize(9).font('Noto').fillColor(accentColor).text('● CUSTOMER TRANSACTIONS', 30, 200);
      doc.fontSize(6).fillColor(secondaryColor).text('- ORIGINAL FOR RECIPIENT', 34, 210);
      doc.rect(30, 220, 535, 90).stroke('#EEEEEE');

      let custY = 225;
      const drawCustField = (label: string, value: string) => {
        doc.fontSize(8).fillColor(headerColor).font('Noto').text(`${label} : `, 40, custY, { continued: true });
        doc.font('Noto').text(value);
        custY += 12;
      };

      drawCustField('Name / नाम', order.user.name);
      drawCustField('Mobile / मोबाइल', order.user.phone);
      drawCustField('Address / पता', order.user.address || 'Bihar');
      drawCustField('Place of Supply / आपूर्ति स्थान', 'BIHAR');

      // Right Customer Info
      doc.image(qrCodeDataUrl, 460, 225, { width: 70 });

      // --- MAIN DATA TABLE ---
      const tableTop = 320;
      doc.rect(30, tableTop, 535, 20).fill(accentColor);
      doc.fontSize(8).fillColor('#FFFFFF').font('Noto');
      
      const cols = [30, 60, 120, 280, 310, 350, 390, 430, 480, 520];
      const colLabels = ['Sl.No.', 'HSN Code', 'Item Description / Purity', 'Qty', 'Gross Weight', 'Stones/Other Material', 'Net Weight', 'Metal Value', 'VA(M) %', 'Gross Amount'];
      
      for(let i=0; i<cols.length; i++) {
        doc.text(colLabels[i], cols[i] + 5, tableTop + 5, { width: (i<cols.length-1 ? cols[i+1]-cols[i]-5 : 565-cols[i]-5), align: 'center' });
      }

      // Row Data
      const rowY = tableTop + 25;
      doc.fillColor('#000000');
      const vaPercent = order.product?.makingCharges ? (Number(order.product.makingCharges) / Number(order.amount) * 100).toFixed(2) : '5.00';
      
      const rowData = [
        '1', '711319', `${order.product?.name || 'Gold Coin'} (24 CT)`, order.quantity.toString(), 
        `${order.weight}g`, '0.000 / 0.00', `${order.weight}g`, Number(order.amount).toFixed(2), 
        `${vaPercent}%`, Number(order.amount).toFixed(2)
      ];

      for(let i=0; i<cols.length; i++) {
        doc.text(rowData[i], cols[i] + 5, rowY, { width: (i<cols.length-1 ? cols[i+1]-cols[i]-5 : 565-cols[i]-5), align: 'center' });
      }

      // Table Border
      doc.rect(30, tableTop, 535, 45).stroke('#EEEEEE');
      doc.font('Noto').text('Total', 35, rowY + 15);
      doc.text(Number(order.amount).toFixed(2), 520, rowY + 15, { width: 40, align: 'center' });

      // --- SUMMARY TABLES ---
      const summaryY = 400;
      // Invoice Summary
      doc.rect(40, summaryY, 140, 75).stroke('#EEEEEE');
      doc.fontSize(7).font('Noto').text('INVOICE SUMMARY', 40, summaryY - 8, { align: 'center', width: 140 });
      let sY = summaryY + 5;
      const drawSumRow = (l: string, v: string, bold=false) => {
        doc.font(bold ? 'Noto' : 'Noto').text(l, 45, sY);
        doc.text(v, 110, sY, { width: 65, align: 'right' });
        sY += 12;
      };
      drawSumRow('Gross Amount', Number(order.amount).toFixed(2));
      drawSumRow('Taxable Amount', Number(order.amount).toFixed(2));
      drawSumRow('CGST 1.50%', (Number(order.gst)/2).toFixed(2));
      drawSumRow('SGST 1.50%', (Number(order.gst)/2).toFixed(2));
      drawSumRow('Invoice Total', Number(order.total).toFixed(2), true);

      // Settlement Summary
      const settX = 200;
      doc.rect(settX, summaryY, 140, 45).stroke('#EEEEEE');
      doc.text('SETTLEMENT SUMMARY', settX, summaryY - 8, { align: 'center', width: 140 });
      let setY = summaryY + 5;
      doc.text('Invoice Total', settX + 5, setY); doc.text(Number(order.total).toFixed(2), settX+80, setY, { width: 50, align: 'right' });
      setY += 12;
      doc.fillColor('#0055AA').text('Net Amount', settX + 5, setY); doc.text(Number(order.total).toFixed(2), settX+80, setY, { width: 50, align: 'right' });
      setY += 12;
      doc.fillColor('#000000').text('Paid Amount', settX + 5, setY); doc.text(Number(order.total).toFixed(2), settX+80, setY, { width: 50, align: 'right' });

      // Mode of Payment
      const payX = 360;
      doc.rect(payX, summaryY, 200, 35).stroke('#EEEEEE');
      doc.text('MODE OF PAYMENT', payX, summaryY - 8, { align: 'center', width: 200 });
      doc.text('ROUND OFF', payX + 5, summaryY + 5); doc.text('0.00', payX + 130, summaryY + 5, { width: 60, align: 'right' });
      doc.text('ONLINE', payX + 5, summaryY + 17); doc.text(Number(order.total).toFixed(2), payX + 130, summaryY + 17, { width: 60, align: 'right' });

      // Amount in words
      doc.fontSize(8).fillColor(secondaryColor).text(`Amount in words (शब्दों में राशि): ${this.numberToWords(Number(order.total))}`, 40, 490);

      // --- BANK DETAILS ---
      const bankY = 530;
      doc.rect(30, bankY, 300, 60).fill('#F9F9F9').stroke('#EEEEEE');
      doc.fillColor(headerColor).fontSize(9).text('BANK & PAYMENT DETAILS / बैंक और भुगतान विवरण', 35, bankY + 5);
      doc.fontSize(7);
      doc.text('Account Name  : ROYAL GOLD TRADERS', 35, bankY + 20);
      doc.text('Account No.   : 00000045030556376', 35, bankY + 30);
      doc.text('MICR Code     : 800002029', 35, bankY + 40);
      
      doc.text('Bank & Branch : SBI, PATNA MAIN BRANCH', 160, bankY + 20);
      doc.text('IFSC Code     : SBIN0009005', 160, bankY + 30);
      doc.text('GSTIN         : 10ADJPI8137N1ZE', 160, bankY + 40);

      // --- SIGNATURE & STAMP ---
      try {
        doc.image(this.logoStamp, 100, 620, { width: 100 });
        doc.fillColor('#AA0000').fontSize(10).font('Helvetica-Bold').text('ITEM BOOKED', 110, 640, { width: 80, align: 'center' });
        doc.fontSize(8).text('DELIVER IN 15 DAYS', 110, 655, { width: 80, align: 'center' });
      } catch (e) {}

      doc.fillColor(headerColor).font('Noto').fontSize(8).text('Customer Signature', 40, 720);
      doc.text('ग्राहक के हस्ताक्षर', 40, 730);

      doc.fontSize(8).text(`Authorised Signatory`, 420, 720, { align: 'right' });
      doc.font('Noto').text(`for ROYAL GOLD TRADERS`, 420, 730, { align: 'right' });

      doc.fontSize(6).fillColor(secondaryColor).text('This is a computer-generated document and does not require a physical signature for validity under the IT Act 2000.', 30, 800, { align: 'center', width: 535 });

      doc.end();
    });

    // Upload to R2
    await r2Service.uploadFile(pdfBuffer, fileName, 'application/pdf');

    // Update DB
    await prisma.order.update({
      where: { id: order.id },
      data: { invoiceUrl: r2Url },
    });

    return r2Url;
  }

  private generateTableRow(doc: PDFKit.PDFDocument, y: number, item: string, qty: string, weight: string, total: string) {
    // Legacy method, unused now in h-f layout
  }

  private generateHr(doc: PDFKit.PDFDocument, y: number) {
    // Legacy method, unused now in h-f layout
  }
}

export default new InvoiceService();
