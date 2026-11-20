import { ApiError } from './errors';
// Don't retain birthdates. Store a coarse age band, and re-check age during account creation.
export function ageFromISO(input: string, now = new Date()): number {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(input)) throw new ApiError(400, 'Invalid birth date');
  const birth = new Date(input + 'T00:00:00.000Z');
  if (Number.isNaN(birth.valueOf()) || birth.toISOString().slice(0, 10) !== input) throw new ApiError(400, 'Invalid birth date');
  const yy=now.getUTCFullYear()-birth.getUTCFullYear();
  const before=now.getUTCMonth()<birth.getUTCMonth() || (now.getUTCMonth()===birth.getUTCMonth() && now.getUTCDate()<birth.getUTCDate());
  const age=yy-(before?1:0);
  if (age<0 || age>120) throw new ApiError(400,'Invalid birth date');
  return age;
}
export function ageBand(age:number): '13_15' | '16_17' | '18_plus' {
  if (age<13) throw new ApiError(403,'Kova social accounts are currently available for ages 13+. A separate parent-consent junior product is not yet available.');
  if (age<16) return '13_15';
  if (age<18) return '16_17';
  return '18_plus';
}
