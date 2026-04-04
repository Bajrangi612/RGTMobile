import { S3Client, PutObjectCommand, DeleteObjectCommand } from "@aws-sdk/client-s3";
import dotenv from "dotenv";

dotenv.config();

class R2Service {
  private s3Client: S3Client;
  private bucketName: string;
  private publicUrl: string;

  constructor() {
    this.s3Client = new S3Client({
      region: "auto",
      endpoint: process.env.R2_ENDPOINT!,
      credentials: {
        accessKeyId: process.env.R2_ACCESS_KEY_ID!,
        secretAccessKey: process.env.R2_SECRET_ACCESS_KEY!,
      },
    });
    this.bucketName = process.env.R2_BUCKET_NAME!;
    this.publicUrl = process.env.R2_PUBLIC_URL!;
  }

  /**
   * Upload a file to Cloudflare R2
   * @param fileBuffer The file content as a Buffer
   * @param fileName The destination path/name in the bucket
   * @param contentType The MIME type (e.g., image/jpeg)
   * @returns The public URL of the uploaded file
   */
  async uploadFile(fileBuffer: Buffer, fileName: string, contentType: string): Promise<string> {
    const command = new PutObjectCommand({
      Bucket: this.bucketName,
      Key: fileName,
      Body: fileBuffer,
      ContentType: contentType,
    });

    await this.s3Client.send(command);
    
    // Ensure public URL ends with a slash before appending fileName
    const baseUrl = this.publicUrl.endsWith('/') ? this.publicUrl : `${this.publicUrl}/`;
    return `${baseUrl}${fileName}`;
  }

  /**
   * Delete a file from Cloudflare R2
   * @param fileName The key of the file to delete
   */
  async deleteFile(fileName: string): Promise<void> {
    const command = new DeleteObjectCommand({
      Bucket: this.bucketName,
      Key: fileName,
    });

    await this.s3Client.send(command);
  }
}

export default new R2Service();
