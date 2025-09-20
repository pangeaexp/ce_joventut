import { useEffect, useState } from 'react'
import { supabase } from '../lib/supabaseClient'
import Link from 'next/link'

export default function Dashboard() {
  const [profile, setProfile] = useState<any>(null)

  useEffect(() => {
    supabase.auth.getUser().then(async ({ data }) => {
      const user = data.user
      if (!user) return
      const { data: p } = await supabase.from('profiles').select('*').eq('id', user.id).single()
      setProfile(p)
    })
  }, [])

  return (
    <main className="p-8">
      <h1 className="text-xl font-bold">Dashboard</h1>
      {profile ? (
        <div className="mt-4">
          <p>Hola, {profile.display_name || profile.full_name || 'Miembro'}</p>
          <p>Rol: {profile.role}</p>
          <div className="mt-4 space-x-2">
            <Link href="/teams" className="text-blue-600">Equipos</Link>
            <Link href="/trainings" className="text-blue-600">Entrenamientos</Link>
            {profile.role === 'admin' && <Link href="/admin" className="text-blue-600">Admin</Link>}
          </div>
        </div>
      ) : (
        <p className="mt-4">Cargando perfil...</p>
      )}
    </main>
  )
}