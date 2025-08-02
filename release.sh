#!/bin/bash

# Auto Release Script for Flutter Package
# This script automates version bumping, tagging, and release preparation

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PUBSPEC_FILE="pubspec.yaml"
CHANGELOG_FILE="CHANGELOG.md"

# Functions
print_usage() {
    echo -e "${BLUE}Usage: $0 [patch|minor|major]${NC}"
    echo ""
    echo -e "${YELLOW}Version types:${NC}"
    echo "  patch  - Bug fixes (0.0.1 -> 0.0.2)"
    echo "  minor  - New features (0.1.0 -> 0.2.0)"
    echo "  major  - Breaking changes (1.0.0 -> 2.0.0)"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  $0 patch"
    echo "  $0 minor"
    echo "  $0 major"
    echo ""
    echo -e "${YELLOW}If no arguments provided, interactive mode will start automatically${NC}"
}

get_current_version() {
    grep "^version:" $PUBSPEC_FILE | sed 's/version: //' | tr -d ' '
}

bump_version() {
    local version_type=$1
    local current_version=$(get_current_version)

    if [[ ! $current_version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo -e "${RED}❌ Invalid version format in pubspec.yaml: $current_version${NC}"
        exit 1
    fi

    IFS='.' read -ra VERSION_PARTS <<< "$current_version"
    local major=${VERSION_PARTS[0]}
    local minor=${VERSION_PARTS[1]}
    local patch=${VERSION_PARTS[2]}

    case $version_type in
        "patch")
            ((patch++))
            ;;
        "minor")
            ((minor++))
            patch=0
            ;;
        "major")
            ((major++))
            minor=0
            patch=0
            ;;
        *)
            echo -e "${RED}❌ Invalid version type: $version_type${NC}"
            exit 1
            ;;
    esac

    echo "$major.$minor.$patch"
}
# Update version and tag in README.md for dependency injection
update_readme_version_and_tag() {
    local version=$1
    local tag_name=$2
    if [[ ! -f README.md ]]; then
        echo -e "${YELLOW}⚠️  README.md not found, skipping update.${NC}"
        return
    fi

    # Update pubspec dependency version (if present)
    if grep -qE 'app_local_notification_handler: *[\^0-9\.]+' README.md; then
        sed -i '' -E "s/(app_local_notification_handler: *)[\^0-9\.]+/\\1^$version/" README.md
    fi

    # Update tag in pub.dev badge or GitHub badge (if present)
    if grep -qE 'badge.*app_local_notification_handler.*tag' README.md; then
        sed -i '' -E "s/(badge.*app_local_notification_handler.*tag=)v?[0-9]+\.[0-9]+\.[0-9]+/\\1$tag_name/" README.md
    fi

    # Optionally, update any version mentions in install instructions
    if grep -qE 'pub add app_local_notification_handler@[\^0-9\.]+' README.md; then
        sed -i '' -E "s/(pub add app_local_notification_handler@)[\^0-9\.]+/\\1^$version/" README.md
    fi
}

update_pubspec_version() {
    local version=$1
    sed -i '' "s/^version: .*/version: $version/" $PUBSPEC_FILE
}

update_changelog() {
    local version=$1
    local date=$(date '+%Y-%m-%d')
    
    if [[ ! -f $CHANGELOG_FILE ]]; then
        # Create new changelog
        cat > $CHANGELOG_FILE << EOF
# Changelog

All notable changes to this project will be documented in this file.

## [$version] - $date

### Added
- Version $version release

EOF
    else
        # Create temporary file with new entry
        local temp_file=$(mktemp)
        
        # Read existing changelog and insert new version
        awk -v version="$version" -v date="$date" '
        /^# Changelog/ { print; getline; print; print "## [" version "] - " date ""; print ""; print "### Added"; print "- Version " version " release"; print ""; next }
        { print }
        ' $CHANGELOG_FILE > $temp_file
        
        mv $temp_file $CHANGELOG_FILE
    fi
}

check_and_setup_release_files() {
    # Check for release automation files and commit them automatically
    local release_files=(".github/workflows/release.yml" "release.sh" "CHANGELOG.md" "SETUP.md")
    local new_files=()
    local modified_files=()
    local doc_files=()
    
    # Check for untracked release files
    for file in "${release_files[@]}"; do
        if [[ -f "$file" ]] && ! git ls-files --error-unmatch "$file" >/dev/null 2>&1; then
            new_files+=("$file")
        fi
    done

    # If release.sh changed, update SETUP.md
    if git diff --name-only | grep -q "release.sh"; then
        echo -e "${BLUE}🔄 release.sh changed, updating SETUP.md...${NC}"
        ./update_setup_md.sh || echo -e "${YELLOW}⚠️  Could not update SETUP.md automatically. Please update manually.${NC}"
    fi
    
    # Check for modified release files (including CHANGELOG.md)
    if git diff --name-only | grep -E "(\.github/workflows/|RELEASE_GUIDE\.md|release\.sh|CHANGELOG\.md)" >/dev/null; then
        while IFS= read -r file; do
            if [[ "$file" =~ (\.github/workflows/|RELEASE_GUIDE\.md|release\.sh|CHANGELOG\.md) ]]; then
                modified_files+=("$file")
            fi
        done <<< "$(git diff --name-only)"
    fi
    
    # Check for documentation files that can be auto-committed
    while IFS= read -r file; do
        if [[ "$file" =~ (README\.md|.*_SETUP\.md|.*_GUIDE\.md|.*_SUMMARY\.md|TROUBLESHOOTING\.md|USAGE_EXAMPLE\.md|SETUP\.md) ]]; then
            doc_files+=("$file")
        fi
    done <<< "$(git status --porcelain | sed 's/^...//')"
    
    # Auto-commit release automation files
    if [[ ${#new_files[@]} -gt 0 || ${#modified_files[@]} -gt 0 ]]; then
        echo -e "${BLUE}🔧 Found release automation files to commit...${NC}"
        
        for file in "${new_files[@]}" "${modified_files[@]}"; do
            echo -e "${YELLOW}  Adding: $file${NC}"
            git add "$file"
        done
        
        echo -e "${BLUE}📝 Committing release automation setup...${NC}"
        git commit -m "chore: setup automated release system

- Add GitHub Actions workflow for releases
- Add release.sh script for automated version management
- Add comprehensive release documentation
- Update changelog format"
        
        echo -e "${GREEN}✅ Release automation files committed${NC}"
    fi
    
    # Auto-commit documentation files
    if [[ ${#doc_files[@]} -gt 0 ]]; then
        echo -e "${BLUE}🔧 Found documentation files to commit...${NC}"
        
        for file in "${doc_files[@]}"; do
            echo -e "${YELLOW}  Adding: $file${NC}"
            git add "$file"
        done
        
        echo -e "${BLUE}📝 Committing documentation updates...${NC}"
        git commit -m "docs: update project documentation

- Update README.md with latest information
- Consolidate setup documentation
- Remove outdated documentation files"
        
        echo -e "${GREEN}✅ Documentation files committed${NC}"
    fi
}

check_git_status() {
    # First check and setup release files
    check_and_setup_release_files
    
    # Check if there are any uncommitted changes
    if ! git diff-index --quiet HEAD --; then
        echo -e "${BLUE}🔍 Found uncommitted changes...${NC}"
        
        # Show what will be committed
        echo -e "${YELLOW}📋 Changes to be auto-committed:${NC}"
        git status --porcelain
        echo ""
        
        # Auto-commit all remaining changes
        echo -e "${BLUE}📝 Auto-committing all changes...${NC}"
        git add .
        
        # Create a descriptive commit message
        local commit_msg="chore: auto-commit changes before release

- Automatic commit of all pending changes
- Preparing workspace for version release"
        
        git commit -m "$commit_msg"
        echo -e "${GREEN}✅ All changes committed automatically${NC}"
    fi
}

check_git_branch() {
    local current_branch=$(git branch --show-current)
    if [[ "$current_branch" != "main" && "$current_branch" != "master" ]]; then
        echo -e "${YELLOW}⚠️  Warning: You are not on main/master branch (current: $current_branch)${NC}"
        read -p "Do you want to continue? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}ℹ️  Cancelled by user${NC}"
            exit 0
        fi
    fi
}

run_tests() {
    echo -e "${BLUE}🔍 Performing basic checks...${NC}"
    
    # Just check if pubspec.yaml exists and has valid version format
    if [[ ! -f $PUBSPEC_FILE ]]; then
        echo -e "${RED}❌ pubspec.yaml not found${NC}"
        exit 1
    fi
    
    local current_version=$(get_current_version)
    if [[ ! $current_version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo -e "${RED}❌ Invalid version format in pubspec.yaml: $current_version${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Basic checks passed${NC}"
}

interactive_mode() {
    echo -e "${BLUE}🚀 Automated Release Mode${NC}"
    echo ""
    
    local current_version=$(get_current_version)
    echo -e "${YELLOW}Current version: $current_version${NC}"
    echo ""
    
    echo "Select version bump type:"
    echo "1) Patch (bug fixes) - $current_version -> $(bump_version patch)"
    echo "2) Minor (new features) - $current_version -> $(bump_version minor)"
    echo "3) Major (breaking changes) - $current_version -> $(bump_version major)"
    echo ""
    
    read -p "Enter your choice (1-3): " choice
    
    case $choice in
        1) version_type="patch" ;;
        2) version_type="minor" ;;
        3) version_type="major" ;;
        *) echo -e "${RED}❌ Invalid choice${NC}"; exit 1 ;;
    esac
    
    echo ""
    echo -e "${YELLOW}Summary:${NC}"
    echo "  Version type: $version_type"
    echo "  New version: $(bump_version $version_type)"
    echo "  Actions: Update files → Commit → Push to GitHub → Create release"
    echo ""
    
    read -p "Proceed with automated release? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}ℹ️  Cancelled by user${NC}"
        exit 0
    fi
    
    perform_release $version_type
}

perform_release() {
    local version_type=$1
    
    echo -e "${BLUE}🚀 Starting automated release process...${NC}"
    
    # Pre-flight checks
    check_git_status
    check_git_branch
    run_tests
    
    # Get versions
    local current_version=$(get_current_version)
    local new_version=$(bump_version $version_type)
    
    echo -e "${YELLOW}📦 Bumping version from $current_version to $new_version${NC}"
    
    # Update files
    update_pubspec_version $new_version
    update_changelog $new_version
    
    echo -e "${GREEN}✅ Files updated successfully!${NC}"
    echo -e "${YELLOW}  Updated: $PUBSPEC_FILE (version: $new_version)${NC}"
    echo -e "${YELLOW}  Updated: $CHANGELOG_FILE${NC}"
    
    # Git operations - fully automated
    echo -e "${BLUE}📝 Adding files to git...${NC}"
    git add $PUBSPEC_FILE $CHANGELOG_FILE
    
    echo -e "${BLUE}📝 Committing changes...${NC}"
    git commit -m "chore: bump version to $new_version

- Update version in pubspec.yaml to $new_version
- Update CHANGELOG.md with new release entry"
    
    # Create tag
    local tag_name="v$new_version"
    echo -e "${BLUE}🏷️  Creating tag $tag_name...${NC}"
    git tag -a $tag_name -m "Release $tag_name

Version $new_version release with automated release system"
    
    echo -e "${BLUE}📤 Pushing changes to GitHub...${NC}"
    git push origin $(git branch --show-current)
    
    echo -e "${BLUE}📤 Pushing tag to GitHub...${NC}"
    git push origin $tag_name
    
    echo -e "${GREEN}🎉 Release $tag_name completed successfully!${NC}"
    echo ""
    echo -e "${BLUE}✨ What happened:${NC}"
    echo -e "${YELLOW}  1. ✅ Updated pubspec.yaml version to $new_version${NC}"
    echo -e "${YELLOW}  2. ✅ Updated CHANGELOG.md with release entry${NC}"
    echo -e "${YELLOW}  3. ✅ Committed changes to git${NC}"
    echo -e "${YELLOW}  4. ✅ Created and pushed tag $tag_name${NC}"
    echo -e "${YELLOW}  5. ✅ Pushed all changes to GitHub${NC}"
    echo ""
    echo -e "${BLUE}🔗 Next steps:${NC}"
    echo -e "${YELLOW}  • GitHub Actions will automatically create a release${NC}"
    echo -e "${YELLOW}  • Check: https://github.com/Shahzad-Official/app_local_notification_handler/actions${NC}"
    echo -e "${YELLOW}  • Release will be available at: https://github.com/Shahzad-Official/app_local_notification_handler/releases${NC}"
}

# Main script logic
main() {
    # If no arguments provided, start interactive mode automatically
    if [[ $# -eq 0 ]]; then
        interactive_mode
        return
    fi
    
    case $1 in
        "interactive")
            interactive_mode
            ;;
        "patch"|"minor"|"major")
            perform_release $1
            ;;
        "-h"|"--help")
            print_usage
            ;;
        *)
            echo -e "${RED}❌ Invalid argument: $1${NC}"
            print_usage
            exit 1
            ;;
    esac
}

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}❌ Not in a git repository${NC}"
    exit 1
fi

# Check if pubspec.yaml exists
if [[ ! -f $PUBSPEC_FILE ]]; then
    echo -e "${RED}❌ pubspec.yaml not found${NC}"
    exit 1
fi

# Run main function
main "$@"
