import type { NextApiRequest, NextApiResponse } from 'next'
import { createServerSupabase } from '../../../lib/supabaseClient'

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'POST') return res.status(405).end()
  const { fileName, bucket = 'public' } = req.body
  const supabase = createServerSupabase()
  // create presigned url using service key
  const { data, error } = await supabase.storage.from(bucket).createSignedUploadUrl(fileName, 60)
  if (error) return res.status(400).json({ error: error.message })
  res.status(200).json(data)
}