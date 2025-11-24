# GitHub Pages Deployment Guide

This directory contains scripts to automate the deployment of the Docusaurus site to GitHub Pages.

## Quick Start

### Using npm script (Recommended)
```bash
npm run deploy-ghpages
```

### Using PowerShell directly
```powershell
.\deploy-ghpages.ps1
```

### Using Bash directly
```bash
chmod +x deploy-ghpages.sh
./deploy-ghpages.sh
```

## What the Script Does

The deployment script automates the following steps:

1. **Checks for uncommitted changes** - Warns you if you have uncommitted work
2. **Builds the Docusaurus site** - Runs `npm run build` to generate static files
3. **Switches to gh-pages branch** - Creates it if it doesn't exist (as orphan branch)
4. **Cleans the branch** - Removes old files while preserving `.git` directory
5. **Copies build files** - Moves all files from `build/` to root of gh-pages branch
6. **Creates `.nojekyll` file** - Required for GitHub Pages to work correctly with Docusaurus
7. **Commits with version** - Creates a commit with timestamp-based version (YYYY.MM.DD.HHMM)
8. **Optionally pushes to GitHub** - Asks if you want to push immediately
9. **Returns to original branch** - Switches back to your working branch

## Script Options

### PowerShell Version

```powershell
# Basic usage
.\deploy-ghpages.ps1

# With custom commit message
.\deploy-ghpages.ps1 -VersionMessage "Added new features"

# Skip build (use existing build directory)
.\deploy-ghpages.ps1 -SkipBuild

# Dry run (see what would happen without making changes)
.\deploy-ghpages.ps1 -DryRun
```

### Bash Version

```bash
# Basic usage
./deploy-ghpages.sh

# With custom commit message
./deploy-ghpages.sh -m "Added new features"

# Skip build
./deploy-ghpages.sh --skip-build

# Dry run
./deploy-ghpages.sh --dry-run
```

## GitHub Pages Configuration

The site is configured in `docusaurus.config.ts`:

- **URL**: `https://github.com` (placeholder)
- **Base URL**: `/StarPilgrims/`
- **Organization**: `StarPilgrims`
- **Project**: `StarPilgrims`

### Expected GitHub Pages URL
After deployment, your site will be available at:
```
https://StarPilgrims.github.io/StarPilgrims/
```

## Important Notes

### .nojekyll File
The script automatically creates a `.nojekyll` file in the gh-pages branch. This is **critical** for Docusaurus sites because:
- GitHub Pages uses Jekyll by default
- Jekyll ignores files/folders starting with `_`
- Docusaurus uses `_next`, `_app`, etc.
- `.nojekyll` tells GitHub Pages to skip Jekyll processing

### Orphan Branch
The `gh-pages` branch is created as an orphan branch, meaning:
- It has no commit history from other branches
- It's completely independent
- This keeps the deployment history separate and clean

### Force Push
The script uses `--force` when pushing because:
- The gh-pages branch is rebuilt from scratch each time
- We don't need to preserve its history
- This ensures a clean deployment every time

## Troubleshooting

### Build Fails
If the build fails:
1. Check `build_log.txt` for errors
2. Run `npm run build` manually to see detailed errors
3. Fix any broken links or missing files
4. Try again

### Permission Denied (Bash)
If you get "Permission denied" on Linux/Mac:
```bash
chmod +x deploy-ghpages.sh
```

### Git Conflicts
If you encounter git conflicts:
1. The script will try to return you to your original branch
2. Manually switch: `git checkout main` (or your branch name)
3. Check gh-pages branch: `git checkout gh-pages`
4. If corrupted, delete it: `git branch -D gh-pages`
5. Run the script again

### Site Not Updating
If your site doesn't update after pushing:
1. Check GitHub Actions tab in your repository
2. Ensure GitHub Pages is enabled in repository settings
3. Verify the source is set to "gh-pages" branch
4. Wait a few minutes (GitHub Pages can take 5-10 minutes to update)

## Manual Deployment

If you prefer to deploy manually:

```bash
# 1. Build the site
npm run build

# 2. Use Docusaurus built-in deploy (if configured)
npm run deploy

# OR manually:
# 3. Switch to gh-pages
git checkout gh-pages

# 4. Copy build files
cp -r build/* .

# 5. Commit and push
git add -A
git commit -m "Deploy"
git push origin gh-pages --force
```

## Version Format

Commits are automatically versioned with the format:
```
Deploy v2025.11.25.0002: [Your custom message]
```

Where:
- `2025.11.25` = Date (YYYY.MM.DD)
- `0002` = Time (HHMM in 24-hour format)

## Custom Domain

To use a custom domain:

1. Uncomment the CNAME section in the script:
```powershell
# PowerShell
"your-domain.com" | Out-File -FilePath "CNAME" -Encoding ASCII -NoNewline
```

```bash
# Bash
echo "your-domain.com" > CNAME
```

2. Configure DNS settings with your domain provider
3. Update `url` in `docusaurus.config.ts`

## Best Practices

1. **Always test locally first**: Run `npm run serve` after building
2. **Review changes**: Use `--dry-run` to preview what will happen
3. **Commit your work**: Commit changes to your main branch before deploying
4. **Check the build**: Verify `build/index.html` exists and looks correct
5. **Monitor GitHub Actions**: Watch for deployment success/failure

## Support

If you encounter issues:
1. Check this README
2. Review the script output for error messages
3. Check GitHub Pages documentation
4. Verify your repository settings
