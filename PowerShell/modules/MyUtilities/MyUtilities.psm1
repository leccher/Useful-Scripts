function Add-ToStartup {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ScriptPath
    )

    # Verifica che il file esista
    if (-not (Test-Path $ScriptPath)) {
        Write-Error "File non trovato: $ScriptPath"
        return
    }

    # Ottieni il percorso della cartella Esecuzione Automatica
    $startupPath = [Environment]::GetFolderPath("Startup")
    
    # Crea l'oggetto Shell per gestire i collegamenti
    $WshShell = New-Object -ComObject WScript.Shell
    
    # Definisci il nome e il percorso dello shortcut
    $shortcutName = (Get-Item $ScriptPath).BaseName + ".lnk"
    $shortcutPath = Join-Path $startupPath $shortcutName
    
    # Crea lo shortcut
    $Shortcut = $WshShell.CreateShortcut($shortcutPath)
    $Shortcut.TargetPath = $ScriptPath
    $Shortcut.WorkingDirectory = Split-Path $ScriptPath
    $Shortcut.Save()
    
    Write-Host "Shortcut creato in: $shortcutPath" -foregroundColor Green
}

# THis function tell you if an app in installed
function Is-AppInsalled {
    param (
        # [string]$NomeApp force parametere to be string.
        # Mandatory=$true PowerShell needs it
        [Parameter(Mandatory=$true)]
        [string]$NomeApp
    )

    # Check if it is a command
    $_app_exists = Get-Command $NomeApp -ErrorAction SilentlyContinue
    
    if ($_app_exists) {
        # A path is associated to command
        return $true
    }

    # Going on further
    $_registry_paths = @(
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    return Get-ItemProperty $_registry_paths -ErrorAction SilentlyContinue | 
        Where-Object { $_.DisplayName -like "*$NomeApp*" } |
        Select-Object DisplayName, DisplayVersion, InstallLocation
}

Export-ModuleMember -Function Add-ToStartup, Is-AppInstalled