# advanced-install.ps1
param(
    [string]$RepoOwner = "username",
    [string]$RepoName = "repo",
    [string]$Branch = "main",
    [string]$InstallPath = "$env:USERPROFILE\MyApp"
)

$ErrorActionPreference = "Stop"

function Write-ColoredOutput($Message, $Color = "White") {
    Write-Host $Message -ForegroundColor $Color
}

function Get-LatestRelease($Owner, $Repo) {
    try {
        $apiUrl = "https://api.github.com/repos/$Owner/$Repo/releases/latest"
        $release = (New-Object System.Net.WebClient).DownloadString($apiUrl) | ConvertFrom-Json
        return $release
    }
    catch {
        Write-ColoredOutput "No releases found, using main branch" "Yellow"
        return $null
    }
}

function Download-FileWithProgress($Url, $OutputPath) {
    try {
        $webClient = New-Object System.Net.WebClient
        
        # Add progress tracking
        Register-ObjectEvent -InputObject $webClient -EventName "DownloadProgressChanged" -Action {
            $percent = $Event.SourceEventArgs.ProgressPercentage
            Write-Progress -Activity "Downloading" -Status "$percent% Complete" -PercentComplete $percent
        } | Out-Null
        
        $webClient.DownloadFile($Url, $OutputPath)
        Write-Progress -Activity "Downloading" -Completed
        $webClient.Dispose()
        return $true
    }
    catch {
        Write-ColoredOutput "Download failed: $($_.Exception.Message)" "Red"
        return $false
    }
}

# Main installation logic
Write-ColoredOutput "🚀 Starting GitHub Installer" "Cyan"
Write-ColoredOutput "Repository: $RepoOwner/$RepoName" "Gray"

# Check for latest release
$release = Get-LatestRelease -Owner $RepoOwner -Repo $RepoName

if ($release) {
    Write-ColoredOutput "📦 Latest release: $($release.tag_name)" "Green"
    $downloadUrl = $release.zipball_url
    $version = $release.tag_name
} else {
    $downloadUrl = "https://github.com/$RepoOwner/$RepoName/archive/refs/heads/$Branch.zip"
    $version = $Branch
}

# Create temp directory
$tempDir = "$env:TEMP\github-installer-$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

try {
    # Download repository
    $zipPath = "$tempDir\repo.zip"
    Write-ColoredOutput "⬇️  Downloading repository..." "Cyan"
    
    if (Download-FileWithProgress -Url $downloadUrl -OutputPath $zipPath) {
        Write-ColoredOutput "✅ Download completed" "Green"
        
        # Extract zip
        Write-ColoredOutput "📂 Extracting files..." "Cyan"
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $tempDir)
        
        # Find the extracted folder
        $extractedFolder = Get-ChildItem -Path $tempDir -Directory | Select-Object -First 1
        
        # Create installation directory
        if (Test-Path $InstallPath) {
            $backup = "${InstallPath}_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            Write-ColoredOutput "📋 Backing up existing installation to: $backup" "Yellow"
            Move-Item -Path $InstallPath -Destination $backup
        }
        
        # Copy files to installation directory
        Write-ColoredOutput "📁 Installing to: $InstallPath" "Cyan"
        Copy-Item -Path $extractedFolder.FullName -Destination $InstallPath -Recurse -Force
        
        # Run post-install script if it exists
        $postInstallScript = "$InstallPath\post-install.ps1"
        if (Test-Path $postInstallScript) {
            Write-ColoredOutput "🔧 Running post-installation script..." "Cyan"
            & $postInstallScript -InstallPath $InstallPath
        }
        
        # Create version file
        $version | Out-File -FilePath "$InstallPath\.version" -Encoding UTF8
        
        # Auto-launch main.bat if it exists
        $mainBatPath = "$InstallPath\main.bat"
        if (Test-Path $mainBatPath) {
            Write-ColoredOutput "🚀 Launching main.bat..." "Cyan"
            try {
                # Launch main.bat in the installation directory
                Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$mainBatPath`"" -WorkingDirectory $InstallPath -WindowStyle Normal
                Write-ColoredOutput "✅ main.bat launched successfully" "Green"
            }
            catch {
                Write-ColoredOutput "❌ Failed to launch main.bat: $($_.Exception.Message)" "Red"
            }
        } else {
            Write-ColoredOutput "⚠️  main.bat not found in installation directory" "Yellow"
        }
        
        Write-ColoredOutput "🎉 Installation completed successfully!" "Green"
        Write-ColoredOutput "Version: $version" "Gray"
        Write-ColoredOutput "Location: $InstallPath" "Gray"
        
    } else {
        throw "Download failed"
    }
}
catch {
    Write-ColoredOutput "❌ Installation failed: $($_.Exception.Message)" "Red"
    exit 1
}
finally {
    # Cleanup
    if (Test-Path $tempDir) {
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
