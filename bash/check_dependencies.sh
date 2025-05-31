#!/bin/bash
# check_dependencies.sh - Check if internal package dependencies match the current version
# chmod +x bash/check_dependencies.sh && ./bash/check_dependencies.sh

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

# First, collect all package names
declare -a package_names=()
for package_dir in packages/*/; do
  pubspec_file="${package_dir}pubspec.yaml"
  if [[ -f "$pubspec_file" ]]; then
    package_name=$(grep -E "^name:" "$pubspec_file" | sed 's/name: //' | tr -d ' ')
    package_names+=("$package_name")
  fi
done

echo "Checking internal dependencies for version consistency with $VERSION..."
has_inconsistency=0

# Check all packages
for package_dir in packages/*/; do
  pubspec_file="${package_dir}pubspec.yaml"
  package_name=$(grep -E "^name:" "$pubspec_file" | sed 's/name: //' | tr -d ' ')
  
  echo "Checking $package_name..."
  
  # Check for dependencies on other internal packages, but only in dependencies section
  for dep_pkg in "${package_names[@]}"; do
    if [[ "$dep_pkg" != "$package_name" ]]; then
      # Extract the dependencies section and check for the package
      deps_section=$(grep -A1000 "^dependencies:" "$pubspec_file" | grep -B1000 -m1 "^[a-z]" || echo "")
      dep_line=$(echo "$deps_section" | grep -E "^  $dep_pkg: \^" || echo "")
      
      if [[ -n "$dep_line" ]]; then
        dep_version=$(echo "$dep_line" | sed -E 's/^  [^:]+: \^([0-9]+\.[0-9]+\.[0-9]+(-.+)?)/\1/')
        
        if [[ "$dep_version" != "$VERSION" ]]; then
          echo "  ⚠️  Inconsistency in $package_name: depends on $dep_pkg version ^$dep_version, should be ^$VERSION"
          has_inconsistency=1
        else
          echo "  ✅ $package_name depends on $dep_pkg version ^$VERSION"
        fi
      fi
    fi
  done

  # Check example folders
  example_pubspec="${package_dir}example/pubspec.yaml"
  if [[ -f "$example_pubspec" ]]; then
    echo "  Checking example project for $package_name..."
    
    # Skip checking examples with dependency_overrides as they use local paths
    if grep -q "dependency_overrides:" "$example_pubspec"; then
      if grep -q "  $package_name:" "$example_pubspec" | grep -q "path:"; then
        echo "  ✅ Example uses local path override for $package_name"
        continue
      fi
    fi
    
    # Extract the dependencies section
    deps_section=$(grep -A1000 "^dependencies:" "$example_pubspec" | grep -B1000 -m1 "^[a-z]" || echo "")
    
    # Check parent package dependency in example - but only in the dependencies section
    parent_dep_line=$(echo "$deps_section" | grep -E "^  $package_name: \^" || echo "")
    if [[ -n "$parent_dep_line" ]]; then
      parent_dep_version=$(echo "$parent_dep_line" | sed -E 's/^  [^:]+: \^([0-9]+\.[0-9]+\.[0-9]+(-.+)?)/\1/')
      if [[ "$parent_dep_version" != "$VERSION" && "$parent_dep_version" != "" ]]; then
        echo "  ⚠️  Example inconsistency: depends on $package_name version ^$parent_dep_version, should be ^$VERSION"
        has_inconsistency=1
      fi
    fi
    
    # Check other internal dependencies in example - only in the dependencies section
    for dep_pkg in "${package_names[@]}"; do
      if [[ "$dep_pkg" != "$package_name" ]]; then
        dep_line=$(echo "$deps_section" | grep -E "^  $dep_pkg: \^" || echo "")
        if [[ -n "$dep_line" ]]; then
          dep_version=$(echo "$dep_line" | sed -E 's/^  [^:]+: \^([0-9]+\.[0-9]+\.[0-9]+(-.+)?)/\1/')
          
          if [[ "$dep_version" != "$VERSION" ]]; then
            echo "  ⚠️  Example inconsistency: depends on $dep_pkg version ^$dep_version, should be ^$VERSION"
            has_inconsistency=1
          fi
        fi
      fi
    done
  fi
done

if [ $has_inconsistency -eq 1 ]; then
  echo -e "\n❌ Found version inconsistencies in dependencies. Run ./bash/update_versions.sh to fix them."
  exit 1
else
  echo -e "\n✅ All internal dependencies are consistent with version $VERSION"
  exit 0
fi
