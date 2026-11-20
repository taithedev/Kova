import type { ReactNode } from 'react';
export const metadata = { title: 'Kova API', robots: { index: false, follow: false } };
export default function Layout({ children }: { children: ReactNode }) { return <html lang="en"><body style={{margin:0,background:'#0b0b11',color:'#fff',fontFamily:'system-ui'}}>{children}</body></html>; }
