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
    
    Write-Host "Shortcut creato in: $shortcutPath" -ForegroundColor Green
}