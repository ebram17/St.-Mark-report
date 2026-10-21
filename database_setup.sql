-- St. Mark Report database setup. Run in Supabase SQL Editor as project owner.
create extension if not exists pgcrypto;
create table if not exists public.branches (id uuid primary key default gen_random_uuid(), name text not null unique);
create table if not exists public.departments (id uuid primary key default gen_random_uuid(), name text not null unique);
create table if not exists public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 email text,
 full_name text not null default '',
 role text not null default 'supervisor' check (role in ('manager','supervisor')),
 branch_id uuid references public.branches(id),
 department_id uuid references public.departments(id),
 active boolean not null default true,
 created_at timestamptz not null default now()
);
create table if not exists public.reports (
 id uuid primary key default gen_random_uuid(),
 supervisor_id uuid not null references public.profiles(id) on delete restrict,
 branch_id uuid references public.branches(id),
 department_id uuid references public.departments(id),
 report_date date not null default current_date,
 work_done text not null,
 complaints text not null default '',
 review_status text not null default 'جديد' check (review_status in ('جديد','تمت المراجعة','متابعة مطلوبة')),
 manager_notes text not null default '',
 reviewed_by uuid references public.profiles(id),
 reviewed_at timestamptz,
 created_at timestamptz not null default now()
);
insert into public.branches(name) values ('الخطاطبة'),('قنا'),('السخنة') on conflict(name) do nothing;
insert into public.departments(name) values ('مشرف مطعم'),('مشرف هاوس كيبنج'),('مشرف مخازن'),('مشرف مشاريع'),('مشرف مطبخ'),('مشرف بوابة'),('مشرف زراعة'),('مشرف Front Office (الحسابات)') on conflict(name) do nothing;
-- Manager row is created for the existing Auth user. If the profile already exists, it is promoted.
insert into public.profiles(id,email,full_name,role,active)
select id,email,coalesce(raw_user_meta_data->>'full_name','مدير النظام'),'manager',true
from auth.users where lower(email)=lower('gamilebram925@gmail.com')
on conflict(id) do update set role='manager', active=true, email=excluded.email;
create or replace function public.is_manager() returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='manager' and p.active=true)
$$;
create or replace function public.is_active_user() returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from public.profiles p where p.id=auth.uid() and p.active=true)
$$;
alter table public.branches enable row level security;
alter table public.departments enable row level security;
alter table public.profiles enable row level security;
alter table public.reports enable row level security;
drop policy if exists "read branches authenticated" on public.branches;
create policy "read branches authenticated" on public.branches for select to authenticated using (public.is_active_user());
drop policy if exists "read departments authenticated" on public.departments;
create policy "read departments authenticated" on public.departments for select to authenticated using (public.is_active_user());
drop policy if exists "profiles read self or manager" on public.profiles;
create policy "profiles read self or manager" on public.profiles for select to authenticated using (id=auth.uid() or public.is_manager());
drop policy if exists "manager insert profiles" on public.profiles;
create policy "manager insert profiles" on public.profiles for insert to authenticated with check (public.is_manager());
drop policy if exists "manager update profiles" on public.profiles;
create policy "manager update profiles" on public.profiles for update to authenticated using (public.is_manager()) with check (public.is_manager());
drop policy if exists "reports read own or manager" on public.reports;
create policy "reports read own or manager" on public.reports for select to authenticated using (supervisor_id=auth.uid() or public.is_manager());
drop policy if exists "active supervisors submit own reports" on public.reports;
create policy "active supervisors submit own reports" on public.reports for insert to authenticated with check (supervisor_id=auth.uid() and public.is_active_user() and exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='supervisor' and p.active=true and p.branch_id=reports.branch_id and p.department_id=reports.department_id));
drop policy if exists "manager updates reports" on public.reports;
create policy "manager updates reports" on public.reports for update to authenticated using (public.is_manager()) with check (public.is_manager());
grant usage on schema public to authenticated;
grant select on public.branches,public.departments,public.profiles,public.reports to authenticated;
grant insert on public.reports to authenticated;
grant insert,update on public.profiles to authenticated;
grant update on public.reports to authenticated;
