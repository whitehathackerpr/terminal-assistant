#!/usr/bin/env bash

# Terminal Assistant Installation Fix Script
# This script fixes common installation issues

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

print_header "Terminal Assistant Fix Script"

# Check if Terminal Assistant is installed
if [ ! -d "$INSTALL_DIR" ]; then
    print_error "Terminal Assistant is not installed. Please run the installer first."
    exit 1
fi

print_header "Fixing Missing Dependencies"

# Check if virtual environment exists
if [ ! -d "$INSTALL_DIR/venv" ]; then
    print_error "Virtual environment not found. Creating a new one..."
    python3 -m venv "$INSTALL_DIR/venv" || {
        print_error "Failed to create virtual environment."
        exit 1
    }
fi

# Activate virtual environment
source "$INSTALL_DIR/venv/bin/activate" || {
    print_error "Failed to activate virtual environment."
    exit 1
}
print_success "Virtual environment activated"

# Install setuptools (which provides pkg_resources)
echo -e "Installing setuptools..."
pip install -U setuptools wheel || {
    print_error "Failed to install setuptools."
    exit 1
}
print_success "Installed setuptools"

# Reinstall required packages
echo -e "Reinstalling required packages..."
pip install -U google-generativeai distro || {
    print_error "Failed to install required packages."
    exit 1
}
print_success "Reinstalled required packages"

# Update requirements.txt
echo -e "Updating requirements.txt..."
REQUIREMENTS_PATH="$INSTALL_DIR/requirements.txt"
pip freeze | grep -E "google-generativeai|distro|setuptools" > "$REQUIREMENTS_PATH"
print_success "Updated requirements.txt with latest versions"

print_header "Fix Complete!"
echo -e "The Terminal Assistant installation has been fixed."
echo -e ""
echo -e "You can now use Terminal Assistant with the ${CYAN}ta${NC} command."
echo -e "If you encounter any other issues, please run the full installer again:"
echo -e "  ${CYAN}./install.sh${NC}" 