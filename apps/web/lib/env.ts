export const hasSupabaseConfig = Boolean(
  process.env.NEXT_PUBLIC_SUPABASE_URL && process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY,
);

export const appEnvironment = process.env.NEXT_PUBLIC_APP_ENV ?? 'staging';
