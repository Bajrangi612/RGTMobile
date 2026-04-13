import * as fs from 'fs';
import * as path from 'path';
import R2Service from '../src/services/R2Service';

async function uploadBanner() {
  try {
    const bannerPath = 'C:\\Users\\Administrator\\.gemini\\antigravity\\brain\\6f9384dd-26fb-44f8-b12f-f2d626740910\\royal_gold_branded_fintech_banner_v2_1776058978864.png';
    
    if (!fs.existsSync(bannerPath)) {
      throw new Error(`Banner file not found at ${bannerPath}`);
    }

    const fileBuffer = fs.readFileSync(bannerPath);
    const fileName = `notifications/royal_gold_banner_${Date.now()}.png`;
    
    console.log('🚀 Uploading branded banner to R2...');
    const publicUrl = await R2Service.uploadFile(fileBuffer, fileName, 'image/png');
    
    console.log(`✅ Upload successful!`);
    console.log(`🔗 Public URL: ${publicUrl}`);
    
    // Save the URL for reference in the next task
    fs.writeFileSync('scratch/BANNER_URL.txt', publicUrl);
  } catch (error) {
    console.error('❌ Upload failed:', error);
    process.exit(1);
  }
}

uploadBanner();
