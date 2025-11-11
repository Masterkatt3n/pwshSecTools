# RunDefenderFullScan.ps1

$logFile = "$env:USERPROFILE\DefenderFullScan.log"
$timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")

Add-Content -Path $logFile -Value "[$timestamp] Starting full Windows Defender scan..."
try {
  # Start elevated PowerShell to run the full scan
  $process = Start-Process powershell -Verb RunAs -ArgumentList @(
    '-NoProfile',
    '-Command',
    'Start-MpScan -ScanType FullScan'
  ) -Wait -PassThru

  $exitCode = $process.ExitCode
  $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
  if ($LASTEXITCODE -eq 0) {
    Add-Content -Path $logFile -Value "[$timestamp] Full Windows Defender scan completed successfully."
  } else {
    Add-Content -Path $logFile -Value "[$timestamp] Defender scan exited with code $exitCode."
  }
} catch {
  $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
  Add-Content -Path $logFile -Value "[$timestamp] ERROR: $($_.Exception.Message)"
}

Write-Host "...FullScan Completed at $timestamp" -ForegroundColor Green
