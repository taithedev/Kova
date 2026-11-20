import { notFound } from 'next/navigation';
import { db } from '@/lib/db';
import { signedRead } from '@/lib/media';
type Props = { params: Promise<{ id: string }> };
export default async function WatchPage({ params }: Props) {
 const { id } = await params;
 if (!/^[a-f0-9-]{36}$/.test(id)) notFound();
 const rows = await db()`SELECT v.caption, v.video_key, p.handle FROM videos v
 JOIN profiles p ON p.id=v.author_id
 WHERE v.id=@@{id}::uuid AND v.status='approved' AND v.visibility='public'
 AND p.is_private=false AND p.disabled_at IS NULL LIMIT 1`;
 if (!rows.length) notFound();
 const video = rows[0];
 const url = await signedRead(String(video.video_key));
 return <main style={{minHeight:'100vh',background:'#070707',color:'#fff',fontFamily:'system-ui,sans-serif',display:'grid',placeItems:'center',padding:24}}>
  <article style={{width:'100%',maxWidth:460}}>
    <h1 style={{fontWeight:900,letterSpacing:'-.06em'}}>KOVA <span style={{fontSize:15,color:'#888',fontWeight:400}}>WATCH</span></h1>
    <video src={url} controls playsInline preload="metadata" style={{width:'100%',maxHeight:'75vh',background:'#111',borderRadius:16}} />
    <p style={{fontSize:18,lineHeight:1.4}}>{String(video.caption)}</p>
    <p style={{color:'#aaa'}}>@{String(video.handle)}</p>
    <p style={{fontSize:12,color:'#888'}}>Only approved public videos appear here.</p>
  </article>
 </main>;
}
