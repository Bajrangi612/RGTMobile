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
      jsonStr = Buffer.from(jsonStr, 'base64').toString('utf8');
    }
    
    const serviceAccount = JSON.parse(jsonStr);

    // FIX: Handle double-escaped newlines in private_key (common in Docker/Env vars)
    if (serviceAccount.private_key) {
      serviceAccount.private_key = serviceAccount.private_key.replace(/\\n/g, '\n');
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
