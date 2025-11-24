#!/usr/bin/env pwsh
# GitHub Pages Deployment Script for Docusaurus
# This script automates the deployment process to gh-pages branch

param(
    [string]$VersionMessage = "",
    [switch]$NoPush = $false,
    [switch]$KeepTemp = $false
)

# Color output functions
function Write-Info { Write-Host "[INFO] $args" -ForegroundColor Cyan }
function Write-Success { Write-Host "[SUCCESS] $args" -ForegroundColor Green }
function Write-Error { Write-Host "[ERROR] $args" -ForegroundColor Red }
function Write-Warning { Write-Host "[WARNING] $args" -ForegroundColor Yellow }

# Error handling
$ErrorActionPreference = "Stop"

# Variable to track temp directory for cleanup
$tempRepoPath = $null

try {
    # Get current directory
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    Set-Location $scriptDir

    Write-Info "Starting GitHub Pages deployment process..."

    # 1. Verify build directory exists
    if (-not (Test-Path "build")) {
        Write-Error "Build directory does not exist. Run 'npm run build' first."
        exit 1
    }

    if (-not (Test-Path "build/index.html")) {
        Write-Error "Build directory is missing index.html. Build may have failed."
        exit 1
    }

    # 2. Prepare version information
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $version = Get-Date -Format "yyyy.MM.dd.HHmm"
    
    if ([string]::IsNullOrWhiteSpace($VersionMessage)) {
        $VersionMessage = "Deploy version $version"
    } else {
        $VersionMessage = "Deploy v${version}: $VersionMessage"
    }

    Write-Info "Version: $version"
    Write-Info "Commit message: $VersionMessage"

    # 3. Get git remote URL (if exists)
    $ErrorActionPreference = "SilentlyContinue"
    $remoteUrl = git config --get remote.origin.url
    $hasRemote = $LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($remoteUrl)
    $ErrorActionPreference = "Stop"

    if ($hasRemote) {
        Write-Info "Remote origin found: $remoteUrl"
    } else {
        Write-Warning "No remote origin configured. Will prepare files locally only."
    }

    # 4. Create temporary directory for gh-pages repo
    $tempRepoPath = Join-Path $env:TEMP "ghpages-deploy-$(Get-Date -Format 'yyyyMMddHHmmss')"
    Write-Info "Creating temporary directory: $tempRepoPath"
    New-Item -ItemType Directory -Path $tempRepoPath -Force | Out-Null

    # 5. Clone or initialize repository in temp directory
    Set-Location $tempRepoPath

    if ($hasRemote) {
        Write-Info "Cloning repository to temp directory..."
        
        # Try to clone gh-pages branch
        $ErrorActionPreference = "SilentlyContinue"
        git clone --branch gh-pages --single-branch --depth 1 $remoteUrl . 2>$null
        $cloneSuccess = $LASTEXITCODE -eq 0
        $ErrorActionPreference = "Stop"

        if (-not $cloneSuccess) {
            # gh-pages branch doesn't exist, create orphan branch
            Write-Info "gh-pages branch doesn't exist, creating new orphan branch..."
            
            $ErrorActionPreference = "SilentlyContinue"
            git clone --depth 1 $remoteUrl . 2>$null
            $mainCloneSuccess = $LASTEXITCODE -eq 0
            $ErrorActionPreference = "Stop"
            
            if (-not $mainCloneSuccess) {
                Write-Error "Failed to clone repository. Check your remote URL and access rights."
                exit 1
            }
            
            git checkout --orphan gh-pages
            git rm -rf . 2>$null
        } else {
            Write-Success "Cloned existing gh-pages branch"
        }
    } else {
        # No remote, just initialize a new repo
        Write-Info "Initializing new git repository..."
        git init
        git checkout -b gh-pages
    }

    # 6. Clean the temp repo (keep .git)
    Write-Info "Cleaning temporary repository..."
    Get-ChildItem -Path . -Exclude ".git" | ForEach-Object {
        Remove-Item -Recurse -Force $_.FullName
    }

    # 7. Copy build files to temp repo
    Write-Info "Copying build files..."
    $buildSource = Join-Path $scriptDir "build"
    Copy-Item -Path "$buildSource\*" -Destination "." -Recurse -Force

    Write-Success "Build files copied successfully"

    # 8. Create .nojekyll file (critical for GitHub Pages)
    Write-Info "Creating .nojekyll file..."
    New-Item -Path ".nojekyll" -ItemType File -Force | Out-Null

    # 9. Add and commit all files
    Write-Info "Adding files to git..."
    git add -A

    # Check if there are changes to commit
    $ErrorActionPreference = "SilentlyContinue"
    git diff --staged --quiet
    $hasChanges = $LASTEXITCODE -ne 0
    $ErrorActionPreference = "Stop"

    if (-not $hasChanges) {
        Write-Warning "No changes to commit. Build is identical to last deployment."
        Set-Location $scriptDir
        exit 0
    }

    Write-Info "Creating commit..."
    git commit -m $VersionMessage

    Write-Success "Commit created successfully"

    # 10. Push to remote (if exists and not disabled)
    if ($hasRemote -and -not $NoPush) {
        Write-Info "Pushing to remote..."
        git push origin gh-pages --force

        if ($LASTEXITCODE -eq 0) {
            Write-Success "Successfully pushed to GitHub!"
            Write-Info "Your site will be available at: https://StarPilgrims.github.io/StarPilgrims/"
        } else {
            Write-Error "Failed to push to remote"
            exit 1
        }
    } elseif ($NoPush) {
        Write-Warning "Push skipped (--NoPush flag set)"
        Write-Info "To push manually, run:"
        Write-Host "  cd '$tempRepoPath'" -ForegroundColor Yellow
        Write-Host "  git push origin gh-pages --force" -ForegroundColor Yellow
    } else {
        Write-Warning "No remote configured, skipping push"
    }

    # 11. Show summary
    Write-Info "═══════════════════════════════════════════════════════"
    Write-Success "Deployment completed successfully!"
    Write-Info "═══════════════════════════════════════════════════════"
    Write-Info "Version: $version"
    Write-Info "Commit: $VersionMessage"
    Write-Info "Temp directory: $tempRepoPath"
    
    if ($hasRemote -and -not $NoPush) {
        Write-Info "Status: Pushed to remote"
    } else {
        Write-Info "Status: Prepared locally"
    }
    
    Write-Info "═══════════════════════════════════════════════════════"

    # Return to original directory
    Set-Location $scriptDir

} catch {
    Write-Error "An error occurred: $_"
    Set-Location $scriptDir
    exit 1
} finally {
    # Clean up temp directory (unless --KeepTemp flag is set)
    if ($tempRepoPath -and (Test-Path $tempRepoPath) -and -not $KeepTemp) {
        Write-Info "Cleaning up temporary directory..."
        Set-Location $scriptDir
        Remove-Item -Recurse -Force $tempRepoPath -ErrorAction SilentlyContinue
        Write-Success "Cleanup completed"
    } elseif ($KeepTemp -and $tempRepoPath) {
        Write-Warning "Temporary directory preserved: $tempRepoPath"
    }
}
