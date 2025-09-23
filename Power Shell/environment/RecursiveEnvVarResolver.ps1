function Resolve-EnvVaraibleRecursive {
	param (
		[Parameter(Mandatory=$true)]
		[string]$envVarName
	)
	$debugEnabled = $false
	if ($debugEnabled) {
		Write-Host -NoNewLine "Working with:" -ForegroundColor Red
		Write-Host $envVarName
	}
	#$envVarValue = (Get-Item "Env:$envVarName").value
	$envVarValue = [System.Environment]::GetEnvironmentVariable($envVarName)
	if ($envVarValue) {
		if ($debugEnabled) {
		Write-Host -NoNewLine "With value:" -ForegroundColor Red
		Write-Host $envVarValue
		}
	} else {
		if ($debugEnabled) {
		Write-Output -NoNewLine "ERROR 1:"
		Write-Output $nuVarValue " is not defined"
		}
		return @{Code=-1;Value="Error " + $nuVarValue + " not defined"}
	}
	$envVars = [regex]::Matches($envVarValue, '%(\w+)%')
	if ($envVars.Count -gt 0) {
		if ($debugEnabled) {
		Write-Host -NoNewLine "Having inside:"  -ForegroundColor Red
		Write-Host $envVars
		}
	}
	foreach ($envVar in $envVars) {
		$nuVarValue = Resolve-EnvVaraibleRecursive($envVar.Groups[1].Value)
		if ($nuVarValue.Code -lt 0) {
			continue
		}
		if ($debugEnabled) {
		Write-Host -NoNewLine "Value returned:" -ForegroundColor Red
		Write-Host $nuVarValue
		}
		# Replacing %VAR_NAME% con var_value in envVarValue
		$envVarValue = $envVarValue.Replace("%" + $envVar.Value + "%", $nuVarValue)
	}
	
	return @{Code=0;Value=$envVarValue}
}

function Resolve-EnvVaraibleRecursive-Wrapper {
	param (
		[Parameter(Mandatory=$true)]
		[string]$envVarName
	)
	$result = Resolve-EnvVaraibleRecursive($envVarName)
	if ($result.Code -ne 0) {
		Write-Host -noNeLine "Warning: "
		Write-Host $result.Value
	}
}

function Resolve-EnvVaraibleRecursive-Module-Help {
	Write-Host "Resolve Windows Environmbent Varaible module"
	Write-Host "This module resolves recursively the variables inside windows envromment."
	Write-Host "This aims to refer to a value in a variable inside another variable and so on deeply."
	Write-Host ""
	Write-Host "Usage:"
	Write-Host 'Resolve-EnvVaraibleRecursive("PATH")'
	Write-Host "To have no results but just using the function"
	Write-Host 'Resolve-EnvVaraibleRecursive-Wrapper("PATH")'
}

Write-Host "Module Windows Recursive Variable Enviroment Resolver enabled (see Resolve-EnvVaraibleRecursive-Module-Help for usage)"
