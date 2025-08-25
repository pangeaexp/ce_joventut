import { useState } from 'react'
import { supabase } from '../../lib/supabaseClient'
import { useRouter } from 'next/router'

export default function Login() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const router = useRouter()

  async function signIn() {
    const { error } = await supabase.auth.signInWithPassword({ email, password })
    if (error) return alert(error.message)
    router.push('/dashboard')
  }

  async function signUp() {
    const { error } = await supabase.auth.signUp({ email, password })
    if (error) return alert(error.message)
    alert('Revisa tu email para confirmar registro.')
  }

  return (
    <main className="p-8 max-w-md">
      <h1 className="text-xl font-bold">Acceso</h1>
      <label className="block mt-4">Email
        <input value={email} onChange={e=>setEmail(e.target.value)} className="border p-2 w-full" />
      </label>
      <label className="block mt-4">Password
        <input type="password" value={password} onChange={e=>setPassword(e.target.value)} className="border p-2 w-full" />
      </label>
      <div className="mt-4 space-x-2">
        <button onClick={signIn} className="bg-blue-600 text-white px-4 py-2">Entrar</button>
        <button onClick={signUp} className="border px-4 py-2">Registrar</button>
      </div>
    </main>
  )
}