#!/usr/bin/env bash

# Terminal Assistant Dependency Updater
# This script updates all Terminal Assistant dependencies to their latest versions

# Set colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

INSTALL_DIR="$HOME/.terminal-assistant"

# Function to print header
print_header() {
    echo -e "\n${BLUE}$1${NC}"
    echo -e "${YELLOW}$(printf '=%.0s' $(seq 1 ${#1}))${NC}\n"
}

# Function to print success message
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Function to print error message
print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_header "Terminal Assistant Dependency Updater"

# Check if Terminal Assistant is installed
if [ ! -d "$INSTALL_DIR" ] || [ ! -d "$INSTALL_DIR/venv" ]; then
    print_error "Terminal Assistant is not installed or the virtual environment is missing."
    echo -e "Please run the installer first: ${CYAN}./install.sh${NC}"
    exit 1
fi

print_header "Activating Virtual Environment"
source "$INSTALL_DIR/venv/bin/activate" || {
    print_error "Failed to activate virtual environment."
    exit 1
}
print_success "Virtual environment activated"

print_header "Updating Dependencies"

# First ensure setuptools is installed (provides pkg_resources)
pip install -U setuptools wheel || {
    print_error "Failed to install setuptools."
    exit 1
}
print_success "Installed setuptools"

# Create a temporary file with just package names
TEMP_REQUIREMENTS=$(mktemp)
echo "google-generativeai" > "$TEMP_REQUIREMENTS"
echo "distro" >> "$TEMP_REQUIREMENTS"

# Install latest versions
pip install -U -r "$TEMP_REQUIREMENTS" || {
    print_error "Failed to update packages."
    rm -f "$TEMP_REQUIREMENTS"
    exit 1
}

# Update requirements.txt with latest versions
REQUIREMENTS_PATH="$INSTALL_DIR/requirements.txt"
pip freeze | grep -E "google-generativeai|distro" > "$REQUIREMENTS_PATH"
print_success "Updated requirements.txt with latest versions"

rm -f "$TEMP_REQUIREMENTS"

# Show updated versions
echo -e "\nInstalled package versions:"
grep -E "google-generativeai|distro" "$REQUIREMENTS_PATH" | sed 's/^/  /'

print_header "Update Complete!"
echo -e "All Terminal Assistant dependencies have been updated to their latest versions."
echo -e ""
echo -e "You can now use Terminal Assistant with the latest package versions."
echo -e "Type ${CYAN}ta${NC} in your terminal to start using Terminal Assistant." 