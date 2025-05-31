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
      # Check if we're inside the dependencies section (not dependency_overrides)
      # Extract dependencies section first
      deps_section=$(awk '/^dependencies:/{flag=1; next} /^[a-z]/{flag=0} flag' "$pubspec_file")
      
      if echo "$deps_section" | grep -q "^  $pkg_name: \^"; then
        echo "Updating dependency on $pkg_name in $pubspec_file to version $VERSION"
        
        if [[ "$OSTYPE" == "darwin"* ]]; then
          # macOS requires a different sed syntax
          # Use awk to only replace in dependencies section, not in dependency_overrides
          awk -v pkg="$pkg_name" -v ver="$VERSION" '
            BEGIN { in_deps = 0 }
            /^dependencies:/ { in_deps = 1; print; next }
            /^[a-z][a-z_]*:/ && in_deps { in_deps = 0 }
            in_deps && $0 ~ "^  "pkg": \\^" {
              print "  "pkg": ^"ver
              next
            }
            { print }
          ' "$pubspec_file" > "${pubspec_file}.tmp" && mv "${pubspec_file}.tmp" "$pubspec_file"
        else
          # Linux/Unix 
          awk -v pkg="$pkg_name" -v ver="$VERSION" '
            BEGIN { in_deps = 0 }
            /^dependencies:/ { in_deps = 1; print; next }
            /^[a-z][a-z_]*:/ && in_deps { in_deps = 0 }
            in_deps && $0 ~ "^  "pkg": \\^" {
                        ' "$pubspec_file" > "${pubspec_file}.tmp" && mv "${pubspec_file}.tmp" "$pubspec_file"
        fi
      fi
      
      # Also check dev_dependencies section
      dev_deps_section=$(awk '/^dev_dependencies:/{flag=1; next} /^[a-z]/{flag=0} flag' "$pubspec_file")
      
      if echo "$dev_deps_section" | grep -q "^  $pkg_name: \^"; then
        echo "Updating dev dependency on $pkg_name in $pubspec_file to version $VERSION"
        
        if [[ "$OSTYPE" == "darwin"* ]]; then
          awk -v pkg="$pkg_name" -v ver="$VERSION" '
            BEGIN { in_dev_deps = 0 }
            /^dev_dependencies:/ { in_dev_deps = 1; print; next }
            /^[a-z][a-z_]*:/ && in_dev_deps { in_dev_deps = 0 }
            in_dev_deps && $0 ~ "^  "pkg": \\^" {
              print "  "pkg": ^"ver
              next
            }
            { print }
          ' "$pubspec_file" > "${pubspec_file}.tmp" && mv "${pubspec_file}.tmp" "$pubspec_file"
        else
          awk -v pkg="$pkg_name" -v ver="$VERSION" '
            BEGIN { in_dev_deps = 0 }
            /^dev_dependencies:/ { in_dev_deps = 1; print; next }
            /^[a-z][a-z_]*:/ && in_dev_deps { in_dev_deps = 0 }
            in_dev_deps && $0 ~ "^  "pkg": \\^" {
              print "  "pkg": ^"ver
              next
            }
            { print }
          ' "$pubspec_file" > "${pubspec_file}.tmp" && mv "${pubspec_file}.tmp" "$pubspec_file"
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
    
    # Update the parent package dependency in the example only in dependencies section
    deps_section=$(awk '/^dependencies:/{flag=1; next} /^[a-z]/{flag=0} flag' "$example_pubspec")
    
    if echo "$deps_section" | grep -q "^  $package_name: \^"; then
      echo "Updating $package_name dependency in example to $VERSION"
      
      if [[ "$OSTYPE" == "darwin"* ]]; then
        # Use awk to only replace in dependencies section, not in dependency_overrides
        awk -v pkg="$package_name" -v ver="$VERSION" '
          BEGIN { in_deps = 0 }
          /^dependencies:/ { in_deps = 1; print; next }
          /^[a-z][a-z_]*:/ && in_deps { in_deps = 0 }
          in_deps && $0 ~ "^  "pkg": \\^" {
            print "  "pkg": ^"ver
            next
          }
          { print }
        ' "$example_pubspec" > "${example_pubspec}.tmp" && mv "${example_pubspec}.tmp" "$example_pubspec"
      else
        # Linux/Unix approach
        awk -v pkg="$package_name" -v ver="$VERSION" '
          BEGIN { in_deps = 0 }
          /^dependencies:/ { in_deps = 1; print; next }
          /^[a-z][a-z_]*:/ && in_deps { in_deps = 0 }
          in_deps && $0 ~ "^  "pkg": \\^" {
            print "  "pkg": ^"ver
            next
          }
          { print }
        ' "$example_pubspec" > "${example_pubspec}.tmp" && mv "${example_pubspec}.tmp" "$example_pubspec"
      fi
    fi
    
    # Update other internal dependencies in example projects, but only in dependencies section
    for pkg_name in "${package_names[@]}"; do
      if [[ "$pkg_name" != "$package_name" ]]; then
        # Only match in the dependencies section
        if echo "$deps_section" | grep -q "^  $pkg_name: \^"; then
          echo "Updating dependency on $pkg_name in example to version $VERSION"
          
          if [[ "$OSTYPE" == "darwin"* ]]; then
            awk -v pkg="$pkg_name" -v ver="$VERSION" '
              BEGIN { in_deps = 0 }
              /^dependencies:/ { in_deps = 1; print; next }
              /^[a-z][a-z_]*:/ && in_deps { in_deps = 0 }
              in_deps && $0 ~ "^  "pkg": \\^" {
                print "  "pkg": ^"ver
                next
              }
              { print }
            ' "$example_pubspec" > "${example_pubspec}.tmp" && mv "${example_pubspec}.tmp" "$example_pubspec"
          else
            awk -v pkg="$pkg_name" -v ver="$VERSION" '
              BEGIN { in_deps = 0 }
              /^dependencies:/ { in_deps = 1; print; next }
              /^[a-z][a-z_]*:/ && in_deps { in_deps = 0 }
              in_deps && $0 ~ "^  "pkg": \\^" {
                print "  "pkg": ^"ver
                next
              }
              { print }
            ' "$example_pubspec" > "${example_pubspec}.tmp" && mv "${example_pubspec}.tmp" "$example_pubspec"
          fi
        fi
      fi
    done
    
    # Also check dev_dependencies section
    dev_deps_section=$(awk '/^dev_dependencies:/{flag=1; next} /^[a-z]/{flag=0} flag' "$example_pubspec")
    
    for pkg_name in "${package_names[@]}"; do
      if echo "$dev_deps_section" | grep -q "^  $pkg_name: \^"; then
        echo "Updating dev dependency on $pkg_name in example to version $VERSION"
        
        if [[ "$OSTYPE" == "darwin"* ]]; then
          # This sed command looks for the package in dev_dependencies section and updates it
          awk -v pkg="$pkg_name" -v ver="$VERSION" '
            BEGIN { in_dev_deps = 0 }
            /^dev_dependencies:/ { in_dev_deps = 1; print; next }
            /^[a-z][a-z_]*:/ && in_dev_deps { in_dev_deps = 0 }
            in_dev_deps && $0 ~ "^  "pkg": \\^" {
              print "  "pkg": ^"ver
              next
            }
            { print }
          ' "$example_pubspec" > "${example_pubspec}.tmp" && mv "${example_pubspec}.tmp" "$example_pubspec"
        else
          # For Linux we use a similar approach
          awk -v pkg="$pkg_name" -v ver="$VERSION" '
            BEGIN { in_dev_deps = 0 }
            /^dev_dependencies:/ { in_dev_deps = 1; print; next }
            /^[a-z][a-z_]*:/ && in_dev_deps { in_dev_deps = 0 }
            in_dev_deps && $0 ~ "^  "pkg": \\^" {
              print "  "pkg": ^"ver
              next
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
