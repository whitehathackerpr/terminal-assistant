#!/usr/bin/env bash

# Terminal Assistant Demo Script

# Set colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if Terminal Assistant is already installed
if [ -d "$HOME/.terminal-assistant" ] && command -v ta &>/dev/null; then
    echo -e "${GREEN}Terminal Assistant is already installed!${NC}"
    echo -e "${YELLOW}Using existing installation for demo.${NC}"
    TA_CMD="ta"
    INSTALLED=true
else
    echo -e "${BLUE}Installing Terminal Assistant...${NC}"
    # Check if install.sh exists, otherwise download it
    if [ -f "install.sh" ]; then
        echo -e "${YELLOW}Running local installer...${NC}"
        chmod +x install.sh
        ./install.sh
    else
        echo -e "${YELLOW}Downloading and running installer...${NC}"
        curl -sSL https://raw.githubusercontent.com/alvin/terminal-assistant/main/install.sh | bash
    fi
    
    # Source the shell config to get the alias
    if [ -f "$HOME/.bashrc" ]; then
        source "$HOME/.bashrc"
    elif [ -f "$HOME/.zshrc" ]; then
        source "$HOME/.zshrc"
    fi
    
    if command -v ta &>/dev/null; then
        TA_CMD="ta"
    else
        TA_CMD="$HOME/.terminal-assistant/venv/bin/python $HOME/.terminal-assistant/terminal_assistant.py --config $HOME/.terminal_assistant_config.json"
    fi
    INSTALLED=false
fi

# Check for API key
if [ ! -f "$HOME/.terminal_assistant_config.json" ] || ! grep -q "api_key" "$HOME/.terminal_assistant_config.json"; then
    echo -e "${YELLOW}Warning: No API key configured.${NC}"
    echo -e "Get an API key from ${CYAN}https://ai.google.dev/${NC}"
    
    echo -e "Please enter your Gemini API key (or press Enter to skip):"
    read -r API_KEY
    
    if [ -n "$API_KEY" ]; then
        if [ -f "$HOME/.terminal_assistant_config.json" ]; then
            # Update existing config
            TMP_FILE=$(mktemp)
            jq --arg key "$API_KEY" '.api_key = $key' "$HOME/.terminal_assistant_config.json" > "$TMP_FILE"
            mv "$TMP_FILE" "$HOME/.terminal_assistant_config.json"
        else
            # Create new config
            mkdir -p "$HOME/scripts"
            echo '{
  "api_key": "'"$API_KEY"'",
  "model": "gemini-2.5-pro-preview-05-06",
  "scripts_dir": "'"$HOME/scripts"'",
  "auto_confirm_safe": false,
  "safety_level": "high"
}' > "$HOME/.terminal_assistant_config.json"
        fi
        echo -e "${GREEN}API key configured successfully!${NC}"
    else
        echo -e "${RED}No API key provided. Demo may not work properly.${NC}"
        echo -e "Press Enter to continue anyway, or Ctrl+C to exit."
        read
    fi
fi

echo -e "${BLUE}Terminal Assistant Demo${NC}"
echo -e "${YELLOW}=====================${NC}"
echo ""

echo -e "${GREEN}1. Explaining a command${NC}"
echo -e "${CYAN}$ $TA_CMD \"explain: ls -la\"${NC}"
echo ""
echo -e "Press Enter to run example 1 or Ctrl+C to exit."
read
eval "$TA_CMD \"explain: ls -la\""
echo ""
echo -e "Press Enter to continue to the next example."
read

echo -e "${GREEN}2. Getting installation instructions${NC}"
echo -e "${CYAN}$ $TA_CMD \"install: docker\"${NC}"
echo ""
echo -e "Press Enter to run example 2 or Ctrl+C to exit."
read
eval "$TA_CMD \"install: docker\""
echo ""
echo -e "Press Enter to continue to the next example."
read

echo -e "${GREEN}3. OS Detection and System Information${NC}"
echo -e "${CYAN}$ $TA_CMD \"system-info\"${NC}"
echo ""
echo -e "Press Enter to run example 3 or Ctrl+C to exit."
read
eval "$TA_CMD \"system-info\""
echo ""
echo -e "Press Enter to continue to the next example."
read

echo -e "${GREEN}4. Automated installation${NC}"
echo -e "${CYAN}$ $TA_CMD \"auto-install: htop\"${NC}"
echo ""
echo -e "Press Enter to run example 4 or Ctrl+C to exit."
read
eval "$TA_CMD \"auto-install: htop\""
echo ""
echo -e "Press Enter to continue to the next example."
read

echo -e "${GREEN}5. Generating a shell script${NC}"
echo -e "${CYAN}$ $TA_CMD \"script: find all log files in /var/log older than 7 days and compress them\"${NC}"
echo ""
echo -e "Press Enter to run example 5 or Ctrl+C to exit."
read
eval "$TA_CMD \"script: find all log files in /var/log older than 7 days and compress them\""
echo ""
echo -e "Press Enter to continue to the next example."
read

echo -e "${GREEN}6. Analyzing an error log${NC}"
if [ -f "examples/error_log_example.txt" ]; then
    ERROR_LOG=$(cat examples/error_log_example.txt)
else
    ERROR_LOG="error: externally-managed-environment

× This environment is externally managed
╰─> To install Python packages system-wide, try apt install
    python3-xyz, where xyz is the package you are trying to
    install."
fi

echo -e "${CYAN}$ $TA_CMD \"errorlog: $ERROR_LOG\"${NC}"
echo ""
echo -e "Press Enter to run example 6 or Ctrl+C to exit."
read
eval "$TA_CMD \"errorlog: $ERROR_LOG\""
echo ""
echo -e "Press Enter to continue to the next example."
read

echo -e "${GREEN}7. Automated fix${NC}"
echo -e "${CYAN}$ $TA_CMD \"fix: python package installation fails with externally-managed-environment error\"${NC}"
echo ""
echo -e "Press Enter to run example 7 or Ctrl+C to exit."
read
eval "$TA_CMD \"fix: python package installation fails with externally-managed-environment error\""
echo ""
echo -e "Press Enter to continue to the next example."
read

echo -e "${GREEN}8. Changing the safety level${NC}"
echo -e "${CYAN}$ $TA_CMD \"safety-level: medium\"${NC}"
echo ""
echo -e "Press Enter to run example 8 or Ctrl+C to exit."
read
eval "$TA_CMD \"safety-level: medium\""
echo ""
echo -e "Press Enter to continue to the next example."
read

echo -e "${GREEN}9. Asking a general question${NC}"
echo -e "${CYAN}$ $TA_CMD \"How do I check disk space on Linux?\"${NC}"
echo ""
echo -e "Press Enter to run example 9 or Ctrl+C to exit."
read
eval "$TA_CMD \"How do I check disk space on Linux?\""
echo ""
echo -e "Press Enter to continue to the interactive mode."
read

echo -e "${GREEN}10. Interactive mode${NC}"
echo -e "${CYAN}$ $TA_CMD -i${NC}"
echo ""
echo -e "Press Enter to start interactive mode or Ctrl+C to exit."
read
eval "$TA_CMD -i"

echo -e "${BLUE}Demo completed!${NC}"

if [ "$INSTALLED" = false ]; then
    echo -e "\n${YELLOW}Terminal Assistant was installed during this demo.${NC}"
    echo -e "You can use it anytime by typing ${CYAN}ta${NC} in your terminal."
    echo -e "To remove it, run: ${CYAN}~/.terminal-assistant/uninstall.sh${NC}"
fi

echo -e "\nFor more information, see README.md" 