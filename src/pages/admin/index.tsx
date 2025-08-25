import { useEffect, useState } from 'react'
import { supabase } from '../../lib/supabaseClient'

export default function AdminPanel() {
  const [profiles, setProfiles] = useState<any[]>([])
  const [roleTarget, setRoleTarget] = useState('member')

  useEffect(() => {
    supabase.from('profiles').select('*').then(({ data }) => setProfiles(data || []))
  }, [])

  async function setRole(user_id: string) {
    const res = await fetch('/api/admin/set-role', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ user_id, role: roleTarget })
    })
    if (res.ok) {
      const updated = await res.json()
      setProfiles(p => p.map(x => (x.id === user_id ? updated : x)))
    } else {
      alert('Error')
    }
  }

  return (
    <main className="p-8">
      <h1 className="text-xl font-bold">Panel Admin</h1>
      <div className="mt-4">
        <label>Nuevo rol:
          <select value={roleTarget} onChange={e=>setRoleTarget(e.target.value)} className="ml-2 border p-1">
            <option value="member">member</option>
            <option value="coach">coach</option>
            <option value="admin">admin</option>
          </select>
        </label>
      </div>
      <ul className="mt-4">
        {profiles.map(p => (
          <li key={p.id} className="border p-3 my-2 flex justify-between items-center">
            <div>
              <div className="font-semibold">{p.display_name || p.full_name || p.id}</div>
              <div className="text-sm">{p.role}</div>
            </div>
            <div>
              <button onClick={()=>setRole(p.id)} className="bg-blue-600 text-white px-3 py-1">Set role</button>
            </div>
          </li>
        ))}
      </ul>
    </main>
  )
}