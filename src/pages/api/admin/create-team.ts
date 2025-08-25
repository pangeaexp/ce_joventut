import type { NextApiRequest, NextApiResponse } from 'next'
import { createServerSupabase } from '../../../lib/supabaseClient'

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'POST') return res.status(405).end()
  const supabase = createServerSupabase()
  const { name, description, coach_id } = req.body
  const { data, error } = await supabase.from('teams').insert([{ name, description, coach_id }]).select('*')
  if (error) return res.status(400).json({ error: error.message })
  res.status(201).json(data?.[0])
}