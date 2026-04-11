import { Router, Request, Response } from 'express';
import { prisma } from '../lib/prisma';
import axios from 'axios';

const router = Router();

/**
 * Public Invoice Direct Download
 * This route is called when the user scans the QR code on the invoice or clicks the view link.
 */
router.get('/download-invoice/:orderId', async (req: Request, res: Response) => {
  try {
    const { orderId } = req.params;

    const order = await prisma.order.findUnique({
      where: { id: orderId },
      select: { invoiceUrl: true, invoiceNo: true }
    });

    if (!order || !order.invoiceUrl) {
      return res.status(404).send('<h1>Invoice Not Found</h1><p>The requested invoice does not exist or has not been generated yet.</p>');
    }

    // Proxy the R2 download to set Content-Disposition: attachment for direct download
    const response = await axios.get(order.invoiceUrl, { responseType: 'stream' });
    
    const fileName = `${order.invoiceNo?.replace(/\//g, '-') || orderId}.pdf`;
    
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename="${fileName}"`);
    
    response.data.pipe(res);
  } catch (error) {
    console.error('❌ Public Download Error:', error);
    res.status(500).send('<h1>Internal Server Error</h1><p>Could not process the download request.</p>');
  }
});

export default router;
