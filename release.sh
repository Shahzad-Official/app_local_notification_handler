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
    echo -e "${BLUE}Usage: $0 [patch|minor|major] [--no-commit]${NC}"
    echo ""
    echo -e "${YELLOW}Version types:${NC}"
    echo "  patch  - Bug fixes (0.0.1 -> 0.0.2)"
    echo "  minor  - New features (0.1.0 -> 0.2.0)"
    echo "  major  - Breaking changes (1.0.0 -> 2.0.0)"
    echo ""
    echo -e "${YELLOW}Options:${NC}"
    echo "  --no-commit - Skip git commit and push (just update files and create tag)"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  $0 patch"
    echo "  $0 minor --no-commit"
    echo "  $0 major"
    echo ""
    echo -e "${YELLOW}Interactive mode:${NC}"
    echo "  $0 interactive"
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

update_pubspec_version() {
    local new_version=$1
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s/^version:.*/version: $new_version/" $PUBSPEC_FILE
    else
        # Linux
        sed -i "s/^version:.*/version: $new_version/" $PUBSPEC_FILE
    fi
}

update_changelog() {
    local version=$1
    local date=$(date +"%Y-%m-%d")
    
    if [[ ! -f $CHANGELOG_FILE ]]; then
        echo -e "${YELLOW}⚠️  Creating new CHANGELOG.md${NC}"
        cat > $CHANGELOG_FILE << EOF
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
    local release_files=(".github/workflows/release.yml" ".github/workflows/ci.yml" "RELEASE_GUIDE.md" "release.sh" "CHANGELOG.md")
    local new_files=()
    local modified_files=()
    
    # Check for untracked release files
    for file in "${release_files[@]}"; do
        if [[ -f "$file" ]] && ! git ls-files --error-unmatch "$file" >/dev/null 2>&1; then
            new_files+=("$file")
        fi
    done
    
    # Check for modified release files (including CHANGELOG.md)
    if git diff --name-only | grep -E "(\.github/workflows/|RELEASE_GUIDE\.md|release\.sh|CHANGELOG\.md)" >/dev/null; then
        while IFS= read -r file; do
            if [[ "$file" =~ (\.github/workflows/|RELEASE_GUIDE\.md|release\.sh|CHANGELOG\.md) ]]; then
                modified_files+=("$file")
            fi
        done <<< "$(git diff --name-only)"
    fi
    
    # Auto-commit release automation files
    if [[ ${#new_files[@]} -gt 0 || ${#modified_files[@]} -gt 0 ]]; then
        echo -e "${BLUE}🔧 Found release automation files to commit...${NC}"
        
        for file in "${new_files[@]}" "${modified_files[@]}"; do
            echo -e "${YELLOW}  Adding: $file${NC}"
            git add "$file"
        done
        
        echo -e "${BLUE}📝 Committing release automation setup...${NC}"
        git commit -m "chore: setup automated release system

- Add GitHub Actions workflows for CI and releases
- Add release.sh script for automated version management
- Add comprehensive release documentation
- Update changelog format"
        
        echo -e "${GREEN}✅ Release automation files committed${NC}"
    fi
}

check_git_status() {
    # First check and setup release files
    check_and_setup_release_files
    
    # Now check if working directory is clean (excluding release files)
    if ! git diff-index --quiet HEAD --; then
        # Get uncommitted changes excluding release automation files
        local uncommitted=$(git status --porcelain | grep -v -E "(\.github/workflows/|RELEASE_GUIDE\.md|release\.sh|CHANGELOG\.md)")
        
        if [[ -n "$uncommitted" ]]; then
            echo -e "${RED}❌ Working directory is not clean. Please commit or stash your changes.${NC}"
            echo -e "${YELLOW}Uncommitted changes:${NC}"
            echo "$uncommitted"
            exit 1
        fi
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
    echo -e "${BLUE}🧪 Running tests...${NC}"
    
    if command -v flutter &> /dev/null; then
        flutter pub get
        flutter analyze
        if flutter test 2>/dev/null; then
            echo -e "${GREEN}✅ All tests passed${NC}"
        else
            echo -e "${YELLOW}⚠️  No tests found or tests failed${NC}"
            read -p "Continue anyway? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
        fi
    else
        echo -e "${YELLOW}⚠️  Flutter not found, skipping tests${NC}"
    fi
}

interactive_mode() {
    echo -e "${BLUE}🚀 Interactive Release Mode${NC}"
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
    read -p "Skip git commit and push? (y/N): " -n 1 -r
    echo
    local no_commit=false
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        no_commit=true
    fi
    
    echo ""
    echo -e "${YELLOW}Summary:${NC}"
    echo "  Version type: $version_type"
    echo "  New version: $(bump_version $version_type)"
    echo "  Git operations: $([ "$no_commit" = true ] && echo "Disabled" || echo "Enabled")"
    echo ""
    
    read -p "Proceed with release? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}ℹ️  Cancelled by user${NC}"
        exit 0
    fi
    
    perform_release $version_type $no_commit
}

perform_release() {
    local version_type=$1
    local no_commit=${2:-false}
    
    echo -e "${BLUE}🚀 Starting release process...${NC}"
    
    # Pre-flight checks (only git status if committing)
    if [[ "$no_commit" != "true" ]]; then
        check_git_status
        check_git_branch
    fi
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
    
    # Git operations (optional)
    if [[ "$no_commit" != "true" ]]; then
        # Git operations
        echo -e "${BLUE}📝 Committing changes...${NC}"
        git add $PUBSPEC_FILE $CHANGELOG_FILE
        git commit -m "chore: bump version to $new_version"
        
        # Create tag
        local tag_name="v$new_version"
        echo -e "${BLUE}🏷️  Creating tag $tag_name...${NC}"
        git tag -a $tag_name -m "Release $tag_name"
        
        echo -e "${GREEN}✅ Release preparation completed!${NC}"
        echo -e "${BLUE}📤 Pushing to remote...${NC}"
        git push origin $(git branch --show-current)
        git push origin $tag_name
        echo -e "${GREEN}🎉 Release $tag_name pushed successfully!${NC}"
        echo -e "${BLUE}🔗 Check GitHub Actions: https://github.com/Shahzad-Official/app_local_notification_handler/actions${NC}"
    else
        echo -e "${BLUE}ℹ️  Skipped git operations (--no-commit flag)${NC}"
        echo -e "${YELLOW}Manual steps if needed:${NC}"
        echo "  1. git add $PUBSPEC_FILE $CHANGELOG_FILE"
        echo "  2. git commit -m \"chore: bump version to $new_version\""
        echo "  3. git tag -a v$new_version -m \"Release v$new_version\""
        echo "  4. git push origin main --tags"
    fi
}

# Main script logic
main() {
    if [[ $# -eq 0 ]]; then
        print_usage
        exit 1
    fi
    
    case $1 in
        "interactive")
            interactive_mode
            ;;
        "patch"|"minor"|"major")
            # Check for --no-commit flag
            local no_commit=false
            if [[ $# -ge 2 && "$2" == "--no-commit" ]]; then
                no_commit=true
            fi
            
            perform_release $1 $no_commit
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
