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

info() { echo -e "${CYAN}ℹ️  $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }
warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }

# Parse arguments
VERSION_MESSAGE=""
SKIP_BUILD=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -m|--message)
            VERSION_MESSAGE="$2"
            shift 2
            ;;
        --skip-build)
            SKIP_BUILD=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

info "Starting GitHub Pages deployment process..."

# 1. Check for uncommitted changes
info "Checking for uncommitted changes..."
if [[ -n $(git status --porcelain) ]] && [[ "$DRY_RUN" != true ]]; then
    warning "You have uncommitted changes in your working directory:"
    git status --short
    read -p "Do you want to continue? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        error "Deployment cancelled by user"
        exit 1
    fi
fi

# Get current branch name
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
info "Current branch: $CURRENT_BRANCH"

# Get current commit hash
CURRENT_COMMIT=$(git rev-parse HEAD)
info "Current commit: $CURRENT_COMMIT"

# 2. Build the project
if [[ "$SKIP_BUILD" != true ]]; then
    info "Building Docusaurus site..."
    
    # Clean previous build
    if [ -d "build" ]; then
        info "Cleaning previous build directory..."
        rm -rf build
    fi
    
    # Run build
    npm run build
    
    success "Build completed successfully"
else
    warning "Skipping build (using existing build directory)"
    if [ ! -d "build" ]; then
        error "Build directory does not exist. Run without --skip-build flag."
        exit 1
    fi
fi

# Verify build directory
if [ ! -f "build/index.html" ]; then
    error "Build directory is missing index.html. Build may have failed."
    exit 1
fi

# 3. Prepare version information
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
VERSION=$(date "+%Y.%m.%d.%H%M")

if [ -z "$VERSION_MESSAGE" ]; then
    VERSION_MESSAGE="Deploy version $VERSION from $CURRENT_BRANCH"
else
    VERSION_MESSAGE="Deploy v$VERSION: $VERSION_MESSAGE"
fi

info "Version: $VERSION"
info "Commit message: $VERSION_MESSAGE"

if [[ "$DRY_RUN" == true ]]; then
    warning "DRY RUN MODE - No changes will be committed"
    info "Build directory contents:"
    ls -la build | head -n 10
    success "Dry run completed successfully"
    exit 0
fi

# 4. Switch to gh-pages branch
info "Switching to gh-pages branch..."

# Check if gh-pages branch exists
if git rev-parse --verify gh-pages >/dev/null 2>&1; then
    # Branch exists, switch to it
    git checkout gh-pages
else
    # Branch doesn't exist, create it as orphan
    info "Creating new gh-pages branch (orphan)..."
    git checkout --orphan gh-pages
    
    # Remove all files from the new orphan branch
    git rm -rf . 2>/dev/null || true
fi

success "Switched to gh-pages branch"

# 5. Clean gh-pages branch (keep .git directory)
info "Cleaning gh-pages branch..."
find . -maxdepth 1 ! -name '.git' ! -name '.' -exec rm -rf {} + 2>/dev/null || true

# 6. Copy build files to gh-pages branch
info "Copying build files to gh-pages branch..."
cp -r build/* .

success "Build files copied successfully"

# 7. Create .nojekyll file (important for GitHub Pages)
info "Creating .nojekyll file..."
touch .nojekyll

# 8. Create CNAME file if needed (uncomment and modify if you have a custom domain)
# info "Creating CNAME file..."
# echo "your-domain.com" > CNAME

# 9. Add all files to git
info "Adding files to git..."
git add -A

# Check if there are changes to commit
if git diff --staged --quiet; then
    warning "No changes to commit"
    git checkout "$CURRENT_BRANCH"
    info "Switched back to $CURRENT_BRANCH"
    exit 0
fi

# 10. Create commit with version
info "Creating commit..."
git commit -m "$VERSION_MESSAGE"

success "Commit created successfully"

# 11. Show summary
info "═══════════════════════════════════════════════════════"
success "Deployment prepared successfully!"
info "═══════════════════════════════════════════════════════"
info "Branch: gh-pages"
info "Version: $VERSION"
info "Commit: $VERSION_MESSAGE"
echo ""
info "To push to GitHub, run:"
echo -e "${YELLOW}  git push origin gh-pages --force${NC}"
echo ""
info "To return to your original branch, run:"
echo -e "${YELLOW}  git checkout $CURRENT_BRANCH${NC}"
info "═══════════════════════════════════════════════════════"

# Ask if user wants to push
read -p "Do you want to push to GitHub now? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    info "Pushing to GitHub..."
    git push origin gh-pages --force
    
    success "Successfully pushed to GitHub!"
    info "Your site will be available at: https://StarPilgrims.github.io/StarPilgrims/"
fi

# Ask if user wants to return to original branch
read -p "Return to $CURRENT_BRANCH branch? (Y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    git checkout "$CURRENT_BRANCH"
    success "Returned to $CURRENT_BRANCH branch"
fi
