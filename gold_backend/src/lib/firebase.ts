import * as admin from 'firebase-admin';
import path from 'path';
import fs from 'fs';

// Look for service account in Environment Variables first (best for CI/CD like Coolify)
// Otherwise, fallback to local file
const serviceAccountEnv = process.env.FIREBASE_SERVICE_ACCOUNT;
const serviceAccountPath = path.join(process.cwd(), 'firebase-service-account.json');

if (serviceAccountEnv) {
  try {
    const serviceAccount = JSON.parse(serviceAccountEnv);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
    console.log('🔥 [FIREBASE] Admin SDK initialized successfully via Environment Variable');
  } catch (error) {
    console.error('❌ [FIREBASE] Failed to parse FIREBASE_SERVICE_ACCOUNT env var:', error);
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
