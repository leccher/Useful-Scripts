# Parameters
param (
	[string]$method, 	# HTTP method used
    [string]$json,  	# JSON file path
    [string]$apiUrl 	# Te url to api
)

# help
function Show-Help {
    Write-Host "Script usage:"
    Write-Host "  .\mycurl.ps1 -method <GET|POST> -jsonFilePath <path_to_json_file> -apiUrl <api_url>"
    Write-Host ""
    Write-Host "Description:"
    Write-Host "  This script send a JSON to a destination URL using a POST request."
    Write-Host ""
    Write-Host "Params:"
	Write-Host "  -help   : Show this help"
	Write-Host "  -method : Used method"
    Write-Host "  -json	  : Path to file to sand or a json string (needed)"
    Write-Host "  -apiUrl : URL of web service to send the message to (needed)"
    Write-Host ""
    Write-Host "Esempio di utilizzo:"
    Write-Host "  .\mycurl.ps1  -method <GET|POST> -jsonFilePath 'C:\path\to\your\data.json' -apiUrl 'http://localhost:8000/atlantis/relatedrisks/'"
}

if ($method -eq "help") {
    Write-Host "Error: -apiUrl parameter is needed."
    Show-Help
    exit 0
}

# Array of HTTP method
$methods = @("GET", "PUT", "POST", "DELETE", "PATCH", "HEAD", "OPTIONS", "TRACE")
$getmethods = @("GET", "HEAD", "OPTIONS", "TRACE")
$postmethods = @("PUT", "POST", "DELETE", "PATCH")
# I need apiUrl
if (-not $apiUrl) {
    Write-Host "Error: -apiUrl parameter is needed."
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