-- Figus — Supabase schema
-- Run this in the Supabase SQL editor (project: cngptfhvhbupyqzldpkc)

-- Collection entries: one row per (user, sticker)
-- Last-write-wins sync: client sends updated_at timestamp with every upsert
create table if not exists collection_entries (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid references auth.users not null,
  sticker_number   text not null,
  status           text not null default 'missing'
                     check (status in ('missing', 'owned', 'duplicate')),
  duplicate_count  int  not null default 0,
  updated_at       timestamptz not null default now(),
  unique (user_id, sticker_number)
);

-- Row-level security: each user can only read/write their own rows
alter table collection_entries enable row level security;

drop policy if exists "own_entries" on collection_entries;
create policy "own_entries" on collection_entries
  for all
  using  (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Index for fast per-user queries
create index if not exists idx_collection_entries_user
  on collection_entries (user_id);
