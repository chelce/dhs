<#!
Tests the Supabase calendar_events table after migration to uuid + soft delete.
Steps:
 1. Fetch sample rows (verify uuid + timestamps)
 2. Insert/Upsert a test event (uuid id)
 3. Retrieve that event
 4. Soft delete it (set deleted_at)
 5. Confirm it disappears from active filter (deleted_at is null)
 6. Output summary
Uses anon key – assumes RLS permits these actions for anon.
!>

param(
    [string]$ProjectUrl = 'https://dfqjhgftmhdsjlcdaaxk.supabase.co',
    [string]$AnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRmcWpoZ2Z0bWhkc2psY2RhYXhrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA4MDY0NTEsImV4cCI6MjA2NjM4MjQ1MX0.iu1OH2wV6hjV9EhxkFBwqSApcy6uRn0b40AOc9yJ0Yk'
)

$ErrorActionPreference = 'Stop'

function Write-Section($title) { Write-Host "`n==== $title ====\n" -ForegroundColor Cyan }

function Invoke-CalApi {
    param(
        [string]$Method = 'GET',
        [string]$Path,
        [object]$Body = $null,
        [hashtable]$Query = @{},
        [switch]$ReturnRaw
    )
    $uri = "$ProjectUrl/rest/v1/$Path"
    if ($Query.Count) {
        $q = $Query.GetEnumerator() | ForEach-Object { "{0}={1}" -f [uri]::EscapeDataString($_.Key), [uri]::EscapeDataString($_.Value) }
        $uri = "$uri?$(($q -join '&'))"
    }
    $headers = @{ apikey = $AnonKey; Authorization = "Bearer $AnonKey" }
    if ($Method -in 'POST','PATCH','PUT') { $headers['Prefer'] = 'resolution=merge-duplicates,return=representation' }
    if ($Body -ne $null) { $json = ($Body | ConvertTo-Json -Depth 6) }
    Write-Host "-> $Method $uri" -ForegroundColor DarkGray
    $resp = Invoke-RestMethod -Method $Method -Uri $uri -Headers $headers -ContentType 'application/json' -Body $json -ErrorAction Stop
    if ($ReturnRaw) { return $resp }
    return $resp | ConvertTo-Json -Depth 6
}

Write-Section '1. Sample rows'
try { Invoke-CalApi -Path 'calendar_events' -Query @{ select='id,created_at,updated_at,deleted_at,event_text,event_date'; order='updated_at.desc'; limit='3' } } catch { Write-Warning $_ }

# Generate test uuid in PowerShell (fallback to .NET GUID)
$testId = [guid]::NewGuid().ToString()
$today = Get-Date -Format 'yyyy-MM-dd'
$dateObj = Get-Date
$body = @(
    @{ id=$testId;
       event_date=$today;
       year=$dateObj.Year;
       month=([int]([int]$dateObj.Month - 1)); # 0-based to match frontend logic
       day=$dateObj.Day;
       event_text='Backend Test Event';
       event_class='reflection';
       is_tentative=$false;
       notes='(auto test)';
       created_at=(Get-Date).ToString('o');
       updated_at=(Get-Date).ToString('o');
       deleted_at=$null }
)

Write-Section '2. Upsert test event'
Invoke-CalApi -Method POST -Path 'calendar_events' -Body $body

Start-Sleep -Milliseconds 500

Write-Section '3. Fetch test event (active)'
Invoke-CalApi -Path 'calendar_events' -Query @{ select='id,event_text,deleted_at'; id="eq.$testId" }

Write-Section '4. Soft delete test event'
$softBody = @(
    @{ id=$testId; deleted_at=(Get-Date).ToString('o') }
)
Invoke-CalApi -Method POST -Path 'calendar_events' -Body $softBody

Start-Sleep -Milliseconds 300

Write-Section '5. Confirm exclusion from active filter'
Invoke-CalApi -Path 'calendar_events' -Query @{ select='id,event_text,deleted_at'; id="eq.$testId"; deleted_at='is.null' }

Write-Section '6. Fetch soft-deleted row directly'
Invoke-CalApi -Path 'calendar_events' -Query @{ select='id,event_text,deleted_at'; id="eq.$testId" }

Write-Host "`nTest Completed. If section 5 returned an empty array and section 6 shows deleted_at timestamp, soft delete works." -ForegroundColor Green
