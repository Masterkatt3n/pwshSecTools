<#
.SYNOPSIS
  pwshSecTools — Personal PowerShell Security & Maintenance Module

.DESCRIPTION
  Provides system-level helpers for secure deletion, random renaming,
  full Microsoft Defender scans, and quick environment sanity checks.
  Integrates PowerShell, Python, and PeaZip securely.

  ✅ No file names from wiped directories are ever logged.
  ✅ Safe-guards against wiping system directories.

.AUTHOR
  Stefan Meyer
.VERSION
  1.0.0
.LICENSE
  MIT
#>

# --- 1. Defender full scan -----------------------------------------------
function Invoke-FullDefenderScan {
  if (-not $IsWindows) {
    Write-Warning "Defender is only available on Windows."
    return
  }
  $scriptPath = Join-Path $PSScriptRoot 'scripts/RunDefenderFullScan.ps1'
  if (-not (Test-Path $scriptPath)) {
    Write-Warning "Defender scan script not found at $scriptPath"
    return
  }
  $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
  Write-Host "Starting Defender FullScan at $timestamp..." -ForegroundColor DarkCyan
  & $scriptPath
}

# --- 2. Secure wipe via PeaZip + random rename ----------------------------
function Invoke-PeaPurge {
  param(
    [Parameter(Mandatory)][ValidateSet("very_fast","fast","medium","slow","very_slow")]
    [string]$Speed,
    [Parameter(Mandatory)][string[]]$Path
  )

  $peaPath = "C:\Program Files\PeaZip\pea.exe"
  $speedOption = "WIPE $($Speed.ToUpper())"

  foreach ($singlePath in $Path) {
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    if (-not (Test-Path $singlePath)) {
      Write-Warning "Path not found: $singlePath"
      continue
    }

    if ($singlePath -match '^(C:\\$|C:\\Windows(\\|$)|C:\\Program Files(\\|$))') {
      Write-Error "Refusing to wipe critical system path: $singlePath"
      continue
    }

    for ($i = 1; $i -le 5; $i++) {
      Write-Host "[$singlePath] Renaming files - Pass $i of 5..." -ForegroundColor DarkRed
      $renameScript = Join-Path $PSScriptRoot 'scripts/rename_files.py'
      python $renameScript $singlePath
    }

    $arguments = "$speedOption `"$singlePath`""
    Write-Host "Wiping [$singlePath] with speed: $Speed at $timestamp..." -ForegroundColor Magenta
    $process = Start-Process -FilePath $peaPath -ArgumentList $arguments -NoNewWindow -Wait -PassThru
    Write-Host "...Wipe completed with exit code: $($process.ExitCode)" -ForegroundColor DarkCyan
  }
}

# --- 3. Random rename utility --------------------------------------------
function Rename-Random {
  param([Parameter(Mandatory)][string]$Path)
  $renameScript = Join-Path $PSScriptRoot 'scripts/rename_files.py'
  if (-not (Test-Path $renameScript)) {
    Write-Warning "Rename script not found at $renameScript"
    return
  }
  python $renameScript $Path
}

# --- 4. Secure file deletion -----------------------------------------------
function Remove-SecureFile {
  <#
        .SYNOPSIS
            Securely overwrite and delete a single file.
        .DESCRIPTION
            Overwrites a file with random bytes for the specified number of passes
            before deleting it. Intended for privacy-focused cleanup of sensitive data.
        .PARAMETER Path
            Path to the target file to be securely deleted.
        .PARAMETER Passes
            Number of overwrite passes (default = 3).
        .EXAMPLE
           Remove-SecureFile -Path "C:\path\to\sensitive-file.txt" -Passes 5

    #>

  param(
    [Parameter(Mandatory)][string]$Path,
    [int]$Passes = 3
  )

  if (-not (Test-Path $Path)) {
    Write-Warning "File not found: $Path"
    return
  }

  try {
    $fileInfo = Get-Item $Path
    $length = $fileInfo.Length

    Write-Host "Overwriting '$Path' with random data ($Passes passes)..." -ForegroundColor DarkYellow

    for ($i = 1; $i -le $Passes; $i++) {
      $bytes = New-Object byte[] $length
      (New-Object System.Random).NextBytes($bytes)
      [System.IO.File]::WriteAllBytes($Path, $bytes)
      Write-Host "  Pass $i/$Passes complete."
    }

    Remove-Item -Path $Path -Force
    Write-Host "✓ Securely deleted: $Path" -ForegroundColor Green
  } catch {
    Write-Error "Failed to securely delete file: $($_.Exception.Message)"
  }
}

# --- 5. Clear Recent Items & Jump Lists ------------------------------------
function Clear-RecentItem {
  <#
        .SYNOPSIS
            Clears Windows Recent Items and Jump List history.
        .DESCRIPTION
            Deletes the contents of %AppData%\Microsoft\Windows\Recent and
            %AppData%\Microsoft\Windows\Recent\AutomaticDestinations to remove
            local file access traces.
        .EXAMPLE
            Clear-RecentItem
    #>

  if (-not $IsWindows) {
    Write-Warning "This function is only supported on Windows."
    return
  }

  $recentPath = Join-Path $env:APPDATA "Microsoft\Windows\Recent"
  $jumpListPath = Join-Path $recentPath "AutomaticDestinations"

  try {
    Write-Host "Clearing Recent Items and Jump Lists..." -ForegroundColor DarkYellow
    if (Test-Path $recentPath) {
      Remove-Item "$recentPath\*" -Force -Recurse -ErrorAction SilentlyContinue 
    }
    if (Test-Path $jumpListPath) {
      Remove-Item "$jumpListPath\*" -Force -Recurse -ErrorAction SilentlyContinue 
    }

    Write-Host "✓ Cleared Recent Items and Jump Lists." -ForegroundColor Green
  } catch {
    Write-Error "Failed to clear Recent Items: $($_.Exception.Message)"
  }
}

# --- 6. Sync helper scripts ----------------------------------------------
function Update-pwshSecToolsModule {
  $srcPS  = Join-Path $HOME 'Documents\PS-skripts\profileScripts'
  $srcPy  = Join-Path $HOME 'Documents\py-scripts\profileScripts'
  $dstDir = Join-Path $HOME 'pwshProfile\Modules\pwshSecTools\scripts'
  $files  = @('RunDefenderFullScan.ps1', 'rename_files.py', 'gen_n_verify-hashes-v2.py')

  foreach ($f in $files) {
    $src = if ($f -like '*.py') {
      Join-Path $srcPy $f 
    } else {
      Join-Path $srcPS $f 
    }
    $dst = Join-Path $dstDir $f
    if (Test-Path $src) {
      Copy-Item $src $dst -Force
      Write-Host "✓ Updated $f" -ForegroundColor Green
    } else {
      Write-Warning "Source missing: $src"
    }
  }

  $modPath = Join-Path $HOME 'pwshProfile\Modules\pwshSecTools\pwshSecTools.psm1'
  if (Test-Path $modPath) {
    Import-Module $modPath -Force
    Write-Host "✓ pwshSecTools module reloaded." -ForegroundColor Cyan
  }
  Write-Host "Update complete." -ForegroundColor Yellow
}

# --- 7. Environment test -------------------------------------------------
function Test-pwshSecToolsSetup {
  $paths = @{
    "Defender script" = Join-Path $PSScriptRoot 'scripts/RunDefenderFullScan.ps1'
    "Rename script"   = Join-Path $PSScriptRoot 'scripts/rename_files.py'
    "Hash script"     = Join-Path $PSScriptRoot 'scripts/gen_n_verify-hashes-v2.py'
    "PeaZip"          = "C:\Program Files\PeaZip\pea.exe"
    "Python"          = (Get-Command python -ErrorAction SilentlyContinue)?.Source
  }

  Write-Host "`n🧩 pwshSecTools environment check:`n" -ForegroundColor Cyan
  foreach ($k in $paths.Keys) {
    if ($paths[$k] -and (Test-Path $paths[$k])) {
      Write-Host ("✓ {0} found: {1}" -f $k, $paths[$k]) -ForegroundColor Green
    } else {
      Write-Host ("✗ {0} missing or not in PATH" -f $k) -ForegroundColor Red
    }
  }

  if ($IsWindows) {
    Write-Host "OS: Windows ✅" -ForegroundColor DarkCyan
  } else {
    Write-Host "OS: Non-Windows ⚠️ (Defender unavailable)" -ForegroundColor Yellow
  }
  Write-Host "`nCheck complete.`n" -ForegroundColor Yellow
}
# --- EOF -----------------------------------------------------------------
Export-ModuleMember -Function `
  Invoke-FullDefenderScan, Invoke-PeaPurge, Rename-Random, `
  Remove-SecureFile, Clear-RecentItem, `
  Update-pwshSecToolsModule, Test-pwshSecToolsSetup
