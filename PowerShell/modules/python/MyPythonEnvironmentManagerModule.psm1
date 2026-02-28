# ==============================================================================
# Python Environment Manager Module
# Require: PowerShell 7.0+
# ==============================================================================

# Controllo versione PowerShell all'importazione
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Warning "Il modulo Python Manager richiede PowerShell 7.0 o superiore. Versione attuale: $($PSVersionTable.PSVersion)"
    return
}

$script:debugEnabled = $false
# --- FUNZIONI INTERNE / PRIVATE ---

function Fix-Path {
    <# .SYNOPSIS 
    Espande le variabili d'ambiente nel PATH e rimuove i duplicati. 
    #>
    if ($script:debugEnebled) {
        Write-Host "Called Fix-Path ..."
    }
    $currentPaths = $env:PATH -split ';' | Where-Object { $_ -ne '' }
    $cleanPaths = foreach ($p in $currentPaths) {
        [Environment]::ExpandEnvironmentVariables($p)
    }
    $env:PATH = ($cleanPaths | Select-Object -Unique) -join ';'
}

function Get-CurrentPythonVersion {
    if ($script:debugEnebled) {
        Write-Host "Called Fix-Path ..." -ForegroundColor yellow
    }
    try {
        $rawVersion = python --version 2>&1 | Out-String
        if ($script:debugEnebled) {
            Write-Host $rawVersion -ForegroundColor yellow
        }        
        if ($rawVersion -match '(\d+\.\d+(\.\d+)?)') {
            if ($script:debugEnebled) {
                Write-Host "It is in x.y.z format!" -ForegroundColor yellow
            }
            return @{ Code = 0; Value = $Matches[1]; Message = "Python attuale: $($Matches[1])" }
        }
        if ($script:debugEnebled) {
            Write-Host "It is not in x.y.z format" -ForegroundColor yellow
        }
        return @{ Code = 1; Value = $null; Message = "Bad version format." }
    }
    catch {
        if ($script:debugEnebled) {
            Write-Host "Python command not found in PATH." -ForegroundColor yellow
        }
        return @{ Code = -1; Value = $null; Message = "Python command not found in PATH." }
    }
}

# --- FUNZIONI CORE (Exportabili) ---

function Set-PythonVersion {
    param ([Parameter(Mandatory=$true)][string]$Version)
    
    $cv = Get-CurrentPythonVersion
    if ($Version -eq $cv.Value) {
		if ($script:debugEnabled) {
			Write-Host "$Version is the current active!!" -ForegroundColor Yellow
		}
        return @{ Code = 0; Value = $Version; Message = "Versione $Version già attiva." }
    }

    $pythonEnvPaths = @{}
    $prefix = "PYTHON_HOME_"
    Get-ChildItem Env: | Where-Object { $_.Name -like "$prefix*" } | ForEach-Object {
		if ($script:debugEnabled) {
			Write-Host "Found $_" -ForegroundColor Yellow
		}
        $v = $_.Name.Substring($prefix.Length).Replace("_", ".")
        $pythonEnvPaths[$v] = $_.Value
    }
    if ($script:debugEnabled) {
        Write-Host "Isolated:" -ForegroundColor Yellow
        Write-Host "$pythonEnvPaths" -ForegroundColor Yellow
    }

    if ($pythonEnvPaths.ContainsKey($Version)) {
        $targetPath = $pythonEnvPaths[$Version]
        $env:PYTHON_HOME = $targetPath
        [System.Environment]::SetEnvironmentVariable("PYTHON_HOME", $targetPath, "User")
        
        $mPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
        $uPath = [Environment]::GetEnvironmentVariable("PATH", "User")
        $env:PATH = "$mPath;$uPath"
        Fix-Path
        return @{ Code = 0; Value = $Version; Message = "Switch a Python $Version eseguito." }
    }
    
    $available = ($pythonEnvPaths.Keys | Sort-Object) -join ", "
    if ($script:debugEnabled) {
        Write-Host "Avaliables:" -ForegroundColor Yellow
        Write-Host "$available" -ForegroundColor Yellow
    }
    return @{ Code = -1; Value = $null; Message = "Versione non supportata. Disponibili: $available" }
}

function Create-PythonVenv {
    param ([string]$Version, [string]$Name)
    
    if (-not $Version) { $Version = (Get-CurrentPythonVersion).Value }
    else {
        $res = Set-PythonVersion -Version $Version
        if ($res.Code -ne 0) { return $res }
    }

    if ([string]::IsNullOrWhiteSpace($Name)) {
        $Name = Read-Host "Nome/Suffisso per il venv (Invio per default)"
    }

    $venvName = if ($Name) { ".venv_${Version}_${Name}" } else { ".venv_$Version" }

    if (-not (Test-Path $venvName)) {
        Write-Host "Creazione venv: $venvName..." -ForegroundColor Cyan
        & python -m venv $venvName
    }
    return @{ Code = 0; Value = $venvName; Message = "Venv pronto: $venvName" }
}

function Get-PythonVenv {
    if ($Env:TERM_PROGRAM -eq "vscode") { return @{ Code = 1; Value = "vscode" } }

    $folders = Get-ChildItem -Directory -Filter ".venv*"
    if (-not $folders) { return @{ Code = -1; Message = "Nessun venv trovato." } }

    Write-Host "`nScegli l'ambiente virtuale:" -ForegroundColor Cyan
    for ($i=0; $i -lt $folders.Count; $i++) {
        Write-Host "$($i+1). $($folders[$i].Name)"
    }

    $sel = Read-Host "Numero (0 per uscire, default 1)"
    if ($sel -eq "0") { return @{ Code = 0; Message = "Annullato." } }
    if ([string]::IsNullOrWhiteSpace($sel)) { $sel = 1 }

    $idx = [int]$sel - 1
    if ($idx -ge 0 -and $idx -lt $folders.Count) {
        return @{ Code = 2; Value = $folders[$idx].Name }
    }
    return @{ Code = -1; Message = "Scelta non valida." }
}

function Enable-PythonVenv {
    param ([string]$Folder)
    
    $target = $Folder
    if (-not $target) {
        $sel = Get-PythonVenv
        if ($sel.Code -eq 2) { $target = $sel.Value }
        elseif ($sel.Code -lt 0) { $target = (Create-PythonVenv).Value }
        else { return $sel }
    }

    $act = Join-Path $target "Scripts\Activate.ps1"
    if (Test-Path $act) {
        & $act
        return @{ Code = 0; Value = $target; Message = "Attivato $target" }
    }
    return @{ Code = -1; Message = "Script attivazione non trovato." }
}

function Start-JupyterLab {
    param ([Parameter(Mandatory=$true)]$Folder)
    $bin = Join-Path $Folder "Scripts\jupyter-lab.exe"
    if (Test-Path $bin) {
        $choice = Read-Host "Avviare Jupyter Lab? (y/n)"
        if ($choice -eq 'y') { & $bin; return @{ Code = 0; Message = "Jupyter avviato." } }
    }
    return @{ Code = 1; Message = "Jupyter non presente o rifiutato." }
}

# --- WRAPPERS PUBBLICI (Interfaccia Modulo) ---

function Enable-MPMVenv {
    param ([string]$Folder)
    $res = Enable-PythonVenv -Folder $Folder
    if ($res.Code -eq 0) { Write-Host $res.Message -ForegroundColor Green }
    else { Write-Warning $res.Message }
    return $res
}

function Enable-MPMVenvAndJupyterLab {
    $res = Get-PythonVenv
    if ($res.Code -eq 0) {
        Start-JupyterLab -Folder $res.Value
    }
}

function Show-MPMHelp {
    Write-Host "`n--- Python Manager Module Help ---" -ForegroundColor Yellow
    $help_functions.GetEnumerator() | Sort-Object Name | ForEach-Object {
        Write-Host "$($_.Name):" -NoNewline -ForegroundColor Cyan
        Write-Host " $($_.Value)"
    }
}

$help_functions = @{
    "Show-MPMHelp"            = "Mostra questo aiuto."
    "Enable-MPMVenv"    = "Sceglie o crea un venv e lo attiva."
    "Enable-MPMVenvAndJupyterLab" = "Attiva venv e chiede di avviare Jupyter."
    "Register-MPMPythonVersion" = "Registra una nuova installazione di Python nelle variabili d'ambiente."
}

Export-ModuleMember -Function Help-MPM, Enable-MPMVenvAndJupyterLab, Enable-MPMVenv, Register-MPMPythonVersion