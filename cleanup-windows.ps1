<#
cleanup-windows.ps1
Safe Windows cleanup helper prepared by Somi assistant.
USAGE:
  1) Open PowerShell (normal privileges ok; for symlink creation admin may be required).
  2) cd "D:\\somi-work\\hello-world-eclipse"
  3) .\cleanup-windows.ps1 -WhatIfListBigFiles    # just show big files
  4) .\cleanup-windows.ps1 -DoTempCleanup        # remove temp files
  5) .\cleanup-windows.ps1 -MoveM2ToD -Target D:\\m2_repo  # move .m2 to D:

Options:
  -WhatIfListBigFiles : List top 40 largest files on C: (no deletion)
  -DoTempCleanup      : Empty %TEMP% and C:\Windows\Temp (non-reversible)
  -MoveM2ToD -Target  : Move %USERPROFILE%\.m2 to target (D:\m2_repo) and create symlink.
                         (Creates backup at %USERPROFILE%\.m2_backup. Requires admin for symlink.)
#>
param(
    [switch]$WhatIfListBigFiles,
    [switch]$DoTempCleanup,
    [switch]$MoveM2ToD,
    [string]$Target = "D:\\m2_repo"
)

function List-BigFiles {
    Write-Host "Scanning C: for largest files (may take a minute)..."
    Get-ChildItem -Path C:\ -Recurse -ErrorAction SilentlyContinue -Force |
      Where-Object {!$_.PSIsContainer} |
      Sort-Object Length -Descending |
      Select-Object -First 40 FullName,@{Name='MB';Expression={[math]::Round($_.Length/1MB,2)}} |
      Format-Table -AutoSize
}

function Do-TempCleanup {
    Write-Host "Cleaning %TEMP%: $env:TEMP"
    try {
        Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Cleared user TEMP."
    } catch {
        Write-Warning "Some temp files could not be deleted."
    }
    Write-Host "Cleaning C:\\Windows\\Temp"
    try {
        cmd /c "del C:\\Windows\\Temp\\* /s /q" | Out-Null
        Write-Host "Requested deletion in C:\\Windows\\Temp (some files in use may remain)."
    } catch {
        Write-Warning "Failed to clean C:\\Windows\\Temp"
    }
    Write-Host "Emptying Recycle Bin..."
    try {
        (New-Object -ComObject Shell.Application).NameSpace(0xA).Items() | ForEach-Object { Remove-Item $_.Path -Recurse -Force -ErrorAction SilentlyContinue }
        Write-Host "Recycle Bin emptied (best-effort)."
    } catch {
        Write-Warning "Recycle Bin could not be emptied automatically."
    }
}

function Move-M2 {
    param($TargetPath)
    $userM2 = Join-Path $env:USERPROFILE ".m2"
    $backup = Join-Path $env:USERPROFILE ".m2_backup_$(Get-Date -Format yyyyMMddHHmmss)"

    if (-Not (Test-Path $userM2)) {
        Write-Host "%USERPROFILE%\.m2 not found; nothing to move."; return
    }
    if (-Not (Test-Path (Split-Path $TargetPath -Parent))) {
        Write-Host "Creating target parent: $(Split-Path $TargetPath -Parent)"
        New-Item -ItemType Directory -Path (Split-Path $TargetPath -Parent) -Force | Out-Null
    }
    Write-Host "Moving $userM2 to $TargetPath (backup -> $backup)"
    try {
        Move-Item -Path $userM2 -Destination $backup -Force
        New-Item -ItemType Directory -Path $TargetPath -Force | Out-Null
        Move-Item -Path $backup -Destination $TargetPath
        Write-Host "Moved .m2 to $TargetPath"
        Write-Host "Creating symbolic link from $userM2 -> $TargetPath"
        New-Item -ItemType SymbolicLink -Path $userM2 -Target $TargetPath
        Write-Host "Symlink created."
    } catch {
        Write-Warning "Failed to move/create symlink: $_"
        Write-Host "Attempting to restore backup if exists..."
        if (Test-Path $backup) { Move-Item -Path $backup -Destination $userM2 -Force }
    }
}

if ($WhatIfListBigFiles) { List-BigFiles; exit }
if ($DoTempCleanup) { Do-TempCleanup; exit }
if ($MoveM2ToD -or $MoveM2ToD) { Move-M2 -TargetPath $Target; exit }

Write-Host "No option specified. Usage:`n .\cleanup-windows.ps1 -WhatIfListBigFiles`n .\cleanup-windows.ps1 -DoTempCleanup`n .\cleanup-windows.ps1 -MoveM2ToD -Target D:\\m2_repo"
