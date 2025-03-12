#!/bin/bash
# chmod +x bash/update_changelog.sh
# ./bash/update_changelog.sh


# Define the path to the main CHANGELOG.md
MAIN_CHANGELOG="CHANGELOG.md"

# Check if the main CHANGELOG.md exists
if [[ ! -f "$MAIN_CHANGELOG" ]]; then
    echo "File $MAIN_CHANGELOG not found!"
    exit 1
fi

# Loop through all subdirectories in packages/
for dir in packages/*/; do
    PACKAGE_CHANGELOG="${dir}CHANGELOG.md"

    # Check if the package's CHANGELOG.md exists
    if [[ -f "$PACKAGE_CHANGELOG" ]]; then
        cp "$MAIN_CHANGELOG" "$PACKAGE_CHANGELOG"
        echo "Updated $PACKAGE_CHANGELOG"
    else
        echo "File $PACKAGE_CHANGELOG not found, skipping..."
    fi
done

echo "Done!"
