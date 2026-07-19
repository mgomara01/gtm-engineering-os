'use client';
import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { hasSupabaseConfig } from '@/lib/env';
import { createClient } from '@/lib/supabase/client';

export function LoginForm() {
  const router = useRouter();
  const [email,setEmail]=useState('');
  const [password,setPassword]=useState('');
  const [error,setError]=useState('');
  const [loading,setLoading]=useState(false);
  async function submit(event: React.FormEvent) {
    event.preventDefault(); setError(''); setLoading(true);
    if (!hasSupabaseConfig) { document.cookie='gtm_demo_session=active; path=/; max-age=86400; samesite=lax'; router.push('/'); router.refresh(); return; }
    const supabase=createClient();
    const { error: signInError }=await supabase.auth.signInWithPassword({email,password});
    if(signInError){setError(signInError.message);setLoading(false);return;}
    router.push('/');router.refresh();
  }
  return <form onSubmit={submit}>
    <label htmlFor="email">Email</label><input id="email" className="input" type="email" value={email} onChange={e=>setEmail(e.target.value)} required={hasSupabaseConfig}/>
    <label htmlFor="password">Password</label><input id="password" className="input" type="password" value={password} onChange={e=>setPassword(e.target.value)} required={hasSupabaseConfig}/>
    {error&&<p className="error" role="alert">{error}</p>}
    {!hasSupabaseConfig&&<p className="notice">Demo mode is active because Supabase credentials are not configured. Any credentials will open the controlled demonstration workspace.</p>}
    <button className="btn button-reset full" disabled={loading}>{loading?'Signing in…':hasSupabaseConfig?'Sign in':'Enter demo workspace'}</button>
  </form>;
}
