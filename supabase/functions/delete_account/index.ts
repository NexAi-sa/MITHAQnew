import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  const { reason, feedback } = await req.json()
  
  // This needs Service Role key which is usually injected via environment variables in Supabase
  const supabaseAdmin = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    }
  )

  // Get user from auth header
  const authHeader = req.headers.get('Authorization')!
  const { data: { user }, error: authError } = await supabaseAdmin.auth.getUser(authHeader.replace('Bearer ', ''))

  if (authError || !user) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401 })
  }

  const userId = user.id

  // 1. Delete profiles (RLS might handle some, but we want full cleanup)
  await supabaseAdmin.from('profiles').delete().eq('owner_user_id', userId)

  // 2. Delete users_private
  await supabaseAdmin.from('users_private').delete().eq('id', userId)

  // 3. Delete user from auth.users (This is why we need Service Role)
  const { error: deleteError } = await supabaseAdmin.auth.admin.deleteUser(userId)

  if (deleteError) {
    return new Response(JSON.stringify({ error: deleteError.message }), { status: 500 })
  }

  return new Response(JSON.stringify({ success: true }), { 
    headers: { "Content-Type": "application/json" } 
  })
})
