# Roku SDK Release Process

Automates the dd-sdk-roku release workflow. Run with `/release <version>` (e.g., `/release 1.4.0`).

## Version Argument

If the user did not provide a version number (e.g., they just typed `/release` with no arguments), read the current version from `package.json` and use AskUserQuestion to present an interactive menu with options:
- **Patch** (e.g., `1.3.1` → `1.3.2`) — for bugfixes
- **Minor** (e.g., `1.3.1` → `1.4.0`) — for new features
- **Major** (e.g., `1.3.1` → `2.0.0`) — for breaking changes

Calculate the actual version numbers from the current version and show them in the labels. Use the selected version for the rest of the process.

## Prerequisites Check

Before starting, verify:
1. You are on the `develop` branch with a clean working tree (`git status`)
2. All CI checks are passing on develop
3. **Version validation**: Read the current version from `package.json` and compare it with the requested version. The new version must be strictly greater than the current one (using semver ordering). If not (e.g., user requests `1.3.0` but current is `1.5.0`), warn the user and abort unless they explicitly confirm it's intentional.

Ask the user to confirm prerequisites are met before proceeding.

## Release Steps

Execute these steps **sequentially**, confirming with the user at each gate:

### Step 1: Create release branch

```bash
git checkout -b release/<version> develop
```

### Step 2: Update CHANGELOG.md

Read the current CHANGELOG.md. Replace the first header line (e.g., `# Next release: x.y.z`) with a dated release header in the format used by existing entries:

```
# <version> / <YYYY-MM-DD>
```

Where `<YYYY-MM-DD>` is today's date.

If there are no bullet points under the "Next release" header, ask the user what changes should be listed. Use the existing format:
- `* [FEATURE] Description. See [#PR](https://github.com/DataDog/dd-sdk-roku/pull/PR)`
- `* [BUGFIX] ...`
- `* [IMPROVEMENT] ...`
- `* [MAINTENANCE] ...`

Show the user the proposed CHANGELOG diff and get approval before committing.

### Step 3: Bump version numbers

Run the release script to update version in all package.json files and the hardcoded SDK version:

```bash
tools/repo/release.sh <version>
```

This script:
- Updates `library/source/datadogSdk.bs` (hardcoded `sdkVersion()`)
- Updates `package.json` in root, `library/`, `test/`, `sample/`
- Packages the release into `datadogroku-<version>.zip`
- Creates a signed commit with all the above changes

### Step 4: Push release branch

```bash
git push -u origin release/<version>
```

Tell the user: "Release branch `release/<version>` has been pushed. Please open a PR targeting `develop` for review."

**GATE: Wait for user to confirm the PR has been reviewed and merged.**

### Step 5: Tag and push

After the PR is merged, switch to develop and pull:

```bash
git checkout develop
git pull origin develop
git tag <version>
git push --tags
```

### Step 6: Create GitHub Release

Tell the user to create the GitHub release:

> Go to https://github.com/DataDog/dd-sdk-roku/releases/new
> - Tag: `<version>` (select existing tag)
> - Target: `develop`
> - Title: `<version>`
> - Paste the changelog entries for this version in the description
>
> **Important:** Creating the GitHub release automatically triggers the npm publish workflow (`.github/workflows/publish.yaml`), so there is no need to run `npm publish` manually.

Offer to draft the release notes body from the CHANGELOG for the user to copy.

### Step 7: Verify npm publish

After the GitHub release is created, tell the user:

> The GitHub Action will automatically publish to npm. You can monitor the action at:
> https://github.com/DataDog/dd-sdk-roku/actions/workflows/publish.yml
>
> Once complete, verify the package is available:
> https://www.npmjs.com/package/datadog-roku

### Step 8: Merge release branch to main

```bash
git checkout main
git pull origin main
git merge develop
git push origin main
```

Ask the user to confirm before pushing to main.

### Step 9: Prepare next development cycle

Ask the user what the next version will be (e.g., `1.5.0`). Then update CHANGELOG.md by adding at the top:

```
# Next release: <next_version>

```

Commit and push to develop:

```bash
git checkout develop
git add CHANGELOG.md
git commit -s -m "Prepare next development cycle (<next_version>)"
git push origin develop
```

## Summary Checklist

At the end, print a summary of what was done:

- [ ] Release branch created
- [ ] CHANGELOG updated with release date
- [ ] Version bumped in all files
- [ ] Release packaged (zip)
- [ ] PR merged to develop
- [ ] Tag created and pushed
- [ ] GitHub release created (triggers npm publish)
- [ ] npm publish verified
- [ ] Release branch merged to main
- [ ] Next development cycle prepared
