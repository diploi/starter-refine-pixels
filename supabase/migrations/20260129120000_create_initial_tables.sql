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

create table if not exists public.profiles (
    id uuid primary key references auth.users (id) on delete cascade,
    email text,
    full_name text,
    avatar_url text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

drop policy if exists "Profiles are readable by everyone" on public.profiles;
create policy "Profiles are readable by everyone" on public.profiles
    for select using (true);

drop policy if exists "Users can update their own profile" on public.profiles;
create policy "Users can update their own profile" on public.profiles
    for update using (auth.uid() = id) with check (auth.uid() = id);

grant select on public.profiles to anon, authenticated;
grant update on public.profiles to authenticated;

alter table public.canvases
    drop constraint if exists canvases_user_id_fkey;

alter table public.canvases
    add constraint canvases_user_id_fkey foreign key (user_id) references public.profiles (id) on delete cascade;

create table if not exists public.pixels (
    id uuid primary key default gen_random_uuid(),
    canvas_id text not null references public.canvases (id) on delete cascade,
    user_id uuid not null references public.profiles (id) on delete cascade,
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

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
    insert into public.profiles (id, email, full_name, avatar_url)
    values (
        new.id,
        new.email,
        coalesce(new.raw_user_meta_data->>'full_name', ''),
        new.raw_user_meta_data->>'avatar_url'
    )
    on conflict (id) do update set
        email = excluded.email,
        full_name = excluded.full_name,
        avatar_url = excluded.avatar_url,
        updated_at = now();

    return new;
end;
$$;

create or replace function public.handle_updated_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
    update public.profiles
    set
        email = new.email,
        full_name = coalesce(new.raw_user_meta_data->>'full_name', full_name),
        avatar_url = new.raw_user_meta_data->>'avatar_url',
        updated_at = now()
    where id = new.id;

    return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
    after insert on auth.users
    for each row execute procedure public.handle_new_user();

drop trigger if exists on_auth_user_updated on auth.users;
create trigger on_auth_user_updated
    after update on auth.users
    for each row execute procedure public.handle_updated_user();

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

drop trigger if exists on_profile_updated on public.profiles;
create trigger on_profile_updated
    before update on public.profiles
    for each row execute procedure public.set_updated_at();