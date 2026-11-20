-- WorkProof AI production database foundation
-- Run in Supabase SQL Editor. Tenant records are scoped to the authenticated workspace owner.

create extension if not exists pgcrypto;

create table if not exists public.workspaces (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null default 'My Business',
  created_at timestamptz not null default now()
);

create table if not exists public.jobs (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  created_by uuid not null references auth.users(id) on delete cascade,
  job_code text not null,
  title text not null,
  customer_name text not null,
  customer_phone text,
  location text,
  amount_paise bigint not null check (amount_paise > 0),
  paid_paise bigint not null default 0 check (paid_paise >= 0 and paid_paise <= amount_paise),
  due_date date,
  status text not null default 'in_progress' check (status in ('in_progress','awaiting_approval','completed')),
  payment_status text generated always as (
    case when paid_paise = 0 then 'unpaid'
         when paid_paise >= amount_paise then 'paid'
         else 'partially_paid' end
  ) stored,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(workspace_id, job_code)
);

create table if not exists public.evidence (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null references public.jobs(id) on delete cascade,
  uploaded_by uuid not null references auth.users(id) on delete cascade,
  storage_path text not null,
  original_name text not null,
  content_type text not null,
  size_bytes bigint not null check (size_bytes > 0 and size_bytes <= 20971520),
  created_at timestamptz not null default now()
);

create table if not exists public.job_events (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null references public.jobs(id) on delete cascade,
  actor_id uuid not null references auth.users(id) on delete cascade,
  event_type text not null,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists jobs_workspace_created_idx on public.jobs(workspace_id, created_at desc);
create index if not exists evidence_job_created_idx on public.evidence(job_id, created_at desc);
create index if not exists job_events_job_created_idx on public.job_events(job_id, created_at desc);

alter table public.workspaces enable row level security;
alter table public.jobs enable row level security;
alter table public.evidence enable row level security;
alter table public.job_events enable row level security;

create policy "Workspace owners can read their workspaces" on public.workspaces
for select to authenticated using (owner_id = (select auth.uid()));
create policy "Users can create their own workspace" on public.workspaces
for insert to authenticated with check (owner_id = (select auth.uid()));
create policy "Workspace owners can update their workspaces" on public.workspaces
for update to authenticated using (owner_id = (select auth.uid())) with check (owner_id = (select auth.uid()));

create policy "Workspace owners can read jobs" on public.jobs
for select to authenticated using (
  exists (select 1 from public.workspaces w where w.id=workspace_id and w.owner_id=(select auth.uid()))
);
create policy "Workspace owners can create jobs" on public.jobs
for insert to authenticated with check (
  created_by=(select auth.uid()) and
  exists (select 1 from public.workspaces w where w.id=workspace_id and w.owner_id=(select auth.uid()))
);
create policy "Workspace owners can update jobs" on public.jobs
for update to authenticated using (
  exists (select 1 from public.workspaces w where w.id=workspace_id and w.owner_id=(select auth.uid()))
) with check (
  exists (select 1 from public.workspaces w where w.id=workspace_id and w.owner_id=(select auth.uid()))
);
create policy "Workspace owners can delete jobs" on public.jobs
for delete to authenticated using (
  exists (select 1 from public.workspaces w where w.id=workspace_id and w.owner_id=(select auth.uid()))
);

create policy "Workspace owners can read evidence metadata" on public.evidence
for select to authenticated using (
  exists (select 1 from public.jobs j join public.workspaces w on w.id=j.workspace_id where j.id=job_id and w.owner_id=(select auth.uid()))
);
create policy "Workspace owners can add evidence metadata" on public.evidence
for insert to authenticated with check (
  uploaded_by=(select auth.uid()) and
  exists (select 1 from public.jobs j join public.workspaces w on w.id=j.workspace_id where j.id=job_id and w.owner_id=(select auth.uid()))
);
create policy "Workspace owners can remove evidence metadata" on public.evidence
for delete to authenticated using (
  exists (select 1 from public.jobs j join public.workspaces w on w.id=j.workspace_id where j.id=job_id and w.owner_id=(select auth.uid()))
);

create policy "Workspace owners can read job events" on public.job_events
for select to authenticated using (
  exists (select 1 from public.jobs j join public.workspaces w on w.id=j.workspace_id where j.id=job_id and w.owner_id=(select auth.uid()))
);
create policy "Workspace owners can add job events" on public.job_events
for insert to authenticated with check (
  actor_id=(select auth.uid()) and
  exists (select 1 from public.jobs j join public.workspaces w on w.id=j.workspace_id where j.id=job_id and w.owner_id=(select auth.uid()))
);

insert into storage.buckets (id,name,public,file_size_limit,allowed_mime_types)
values ('job-evidence','job-evidence',false,20971520,array['image/jpeg','image/png','image/webp','video/mp4','application/pdf'])
on conflict (id) do nothing;

create policy "Users can read own workspace evidence files" on storage.objects
for select to authenticated using (
  bucket_id='job-evidence' and (storage.foldername(name))[1]=(select auth.uid())::text
);
create policy "Users can upload evidence into own folder" on storage.objects
for insert to authenticated with check (
  bucket_id='job-evidence' and (storage.foldername(name))[1]=(select auth.uid())::text
);
create policy "Users can delete evidence in own folder" on storage.objects
for delete to authenticated using (
  bucket_id='job-evidence' and (storage.foldername(name))[1]=(select auth.uid())::text
);
