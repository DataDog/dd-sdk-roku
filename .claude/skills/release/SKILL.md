# Roku SDK Release Process

Automates the dd-sdk-roku release workflow. Run with `/release <version>` (e.g., `/release 1.4.0`).

## Version Argument

If the user did not provide a version number (e.g., they just typed `/release` with no arguments), read the current version from `package.json` and use AskUserQuestion to present an interactive menu with options:
- **Patch** (e.g., `1.3.0` → `1.3.1`) — for hotfixes only
- **Minor** (e.g., `1.3.1` → `1.4.0`) — for regular releases (may contain breaking changes)
- **Major** (e.g., `1.3.1` → `2.0.0`) — for planned large-scale changes

Calculate the actual version numbers from the current version and show them in the labels. Use the selected version for the rest of the process.

If the user provided a version directly, read the current version from `package.json` and validate that the requested version is strictly greater (using semver ordering). If not (e.g., user requests `1.3.0` but current is `1.5.0`), warn the user and abort unless they explicitly confirm it's intentional.

## Prerequisites Check

Before starting, verify:
1. You are on the `develop` branch (`git status`)
2. Pull latest changes: `git pull origin develop`
3. Working tree is clean (`git status`)
4. All CI checks are passing on develop. Use the following command to check CI status:

```bash
gh api repos/{owner}/{repo}/commits/develop/status --jq '.state'
```

If the result is not `success`, show the failing checks and **abort the release**:

```bash
gh api repos/{owner}/{repo}/commits/develop/status --jq '.statuses[] | select(.state != "success") | "\(.context): \(.state)"'
```

Ask the user to fix CI before retrying the release.

## Release Steps

Execute these steps **sequentially**, confirming with the user at each gate:

### Step 1: Create release and working branches

Create the release branch from develop and push it, then create a personal working branch:

```bash
git checkout -b release/<version> develop
git push -u origin release/<version>
git checkout -b <github-username>/prepare-release-<version>
```

All changes in Steps 2-3 will be made on the personal branch.

### Step 2: Update CHANGELOG.md

Read the current CHANGELOG.md. The first line should be a "Next release" header (e.g., `# Next release: x.y.z`).

**Auto-generate changelog entries**: Collect all commits since the last release tag and generate changelog entries from them. Use the existing format and categorize by type:
- `* [FEATURE] Description. See [#PR](https://github.com/DataDog/dd-sdk-roku/pull/PR)`
- `* [BUGFIX] ...`
- `* [IMPROVEMENT] ...`
- `* [MAINTENANCE] ...`

To get commits since the last tag:
```bash
git log $(git describe --tags --abbrev=0)..HEAD --oneline
```

Then update the CHANGELOG as follows:
1. Replace the "Next release" header with the next development version: `# Next release: <next_minor_version>` (bump the minor version, e.g., `1.4.0` → `1.5.0`)
2. Below it, add the dated release header: `# <version> / <YYYY-MM-DD>` (where `<YYYY-MM-DD>` is today's date)
3. Below the dated header, add the auto-generated changelog entries

Show the user the proposed CHANGELOG changes and get approval. The user may request edits to wording, categorization, or which entries to include. Iterate until the user is satisfied.

**GATE: Do not proceed until the user approves the CHANGELOG.**

### Step 3: Bump version numbers

Run the release script to update version in all package.json files and the hardcoded SDK version:

```bash
tools/repo/release.sh <version>
```

This script:
- Updates `library/source/datadogSdk.bs` (hardcoded `sdkVersion()`)
- Updates `package.json` in root, `library/`, `test/`, `sample/`
- Removes old `datadogroku-*.zip` files
- Packages the release into `datadogroku-<version>.zip`
- Stages `CHANGELOG.md` (must be edited before running the script)
- Creates a signed commit with all the above changes

### Step 4: Push and open PR

Push the personal branch and create a PR targeting the release branch:

```bash
git push -u origin <github-username>/prepare-release-<version>
gh pr create --base release/<version> --head <github-username>/prepare-release-<version> --title "Bump version to <version>" --body ""
```

**GATE: Wait for user to confirm the PR has been reviewed and merged into the release branch.**

### Step 5: Tag and push

After the PR is merged, pull the release branch to get the merge commit, then tag it:

```bash
git checkout release/<version>
git pull origin release/<version>
git tag -a <version> -m "<version>"
git push --tags
```

### Step 6: Create GitHub Release

Generate the release notes body from the CHANGELOG entries for this version, using the following template:

```
## What's Changed
<changelog entries>

## ROPM Setup
If your project is set up to use ROPM, you can use the following command to install the Datadog dependency:

ropm install datadogroku

## Manual Setup
If your project does not use ROPM, install the library manually by downloading the Roku SDK zip archive,
and unzipping it in your project's root folder.

Make sure you have a roku_modules/datadogroku subfolder in both the components and source folders of your project.
```

Then create the release and upload the zip as an asset:

```bash
gh release create <version> --title "<version>" --notes "<release notes>"
gh release upload <version> datadogroku-<version>.zip
```

This automatically triggers the npm publish workflow (`.github/workflows/publish.yaml`).

### Step 7: Verify npm publish

After the GitHub release is created, the GitHub Action will automatically publish to npm. Monitor the action at:
https://github.com/DataDog/dd-sdk-roku/actions/workflows/publish.yaml

If the GitHub Action fails, the user can publish manually:

```bash
git checkout <version>
npm login
npm publish
```

Once published (either automatically or manually), verify:

```bash
npm view datadog-roku@<version> version
```

And confirm the package page is accessible at: `https://www.npmjs.com/package/datadog-roku/v/<version>`

### Step 8: Merge to main and develop

Never push directly to `main` or `develop`. Both merges must go through PRs.

Open the PRs directly from `release/<version>` and merge each with a merge commit, so the tagged commit stays reachable from `main` and `develop`.

```bash
gh pr create --base main --head release/<version> --title "Merge release <version> to main" --body ""
```

**GATE: Wait for user to confirm the PR has been merged.**

```bash
gh pr create --base develop --head release/<version> --title "Merge release <version> to develop" --body ""
```

**GATE: Wait for user to confirm the PR has been merged.**

## Summary Checklist

At the end, print a summary of what was done:

- [ ] Release branch created
- [ ] CHANGELOG updated with release date and next version header
- [ ] Version bumped in all files
- [ ] Release packaged (zip), old zips removed
- [ ] Prepare-release PR merged into release branch
- [ ] Tag created and pushed
- [ ] GitHub release created (with zip asset)
- [ ] npm publish verified (`npm view` and npmjs.com page)
- [ ] Release branch merged to main (via PR)
- [ ] Release branch merged to develop (via PR)
