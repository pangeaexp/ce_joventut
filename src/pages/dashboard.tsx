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
            <Link href="/teams"><a className="text-blue-600">Equipos</a></Link>
            <Link href="/trainings"><a className="text-blue-600">Entrenamientos</a></Link>
            {profile.role === 'admin' && <Link href="/admin"><a className="text-blue-600">Admin</a></Link>}
          </div>
        </div>
      ) : (
        <p className="mt-4">Cargando perfil...</p>
      )}
    </main>
  )
}