# THis function tell you if an app in installed
function isAppInsalled {
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