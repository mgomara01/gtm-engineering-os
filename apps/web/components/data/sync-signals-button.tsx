'use client';
import {useState} from 'react';
import {useRouter} from 'next/navigation';
export function SyncSignalsButton(){
  const router=useRouter();
  const [status,setStatus]=useState<'idle'|'syncing'|'error'>('idle');
  async function sync(){
    setStatus('syncing');
    try{
      const res=await fetch('/api/signals/sync',{method:'POST'});
      if(!res.ok)throw new Error(String(res.status));
      setStatus('idle');
      router.refresh();
    }catch{
      setStatus('error');
    }
  }
  return <button className="btn" onClick={sync} disabled={status==='syncing'}>{status==='syncing'?'Syncing…':status==='error'?'Sync failed — retry':'Sync live sources'}</button>;
}
