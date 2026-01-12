# PowerShell Useful Scripts
This section of the Useful Scripts contains some scripts in Power Shell v7 or more.
Not all peaple knows that Power Shell in windows has two souls: one called **Windows Power Shell** 
that is a specific version of powershell used to manage many interfaces and features in windows, 
and **PowerShell**, that is the most evoluted version of powershell and can run over different OS.

The most important thing to know is those are not compatible one with the other.
* Windows PowerShell refers to a 5.x version of the script language
* PoweShell refers to a version grather 7 and is available also in Linux and Mac OS.

This rrepository contains only scripts for **PowerSehll** that are in my opinion useful for a developer using Windows shell.

## Compress scripts
In this folder you can find scripts usefull to pack and unpack files in a folder.

## Curl
Here there is a script that help you to call a remote endpoint sending post data too.

## Environment
Here there is a script to recursive solve windows environment variables that otherway are solved just at first level.

## Logger
A script that let you use a common logging level management for your script.

## Python utilities
Some scripts to help you browsing in Windows your folders and enabling, if there are, the desired python virtual environment, 
jupyter lab if inside and changing system python version if installed. You can create a specific python virtual enviroment version
if you have it installed in your system.

# Powerhell integration
For integrating scripts inside powershell session, you can check which is the value of %PROFILE% and in that file, after adding reference to the script file you want integrate, you can choose 2 ways:
* override Set-Location function
```PowerShell
function Set-Location {
    param (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [Alias("Path")]
        [string]$LiteralPath
    )
    try {
		# Usa il comando originale per cambiare directory
		Microsoft.PowerShell.Management\Set-Location -LiteralPath $LiteralPath -ErrorAction Stop
		if($env:DISABLE_CUSTOM_FUNCTION_FOR_DIRECTORY_WALKING){
			# Cancella la variabile di ambiente
			Remove-Item env:DISABLE_CUSTOM_FUNCTION_FOR_DIRECTORY_WALKING
		}else{
			# Chiama la funzione per monitorare il cambiamento
			Enable-PythonVirtualEnviroment-AndJupyter
		}
	} catch {
		Write-Host "Folder not found $LiteralPath"
		return ${Code=-1;Value="Folder $LiteralPath not exists"}
	}
}
```
* override "prompt" function
