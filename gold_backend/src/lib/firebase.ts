import * as admin from 'firebase-admin';
import path from 'path';
import fs from 'fs';

// Look for service account in Environment Variables first (best for CI/CD like Coolify)
// Otherwise, fallback to local file
const serviceAccountEnv = process.env.FIREBASE_CONFIG_B64;
const serviceAccountPath = path.join(process.cwd(), 'firebase-service-account.json');

if (serviceAccountEnv) {
  try {
    let jsonStr = serviceAccountEnv.trim();

    // Check if it's base64 encoded (doesn't start with '{')
    if (!jsonStr.startsWith('{')) {
      console.log('📦 [FIREBASE] Decoding Base64 service account...');
      // Remove any hidden whitespace or control characters from the B64 string itself
      const cleanB64 = serviceAccountEnv.replace(/[\s\n\r]/g, '');
      jsonStr = Buffer.from(cleanB64, 'base64').toString('utf8');
    }
    
    // Final safety check: remove any real control characters except for real newlines
    const sanitizedJson = jsonStr.replace(/[\x00-\x09\x0B-\x1F\x7F-\x9F]/g, "");
    
    const serviceAccount = JSON.parse(sanitizedJson);

    // FIX: PEM formatting is extremely sensitive
    if (serviceAccount.private_key) {
      serviceAccount.private_key = serviceAccount.private_key
        .replace(/\\n/g, '\n') // Convert escaped \n to real newlines
        .replace(/\r/g, '')     // Remove carriage returns
        .trim();                 // Remove surrounding whitespace

      // Re-ensure headers are on their own lines
      if (!serviceAccount.private_key.includes('\n') && serviceAccount.private_key.includes('-----')) {
         serviceAccount.private_key = serviceAccount.private_key
           .replace('-----BEGIN PRIVATE KEY-----', '-----BEGIN PRIVATE KEY-----\n')
           .replace('-----END PRIVATE KEY-----', '\n-----END PRIVATE KEY-----');
      }
    }

    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
    console.log('🔥 [FIREBASE] Admin SDK initialized successfully via Environment Variable');
  } catch (error) {
    console.error('❌ [FIREBASE] Failed to initialize Firebase from env var:', error);
  }
} else if (fs.existsSync(serviceAccountPath)) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccountPath)
  });
  console.log('🔥 [FIREBASE] Admin SDK initialized successfully via service-account.json');
} else {
  console.warn('⚠️ [FIREBASE] Service account NOT found (no env var or file). Push notifications will be mocked.');
}

export default admin;
