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
CONFIG_PATH="$HOME/.terminal_assistant_config.json"

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

# Check and update API key
print_header "Checking API Key Configuration"

if [ -f "$CONFIG_PATH" ]; then
    if grep -q '"api_key":' "$CONFIG_PATH"; then
        echo -e "API key configuration found in $CONFIG_PATH"
        echo -e "Your current API key might be invalid or expired."
        echo -e "Would you like to update your Gemini API key? (yes/no)"
        read -r UPDATE_KEY
        
        if [[ "$UPDATE_KEY" =~ ^[Yy](es)?$ ]]; then
            echo -e "Get an API key from ${CYAN}https://ai.google.dev/${NC}"
            echo -e "Please enter your new Gemini API key:"
            read -r API_KEY
            
            if [ -n "$API_KEY" ]; then
                # Create a temporary file and update the API key
                TMP_FILE=$(mktemp)
                if command -v jq &>/dev/null; then
                    # Use jq if available
                    jq --arg key "$API_KEY" '.api_key = $key' "$CONFIG_PATH" > "$TMP_FILE"
                    mv "$TMP_FILE" "$CONFIG_PATH"
                else
                    # Fallback to sed if jq is not available
                    sed -E "s/(\"api_key\"[[:space:]]*:[[:space:]]*)\"[^\"]*\"/\1\"$API_KEY\"/" "$CONFIG_PATH" > "$TMP_FILE"
                    mv "$TMP_FILE" "$CONFIG_PATH"
                fi
                print_success "API key updated in $CONFIG_PATH"
            else
                print_error "No API key provided. You'll need to update it manually."
            fi
        fi
    else
        echo -e "No API key found in config file. Adding one now."
        echo -e "Get an API key from ${CYAN}https://ai.google.dev/${NC}"
        echo -e "Please enter your Gemini API key:"
        read -r API_KEY
        
        if [ -n "$API_KEY" ]; then
            # Check if config file is valid JSON
            if command -v jq &>/dev/null && jq . "$CONFIG_PATH" >/dev/null 2>&1; then
                # Use jq to add API key to existing config
                TMP_FILE=$(mktemp)
                jq --arg key "$API_KEY" '. + {api_key: $key}' "$CONFIG_PATH" > "$TMP_FILE"
                mv "$TMP_FILE" "$CONFIG_PATH"
            else
                # Create a new config file
                echo '{
  "api_key": "'"$API_KEY"'",
  "model": "gemini-1.5-pro",
  "scripts_dir": "'"$HOME/scripts"'",
  "auto_confirm_safe": false,
  "safety_level": "high"
}' > "$CONFIG_PATH"
            fi
            print_success "API key added to $CONFIG_PATH"
        else
            print_error "No API key provided. You'll need to add one manually."
        fi
    fi
else
    echo -e "No configuration file found at $CONFIG_PATH"
    echo -e "Creating a new configuration file..."
    echo -e "Get an API key from ${CYAN}https://ai.google.dev/${NC}"
    echo -e "Please enter your Gemini API key:"
    read -r API_KEY
    
    if [ -n "$API_KEY" ]; then
        echo '{
  "api_key": "'"$API_KEY"'",
  "model": "gemini-1.5-pro",
  "scripts_dir": "'"$HOME/scripts"'",
  "auto_confirm_safe": false,
  "safety_level": "high"
}' > "$CONFIG_PATH"
        print_success "Created configuration file with API key"
    else
        echo '{
  "model": "gemini-1.5-pro",
  "scripts_dir": "'"$HOME/scripts"'",
  "auto_confirm_safe": false,
  "safety_level": "high"
}' > "$CONFIG_PATH"
        print_error "No API key provided. You'll need to add one manually."
    fi
fi

print_header "Fix Complete!"
echo -e "The Terminal Assistant installation has been fixed."
echo -e ""
echo -e "You can now use Terminal Assistant with the ${CYAN}ta${NC} command."
echo -e "If you encounter any other issues, please run the full installer again:"
echo -e "  ${CYAN}./install.sh${NC}" 