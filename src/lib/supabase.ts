/**
 * Clientes Supabase
 *
 * IMPORTANTE:
 * - supabase: Cliente publico com ANON_KEY (respeita RLS)
 *   Usar em: Rotas publicas de clientes, operacoes com RLS
 *
 * - supabaseAdmin: Cliente admin com SERVICE_ROLE_KEY (bypassa RLS)
 *   Usar em: Cron jobs, operacoes administrativas protegidas
 */

import { createClient } from '@supabase/supabase-js'

const FALLBACK_SUPABASE_URL = 'https://cyhlhhuqbtrldycufacv.supabase.co'
const FALLBACK_SUPABASE_ANON_KEY =
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN5aGxoaHVxYnRybGR5Y3VmYWN2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMxNTk4MTQsImV4cCI6MjA4ODczNTgxNH0.XAIQOeDJnJNT1C8OtvBVbghYjkbZ4iyMV-AW5i1doIk'

export const supabaseUrl =
  process.env.NEXT_PUBLIC_SUPABASE_URL || FALLBACK_SUPABASE_URL

export const supabaseAnonKey =
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || FALLBACK_SUPABASE_ANON_KEY

/**
 * Cliente publico - Respeita Row Level Security (RLS)
 * Use este para operacoes normais da API
 * IMPORTANTE: Agendamentos usam este cliente (RLS deve permitir INSERT/UPDATE)
 */
export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    persistSession: false,
    autoRefreshToken: false
  }
})

/**
 * Cliente admin - Bypassa Row Level Security (RLS)
 * ATENCAO: Use apenas em rotas protegidas (cron, admin)
 * Nunca exponha este cliente em rotas publicas!
 */
export const supabaseAdmin = createClient(
  supabaseUrl,
  process.env.SUPABASE_SERVICE_ROLE_KEY || supabaseAnonKey
)

export function getAdminClient() {
  if (!process.env.SUPABASE_SERVICE_ROLE_KEY) {
    throw new Error(
      'Missing env.SUPABASE_SERVICE_ROLE_KEY. Configure this variable in Vercel Project Settings > Environment Variables.'
    )
  }

  return createClient(supabaseUrl, process.env.SUPABASE_SERVICE_ROLE_KEY)
}
