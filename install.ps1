# install.ps1 - Simple installer that auto-runs main.bat
param(
    [string]$InstallPath = "$env:USERPROFILE\MyApp"
)

Write-Host "Installing application..." -ForegroundColor Green

# Create installation directory
if (-not (Test-Path $InstallPath)) {
    New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
}

# Download the repository as zip
$zipUrl = "https://github.com/username/repo/archive/refs/heads/main.zip"
$zipPath = "$env:TEMP\app-install.zip"

try {
    # Download zip file
    (New-Object System.Net.WebClient).DownloadFile($zipUrl, $zipPath)
    
    # Extract zip
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $tempExtract = "$env:TEMP\app-extract"
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $tempExtract)
    
    # Find the extracted folder and copy contents
    $extractedFolder = Get-ChildItem -Path $tempExtract -Directory | Select-Object -First 1
    Copy-Item -Path "$($extractedFolder.FullName)\*" -Destination $InstallPath -Recurse -Force
    
    Write-Host "Installation complete!" -ForegroundColor Green
    
    # Auto-run main.bat
    $mainBat = "$InstallPath\main.bat"
    if (Test-Path $mainBat) {
        Write-Host "Starting application..." -ForegroundColor Cyan
        Start-Process -FilePath $mainBat -WorkingDirectory $InstallPath
    }
    
} catch {
    Write-Error "Installation failed: $($_.Exception.Message)"
} finally {
    # Cleanup
    if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
    if (Test-Path "$env:TEMP\app-extract") { Remove-Item "$env:TEMP\app-extract" -Recurse -Force }
}
