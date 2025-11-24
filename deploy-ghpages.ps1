#!/usr/bin/env pwsh
# GitHub Pages Deployment Script for Docusaurus
# This script automates the deployment process to gh-pages branch

param(
    [string]$VersionMessage = "",
    [switch]$SkipBuild = $false,
    [switch]$DryRun = $false
)

# Color output functions
function Write-Info { Write-Host "[INFO] $args" -ForegroundColor Cyan }
function Write-Success { Write-Host "[SUCCESS] $args" -ForegroundColor Green }
function Write-Error { Write-Host "[ERROR] $args" -ForegroundColor Red }
function Write-Warning { Write-Host "[WARNING] $args" -ForegroundColor Yellow }

# Error handling
$ErrorActionPreference = "Stop"

try {
    # Get current directory
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    Set-Location $scriptDir

    Write-Info "Starting GitHub Pages deployment process..."

    # 1. Check for uncommitted changes
    Write-Info "Checking for uncommitted changes..."
    $gitStatus = git status --porcelain
    if ($gitStatus -and -not $DryRun) {
        Write-Warning "You have uncommitted changes in your working directory:"
        git status --short
        $response = Read-Host "Do you want to continue? (y/N)"
        if ($response -ne 'y' -and $response -ne 'Y') {
            Write-Error "Deployment cancelled by user"
            exit 1
        }
    }

    # Get current branch name
    $currentBranch = git rev-parse --abbrev-ref HEAD
    Write-Info "Current branch: $currentBranch"

    # Get current commit hash for reference
    $currentCommit = git rev-parse HEAD
    Write-Info "Current commit: $currentCommit"

    # 2. Build the project
    if (-not $SkipBuild) {
        Write-Info "Building Docusaurus site..."
        
        # Clean previous build
        if (Test-Path "build") {
            Write-Info "Cleaning previous build directory..."
            Remove-Item -Recurse -Force "build"
        }

        # Run build
        npm run build
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Build failed with exit code $LASTEXITCODE"
            exit $LASTEXITCODE
        }
        
        Write-Success "Build completed successfully"
    } else {
        Write-Warning "Skipping build (using existing build directory)"
        if (-not (Test-Path "build")) {
            Write-Error "Build directory does not exist. Run without -SkipBuild flag."
            exit 1
        }
    }

    # Verify build directory exists and has content
    if (-not (Test-Path "build/index.html")) {
        Write-Error "Build directory is missing index.html. Build may have failed."
        exit 1
    }

    # 3. Prepare version information
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $version = Get-Date -Format "yyyy.MM.dd.HHmm"
    
    if ([string]::IsNullOrWhiteSpace($VersionMessage)) {
        $VersionMessage = "Deploy version $version from $currentBranch"
    } else {
        $VersionMessage = "Deploy v${version}: $VersionMessage"
    }

    Write-Info "Version: $version"
    Write-Info "Commit message: $VersionMessage"

    if ($DryRun) {
        Write-Warning "DRY RUN MODE - No changes will be committed"
        Write-Info "Build directory contents:"
        Get-ChildItem -Path "build" -Recurse -File | Select-Object -First 10 | ForEach-Object { Write-Host "  $_" }
        Write-Success "Dry run completed successfully"
        exit 0
    }

    # 4. Switch to gh-pages branch
    Write-Info "Switching to gh-pages branch..."
    
    # Check if gh-pages branch exists
    $branchExists = git rev-parse --verify gh-pages 2>$null
    
    if ($LASTEXITCODE -eq 0) {
        # Branch exists, switch to it
        git checkout gh-pages
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to checkout gh-pages branch"
            exit $LASTEXITCODE
        }
    } else {
        # Branch doesn't exist, create it as orphan
        Write-Info "Creating new gh-pages branch (orphan)..."
        git checkout --orphan gh-pages
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to create gh-pages branch"
            exit $LASTEXITCODE
        }
        
        # Remove all files from the new orphan branch
        git rm -rf . 2>$null
    }

    Write-Success "Switched to gh-pages branch"

    # 5. Clean gh-pages branch (keep .git directory)
    Write-Info "Cleaning gh-pages branch..."
    
    Get-ChildItem -Path . -Exclude ".git" | ForEach-Object {
        Remove-Item -Recurse -Force $_.FullName
    }

    # 6. Copy build files to gh-pages branch
    Write-Info "Copying build files to gh-pages branch..."
    
    # Copy all files from build directory to root
    Copy-Item -Path "build\*" -Destination "." -Recurse -Force
    
    Write-Success "Build files copied successfully"

    # 7. Create .nojekyll file (important for GitHub Pages)
    Write-Info "Creating .nojekyll file..."
    New-Item -Path ".nojekyll" -ItemType File -Force | Out-Null
    
    # 8. Create CNAME file if needed (uncomment and modify if you have a custom domain)
    # Write-Info "Creating CNAME file..."
    # "your-domain.com" | Out-File -FilePath "CNAME" -Encoding ASCII -NoNewline

    # 9. Add all files to git
    Write-Info "Adding files to git..."
    git add -A
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to add files to git"
        exit $LASTEXITCODE
    }

    # Check if there are changes to commit
    $hasChanges = git diff --staged --quiet
    if ($LASTEXITCODE -eq 0) {
        Write-Warning "No changes to commit"
        git checkout $currentBranch
        Write-Info "Switched back to $currentBranch"
        exit 0
    }

    # 10. Create commit with version
    Write-Info "Creating commit..."
    git commit -m $VersionMessage
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to create commit"
        exit $LASTEXITCODE
    }

    Write-Success "Commit created successfully"

    # 11. Show summary
    Write-Info "═══════════════════════════════════════════════════════"
    Write-Success "Deployment prepared successfully!"
    Write-Info "═══════════════════════════════════════════════════════"
    Write-Info "Branch: gh-pages"
    Write-Info "Version: $version"
    Write-Info "Commit: $VersionMessage"
    Write-Info ""
    Write-Info "To push to GitHub, run:"
    Write-Host "  git push origin gh-pages --force" -ForegroundColor Yellow
    Write-Info ""
    Write-Info "To return to your original branch, run:"
    Write-Host "  git checkout $currentBranch" -ForegroundColor Yellow
    Write-Info "═══════════════════════════════════════════════════════"

    # Ask if user wants to push
    $pushResponse = Read-Host "Do you want to push to GitHub now? (y/N)"
    if ($pushResponse -eq 'y' -or $pushResponse -eq 'Y') {
        Write-Info "Pushing to GitHub..."
        git push origin gh-pages --force
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Successfully pushed to GitHub!"
            Write-Info "Your site will be available at: https://StarPilgrims.github.io/StarPilgrims/"
        } else {
            Write-Error "Failed to push to GitHub"
        }
    }

    # Ask if user wants to return to original branch
    $checkoutResponse = Read-Host "Return to $currentBranch branch? (Y/n)"
    if ($checkoutResponse -ne 'n' -and $checkoutResponse -ne 'N') {
        git checkout $currentBranch
        Write-Success "Returned to $currentBranch branch"
    }

} catch {
    Write-Error "An error occurred: $_"
    Write-Info "Attempting to return to original branch..."
    git checkout $currentBranch 2>$null
    exit 1
}
