import * as admin from 'firebase-admin';
import path from 'path';
import fs from 'fs';

// Look for service account in Environment Variables first (best for CI/CD like Coolify)
// Otherwise, fallback to local file
const serviceAccountEnv = process.env.FIREBASE_CONFIG_B64;
const serviceAccountPath = path.join(process.cwd(), 'firebase-service-account.json');
if (fs.existsSync(serviceAccountPath)) {
  try {
    // Firebase Admin SDK natively supports reading the file path and handling all PEM parsing internally
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccountPath)
    });
    console.log('🔥 [FIREBASE] Admin SDK initialized successfully via local service-account.json');
  } catch (error) {
    console.error('❌ [FIREBASE] Failed to initialize Firebase from local file:', error);
  }
} else if (serviceAccountEnv) {
  // Fallback to Env Var if file is totally missing and they set the var
  try {
    let jsonStr = serviceAccountEnv.trim();
    if (!jsonStr.startsWith('{')) {
      console.log('📦 [FIREBASE] Decoding Base64 service account as fallback...');
      const cleanB64 = serviceAccountEnv.replace(/[\s\n\r]/g, '');
      jsonStr = Buffer.from(cleanB64, 'base64').toString('utf8');
    }
    
    // Safety check for common environment variable corruptions
    const sanitizedJson = jsonStr.replace(/[\x00-\x09\x0B-\x1F\x7F-\x9F]/g, "");
    const serviceAccount = JSON.parse(sanitizedJson);

    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
    console.log('🔥 [FIREBASE] Admin SDK initialized successfully via Fallback Env Var');
  } catch (error) {
    console.error('❌ [FIREBASE] Failed to initialize Firebase from fallback env var:', error);
  }
} else {
  console.warn('⚠️ [FIREBASE] Service account NOT found (no file or env var). Push notifications will be mocked.');
}

export default admin;
