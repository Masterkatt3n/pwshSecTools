
# pwshSecTools

**Personal PowerShell security & maintenance utilities** — a compact, modular helper module for PowerShell (Windows).

## Overview
`pwshSecTools` bundles a small set of safe, well-tested utilities for secure deletion, random renaming, running Defender scans, and quick environment checks. It is intended as a *personal* toolkit and a clean, portable base for dotfile/dotprofile setups.

## Features
- Secure deletion (random overwrite + rename + truncate + delete)
- Secure directory purge using PeaZip (`Invoke-PeaPurge`)
- Random renaming helper (`Rename-Random`)
- Full Microsoft Defender scan launcher (`Invoke-FullDefenderScan`)
- Recent items / Jump Lists cleanup (`Clear-RecentItem`)
- Simple self-update helper (`Update-pwshSecToolsModule`)
- Environment sanity check (`Test-pwshSecToolsSetup`)

## Dependencies
- **PowerShell 7.x or newer** (tested on 7.4)
- **Python 3.10+** (for `rename_files.py` and the included optional hash tool)
- **PeaZip** (CLI: `C:\Program Files\PeaZip\pea.exe`) — used by `Invoke-PeaPurge`

## Quick install (local)
```powershell
# Extract zip into your pwshProfile Modules folder
Expand-Archive pwshSecTools-final.zip -DestinationPath "$HOME\pwshProfile\Modules\"

# Import into current session
Import-Module "$HOME\pwshProfile\Modules\pwshSecTools\pwshSecTools.psm1" -Force

# Optional: check dependencies
Test-pwshSecToolsSetup
```

## Usage examples
```powershell
# Full Defender scan (elevated)
Invoke-FullDefenderScan

# Securely wipe folders (no filenames or paths are logged)
Invoke-PeaPurge -Speed fast -Path "D:\sensitive" ,"E:\old_backups"

# Randomly rename files in a folder
Rename-Random -Path "D:\staging\to_wipe"

# Remove a single file securely
Remove-SecureFile -Path "D:\secret\passwords.txt" -Passes 5

# Clear Recent Items & Jump Lists
Clear-RecentItem

# Update module helper scripts and reload
Update-pwshSecToolsModule

# Run quick environment check
Test-pwshSecToolsSetup
```

## Maintenance & license
This is a personal project intended primarily for reference and demonstration. I will update it occasionally; community contributions are welcome but may not be merged promptly.

Licensed under the **MIT License** — see `LICENSE` for details.
