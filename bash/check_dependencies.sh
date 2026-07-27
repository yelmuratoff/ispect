#!/bin/bash

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root_dir" || exit 1

version_file="version.config"
if [[ ! -f "$version_file" ]]; then
  echo "Error: $version_file not found"
  exit 1
fi

VERSION=$(awk -F= '$1 == "VERSION" { print substr($0, index($0, "=") + 1); exit }' "$version_file")
if [[ -z "$VERSION" ]]; then
  echo "Error: VERSION not defined in $version_file"
  exit 1
fi

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

for package_dir in packages/*/; do
  pubspec_file="${package_dir}pubspec.yaml"
  package_name=$(grep -E "^name:" "$pubspec_file" | sed 's/name: //' | tr -d ' ')
  
  echo "Checking $package_name..."
  
  for dep_pkg in "${package_names[@]}"; do
    if [[ "$dep_pkg" != "$package_name" ]]; then
      deps_section=$(awk '/^dependencies:/{flag=1; next} /^[a-z]/{flag=0} flag' "$pubspec_file" || echo "")
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
  
  for dep_pkg in "${package_names[@]}"; do
    if [[ "$dep_pkg" != "$package_name" ]]; then
      dev_deps_section=$(awk '/^dev_dependencies:/{flag=1; next} /^[a-z]/{flag=0} flag' "$pubspec_file" || echo "")
      dev_dep_line=$(echo "$dev_deps_section" | grep -E "^  $dep_pkg: \^" || echo "")
      
      if [[ -n "$dev_dep_line" ]]; then
        dev_dep_version=$(echo "$dev_dep_line" | sed -E 's/^  [^:]+: \^([0-9]+\.[0-9]+\.[0-9]+(-.+)?)/\1/')
        
        if [[ "$dev_dep_version" != "$VERSION" ]]; then
          echo "  ⚠️  Dev dependency inconsistency in $package_name: depends on $dep_pkg version ^$dev_dep_version, should be ^$VERSION"
          has_inconsistency=1
        else
          echo "  ✅ $package_name dev depends on $dep_pkg version ^$VERSION"
        fi
      fi
    fi
  done

  example_pubspec="${package_dir}example/pubspec.yaml"
  if [[ -f "$example_pubspec" ]]; then
    echo "  Checking example project for $package_name..."
    
    deps_section=$(awk '/^dependencies:/{flag=1; next} /^[a-z]/{flag=0} flag' "$example_pubspec" || echo "")
    
    parent_dep_line=$(echo "$deps_section" | grep -E "^  $package_name: \^" || echo "")
    if [[ -n "$parent_dep_line" ]]; then
      parent_dep_version=$(echo "$parent_dep_line" | sed -E 's/^  [^:]+: \^([0-9]+\.[0-9]+\.[0-9]+(-.+)?)/\1/')
      if [[ "$parent_dep_version" != "$VERSION" && "$parent_dep_version" != "" ]]; then
        echo "  ⚠️  Example inconsistency: depends on $package_name version ^$parent_dep_version, should be ^$VERSION"
        has_inconsistency=1
      fi
    fi
    
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
    
    if grep -q "dependency_overrides:" "$example_pubspec"; then
      for dep_pkg in "${package_names[@]}"; do
        if grep -A10 "dependency_overrides:" "$example_pubspec" | grep -q "  $dep_pkg:" && grep -A10 "dependency_overrides:" "$example_pubspec" | grep -A1 "  $dep_pkg:" | grep -q "path:"; then
          echo "  📝 Example uses local path override for $dep_pkg"
        fi
      done
    fi
  fi
done

# Local path overrides do not replace published-style version constraints.
project_pubspec="web_logs_viewer/pubspec.yaml"
if [[ -f "$project_pubspec" ]]; then
  project_name=$(grep -E "^name:" "$project_pubspec" | sed 's/name: //' | tr -d ' ')
  echo "Checking $project_name..."

  deps_section=$(awk '/^dependencies:/{flag=1; next} /^[a-z]/{flag=0} flag' "$project_pubspec" || echo "")
  dev_deps_section=$(awk '/^dev_dependencies:/{flag=1; next} /^[a-z]/{flag=0} flag' "$project_pubspec" || echo "")

  for dep_pkg in "${package_names[@]}"; do
    dep_line=$(echo "$deps_section" | grep -E "^  $dep_pkg: \^" || echo "")
    if [[ -n "$dep_line" ]]; then
      dep_version=$(echo "$dep_line" | sed -E 's/^  [^:]+: \^([0-9]+\.[0-9]+\.[0-9]+(-.+)?)/\1/')
      if [[ "$dep_version" != "$VERSION" ]]; then
        echo "  ⚠️  Inconsistency in $project_name: depends on $dep_pkg version ^$dep_version, should be ^$VERSION"
        has_inconsistency=1
      else
        echo "  ✅ $project_name depends on $dep_pkg version ^$VERSION"
      fi
    fi

    dev_dep_line=$(echo "$dev_deps_section" | grep -E "^  $dep_pkg: \^" || echo "")
    if [[ -n "$dev_dep_line" ]]; then
      dev_dep_version=$(echo "$dev_dep_line" | sed -E 's/^  [^:]+: \^([0-9]+\.[0-9]+\.[0-9]+(-.+)?)/\1/')
      if [[ "$dev_dep_version" != "$VERSION" ]]; then
        echo "  ⚠️  Dev dependency inconsistency in $project_name: depends on $dep_pkg version ^$dev_dep_version, should be ^$VERSION"
        has_inconsistency=1
      else
        echo "  ✅ $project_name dev depends on $dep_pkg version ^$VERSION"
      fi
    fi
  done
fi

if [ $has_inconsistency -eq 1 ]; then
  echo -e "\n❌ Found version inconsistencies in dependencies. Run ./bash/update_versions.sh to fix them."
  exit 1
else
  echo -e "\n✅ All internal dependencies are consistent with version $VERSION"
  exit 0
fi
