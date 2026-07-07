-- Matches table for matchmaking between players
-- Run this migration in your Supabase SQL Editor

-- Create matches table
create table public.matches (
  id uuid not null default gen_random_uuid (),
  court_id uuid not null,
  sport_id uuid null,
  player1_id uuid not null,
  player2_id uuid null,
  player3_id uuid null,
  player4_id uuid null,
  referee_id uuid null,
  match_type text not null default '1v1',
  match_mode text not null default 'random',
  status text not null default 'pending',
  scheduled_date date not null,
  scheduled_time text not null,
  invite_code text null,
  winner_id uuid null,
  score_data jsonb null,
  notes text null,
  created_at timestamp with time zone null default now(),
  updated_at timestamp with time zone null default now(),
  
  constraint matches_pkey primary key (id),
  constraint matches_court_id_fkey foreign key (court_id) references courts (id) on delete cascade,
  constraint matches_sport_id_fkey foreign key (sport_id) references sports (id) on delete set null,
  constraint matches_player1_id_fkey foreign key (player1_id) references users (id) on delete cascade,
  constraint matches_player2_id_fkey foreign key (player2_id) references users (id) on delete set null,
  constraint matches_player3_id_fkey foreign key (player3_id) references users (id) on delete set null,
  constraint matches_player4_id_fkey foreign key (player4_id) references users (id) on delete set null,
  constraint matches_referee_id_fkey foreign key (referee_id) references users (id) on delete set null,
  constraint matches_winner_id_fkey foreign key (winner_id) references users (id) on delete set null,
  constraint matches_invite_code_key unique (invite_code),
  constraint matches_match_type_check check (match_type in ('1v1', '2v2')),
  constraint matches_match_mode_check check (match_mode in ('random', 'private', 'team_up')),
  constraint matches_status_check check (status in ('pending', 'waiting_for_opponent', 'matched', 'confirmed', 'in_progress', 'completed', 'cancelled'))
) tablespace pg_default;

-- Create indexes for better query performance
create index if not exists idx_matches_court_id on public.matches using btree (court_id) tablespace pg_default;
create index if not exists idx_matches_player1_id on public.matches using btree (player1_id) tablespace pg_default;
create index if not exists idx_matches_player2_id on public.matches using btree (player2_id) tablespace pg_default;
create index if not exists idx_matches_referee_id on public.matches using btree (referee_id) tablespace pg_default;
create index if not exists idx_matches_status on public.matches using btree (status) tablespace pg_default;
create index if not exists idx_matches_scheduled_date on public.matches using btree (scheduled_date) tablespace pg_default;
create index if not exists idx_matches_invite_code on public.matches using btree (invite_code) tablespace pg_default;

-- Trigger to update updated_at timestamp
create trigger update_matches_updated_at 
before update on matches 
for each row
execute function update_updated_at_column ();

-- Enable Row Level Security
alter table public.matches enable row level security;

-- RLS Policies

-- Players can view matches they are part of
create policy "Players can view their matches" on public.matches
  for select using (
    auth.uid() = player1_id or 
    auth.uid() = player2_id or 
    auth.uid() = player3_id or 
    auth.uid() = player4_id or
    auth.uid() = referee_id
  );

-- Players can insert matches as player1
create policy "Players can create matches" on public.matches
  for insert with check (
    auth.uid() = player1_id
  );

-- Players can update matches they created (only certain fields)
create policy "Players can update their matches" on public.matches
  for update using (
    auth.uid() = player1_id or 
    auth.uid() = player2_id or 
    auth.uid() = player3_id or 
    auth.uid() = player4_id
  );

-- Referees can view matches at their assigned courts
create policy "Referees can view court matches" on public.matches
  for select using (
    exists (
      select 1 from court_assignments ca 
      where ca.referee_id = auth.uid() 
      and ca.court_id = matches.court_id 
      and ca.is_active = true
    )
  );

-- Referees can update matches at their assigned courts
create policy "Referees can update court matches" on public.matches
  for update using (
    auth.uid() = referee_id or
    exists (
      select 1 from court_assignments ca 
      where ca.referee_id = auth.uid() 
      and ca.court_id = matches.court_id 
      and ca.is_active = true
    )
  );

-- Enable realtime for matches table
alter publication supabase_realtime add table matches;

-- Function to auto-assign referee when match is created
create or replace function auto_assign_referee()
returns trigger as $$
declare
  assigned_referee uuid;
begin
  -- Find an active referee assigned to this court
  select referee_id into assigned_referee
  from court_assignments
  where court_id = NEW.court_id
    and is_active = true
  limit 1;
  
  -- Note: We don't auto-assign anymore, referee needs to accept
  -- This function can be modified if auto-assignment is desired
  
  return NEW;
end;
$$ language plpgsql;

-- Optional: Create trigger for auto-assignment (commented out by default)
-- create trigger auto_assign_referee_trigger
-- before insert on matches
-- for each row
-- execute function auto_assign_referee();
