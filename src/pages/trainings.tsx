import { useEffect, useState } from 'react'
import { supabase } from '../lib/supabaseClient'

export default function TrainingsPage() {
  const [list, setList] = useState<any[]>([])
  useEffect(() => {
    supabase.from('trainings').select('*, teams(*)').then(({ data }) => setList(data || []))
  }, [])
  return (
    <main className="p-8">
      <h1 className="text-xl font-bold">Entrenamientos</h1>
      <ul className="mt-4">
        {list.map(t => (
          <li key={t.id} className="border p-3 my-2">
            <div className="flex justify-between">
              <div>
                <h3 className="font-semibold">{t.title}</h3>
                <p className="text-sm">{t.description}</p>
              </div>
              <div className="text-sm">{t.scheduled_at ? new Date(t.scheduled_at).toLocaleString() : ''}</div>
            </div>
          </li>
        ))}
      </ul>
    </main>
  )
}