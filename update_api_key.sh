#!/usr/bin/env bash

# Terminal Assistant API Key Update Script

# Set colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

CONFIG_PATH="$HOME/.terminal_assistant_config.json"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}    Terminal Assistant API Key Update  ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if config file exists
if [ ! -f "$CONFIG_PATH" ]; then
    echo -e "${YELLOW}No configuration file found. Creating a new one...${NC}"
    
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
        echo -e "${GREEN}Created configuration file with API key${NC}"
    else
        echo -e "${RED}No API key provided. Cannot continue.${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}Updating API key in existing configuration file${NC}"
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
        echo -e "${GREEN}API key updated successfully${NC}"
    else
        echo -e "${RED}No API key provided. Cannot continue.${NC}"
        exit 1
    fi
fi

echo ""
echo -e "${GREEN}API key update complete!${NC}"
echo -e "You can now use Terminal Assistant with the ${CYAN}ta${NC} command." 