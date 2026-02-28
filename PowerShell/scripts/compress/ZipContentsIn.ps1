# Parameters
param (
	[string]$folderPath        # Poth to folder
)

# Check if path exists
if (Test-Path -Path $folderPath) {
    # Get all folders inside
    $directories = Get-ChildItem -Path $folderPath -Directory
    
    foreach ($dir in $directories) {
        # Create a zip with same name of folder
        $zipPath = Join-Path -Path $folderPath -ChildPath ($dir.Name + ".zip")
        
        # Compress folder
        Compress-Archive -Path $dir.FullName -DestinationPath $zipPath
        
        Write-Host "Zip file for folder: $($dir.Name)"
    }
} else {
    Write-Host "Path ${folderPath} does not exist."
}
