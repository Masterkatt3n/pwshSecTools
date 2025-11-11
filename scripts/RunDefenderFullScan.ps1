# RunDefenderFullScan.ps1

$logFile = "$env:USERPROFILE\DefenderFullScan.log"
$timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")

Add-Content -Path $logFile -Value "[$timestamp] Starting full Windows Defender scan..."

try
{
  # Start elevated PowerShell to run the full scan
  Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -Command `"Start-MpScan -ScanType FullScan`"" -Wait

  $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
  Add-Content -Path $logFile -Value "[$timestamp] Full Windows Defender scan completed successfully."
} catch
{
  $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
  Add-Content -Path $logFile -Value "[$timestamp] ERROR: $_"
}

