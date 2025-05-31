#!/bin/bash
# update_versions.sh - Updates package versions based on version.config
# chmod +x bash/update_versions.sh && ./bash/update_versions.sh

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

echo "Updating all packages to version: $VERSION"

# First, get all package names for later dependency updating
declare -a package_names=()
for package_dir in packages/*/; do
  pubspec_file="${package_dir}pubspec.yaml"
  if [[ -f "$pubspec_file" ]]; then
    package_name=$(grep -E "^name:" "$pubspec_file" | sed 's/name: //' | tr -d ' ')
    package_names+=("$package_name")
  fi
done

echo "Found packages: ${package_names[@]}"

# Update pubspec.yaml files in all packages
for package_dir in packages/*/; do
  pubspec_file="${package_dir}pubspec.yaml"
  
  if [[ -f "$pubspec_file" ]]; then
    # Get the current version
    current_version=$(grep -E "^version:" "$pubspec_file" | sed 's/version: //')
    
    # Update the package version
    if [[ "$current_version" != "$VERSION" ]]; then
      echo "Updating $pubspec_file from $current_version to $VERSION"
      
      # Use sed to replace the version line
      if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS requires a different sed syntax
        sed -i '' "s/^version:.*$/version: $VERSION/" "$pubspec_file"
      else
        # Linux/Unix sed syntax
        sed -i "s/^version:.*$/version: $VERSION/" "$pubspec_file"
      fi
    else
      echo "$pubspec_file already at version $VERSION"
    fi
    
    # Now update all internal package dependencies
    for pkg_name in "${package_names[@]}"; do
      # Look for dependencies on internal packages (ignoring path-based dependency_overrides)
      if grep -q "^  $pkg_name: \^" "$pubspec_file"; then
        echo "Updating dependency on $pkg_name in $pubspec_file to version $VERSION"
        
        if [[ "$OSTYPE" == "darwin"* ]]; then
          # macOS requires a different sed syntax
          sed -i '' "s/^  $pkg_name: \^.*$/  $pkg_name: ^$VERSION/" "$pubspec_file"
        else
          # Linux/Unix sed syntax
          sed -i "s/^  $pkg_name: \^.*$/  $pkg_name: ^$VERSION/" "$pubspec_file"
        fi
      fi
    done
  else
    echo "Pubspec file $pubspec_file not found, skipping..."
  fi
done

# Update dependencies in example folders as well
for package_dir in packages/*/; do
  example_dir="${package_dir}example/"
  example_pubspec="${example_dir}pubspec.yaml"
  
  if [[ -f "$example_pubspec" ]]; then
    package_name=$(grep -E "^name:" "${package_dir}pubspec.yaml" | sed 's/name: //' | tr -d ' ')
    echo "Checking example project for $package_name..."
    
    # Update the parent package dependency in the example
    if grep -q "^  $package_name:" "$example_pubspec"; then
      echo "Updating $package_name dependency in example to $VERSION"
      
      if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/^  $package_name:.*$/  $package_name: ^$VERSION/" "$example_pubspec"
      else
        sed -i "s/^  $package_name:.*$/  $package_name: ^$VERSION/" "$example_pubspec"
      fi
    fi
    
    # Update other internal dependencies in example projects
    for pkg_name in "${package_names[@]}"; do
      if [[ "$pkg_name" != "$package_name" ]] && grep -q "^  $pkg_name: \^" "$example_pubspec"; then
        echo "Updating dependency on $pkg_name in example to version $VERSION"
        
        if [[ "$OSTYPE" == "darwin"* ]]; then
          sed -i '' "s/^  $pkg_name: \^.*$/  $pkg_name: ^$VERSION/" "$example_pubspec"
        else
          sed -i "s/^  $pkg_name: \^.*$/  $pkg_name: ^$VERSION/" "$example_pubspec"
        fi
      fi
    done
    
    # Also check dev_dependencies section
    for pkg_name in "${package_names[@]}"; do
      if grep -q "^  $pkg_name: \^" "$example_pubspec" && \
         grep -A 50 "^dev_dependencies:" "$example_pubspec" | grep -q "^  $pkg_name: \^"; then
        echo "Updating dev dependency on $pkg_name in example to version $VERSION"
        
        if [[ "$OSTYPE" == "darwin"* ]]; then
          # This sed command looks for the package in dev_dependencies section and updates it
          awk -v pkg="$pkg_name" -v ver="$VERSION" '
            /^dev_dependencies:/,/^[a-z]/ {
              if ($0 ~ "^  "pkg": \\^") {
                print "  "pkg": ^"ver
                next
              }
            }
            { print }
          ' "$example_pubspec" > "${example_pubspec}.tmp" && mv "${example_pubspec}.tmp" "$example_pubspec"
        else
          # For Linux we use a similar approach
          awk -v pkg="$pkg_name" -v ver="$VERSION" '
            /^dev_dependencies:/,/^[a-z]/ {
              if ($0 ~ "^  "pkg": \\^") {
                print "  "pkg": ^"ver
                next
              }
            }
            { print }
          ' "$example_pubspec" > "${example_pubspec}.tmp" && mv "${example_pubspec}.tmp" "$example_pubspec"
        fi
      fi
    done
  fi
done

# Update the main CHANGELOG.md to ensure it has the correct version
changelog_file="CHANGELOG.md"
if [[ -f "$changelog_file" ]]; then
  # Check if the current version exists in the CHANGELOG
  if ! grep -q "## $VERSION" "$changelog_file"; then
    # Version doesn't exist in changelog, so add it below the header
    echo "Adding version $VERSION to main CHANGELOG.md"
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
      # macOS requires a different sed syntax
      sed -i '' "s/# Changelog/# Changelog\n\n## $VERSION\n\n### Added\n- Initial release of version $VERSION\n/" "$changelog_file"
    else
      # Linux/Unix sed syntax
      sed -i "s/# Changelog/# Changelog\n\n## $VERSION\n\n### Added\n- Initial release of version $VERSION\n/" "$changelog_file"
    fi
  fi
fi

# Now update changelogs after version update
if [[ -f "bash/update_changelog.sh" ]]; then
  echo "Running update_changelog.sh to sync all package changelogs..."
  bash/update_changelog.sh
fi

echo "Version update completed!"
