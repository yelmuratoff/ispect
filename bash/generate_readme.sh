#!/bin/bash
# ./bash/generate_readme.sh generate all

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Paths
GENERATOR_SCRIPT="$ROOT_DIR/readme_generator/generate_readme.dart"
CONFIGS_DIR="$ROOT_DIR/readme_generator/configs"
PACKAGES_DIR="$ROOT_DIR/packages"

# Function to display usage
show_usage() {
    echo -e "${BLUE}README Generator for ISpect Packages${NC}"
    echo ""
    echo "Usage: $0 [COMMAND] [PACKAGE_NAME]"
    echo ""
    echo "Commands:"
    echo "  generate [package_name]  Generate README for specific package"
    echo "  generate all            Generate README for all packages"
    echo "  list                    List available packages"
    echo "  validate [package_name] Validate package configuration"
    echo "  help                    Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 generate ispect"
    echo "  $0 generate all"
    echo "  $0 list"
    echo "  $0 validate ispectify_dio"
}

# Function to list available packages
list_packages() {
    echo -e "${BLUE}Available packages:${NC}"
    if [ -d "$CONFIGS_DIR" ]; then
        for config in "$CONFIGS_DIR"/*.json; do
            if [ -f "$config" ]; then
                package_name=$(basename "$config" .json)
                echo -e "  ${GREEN}✓${NC} $package_name"
            fi
        done
    else
        echo -e "${RED}❌ Configs directory not found: $CONFIGS_DIR${NC}"
        exit 1
    fi
}

# Function to validate package configuration
validate_package() {
    local package_name="$1"
    local config_file="$CONFIGS_DIR/$package_name.json"
    local package_dir="$PACKAGES_DIR/$package_name"
    
    echo -e "${BLUE}Validating package: $package_name${NC}"
    
    # Check if config exists
    if [ ! -f "$config_file" ]; then
        echo -e "${RED}❌ Config file not found: $config_file${NC}"
        return 1
    fi
    
    # Check if package directory exists
    if [ ! -d "$package_dir" ]; then
        echo -e "${RED}❌ Package directory not found: $package_dir${NC}"
        return 1
    fi
    
    # Validate JSON syntax
    if ! jq empty "$config_file" 2>/dev/null; then
        echo -e "${RED}❌ Invalid JSON in config file: $config_file${NC}"
        return 1
    fi
    
    # Check required fields
    local required_fields=("package_name" "title" "description" "version")
    for field in "${required_fields[@]}"; do
        if ! jq -e ".$field" "$config_file" >/dev/null 2>&1; then
            echo -e "${RED}❌ Missing required field '$field' in config${NC}"
            return 1
        fi
    done
    
    echo -e "${GREEN}✅ Package configuration is valid${NC}"
    return 0
}

# Function to generate README
generate_readme() {
    local package_name="$1"
    
    if [ "$package_name" = "all" ]; then
        echo -e "${BLUE}Generating README files for all packages...${NC}"
        dart run "$GENERATOR_SCRIPT" all
    else
        if validate_package "$package_name"; then
            echo -e "${BLUE}Generating README for $package_name...${NC}"
            dart run "$GENERATOR_SCRIPT" "$package_name"
        else
            echo -e "${RED}❌ Cannot generate README due to validation errors${NC}"
            exit 1
        fi
    fi
}

# Function to check dependencies
check_dependencies() {
    # Check if dart is available
    if ! command -v dart &> /dev/null; then
        echo -e "${RED}❌ Dart is not installed or not in PATH${NC}"
        exit 1
    fi
    
    # Check if jq is available (for JSON validation)
    if ! command -v jq &> /dev/null; then
        echo -e "${YELLOW}⚠️  jq is not installed. JSON validation will be skipped.${NC}"
        echo -e "${YELLOW}   Install jq for better validation: brew install jq${NC}"
    fi
}

# Main script logic
main() {
    check_dependencies
    
    case "${1:-help}" in
        "generate")
            if [ -z "$2" ]; then
                echo -e "${RED}❌ Package name required${NC}"
                echo "Usage: $0 generate <package_name|all>"
                exit 1
            fi
            generate_readme "$2"
            ;;
        "list")
            list_packages
            ;;
        "validate")
            if [ -z "$2" ]; then
                echo -e "${RED}❌ Package name required${NC}"
                echo "Usage: $0 validate <package_name>"
                exit 1
            fi
            validate_package "$2"
            ;;
        "help"|"-h"|"--help")
            show_usage
            ;;
        *)
            echo -e "${RED}❌ Unknown command: $1${NC}"
            show_usage
            exit 1
            ;;
    esac
}

# Change to root directory
cd "$ROOT_DIR" || exit 1

# Run main function
main "$@"
