-- Create calendar_events table for teaching calendar
CREATE TABLE IF NOT EXISTS calendar_events (
    id BIGSERIAL PRIMARY KEY,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    year INTEGER NOT NULL,
    month INTEGER NOT NULL,
    day INTEGER NOT NULL,
    event_text TEXT NOT NULL,
    event_class TEXT NOT NULL CHECK (event_class IN ('2a', '2b', '3b', 'ap', '4b', 'reflection')),
    is_tentative BOOLEAN DEFAULT false NOT NULL
);

-- Add indexes for efficient querying
CREATE INDEX IF NOT EXISTS idx_calendar_events_date ON calendar_events (year, month, day);
CREATE INDEX IF NOT EXISTS idx_calendar_events_class ON calendar_events (event_class);

-- Enable Row Level Security (RLS)
ALTER TABLE calendar_events ENABLE ROW LEVEL SECURITY;

-- Create policy to allow public access (since this is a personal calendar)
-- In production, you might want to restrict this to authenticated users
CREATE POLICY "Public access for calendar_events" ON calendar_events
    FOR ALL USING (true);

-- Add some comments for documentation
COMMENT ON TABLE calendar_events IS 'Teaching calendar events with class associations';
COMMENT ON COLUMN calendar_events.year IS 'Calendar year (e.g., 2025)';
COMMENT ON COLUMN calendar_events.month IS 'Calendar month (0-11, JavaScript style)';
COMMENT ON COLUMN calendar_events.day IS 'Calendar day (1-31)';
COMMENT ON COLUMN calendar_events.event_class IS 'Class identifier: 2a, 2b, 3b, ap, 4b, or reflection';
COMMENT ON COLUMN calendar_events.is_tentative IS 'Whether this event is tentative/provisional';
