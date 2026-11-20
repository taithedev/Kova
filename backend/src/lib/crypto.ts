import { randomBytes, scrypt as scryptCb, timingSafeEqual, createHash } from 'node:crypto';
import { promisify } from 'node:util';
const scrypt=promisify(scryptCb);
export async function hashPassword(password:string) {
 const salt=randomBytes(16).toString('hex');
 const key=(await scrypt(password,salt,64)) as Buffer;
 return `scrypt$${salt}$${key.toString('hex')}`;
}
export async function verifyPassword(password:string, saved:string) {
 const [algorithm,salt,hex]=saved.split('$');
 if(algorithm!=='scrypt'||!salt||!hex) return false;
 try { const stored=Buffer.from(hex,'hex'); const test=(await scrypt(password,salt,stored.length)) as Buffer; return stored.length===test.length && timingSafeEqual(stored,test); }
 catch { return false; }
}
export function createToken() { return randomBytes(32).toString('base64url'); }
export function tokenHash(token:string) { return createHash('sha256').update(token).digest('hex'); }
