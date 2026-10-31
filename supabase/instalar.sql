-- CORREPLUS CRM · instalación de la base de datos en Supabase
-- Pegar completo en Supabase › SQL Editor › New query › Run. Se puede correr más de una vez.

create table if not exists public.registros (
  coleccion text not null,          -- clientes, polizas, cobros, usuarios…
  id text not null,
  data jsonb not null,
  orden double precision default 0,
  actualizado timestamptz not null default now(),
  actualizado_por text default (auth.jwt() ->> 'email'),
  primary key (coleccion, id)
);
create table if not exists public.meta (
  clave text primary key,           -- config y otros ajustes generales
  valor text not null,
  actualizado timestamptz not null default now()
);
alter table public.registros replica identity full;
alter table public.meta replica identity full;

-- ¿quién entró? su correo debe estar en Configuración › Usuarios y activo.
-- Mientras no haya ningún usuario con correo (sistema recién instalado), el primero que entra queda de administrador.
create or replace function public.crm_acceso() returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce(auth.jwt() ->> 'email', '') <> '' and (
    exists (select 1 from registros
            where coleccion = 'usuarios'
              and lower(data ->> 'email') = lower(auth.jwt() ->> 'email')
              and coalesce(data ->> 'estado', 'Activo') = 'Activo')
    or not exists (select 1 from registros where coleccion = 'usuarios' and coalesce(data ->> 'email', '') <> '')
  );
$$;
create or replace function public.crm_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce(auth.jwt() ->> 'email', '') <> '' and (
    exists (select 1 from registros
            where coleccion = 'usuarios'
              and lower(data ->> 'email') = lower(auth.jwt() ->> 'email')
              and coalesce(data ->> 'estado', 'Activo') = 'Activo'
              and data ->> 'rol' = 'Administrador')
    or not exists (select 1 from registros where coleccion = 'usuarios' and coalesce(data ->> 'email', '') <> '')
  );
$$;
revoke all on function public.crm_acceso() from public, anon;
revoke all on function public.crm_admin() from public, anon;
grant execute on function public.crm_acceso() to authenticated;
grant execute on function public.crm_admin() to authenticated;

alter table public.registros enable row level security;
alter table public.meta enable row level security;

drop policy if exists "leer registros" on public.registros;
drop policy if exists "crear registros" on public.registros;
drop policy if exists "cambiar registros" on public.registros;
drop policy if exists "borrar registros" on public.registros;
create policy "leer registros" on public.registros for select to authenticated using (public.crm_acceso());
-- la lista de usuarios solo la cambian los administradores
create policy "crear registros" on public.registros for insert to authenticated
  with check (public.crm_acceso() and (coleccion <> 'usuarios' or public.crm_admin()));
create policy "cambiar registros" on public.registros for update to authenticated
  using (public.crm_acceso() and (coleccion <> 'usuarios' or public.crm_admin()))
  with check (public.crm_acceso() and (coleccion <> 'usuarios' or public.crm_admin()));
create policy "borrar registros" on public.registros for delete to authenticated
  using (public.crm_acceso() and (coleccion <> 'usuarios' or public.crm_admin()));

drop policy if exists "meta" on public.meta;
create policy "meta" on public.meta for all to authenticated using (public.crm_acceso()) with check (public.crm_acceso());

-- fecha de último cambio
create or replace function public.crm_tocar() returns trigger language plpgsql as $$
begin new.actualizado := now(); new.actualizado_por := auth.jwt() ->> 'email'; return new; end $$;
drop trigger if exists tocar on public.registros;
create trigger tocar before update on public.registros for each row execute function public.crm_tocar();

-- cambios en vivo entre computadoras
do $$ begin
  begin alter publication supabase_realtime add table public.registros; exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table public.meta; exception when duplicate_object then null; end;
end $$;
