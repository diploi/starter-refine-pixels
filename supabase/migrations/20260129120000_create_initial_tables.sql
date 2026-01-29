-- Base schema for Collaborative Drawing App
create extension if not exists "pgcrypto";

create table if not exists public.canvases (
    id text primary key,
    user_id uuid not null references auth.users (id) on delete cascade,
    name text,
    width integer not null check (width > 0),
    height integer not null check (height > 0),
    is_featured boolean not null default false,
    created_at timestamptz not null default now()
);

create index if not exists canvases_created_at_idx on public.canvases (created_at desc);
create index if not exists canvases_featured_idx on public.canvases (is_featured);

alter table public.canvases enable row level security;

drop policy if exists "Canvases are readable by everyone" on public.canvases;
create policy "Canvases are readable by everyone" on public.canvases
    for select using (true);

drop policy if exists "Users can insert their own canvases" on public.canvases;
create policy "Users can insert their own canvases" on public.canvases
    for insert with check (auth.uid() = user_id);

create table if not exists public.pixels (
    id uuid primary key default gen_random_uuid(),
    canvas_id text not null references public.canvases (id) on delete cascade,
    user_id uuid not null references auth.users (id) on delete cascade,
    x integer not null check (x >= 0),
    y integer not null check (y >= 0),
    color text not null,
    name text,
    created_at timestamptz not null default now()
);

create index if not exists pixels_canvas_created_at_idx on public.pixels (canvas_id, created_at desc);

alter table public.pixels enable row level security;

drop policy if exists "Pixels are readable by everyone" on public.pixels;
create policy "Pixels are readable by everyone" on public.pixels
    for select using (true);

drop policy if exists "Users can insert their own pixels" on public.pixels;
create policy "Users can insert their own pixels" on public.pixels
    for insert with check (auth.uid() = user_id);

create table if not exists public.logs (
    id uuid primary key default gen_random_uuid(),
    resource text not null,
    action text not null,
    author jsonb,
    meta jsonb,
    previous_data jsonb,
    data jsonb,
    name text,
    created_at timestamptz not null default now()
);

create index if not exists logs_resource_idx on public.logs (resource);
create index if not exists logs_canvas_id_idx on public.logs ((meta #>> '{canvas,id}'));

alter table public.logs enable row level security;

drop policy if exists "Logs are readable by everyone" on public.logs;
create policy "Logs are readable by everyone" on public.logs
    for select using (true);

drop policy if exists "Authenticated users can insert logs" on public.logs;
create policy "Authenticated users can insert logs" on public.logs
    for insert with check (auth.role() in ('authenticated', 'service_role'));

drop policy if exists "Authenticated users can update logs" on public.logs;
create policy "Authenticated users can update logs" on public.logs
    for update using (auth.role() in ('authenticated', 'service_role')) with check (auth.role() in ('authenticated', 'service_role'));

alter publication supabase_realtime add table public.canvases;
alter publication supabase_realtime add table public.pixels;
alter publication supabase_realtime add table public.logs;
