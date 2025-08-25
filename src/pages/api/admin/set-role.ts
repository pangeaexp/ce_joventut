import type { NextApiRequest, NextApiResponse } from 'next'
import { createServerSupabase } from '../../../lib/supabaseClient'

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'POST') return res.status(405).end()
  const supabase = createServerSupabase()
  const { user_id, role } = req.body
  if (!['member','coach','admin'].includes(role)) return res.status(400).json({ error: 'invalid role' })
  const { data, error } = await supabase.from('profiles').update({ role }).eq('id', user_id).select('*')
  if (error) return res.status(400).json({ error: error.message })
  res.status(200).json(data?.[0])
}