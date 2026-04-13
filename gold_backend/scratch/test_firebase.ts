import * as fs from 'fs';
import * as path from 'path';

// Simulation of the firebase.ts logic
function testFirebaseInit(b64String: string) {
    console.log('--- Starting Test ---');
    try {
        let jsonStr = b64String.trim();
        
        if (!jsonStr.startsWith('{')) {
            console.log('📦 Decoding Base64...');
            jsonStr = Buffer.from(jsonStr, 'base64').toString('utf8');
        }

        console.log('🔍 First 50 chars of decoded string:', jsonStr.substring(0, 50));
        
        const serviceAccount = JSON.parse(jsonStr);
        console.log('✅ JSON.parse successful!');

        if (serviceAccount.private_key) {
            const hasEscapedN = serviceAccount.private_key.includes('\\n');
            console.log('🔍 private_key has literal \\n:', hasEscapedN);
            
            // Apply the fix
            serviceAccount.private_key = serviceAccount.private_key.replace(/\\n/g, '\n');
            
            const hasRealNewline = serviceAccount.private_key.includes('\n');
            console.log('✅ private_key has actual newlines after fix:', hasRealNewline);
        }

        return true;
    } catch (error) {
        console.error('❌ Test FAILED:', error.message);
        if (error instanceof SyntaxError) {
             // Find position in message
             const posMatch = error.message.match(/at position (\d+)/);
             if (posMatch) {
                 const pos = parseInt(posMatch[1]);
                 console.log('Context around error pos:', jsonStr.substring(pos - 10, pos + 10));
             }
        }
        return false;
    }
}

// Generate the B64 string exactly as I provided it
const originalFile = fs.readFileSync('firebase-service-account.json', 'utf8');
const perfectB64 = Buffer.from(JSON.stringify(JSON.parse(originalFile))).toString('base64');

console.log('Testing with perfect Base64 string...');
testFirebaseInit(perfectB64);
