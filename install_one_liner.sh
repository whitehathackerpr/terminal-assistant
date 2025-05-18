#!/usr/bin/env bash

# One-line installer for Terminal Assistant
# Usage: curl -sSL https://raw.githubusercontent.com/alvin/terminal-assistant/main/install_one_liner.sh | bash

# Set colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}    Terminal Assistant Installer       ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}This script will download and install Terminal Assistant.${NC}"
echo -e "${YELLOW}The script will:${NC}"
echo -e "  ${GREEN}1.${NC} Create a directory at ${CYAN}~/.terminal-assistant${NC}"
echo -e "  ${GREEN}2.${NC} Set up a Python virtual environment"
echo -e "  ${GREEN}3.${NC} Install and auto-update required dependencies to latest versions"
echo -e "  ${GREEN}4.${NC} Add a ${CYAN}ta${NC} command to your shell"
echo -e "  ${GREEN}5.${NC} Ask for your Gemini API key"
echo ""
echo -e "${YELLOW}Press Enter to continue or Ctrl+C to cancel${NC}"
read -r

# Create temporary directory
TMP_DIR=$(mktemp -d)
cd "$TMP_DIR" || { echo -e "${RED}Failed to create temporary directory${NC}"; exit 1; }

# Download the repository files
echo -e "${BLUE}Downloading Terminal Assistant...${NC}"
if command -v git &>/dev/null; then
    git clone https://github.com/alvin/terminal-assistant.git .
else
    # If git is not available, download main files individually
    echo -e "${YELLOW}Git not found, downloading individual files...${NC}"
    mkdir -p examples
    curl -sSL https://raw.githubusercontent.com/alvin/terminal-assistant/main/terminal_assistant.py -o terminal_assistant.py
    curl -sSL https://raw.githubusercontent.com/alvin/terminal-assistant/main/install.sh -o install.sh
    curl -sSL https://raw.githubusercontent.com/alvin/terminal-assistant/main/README.md -o README.md
    curl -sSL https://raw.githubusercontent.com/alvin/terminal-assistant/main/examples/error_log_example.txt -o examples/error_log_example.txt
fi

# Make install script executable
chmod +x install.sh

# Run the installer
echo -e "${BLUE}Running installer...${NC}"
./install.sh

# Clean up
cd - > /dev/null
rm -rf "$TMP_DIR"

echo -e "${GREEN}Installation complete!${NC}"
echo -e "${YELLOW}You may need to restart your terminal or run ${CYAN}source ~/.bashrc${NC} (or your shell's config file)${NC}"
echo -e "${YELLOW}Then simply use ${CYAN}ta${NC} to run Terminal Assistant${NC}" 