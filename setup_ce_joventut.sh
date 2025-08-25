#!/usr/bin/env bash
set -e
ROOT="$(pwd)"
echo "Creando repo en $ROOT"

# Inicializar git
git init
git checkout -b main

# Crear carpetas
mkdir -p src/pages src/pages/api/auth src/pages/api/admin src/pages/admin src/lib migrations scripts public styles src/pages/auth src/pages/api/media/

# .gitignore
cat > .gitignore <<'GIT'
node_modules
.next
.env*
ce_joventut.zip
.DS_Store
.env.local
.env.development.local
.env.production.local
GIT

# package.json
cat > package.json <<'JSON'
{
  "name": "ce_joventut",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint"
  },
  "dependencies": {
    "@supabase/supabase-js": "^2.29.0",
    "next": "14.4.0",
    "react": "18.2.0",
    "react-dom": "18.2.0",
    "tailwindcss": "^4.0.0",
    "autoprefixer": "^10.4.14",
    "postcss": "^8.4.24"
  },
  "devDependencies": {
    "typescript": "^5.6.2",
    "eslint": "8.48.0",
    "eslint-config-next": "14.4.0"
  }
}
JSON

# Tailwind & PostCSS configs
cat > tailwind.config.cjs <<'TW'
module.exports = {
  content: ['./src/**/*.{js,ts,jsx,tsx,mdx}', './public/index.html'],
  theme: { extend: {} },
  plugins: []
}
TW

cat > postcss.config.cjs <<'PC'
module.exports = {
  plugins: { tailwindcss: {}, autoprefixer: {} }
}
PC

# styles
mkdir -p styles
cat > styles/globals.css <<'CSS'
@tailwind base;
@tailwind components;
@tailwind utilities;
CSS

# README
cat > README.md <<'MD'
# ce_joventut

Proyecto inicial CE Joventut — Next.js, TypeScript, Tailwind CSS y Supabase.

Variables de entorno (.env.example):
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=
NEXT_PUBLIC_APP_URL=http://localhost:3000

Ver README en el repo para más detalles.
MD

# .env.example
cat > .env.example <<'ENV'
NEXT_PUBLIC_SUPABASE_URL=https://xyzcompany.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=public-anon-key
SUPABASE_SERVICE_ROLE_KEY=service-role-secret
NEXT_PUBLIC_APP_URL=http://localhost:3000
ENV

# Supabase client
cat > src/lib/supabaseClient.ts <<'TS'
import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!

export const supabase = createClient(supabaseUrl, supabaseAnonKey)

export function createServerSupabase(serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY!) {
  return createClient(process.env.NEXT_PUBLIC_SUPABASE_URL!, serviceRoleKey, {
    auth: { persistSession: false }
  })
}
TS

# Pages: _app, index
cat > src/pages/_app.tsx <<'APP'
import '../styles/globals.css'
import type { AppProps } from 'next/app'
export default function App({ Component, pageProps }: AppProps) {
  return <Component {...pageProps} />
}
APP

cat > src/pages/index.tsx <<'HOME'
import Link from 'next/link'

export default function Home() {
  return (
    <main className="p-8">
      <h1 className="text-2xl font-bold">CE Joventut</h1>
      <p className="mt-4">Bienvenido — demo inicial</p>
      <div className="mt-6 space-x-4">
        <Link href="/auth/login"><a className="text-blue-600">Login</a></Link>
        <Link href="/dashboard"><a className="text-blue-600">Dashboard</a></Link>
      </div>
    </main>
  )
}
HOME

# Auth pages
cat > src/pages/auth/login.tsx <<'LOGIN'
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
LOGIN

# Dashboard, Teams, Trainings, Admin pages
cat > src/pages/dashboard.tsx <<'DASH'
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
DASH

cat > src/pages/teams.tsx <<'TEAMS'
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
TEAMS

cat > src/pages/trainings.tsx <<'TR'
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
TR

cat > src/pages/admin/index.tsx <<'ADMIN'
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
ADMIN

# API routes
cat > src/pages/api/admin/set-role.ts <<'SR'
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
SR

cat > src/pages/api/admin/create-team.ts <<'CT'
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
CT

cat > src/pages/api/media/upload-url.ts <<'UP'
import type { NextApiRequest, NextApiResponse } from 'next'
import { createServerSupabase } from '../../../lib/supabaseClient'

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'POST') return res.status(405).end()
  const { fileName, bucket = 'public' } = req.body
  const supabase = createServerSupabase()
  const { data, error } = await supabase.storage.from(bucket).createSignedUploadUrl(fileName, 60)
  if (error) return res.status(400).json({ error: error.message })
  res.status(200).json(data)
}
UP

# Migrations
mkdir -p migrations
cat > migrations/001_init.sql <<'SQL'
-- 001_init.sql
create extension if not exists pgcrypto;

create table if not exists profiles (
  id uuid primary key references auth.users on delete cascade,
  full_name text,
  display_name text,
  role text not null default 'member',
  avatar_url text,
  created_at timestamptz default now()
);

create table if not exists teams (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  coach_id uuid references profiles(id),
  created_at timestamptz default now()
);

create table if not exists news (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  content text,
  author_id uuid references profiles(id),
  published_at timestamptz default now()
);

create table if not exists events (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  starts_at timestamptz,
  ends_at timestamptz,
  created_by uuid references profiles(id),
  created_at timestamptz default now()
);

create table if not exists trainings (
  id uuid primary key default gen_random_uuid(),
  team_id uuid references teams(id),
  title text,
  description text,
  scheduled_at timestamptz,
  created_by uuid references profiles(id),
  created_at timestamptz default now()
);

create table if not exists attendance (
  id uuid primary key default gen_random_uuid(),
  training_id uuid references trainings(id),
  user_id uuid references profiles(id),
  status text default 'absent',
  recorded_at timestamptz default now()
);

create table if not exists media (
  id uuid primary key default gen_random_uuid(),
  bucket text not null,
  path text not null,
  public boolean default true,
  uploaded_by uuid references profiles(id),
  created_at timestamptz default now()
);

create table if not exists missions (
  id uuid primary key default gen_random_uuid(),
  title text,
  description text,
  starts_at timestamptz,
  ends_at timestamptz
);

create table if not exists badges (
  id uuid primary key default gen_random_uuid(),
  code text unique,
  title text,
  description text
);

alter table profiles enable row level security;
alter table teams enable row level security;
alter table news enable row level security;
alter table events enable row level security;
alter table trainings enable row level security;
alter table attendance enable row level security;
alter table media enable row level security;
SQL

cat > migrations/002_policies.sql <<'SQL'
-- 002_policies.sql
create policy "profiles_insert_own" on profiles
  for insert
  with check ( auth.uid() = id );

create policy "profiles_select_public" on profiles
  for select
  using ( true );

create policy "profiles_update_own" on profiles
  for update
  using ( auth.uid() = id )
  with check ( auth.uid() = id );

create policy "teams_select" on teams
  for select
  using ( true );

create policy "teams_insert_coach_admin" on teams
  for insert
  with check (
    exists (
      select 1 from profiles p where p.id = auth.uid() and p.role in ('coach','admin')
    )
  );

create policy "teams_update_coach_admin" on teams
  for update
  using (
    exists (
      select 1 from profiles p where p.id = auth.uid() and p.role in ('coach','admin')
    )
  );

create policy "teams_delete_admin" on teams
  for delete
  using (
    exists (
      select 1 from profiles p where p.id = auth.uid() and p.role = 'admin'
    )
  );

create policy "news_select" on news
  for select using ( true );

create policy "news_insert_roles" on news
  for insert
  with check (
    exists (select 1 from profiles p where p.id = auth.uid() and p.role in ('coach','admin'))
  );

create policy "news_update_author_or_admin" on news
  for update
  using (
    exists (select 1 from profiles p where p.id = auth.uid() and (p.role = 'admin' or p.id = news.author_id))
  );

create policy "trainings_select" on trainings for select using ( true );

create policy "trainings_insert_coach_admin" on trainings
  for insert
  with check ( exists (select 1 from profiles p where p.id = auth.uid() and p.role in ('coach','admin')) );

create policy "trainings_update_coach_admin" on trainings
  for update
  using ( exists (select 1 from profiles p where p.id = auth.uid() and p.role in ('coach','admin')) );

create policy "attendance_insert_coach_admin" on attendance
  for insert
  with check ( exists (select 1 from profiles p where p.id = auth.uid() and p.role in ('coach','admin')) );

create policy "attendance_update_coach_admin_or_self" on attendance
  for update
  using (
    exists (select 1 from profiles p where p.id = auth.uid() and p.role in ('coach','admin'))
    or auth.uid() = attendance.user_id
  );

create policy "attendance_select" on attendance for select using (
  auth.uid() = attendance.user_id
  or exists (select 1 from profiles p where p.id = auth.uid() and p.role in ('coach','admin'))
);

create policy "media_select_public" on media for select using ( public = true );
create policy "media_insert_auth" on media for insert with check ( auth.uid() IS NOT NULL );
SQL

cat > migrations/003_seed.sql <<'SQL'
-- 003_seed.sql
-- Seed helpers / instructions.
-- Create a user via Supabase Auth (email sign-up) to obtain the UID.
-- Then run:
-- update profiles set role='admin' where id = '<USER_UUID>';
-- insert into profiles (id, full_name, display_name, role) values ('<USER_UUID>','Admin','Admin','admin');
SQL

# scripts
mkdir -p scripts
cat > scripts/create_supabase.sh <<'SHS'
#!/usr/bin/env bash
echo "Placeholder: use supabase CLI to create project and apply migrations."
echo "Example:"
echo "  supabase login"
echo "  supabase projects create --name ce_joventut"
echo "  # then push migrations or use dashboard"
SHS
chmod +x scripts/create_supabase.sh

# Inicial commit
git add .
git commit -m "chore: scaffold ce_joventut full initial files"

# Create zip
ZIP_PATH="$(dirname "$ROOT")/ce_joventut.zip"
echo "Creando zip en $ZIP_PATH ..."
cd ..
zip -r ce_joventut.zip "$(basename "$ROOT")" > /dev/null
cd "$ROOT"

echo "Listo. ZIP creado en $(dirname "$ROOT")/ce_joventut.zip"
