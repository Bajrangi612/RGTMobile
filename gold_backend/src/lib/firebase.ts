import * as admin from 'firebase-admin';
import path from 'path';
import fs from 'fs';

// Look for service account in the root directory
const serviceAccountPath = path.join(process.cwd(), 'firebase-service-account.json');

if (fs.existsSync(serviceAccountPath)) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccountPath)
  });
  console.log('🔥 [FIREBASE] Admin SDK initialized successfully');
} else {
  console.warn('⚠️ [FIREBASE] Service account file not found. Push notifications will be mocked.');
}

export default admin;
