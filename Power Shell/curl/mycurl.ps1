# Parameters
param (
	[string]$method,        # HTTP method used
    [string]$json,  # JSON file path
    [string]$apiUrl         # Te url to api
)

# help
function Show-Help {
    Write-Host "Uso del comando:"
    Write-Host "  .\mycurl.ps1 -method <GET|POST> -jsonFilePath <path_to_json_file> -apiUrl <api_url>"
    Write-Host ""
    Write-Host "Descrizione:"
    Write-Host "  Questo script invia un file JSON a un URL specificato tramite una richiesta POST."
    Write-Host ""
    Write-Host "Parametri:"
	Write-Host "  -help   : Mostra questo metodo"
	Write-Host "  -method : Metodo usato"
    Write-Host "  -json	  : Percorso del file JSON da inviare o stringa json (obbligatorio)"
    Write-Host "  -apiUrl : URL del servizio web a cui inviare la richiesta (obbligatorio)"
    Write-Host ""
    Write-Host "Esempio di utilizzo:"
    Write-Host "  .\mycurl.ps1  -method <GET|POST> -jsonFilePath 'C:\path\to\your\data.json' -apiUrl 'http://localhost:8000/atlantis/relatedrisks/'"
}

if ($method -eq "help") {
    Write-Host "Errore: Il parametro -apiUrl è obbligatorio."
    Show-Help
    exit 0
}

# Array of HTTP method
$methods = @("GET", "PUT", "POST", "DELETE", "PATCH", "HEAD", "OPTIONS", "TRACE")
$getmethods = @("GET", "HEAD", "OPTIONS", "TRACE")
$postmethods = @("PUT", "POST", "DELETE", "PATCH")
# I need apiUrl
if (-not $apiUrl) {
    Write-Host "Errore: Il parametro -apiUrl è obbligatorio."
    Show-Help
    exit -1
}

# Check if URL is valid
if ($apiUrl -notmatch "^https?://") {
    Write-Host "Error: Specific URL is not valid: $apiUrl"
    exit -1
}

if (-not $method) {
	if (-not $json) {
		$method="GET"
	}else{
		$method="POST"
	}
}else{
	if (-not $methods.contains($method)) {
		Write-Output "Method param should be in $($methods -join ', ')"
		exit -1
	}
}
if ($json) {
	if ( -not $postmethods.contains($method)) {
		Write-Host "Error: Specific method should be $($postmethods -join ', '): $method"
		exit -1
	}
	# Check if JSON file esists
	if (Test-Path $json) {
		# Load JSON conent as string
		$json = Get-Content -Path $json -Raw
	}
	# Send request with JSON
	$response = Invoke-RestMethod -Uri $apiUrl -Method $method -Body $json -ContentType "application/json"
}else{
	if ( -not $getmethods.contains($method)) {
		Write-Host "Error: Specific method should be $($getmethods -join ', '): $method"
		exit -1
	}
	$response = Invoke-RestMethod -Uri $apiUrl -Method $method
}

# Print the answer
$response