# Release Management Guide

This repository uses automated release management with GitHub Actions and a custom shell script.

## 🚀 How It Works

1. **Tagging**: When you push a version tag (e.g., `v1.0.0`), GitHub Actions automatically creates a release
2. **Shell Script**: The `release.sh` script automates version bumping, changelog updates, and tagging
3. **Automated**: The entire process from version bump to GitHub release is automated

## 📋 Quick Start

### Using the Release Script

The easiest way to create a release is using the interactive mode:

```bash
./release.sh interactive
```

Or specify the version type and commit message directly:

```bash
# Patch release (0.0.1 -> 0.0.2)
./release.sh patch "Fix notification display issue"

# Minor release (0.1.0 -> 0.2.0)
./release.sh minor "Add new notification scheduling feature"

# Major release (1.0.0 -> 2.0.0)
./release.sh major "Redesign notification API"
```

### Manual Process

If you prefer to do it manually:

1. Update version in `pubspec.yaml`
2. Update `CHANGELOG.md`
3. Commit changes: `git commit -am "chore: bump version to x.x.x"`
4. Create tag: `git tag -a vx.x.x -m "Release vx.x.x"`
5. Push: `git push origin main --tags`

## 🛠️ What the Script Does

1. **Pre-flight Checks**:

   - Ensures working directory is clean
   - Checks you're on main/master branch
   - Runs tests and code analysis

2. **Version Management**:

   - Automatically bumps version in `pubspec.yaml`
   - Updates `CHANGELOG.md` with new entry
   - Follows semantic versioning

3. **Git Operations**:

   - Commits changes with conventional commit message
   - Creates annotated git tag
   - Optionally pushes to remote

4. **GitHub Integration**:
   - GitHub Actions detects the new tag
   - Automatically creates a release with changelog
   - Includes installation instructions

## 📝 Semantic Versioning

We follow [Semantic Versioning](https://semver.org/):

- **MAJOR** (x.0.0): Breaking changes
- **MINOR** (0.x.0): New features (backward compatible)
- **PATCH** (0.0.x): Bug fixes (backward compatible)

## 🔧 Customization

### Modifying the Release Workflow

Edit `.github/workflows/release.yml` to customize:

- Release notes format
- Additional build steps
- Notification settings

### Script Configuration

The `release.sh` script can be customized by modifying these variables at the top:

- `PUBSPEC_FILE`: Path to pubspec.yaml
- `CHANGELOG_FILE`: Path to changelog file

## 📚 Examples

### Creating Your First Release

```bash
# Interactive mode (recommended for first time)
./release.sh interactive

# Follow the prompts:
# 1. Select version type
# 2. Enter commit message
# 3. Review and confirm
# 4. Choose to push automatically
```

### Bug Fix Release

```bash
./release.sh patch "Fix timezone handling in scheduled notifications"
```

### Feature Release

```bash
./release.sh minor "Add support for notification actions and replies"
```

### Breaking Change Release

```bash
./release.sh major "Redesign notification configuration API"
```

## 🔍 Troubleshooting

### Common Issues

1. **"Working directory is not clean"**

   - Commit or stash your changes before running the script

2. **"Not on main/master branch"**

   - Switch to main branch or confirm you want to release from current branch

3. **"Tests failed"**
   - Fix failing tests or choose to continue anyway (not recommended)

### Getting Help

```bash
./release.sh --help
```

## 🎯 Best Practices

1. **Always run tests** before releasing
2. **Write meaningful commit messages** for the changelog
3. **Use semantic versioning** appropriately
4. **Review changes** before pushing tags
5. **Test releases** in a development environment first

## 🔗 Related Files

- `.github/workflows/release.yml` - GitHub Actions release workflow
- `.github/workflows/ci.yml` - Continuous integration workflow
- `CHANGELOG.md` - Project changelog
- `pubspec.yaml` - Package version configuration
