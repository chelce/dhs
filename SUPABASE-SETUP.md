# 🚀 Supabase Calendar Setup Guide

## Step 1: Create Supabase Project

1. Go to [supabase.com](https://supabase.com) and create a free account
2. Click "New Project"
3. Choose your organization and give it a name like "Teaching Calendar"
4. Set a database password (save this!)
5. Wait for setup to complete (~2 minutes)

## Step 2: Create the Events Table

1. In your Supabase dashboard, go to **Table Editor**
2. Click **"New Table"**
3. Name it: `calendar_events`
4. Add these columns:

| Column Name | Type | Default | Extra Settings |
|------------|------|---------|----------------|
| `id` | `int8` | - | Primary Key, Auto-increment |
| `created_at` | `timestamptz` | `now()` | - |
| `year` | `int4` | - | Required |
| `month` | `int4` | - | Required |
| `day` | `int4` | - | Required |
| `event_text` | `text` | - | Required |
| `event_class` | `text` | - | Required |
| `is_tentative` | `bool` | `false` | - |

5. Click **Save**

## Step 3: Set Up Row Level Security (RLS)

1. Go to **Authentication > Policies**
2. Find your `calendar_events` table
3. Click **"New Policy"**
4. Choose **"Get started quickly"**
5. Select **"Enable read access for all users"**
6. Create another policy for **"Enable insert access for all users"**
7. Create another policy for **"Enable update access for all users"**
8. Create another policy for **"Enable delete access for all users"**

*Note: This gives public access - perfect for a personal calendar. For more security later, you can add authentication.*

## Step 4: Get Your API Keys

1. Go to **Settings > API**
2. Copy your **Project URL** 
3. Copy your **anon/public key**

## Step 5: Update Your Calendar

1. Open `class-calendar.html`
2. Find these lines near the top of the JavaScript:
   ```javascript
   const SUPABASE_URL = 'YOUR_SUPABASE_URL'
   const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY'
   ```
3. Replace with your actual values:
   ```javascript
   const SUPABASE_URL = 'https://your-project-ref.supabase.co'
   const SUPABASE_ANON_KEY = 'your-anon-key-here'
   ```

## Step 6: Deploy & Test

1. Save the file
2. Push to your dhs repository
3. Enable GitHub Pages on the dhs repo
4. Test adding/editing events!

## 🎉 You're Done!

Your calendar will now:
- ✅ Save all changes to Supabase
- ✅ Sync across all devices and browsers  
- ✅ Work on GitHub Pages
- ✅ Fall back to local storage if Supabase is down
- ✅ Keep your existing events

## Troubleshooting

- **Events not saving?** Check the browser console for errors
- **Can't connect?** Verify your URL and API key
- **Policies not working?** Make sure RLS policies allow public access
- **Still having issues?** The calendar falls back to localStorage automatically

---

*Free Supabase tier includes: 500MB database, 2GB bandwidth, 50MB file storage - more than enough for a calendar!*
