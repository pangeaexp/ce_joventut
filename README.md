
# ce_joventut

Proyecto inicial CE Joventut — Next.js (App Router compatible), TypeScript, Tailwind CSS y Supabase.

Resumen:
- Autenticación: Supabase Auth (SupabaseAuthClient)
- Base de datos: Supabase (Postgres) con Row Level Security
- Multimedia: supabase storage (bucket público)
- Roles: member, coach, admin (profiles.role)
- Single-tenant, coaches-global

Contenido del README: pasos para crear proyecto Supabase, aplicar migraciones, configurar variables y desplegar.

Instalación rápida (local)
1. Clona:
   git clone git@github.com:TU_USUARIO/ce_joventut.git
   cd ce_joventut
2. Instala dependencias:
   npm install
3. Copia variables de ejemplo:
   cp .env.example .env.local
   (rellena los valores)
4. Ejecuta en desarrollo:
   npm run dev

Variables de entorno (.env.example)
- NEXT_PUBLIC_SUPABASE_URL=
- NEXT_PUBLIC_SUPABASE_ANON_KEY=
- SUPABASE_SERVICE_ROLE_KEY=
- NEXT_PUBLIC_APP_URL=http://localhost:3000

Supabase — aplicar migraciones
1. Instala supabase CLI y autentica.
2. Crea proyecto Supabase en la consola o con CLI.
3. Sube las migraciones en /migrations al proyecto (supabase db push / supabase migration).
4. Crea usuarios de prueba vía Auth UI y actualiza profiles.role según necesites.

Despliegue
- Configura variables de entorno en Vercel/GitHub Actions (poner SUPABASE_SERVICE_ROLE_KEY como variable server-only).
- Despliega el proyecto.

Políticas RLS: implementadas para profiles, teams, news, trainings, attendance, media. Coaches y Admins tienen privilegios según spec.


10) migraciones, crear usuario admin y actualizar role, configurar bucket público en Storage > Buckets > crear 'public'.

11) Notas importantes (coloca en README o DOCUMENTATION)
- El endpoint /api/admin/* usa createServerSupabase() que inyecta SUPABASE_SERVICE_ROLE_KEY: asegúrate de definir SUPABASE_SERVICE_ROLE_KEY en entorno del servidor (Vercel/GitHub Actions) y no exponerlo en cliente.
- Las políticas RLS usan auth.uid() y la tabla profiles referencia auth.users; cuando un usuario se registra en Supabase Auth, crea manualmente o via trigger la fila en profiles (puedes crear trigger en Supabase para crear profiles on auth.user_signup).
  Ejemplo trigger SQL (opcional):
  create function public.handle_new_user() returns trigger as $$
  begin
    insert into profiles (id, full_name, display_name, created_at) values (new.id, new.email, new.email, now());
    return new;
  end;
  $$ language plpgsql;
  create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_user();

- Para subir media pública crea bucket "public" y configura políticas en Storage (por defecto público).

Fin — esto cubre la base mínima, RLS, API server-safe y frontend de ejemplo. Si quieres que genere ahora un script de shell que cree todos los archivos locales y empaquete un ZIP (para que ejecutes y obtengas el zip), dime y lo genero listo para pegar en tu terminal.
