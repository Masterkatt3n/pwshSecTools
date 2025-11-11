@{
  RootModule        = "pwshSecTools.psm1"
  ModuleVersion     = "1.0.0"
  GUID              = "b93d1ab4-10a4-47b2-9d67-1b2b0ac435f2"
  Author            = "Stefan Meyer"
  Description       = "PowerShell helper module providing secure deletion, renaming, and maintenance utilities."
  PowerShellVersion = "7.0"
  FunctionsToExport = @("Invoke-FullDefenderScan","Invoke-PeaPurge","Rename-Random","Remove-SecureFile","Clear-RecentItem","Update-pwshSecToolsModule","Test-pwshSecToolsSetup")
}