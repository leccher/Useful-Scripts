# ==============================================================================
# Module: MEMM (Management Environment Modulo)
# ==============================================================================

$script:debugEnabled = $false

function Resolve-EnvVariableRecursive {
    param (
        [Parameter(Mandatory=$true)]
        [string]$envVarName
    )

    if ($script:debugEnabled) {
        Write-Host "[DEBUG] Analisi variabile: $envVarName" -ForegroundColor Yellow
    }

    # Recupero il valore grezzo dalla memoria
    $envVarValue = [System.Environment]::GetEnvironmentVariable($envVarName)

    if (-not $envVarValue) {
        return @{Code=-1; Value="Errore: Variabile '$envVarName' non definita"; Message="Not Found"}
    }

    if ($script:debugEnabled) {
        Write-Host "[DEBUG] Valore trovato: $envVarValue" -ForegroundColor Gray
    }

    # Regex per trovare pattern %VARIABILE%
    $matches = [regex]::Matches($envVarValue, '%(\w+)%')
    
    if ($matches.Count -gt 0) {
        # Estraggo i nomi univoci delle variabili trovate all'interno
        $nestedVars = $matches | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique

        foreach ($nestedName in $nestedVars) {
            # CHIAMATA RICORSIVA (Nota: senza parentesi)
            $subResult = Resolve-EnvVariableRecursive -envVarName $nestedName
            
            if ($subResult.Code -eq 0) {
                $oldValue = "%$nestedName%"
                $newValue = $subResult.Value
                
                if ($script:debugEnabled) {
                    Write-Host "[DEBUG] Sostituzione $oldValue -> $newValue" -ForegroundColor DarkGray
                }
                $envVarValue = $envVarValue.Replace($oldValue, $newValue)
            }
        }
    }

    return @{Code=0; Value=$envVarValue}
}

function Resolve-MEMMRecursiveVariable {
    param (
        [Parameter(Mandatory=$true)]
        [string]$envVarName
    )
    
    $result = Resolve-EnvVariableRecursive -envVarName $envVarName
    
    if ($result.Code -ne 0) {
        Write-Warning "MEMM: $($result.Value)"
    } else {
        # AGGIORNAMENTO: Usiamo [System.Environment] per maggiore stabilità con variabili lunghe come PATH
        $envPath = "Env:$envVarName"
        Set-Item -Path $envPath -Value $result.Value
        Write-Log "Variable '$envVarName' successfully resolved." -ForegroundColor Green
    }
}

function Set-MEMMDebug {
    param (
        [Parameter(Mandatory=$true)]
		[bool]$debug
	)
    $script:debugEnabled = $debug
    Write-Host "Debug Mode: $script:debugEnabled" -ForegroundColor Cyan
}

function Show-MEMMHelp {
    Write-Host "`n--- My Environment Manager Module ---" -ForegroundColor Cyan
    Write-Host "Resolve recursively references among environment variables (eg. %VAR%)."
    Write-Host "`nAvailable commands:"
    Write-Host "  Resolve-MEMMRecursiveVariable 'NOME_VAR' : Resolve and apply to current session."
    Write-Host "  Set-MEMMDebug `$true/`$false              : Enable/Disable detailed logs."
    Write-Host "`nExample:"
    Write-Host "  Resolve-MEMMRecursiveVariable 'PATH'"
}

Export-ModuleMember -Function Show-MEMMHelp, Resolve-MEMMRecursiveVariable, Set-MEMMDebug