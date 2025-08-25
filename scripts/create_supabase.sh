Instrucciones rápidas:
- Instala supabase CLI: npm i -g supabase
- supabase login
- supabase projects create --name ce_joventut (o crea en la consola web)
- Obtén URL y anon/service keys en Settings > API
- Conecta remote DB y aplica migraciones:
  supabase db remote set "postgresql://..."
  supabase db push --project-ref <ref> --schema public

Nota: puedes usar la interfaz de Migrations en la consola Supabase o supabase/migrations.
