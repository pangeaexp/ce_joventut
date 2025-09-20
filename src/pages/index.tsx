import Link from 'next/link'

export default function Home() {
  return (
    <main className="p-8">
      <h1 className="text-2xl font-bold">CE Joventut</h1>
      <p className="mt-4">Bienvenido — demo inicial</p>
      <div className="mt-6 space-x-4">
        <Link href="/auth/login" className="text-blue-600">Login</Link>
        <Link href="/dashboard" className="text-blue-600">Dashboard</Link>
      </div>
    </main>
  )
}