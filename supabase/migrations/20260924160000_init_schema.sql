-- JeanCar Connect — Fase 1: Backend core
-- Schema base + RLS + trigger de perfil automático (RF1, RF2)

-- ============ ENUMS ============
create type public.rol_usuario as enum ('cliente', 'mecanico');
create type public.estado_reserva as enum ('pendiente', 'confirmada', 'en_proceso', 'completada', 'cancelada');
create type public.estado_factura as enum ('borrador', 'emitida', 'pagada', 'anulada');
create type public.tipo_documento as enum ('reserva', 'factura');

-- ============ TABLAS ============

-- Perfil de usuario (extiende auth.users de Supabase Auth)
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  rol public.rol_usuario not null default 'cliente',
  nombre_completo text not null default '',
  telefono text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Catálogo de servicios del taller (RF6, RF7)
create table public.servicios (
  id uuid primary key default gen_random_uuid(),
  nombre text not null,
  descripcion text not null default '',
  precio_base numeric(10, 2) not null check (precio_base >= 0),
  duracion_min integer not null default 60 check (duracion_min > 0),
  activo boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Reservas / órdenes de trabajo (RF3, RF4)
create table public.reservas (
  id uuid primary key default gen_random_uuid(),
  cliente_id uuid not null references public.profiles (id),
  mecanico_id uuid references public.profiles (id),
  servicio_id uuid not null references public.servicios (id),
  vehiculo_marca text not null default '',
  vehiculo_modelo text not null default '',
  vehiculo_anio integer,
  vehiculo_placa text not null default '',
  fecha_hora timestamptz not null,
  estado public.estado_reserva not null default 'pendiente',
  notas_cliente text not null default '',
  notas_mecanico text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Facturación (RF8)
create table public.facturas (
  id uuid primary key default gen_random_uuid(),
  reserva_id uuid not null unique references public.reservas (id),
  numero bigint generated always as identity,
  subtotal numeric(10, 2) not null default 0 check (subtotal >= 0),
  impuesto_pct numeric(5, 2) not null default 0 check (impuesto_pct >= 0),
  total numeric(10, 2) generated always as (round(subtotal * (1 + impuesto_pct / 100), 2)) stored,
  estado public.estado_factura not null default 'borrador',
  metodo_pago text,
  pagada_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Documentos PDF generados (RF5, RF9, RF10) — el archivo vive en Storage
create table public.documentos (
  id uuid primary key default gen_random_uuid(),
  reserva_id uuid references public.reservas (id) on delete cascade,
  factura_id uuid references public.facturas (id) on delete cascade,
  tipo public.tipo_documento not null,
  storage_path text not null,
  created_at timestamptz not null default now(),
  check (num_nulls(reserva_id, factura_id) = 1)
);

-- ============ ÍNDICES ============
create index reservas_cliente_idx on public.reservas (cliente_id);
create index reservas_mecanico_idx on public.reservas (mecanico_id) where mecanico_id is not null;
create index reservas_estado_fecha_idx on public.reservas (estado, fecha_hora);
create index facturas_reserva_idx on public.facturas (reserva_id);
create index documentos_reserva_idx on public.documentos (reserva_id) where reserva_id is not null;
create index documentos_factura_idx on public.documentos (factura_id) where factura_id is not null;

-- ============ FUNCIONES ============

-- Helper para políticas RLS: ¿el usuario actual es mecánico?
create or replace function public.is_mecanico()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and rol = 'mecanico'
  );
$$;

-- updated_at automático
create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_touch before update on public.profiles
  for each row execute function public.touch_updated_at();
create trigger servicios_touch before update on public.servicios
  for each row execute function public.touch_updated_at();
create trigger reservas_touch before update on public.reservas
  for each row execute function public.touch_updated_at();
create trigger facturas_touch before update on public.facturas
  for each row execute function public.touch_updated_at();

-- Crea el perfil cuando Supabase Auth registra un usuario (RF1)
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, rol, nombre_completo, telefono)
  values (
    new.id,
    case
      when (new.raw_user_meta_data ->> 'rol') in ('cliente', 'mecanico')
        then (new.raw_user_meta_data ->> 'rol')::public.rol_usuario
      else 'cliente'
    end,
    coalesce(new.raw_user_meta_data ->> 'nombre_completo', ''),
    new.raw_user_meta_data ->> 'telefono'
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Un cliente no puede cambiarse el rol a sí mismo
create or replace function public.guard_rol_change()
returns trigger
language plpgsql
as $$
begin
  if new.rol is distinct from old.rol and not public.is_mecanico() then
    raise exception 'Solo un mecánico puede cambiar roles';
  end if;
  return new;
end;
$$;

create trigger profiles_guard_rol before update on public.profiles
  for each row execute function public.guard_rol_change();

-- ============ ROW LEVEL SECURITY ============
alter table public.profiles enable row level security;
alter table public.servicios enable row level security;
alter table public.reservas enable row level security;
alter table public.facturas enable row level security;
alter table public.documentos enable row level security;

-- profiles: cada quien ve/edita el suyo; mecánico ve todos
create policy profiles_select on public.profiles
  for select using (id = auth.uid() or public.is_mecanico());
create policy profiles_update on public.profiles
  for update using (id = auth.uid() or public.is_mecanico())
  with check (id = auth.uid() or public.is_mecanico());

-- servicios: todos leen los activos; solo mecánico escribe
create policy servicios_select on public.servicios
  for select using (activo or public.is_mecanico());
create policy servicios_insert on public.servicios
  for insert with check (public.is_mecanico());
create policy servicios_update on public.servicios
  for update using (public.is_mecanico()) with check (public.is_mecanico());
create policy servicios_delete on public.servicios
  for delete using (public.is_mecanico());

-- reservas: cliente ve/edita solo las suyas mientras estén pendientes; mecánico todo
create policy reservas_select on public.reservas
  for select using (cliente_id = auth.uid() or public.is_mecanico());
create policy reservas_insert on public.reservas
  for insert with check (cliente_id = auth.uid());
create policy reservas_update_cliente on public.reservas
  for update using (cliente_id = auth.uid() and estado = 'pendiente')
  with check (cliente_id = auth.uid() and estado in ('pendiente', 'cancelada'));
create policy reservas_update_mecanico on public.reservas
  for update using (public.is_mecanico()) with check (public.is_mecanico());

-- facturas: cliente lee las de sus reservas; mecánico gestiona todo
create policy facturas_select on public.facturas
  for select using (
    public.is_mecanico()
    or exists (
      select 1 from public.reservas r
      where r.id = facturas.reserva_id and r.cliente_id = auth.uid()
    )
  );
create policy facturas_insert on public.facturas
  for insert with check (public.is_mecanico());
create policy facturas_update on public.facturas
  for update using (public.is_mecanico()) with check (public.is_mecanico());

-- documentos: visible si el dueño de la reserva/factura es el usuario o es mecánico
create policy documentos_select on public.documentos
  for select using (
    public.is_mecanico()
    or exists (
      select 1 from public.reservas r
      where r.id = documentos.reserva_id and r.cliente_id = auth.uid()
    )
    or exists (
      select 1 from public.facturas f
      join public.reservas r on r.id = f.reserva_id
      where f.id = documentos.factura_id and r.cliente_id = auth.uid()
    )
  );
create policy documentos_insert on public.documentos
  for insert with check (public.is_mecanico());
create policy documentos_delete on public.documentos
  for delete using (public.is_mecanico());
