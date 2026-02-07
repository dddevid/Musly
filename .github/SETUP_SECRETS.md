# 🔐 GitHub Secrets Setup Guide

This guide explains how to set up the required GitHub secrets for Crowdin integration and automated releases.

## Required Secrets

### For Crowdin Integration (`crowdin-sync.yml`)

1. **CROWDIN_API_TOKEN**
   - **Description**: Your Crowdin Personal Access Token
   - **How to get it**:
     1. Go to https://crowdin.com/settings#api-key
     2. Click "New Token"
     3. Give it a name (e.g., "Musly GitHub Actions")
     4. Set scope to "Project" with read/write permissions
     5. Copy the generated token

2. **CROWDIN_PROJECT_ID**
   - **Description**: Your Crowdin Project ID
   - **How to get it**:
     1. Go to your project: https://crowdin.com/project/musly
     2. Click on "Settings" > "API"
     3. Copy the "Project ID" (numeric value)

### For Automated Releases (`release.yml`)

The `GITHUB_TOKEN` is automatically provided by GitHub Actions - no setup needed!

## How to Add Secrets to GitHub

1. Go to your repository: https://github.com/dddevid/Musly

2. Click on **Settings** tab

3. In the left sidebar, click on **Secrets and variables** > **Actions**

4. Click **New repository secret**

5. Add each secret:
   - **Name**: `CROWDIN_API_TOKEN`
   - **Value**: (paste your Crowdin API token)
   - Click **Add secret**

6. Repeat for `CROWDIN_PROJECT_ID`:
   - **Name**: `CROWDIN_PROJECT_ID`
   - **Value**: (paste your Crowdin project ID)
   - Click **Add secret**

## Verify Setup

Once secrets are added:

1. **Test Crowdin Sync**:
   - Go to **Actions** tab
   - Select "Crowdin Translations Sync" workflow
   - Click "Run workflow"
   - If successful, you'll see translations synced!

2. **Test Release Build** (optional):
   - Go to **Actions** tab
   - Select "Build and Release" workflow
   - Click "Run workflow"
   - Enter a version number (e.g., 1.0.5)
   - Builds will be created for Android, Windows, and Linux

## Workflow Triggers

### Crowdin Sync Workflow
- **Automatic**: Runs daily at midnight UTC
- **Manual**: Can be triggered manually from Actions tab
- **On Push**: Runs when `lib/l10n/app_en.arb` is updated

### Release Workflow
- **Automatic**: Triggers when you push a version tag (e.g., `v1.0.5`)
- **Manual**: Can be triggered manually with custom version number

## Example: Creating a Release

```bash
# Create and push a version tag
git tag v1.0.5
git push origin v1.0.5

# GitHub Actions will automatically:
# 1. Build Android APK/AAB
# 2. Build Windows executable
# 3. Build Linux binary
# 4. Create a GitHub Release with all artifacts
```

## Troubleshooting

### Crowdin Sync Fails
- Check that `CROWDIN_API_TOKEN` is valid and not expired
- Verify `CROWDIN_PROJECT_ID` matches your project
- Ensure the token has project read/write permissions

### Release Build Fails
- Check the Actions log for specific error messages
- Ensure Flutter version in workflow matches your development version
- For Android: Verify Java version is correct (17)

### Secrets Not Found
- Secrets are case-sensitive - use EXACT names
- Secrets are only available to workflows in the same repository
- Forked repositories don't inherit secrets (for security)

## Security Notes

⚠️ **Never commit secrets to the repository!**

- Secrets are encrypted and only accessible to GitHub Actions
- They won't appear in logs or be accessible to pull requests from forks
- Rotate tokens periodically for security
- Use separate tokens for different purposes

## Need Help?

- **Crowdin issues**: Check [Crowdin documentation](https://support.crowdin.com/)
- **GitHub Actions issues**: See [GitHub Actions documentation](https://docs.github.com/en/actions)
- **App-specific questions**: Open an [issue](https://github.com/dddevid/Musly/issues)

---

Setup complete! 🎉 Your automation is ready to go.
