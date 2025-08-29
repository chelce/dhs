-- Add event_date column for better date handling in weekly calendar
ALTER TABLE calendar_events ADD COLUMN IF NOT EXISTS event_date DATE;

-- Update existing records to have event_date based on year/month/day
UPDATE calendar_events 
SET event_date = make_date(year, month + 1, day)
WHERE event_date IS NULL;

-- Add index for the new date column
CREATE INDEX IF NOT EXISTS idx_calendar_events_event_date ON calendar_events (event_date);
