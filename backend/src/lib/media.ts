import { S3Client, HeadObjectCommand, PutObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { ApiError } from './errors';
const MAX_VIDEO_BYTES=100*1024*1024;
let client:S3Client|undefined;
function config() {
 const {S3_ENDPOINT,S3_REGION,S3_BUCKET,S3_ACCESS_KEY_ID,S3_SECRET_ACCESS_KEY,MEDIA_PUBLIC_URL}=process.env;
 if(!S3_ENDPOINT||!S3_BUCKET||!S3_ACCESS_KEY_ID||!S3_SECRET_ACCESS_KEY||!MEDIA_PUBLIC_URL) throw new ApiError(503,'Video uploads are not configured');
 if(!MEDIA_PUBLIC_URL.startsWith('https://')) throw new ApiError(503,'MEDIA_PUBLIC_URL must be HTTPS');
 client??=new S3Client({region:S3_REGION||'auto',endpoint:S3_ENDPOINT,forcePathStyle:true,credentials:{accessKeyId:S3_ACCESS_KEY_ID,secretAccessKey:S3_SECRET_ACCESS_KEY}});
 return {client,bucket:S3_BUCKET,base:MEDIA_PUBLIC_URL.replace(/\/$/,'')};
}
export async function signedUpload(key:string,mime:string) {
 if(!['video/mp4','video/quicktime'].includes(mime)) throw new ApiError(400,'Only MP4 or MOV videos supported');
 const {client,bucket}=config();
 const url=await getSignedUrl(client,new PutObjectCommand({Bucket:bucket,Key:key,ContentType:mime}),{expiresIn:600});
 return {url, method:'PUT', mime, expires_in_seconds:600, max_bytes:MAX_VIDEO_BYTES};
}
export async function validatedUpload(key:string) {
 const {client,bucket,base}=config();
 const obj=await client.send(new HeadObjectCommand({Bucket:bucket,Key:key})).catch(()=>{throw new ApiError(400,'Video upload not found')});
 if(!obj.ContentLength||obj.ContentLength>MAX_VIDEO_BYTES) throw new ApiError(400,'Video must be 1–100 MB');
 if(!['video/mp4','video/quicktime'].includes(obj.ContentType||'')) throw new ApiError(400,'Unsupported uploaded file');
 return `${base}/${key.split('/').map(encodeURIComponent).join('/')}`;
}
