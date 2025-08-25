import { useEffect, useState } from 'react'
import { supabase } from '../lib/supabaseClient'

export default function TeamsPage() {
  const [teams, setTeams] = useState<any[]>([])

  useEffect(() => {
    supabase.from('teams').select('*').then(({ data }) => setTeams(data || []))
  }, [])

  return (
    <main className="p-8">
      <h1 className="text-xl font-bold">Equipos</h1>
      <ul className="mt-4">
        {teams.map(t => (
          <li key={t.id} className="border p-3 my-2">
            <h3 className="font-semibold">{t.name}</h3>
            <p className="text-sm">{t.description}</p>
          </li>
        ))}
      </ul>
    </main>
  )
}