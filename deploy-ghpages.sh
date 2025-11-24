#!/bin/bash
# GitHub Pages Deployment Script for Docusaurus
# This script automates the deployment process to gh-pages branch

set -e  # Exit on error

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

info() { echo -e "${CYAN}[INFO] $1${NC}"; }
success() { echo -e "${GREEN}[SUCCESS] $1${NC}"; }
error() { echo -e "${RED}[ERROR] $1${NC}"; }
warning() { echo -e "${YELLOW}[WARNING] $1${NC}"; }

# Parse arguments
VERSION_MESSAGE=""
NO_PUSH=false
KEEP_TEMP=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -m|--message)
            VERSION_MESSAGE="$2"
            shift 2
            ;;
        --no-push)
            NO_PUSH=true
            shift
            ;;
        --keep-temp)
            KEEP_TEMP=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_REPO_PATH=""

# Cleanup function
cleanup() {
    if [ -n "$TEMP_REPO_PATH" ] && [ -d "$TEMP_REPO_PATH" ] && [ "$KEEP_TEMP" != true ]; then
        info "Cleaning up temporary directory..."
        cd "$SCRIPT_DIR"
        rm -rf "$TEMP_REPO_PATH"
        success "Cleanup completed"
    elif [ "$KEEP_TEMP" = true ] && [ -n "$TEMP_REPO_PATH" ]; then
        warning "Temporary directory preserved: $TEMP_REPO_PATH"
    fi
}

# Set trap for cleanup
trap cleanup EXIT

cd "$SCRIPT_DIR"

info "Starting GitHub Pages deployment process..."

# 1. Verify build directory exists
if [ ! -d "build" ]; then
    error "Build directory does not exist. Run 'npm run build' first."
    exit 1
fi

if [ ! -f "build/index.html" ]; then
    error "Build directory is missing index.html. Build may have failed."
    exit 1
fi

# 2. Prepare version information
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
VERSION=$(date "+%Y.%m.%d.%H%M")

if [ -z "$VERSION_MESSAGE" ]; then
    VERSION_MESSAGE="Deploy version $VERSION"
else
    VERSION_MESSAGE="Deploy v${VERSION}: $VERSION_MESSAGE"
fi

info "Version: $VERSION"
info "Commit message: $VERSION_MESSAGE"

# 3. Get git remote URL (if exists)
REMOTE_URL=$(git config --get remote.origin.url 2>/dev/null || true)
HAS_REMOTE=false

if [ -n "$REMOTE_URL" ]; then
    HAS_REMOTE=true
    info "Remote origin found: $REMOTE_URL"
else
    warning "No remote origin configured. Will prepare files locally only."
fi

# 4. Create temporary directory for gh-pages repo
TEMP_REPO_PATH=$(mktemp -d -t ghpages-deploy-XXXXXXXXXX)
info "Creating temporary directory: $TEMP_REPO_PATH"

# 5. Clone or initialize repository in temp directory
cd "$TEMP_REPO_PATH"

if [ "$HAS_REMOTE" = true ]; then
    info "Cloning repository to temp directory..."
    
    # Try to clone gh-pages branch
    if git clone --branch gh-pages --single-branch --depth 1 "$REMOTE_URL" . 2>/dev/null; then
        success "Cloned existing gh-pages branch"
    else
        # gh-pages branch doesn't exist, create orphan branch
        info "gh-pages branch doesn't exist, creating new orphan branch..."
        git clone --depth 1 "$REMOTE_URL" . 2>/dev/null
        git checkout --orphan gh-pages
        git rm -rf . 2>/dev/null || true
    fi
else
    # No remote, just initialize a new repo
    info "Initializing new git repository..."
    git init
    git checkout -b gh-pages
fi

# 6. Clean the temp repo (keep .git)
info "Cleaning temporary repository..."
find . -maxdepth 1 ! -name '.git' ! -name '.' -exec rm -rf {} + 2>/dev/null || true

# 7. Copy build files to temp repo
info "Copying build files..."
cp -r "$SCRIPT_DIR/build/"* .

success "Build files copied successfully"

# 8. Create .nojekyll file (critical for GitHub Pages)
info "Creating .nojekyll file..."
touch .nojekyll

# 9. Add and commit all files
info "Adding files to git..."
git add -A

# Check if there are changes to commit
if git diff --staged --quiet; then
    warning "No changes to commit. Build is identical to last deployment."
    cd "$SCRIPT_DIR"
    exit 0
fi

info "Creating commit..."
git commit -m "$VERSION_MESSAGE"

success "Commit created successfully"

# 10. Push to remote (if exists and not disabled)
if [ "$HAS_REMOTE" = true ] && [ "$NO_PUSH" != true ]; then
    info "Pushing to remote..."
    git push origin gh-pages --force
    
    success "Successfully pushed to GitHub!"
    info "Your site will be available at: https://StarPilgrims.github.io/StarPilgrims/"
elif [ "$NO_PUSH" = true ]; then
    warning "Push skipped (--no-push flag set)"
    info "To push manually, run:"
    echo -e "${YELLOW}  cd '$TEMP_REPO_PATH'${NC}"
    echo -e "${YELLOW}  git push origin gh-pages --force${NC}"
else
    warning "No remote configured, skipping push"
fi

# 11. Show summary
info "═══════════════════════════════════════════════════════"
success "Deployment completed successfully!"
info "═══════════════════════════════════════════════════════"
info "Version: $VERSION"
info "Commit: $VERSION_MESSAGE"
info "Temp directory: $TEMP_REPO_PATH"

if [ "$HAS_REMOTE" = true ] && [ "$NO_PUSH" != true ]; then
    info "Status: Pushed to remote"
else
    info "Status: Prepared locally"
fi

info "═══════════════════════════════════════════════════════"

# Return to original directory
cd "$SCRIPT_DIR"
