-- Add materials and tags support to calendar_events table
-- Run this in Supabase SQL Editor

-- Add materials column (JSONB array of material objects)
alter table calendar_events 
  add column if not exists materials jsonb default '[]'::jsonb;

-- Add tags column (JSONB array of tag strings)
alter table calendar_events 
  add column if not exists tags jsonb default '[]'::jsonb;

-- Add indexes for materials and tags queries
create index if not exists idx_calendar_events_materials 
  on calendar_events using gin (materials);

create index if not exists idx_calendar_events_tags 
  on calendar_events using gin (tags);

-- Add comments for documentation
comment on column calendar_events.materials is 'Array of lesson materials: [{"type":"file|url|workspace","path":"...","title":"...","thumbnail":"..."}]';
comment on column calendar_events.tags is 'Array of auto-generated and manual tags: ["analogies", "critical-thinking", "easy", "ap-prep"]';

-- Verify the schema
select column_name, data_type, is_nullable, column_default
from information_schema.columns 
where table_name = 'calendar_events' 
  and table_schema = 'public'
order by ordinal_position;
