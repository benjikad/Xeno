# install.ps1 - Simple installer that auto-runs main.bat
param(
    [string]$InstallPath = "$env:USERPROFILE\Xeno"
)

Write-Host "Installing Xeno application..." -ForegroundColor Green
Write-Host "Install path: $InstallPath" -ForegroundColor Yellow

# Create installation directory
if (-not (Test-Path $InstallPath)) {
    Write-Host "Creating directory: $InstallPath" -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
}

# Download the repository as zip
$zipUrl = "https://github.com/benjikad/Xeno/archive/refs/heads/main.zip"
$zipPath = "$env:TEMP\xeno-install.zip"

try {
    Write-Host "Downloading from GitHub..." -ForegroundColor Cyan
    
    # Download zip file with progress
    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadFile($zipUrl, $zipPath)
    $webClient.Dispose()
    
    Write-Host "Download complete. Extracting..." -ForegroundColor Cyan
    
    # Clean up any existing temp extraction
    $tempExtract = "$env:TEMP\xeno-extract"
    if (Test-Path $tempExtract) {
        Remove-Item $tempExtract -Recurse -Force
    }
    
    # Extract zip
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $tempExtract)
    
    # Find the extracted folder and copy contents
    $extractedFolder = Get-ChildItem -Path $tempExtract -Directory | Select-Object -First 1
    Write-Host "Copying files to installation directory..." -ForegroundColor Cyan
    Copy-Item -Path "$($extractedFolder.FullName)\*" -Destination $InstallPath -Recurse -Force
    
    Write-Host "Installation complete!" -ForegroundColor Green
    
    # Auto-run main.bat
    $mainBat = "$InstallPath\main.bat"
    Write-Host "Looking for main.bat at: $mainBat" -ForegroundColor Yellow
    
    if (Test-Path $mainBat) {
        Write-Host "Found main.bat! Starting application..." -ForegroundColor Green
        # Use cmd to run the bat file properly
        Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$mainBat`"" -WorkingDirectory $InstallPath
        Write-Host "Application started!" -ForegroundColor Green
    } else {
        Write-Host "main.bat not found in installation directory" -ForegroundColor Red
        Write-Host "Files in directory:" -ForegroundColor Yellow
        Get-ChildItem -Path $InstallPath | ForEach-Object { Write-Host "  $($_.Name)" -ForegroundColor Gray }
    }
    
} catch {
    Write-Host "Installation failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Error details: $($_.Exception)" -ForegroundColor Red
} finally {
    # Cleanup
    if (Test-Path $zipPath) { 
        Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path $tempExtract) { 
        Remove-Item $tempExtract -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Keep window open to see results
Write-Host ""
Write-Host "Press any key to close this window..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
