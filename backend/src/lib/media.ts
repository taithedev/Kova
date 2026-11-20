import { S3Client, HeadObjectCommand, PutObjectCommand, GetObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { ApiError } from './errors';

const MAX_VIDEO_BYTES = 100 * 1024 * 1024;
let client: S3Client | undefined;
function config() {
  const { S3_ENDPOINT, S3_REGION, S3_BUCKET, S3_ACCESS_KEY_ID, S3_SECRET_ACCESS_KEY } = process.env;
  if (!S3_ENDPOINT || !S3_BUCKET || !S3_ACCESS_KEY_ID || !S3_SECRET_ACCESS_KEY)
    throw new ApiError(503, 'Private video storage is not configured');
  if (!S3_ENDPOINT.startsWith('https://')) throw new ApiError(503, 'HTTPS storage is required');
  client ??= new S3Client({
    region: S3_REGION || 'us-east-1', endpoint: S3_ENDPOINT, forcePathStyle: true,
    credentials: { accessKeyId: S3_ACCESS_KEY_ID, secretAccessKey: S3_SECRET_ACCESS_KEY }
  });
  return { client, bucket: S3_BUCKET };
}
function validateKey(key: string) {
  if (!/^videos\/[a-f0-9-]{36}\/[a-f0-9-]{36}\.(mp4|mov)$/.test(key))
    throw new ApiError(400, 'Invalid media key');
}
export async function signedUpload(key: string, mime: string) {
  validateKey(key);
  if (!['video/mp4', 'video/quicktime'].includes(mime))
    throw new ApiError(400, 'Only MP4 and MOV videos are supported');
  const { client, bucket } = config();
  const url = await getSignedUrl(client, new PutObjectCommand({ Bucket: bucket, Key: key, ContentType: mime }), { expiresIn: 600 });
  return { url, method: 'PUT', mime, expires_in_seconds: 600, max_bytes: MAX_VIDEO_BYTES };
}
export async function validatedUpload(key: string) {
  validateKey(key);
  const { client, bucket } = config();
  const obj = await client.send(new HeadObjectCommand({ Bucket: bucket, Key: key })).catch(() => {
    throw new ApiError(400, 'Video upload not found');
  });
  if (!obj.ContentLength || obj.ContentLength > MAX_VIDEO_BYTES) throw new ApiError(400, 'Video must be 1–100 MB');
  if (!['video/mp4', 'video/quicktime'].includes(obj.ContentType || '')) throw new ApiError(400, 'Unsupported video content type');
}
export async function signedRead(key: string): Promise<string> {
  validateKey(key);
  const { client, bucket } = config();
  return getSignedUrl(client, new GetObjectCommand({ Bucket: bucket, Key: key }), { expiresIn: 900 });
}
