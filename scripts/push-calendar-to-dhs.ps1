Param(
  [string]$Token
)

<#
Purpose: Quick one-off sync of class-calendar.html to public chelce/dhs repo while actively iterating.
WARNING: Only syncs the whitelisted file (class-calendar.html). Does NOT expose other private repo content.

Usage examples (PowerShell):
  # Using GH fine-grained PAT stored in env var DHS_PAT
  $env:DHS_PAT | ./scripts/push-calendar-to-dhs.ps1

  # Or pass explicitly
  ./scripts/push-calendar-to-dhs.ps1 -Token $env:DHS_PAT

If no token is supplied, a normal https clone is attempted (will prompt if authentication required).
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repo = 'chelce/dhs'
$branch = 'main'
$fileList = @('class-calendar.html')

if (-not $Token -and $env:DHS_PAT) { $Token = $env:DHS_PAT }

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("dhs-sync-" + [System.Guid]::NewGuid())
Write-Host "Temp clone path: $tmp"
New-Item -ItemType Directory -Path $tmp | Out-Null

if ($Token) {
  $cloneUrl = "https://x-access-token:$Token@github.com/$repo.git"
} else {
  $cloneUrl = "https://github.com/$repo.git"
  Write-Warning 'No token provided; relying on cached credentials or public access.'
}

Write-Host "Cloning $repo..."
git clone --depth 1 $cloneUrl $tmp | Out-Null

$changed = $false
foreach ($f in $fileList) {
  $src = Join-Path (Get-Location) $f
  $dest = Join-Path $tmp $f
  if (Test-Path $src) {
    Write-Host "Copying $f"
    Copy-Item -Force $src $dest
    Push-Location $tmp
    if (-not (git diff --quiet -- $f 2>$null)) { $changed = $true }
    Pop-Location
  } else {
    Write-Warning "Source file missing: $f"
  }
}

if ($changed) {
  Push-Location $tmp
  git add $fileList | Out-Null
  $shortSha = (git rev-parse --short HEAD 2>$null) # commit in target repo currently
  git config user.email "calendar-sync-bot@users.noreply.github.com"
  git config user.name "calendar-sync-bot"
  $msg = "Direct push calendar update (source SCHOOL working copy)"
  git commit -m $msg | Out-Null
  Write-Host "Pushing changes to $repo:$branch ..."
  git push origin $branch | Out-Null
  Pop-Location
  Write-Host 'Done.'
} else {
  Write-Host 'No changes detected; nothing to push.'
}

try { Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue } catch { }
