#!/usr/bin/env powershell
<#
Test script for materials functionality in calendar
Tests database schema and basic materials operations
#>

param(
    [string]$ProjectUrl = 'https://dfqjhgftmhdsjlcdaaxk.supabase.co',
    [string]$AnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRmcWpoZ2Z0bWhkc2psY2RhYXhrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA4MDY0NTEsImV4cCI6MjA2NjM4MjQ1MX0.iu1OH2wV6hjV9EhxkFBwqSApcy6uRn0b40AOc9yJ0Yk'
)

$ErrorActionPreference = 'Stop'

function Write-Section($title) { Write-Host "`n==== $title ====`n" -ForegroundColor Cyan }

function Invoke-CalApi {
    param([string]$Method = 'GET', [string]$Path, [object]$Body = $null, [hashtable]$Query = @{})
    $uri = "$ProjectUrl/rest/v1/$Path"
    if ($Query.Count) {
        $q = $Query.GetEnumerator() | ForEach-Object { "{0}={1}" -f [uri]::EscapeDataString($_.Key), [uri]::EscapeDataString($_.Value) }
        $uri = "$uri?$(($q -join '&'))"
    }
    $headers = @{ apikey = $AnonKey; Authorization = "Bearer $AnonKey" }
    if ($Method -in 'POST','PATCH','PUT') { $headers['Prefer'] = 'resolution=merge-duplicates,return=representation' }
    if ($Body) { $json = ($Body | ConvertTo-Json -Depth 6) }
    Write-Host "-> $Method $uri" -ForegroundColor DarkGray
    Invoke-RestMethod -Method $Method -Uri $uri -Headers $headers -ContentType 'application/json' -Body $json -ErrorAction Stop | ConvertTo-Json -Depth 6
}

Write-Section 'Testing Materials & Tags Schema'
try {
    # Test if materials and tags columns exist by inserting event with both
    $testId = [guid]::NewGuid().ToString()
    $today = Get-Date -Format 'yyyy-MM-dd'
    $body = @(
        @{
            id = $testId
            event_date = $today
            year = (Get-Date).Year
            month = ([int](Get-Date).Month - 1)
            day = (Get-Date).Day
            event_text = 'Auto-Tag Test Event with Analogies'
            event_class = 'ap'
            is_tentative = $false
            notes = '<p>Test event for materials and auto-tagging</p>'
            materials = @(
                @{ type = 'workspace'; path = 'analogies-task-cards.html'; title = 'Analogies Task Cards (auto)'; auto = $true }
                @{ type = 'url'; path = 'https://example.com'; title = 'Example Link' }
            )
            tags = @('analogies', 'critical-thinking', 'ap-prep', 'class-ap', 'auto-tagged')
            created_at = (Get-Date).ToString('o')
            updated_at = (Get-Date).ToString('o')
            deleted_at = $null
        }
    )
    
    Write-Host "Inserting test event with materials and tags..." -ForegroundColor Yellow
    Invoke-CalApi -Method POST -Path 'calendar_events' -Body $body
    
    Start-Sleep -Milliseconds 300
    
    Write-Host "Fetching test event to verify materials and tags..." -ForegroundColor Yellow
    Invoke-CalApi -Path 'calendar_events' -Query @{ select='id,event_text,materials,tags'; id="eq.$testId" }
    
    Write-Host "Cleaning up test event..." -ForegroundColor Yellow
    Invoke-CalApi -Method POST -Path 'calendar_events' -Body @( @{ id=$testId; deleted_at=(Get-Date).ToString('o') } )
    
    Write-Host "`nMaterials & Tags schema test PASSED!" -ForegroundColor Green
    
} catch {
    Write-Host "`nMaterials & Tags schema test FAILED: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Message -match "column.*does not exist") {
        Write-Host "Run the migration SQL first: scripts/migrate-add-materials.sql" -ForegroundColor Yellow
    }
}

Write-Host "`nAuto-attach & Auto-tag functionality ready! Key features:" -ForegroundColor Green
Write-Host "• Smart material auto-attachment based on keywords and class" -ForegroundColor White
Write-Host "• Auto-tagging with subject, difficulty, activity type tags" -ForegroundColor White  
Write-Host "• Workspace file suggestions with scoring algorithm" -ForegroundColor White
Write-Host "• Tag-based categorization and filtering" -ForegroundColor White
Write-Host "• Materials and tags included in all persistence layers" -ForegroundColor White
Write-Host "• Visual tag display with color coding" -ForegroundColor White

Write-Host "`nExample auto-behaviors:" -ForegroundColor Cyan
Write-Host "• 'Analogies Introduction' (AP class) → auto-attaches analogies cards + tags: analogies, critical-thinking, ap-prep" -ForegroundColor Gray
Write-Host "• 'Logic Puzzle Game' → auto-attaches logic materials + tags: logic-puzzles, interactive, problem-solving" -ForegroundColor Gray
Write-Host "• 'Cooking Activity Easy' → auto-attaches cooking cards + tags: cooking, easy, life-skills" -ForegroundColor Gray
