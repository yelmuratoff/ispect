#!/bin/bash
# check_version_sync.sh - Check if package versions match the main version
# chmod +x bash/check_version_sync.sh && ./bash/check_version_sync.sh

# Source the version config
if [ -f "version.config" ]; then
  source "version.config"
else
  # Try with full path
  script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
  root_dir="$(dirname "$script_dir")"
  version_file="$root_dir/version.config"
  
  if [ -f "$version_file" ]; then
    source "$version_file"
  fi
fi

if [ -z "$VERSION" ]; then
  echo "Error: VERSION not defined in version.config"
  exit 1
fi

echo "Main version from version.config: $VERSION"
echo "-----------------------------------------"
echo "Checking all packages..."

# Array to track out-of-sync packages
declare -a out_of_sync_packages

# Loop through all packages and check their versions
for package_dir in packages/*/; do
  pubspec_file="${package_dir}pubspec.yaml"
  
  if [[ -f "$pubspec_file" ]]; then
    # Get the current version
    package_name=$(grep -E "^name:" "$pubspec_file" | sed 's/name: //')
    current_version=$(grep -E "^version:" "$pubspec_file" | sed 's/version: //')
    
    if [[ "$current_version" == "$VERSION" ]]; then
      echo "✅ $package_name: $current_version"
    else
      echo "❌ $package_name: $current_version (should be $VERSION)"
      out_of_sync_packages+=("$package_name")
    fi
  else
    echo "Pubspec file $pubspec_file not found, skipping..."
  fi
done

echo "-----------------------------------------"

# Check if any packages are out of sync
if [ ${#out_of_sync_packages[@]} -eq 0 ]; then
  echo "All packages are in sync with version $VERSION! 🎉"
else
  echo "WARNING: ${#out_of_sync_packages[@]} packages are out of sync! 🚨"
  echo "Run './bash/update_versions.sh' to sync all package versions."
  exit 1
fi
