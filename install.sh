#!/usr/bin/env bash

# Terminal Assistant Installer
# This script automatically installs and configures the Terminal Assistant

# Set colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

INSTALL_DIR="$HOME/.terminal-assistant"
SCRIPT_PATH="$INSTALL_DIR/terminal_assistant.py"
CONFIG_PATH="$HOME/.terminal_assistant_config.json"
SCRIPTS_DIR="$HOME/scripts"
ALIAS_NAME="terminal-assistant"
ALIAS_CMD="ta"

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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for root
if [[ $EUID -eq 0 ]]; then
    print_error "This script should not be run as root."
    exit 1
fi

print_header "Terminal Assistant Installer"

# Detect OS
print_header "Detecting Operating System"
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
    
    # Try to detect Linux distribution
    if command_exists lsb_release; then
        DISTRO=$(lsb_release -si)
    elif [ -f /etc/os-release ]; then
        DISTRO=$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"')
    else
        DISTRO="unknown"
    fi
    
    echo -e "Detected: ${CYAN}Linux - $DISTRO${NC}"
    
    # Check package manager
    if command_exists apt; then
        PKG_MANAGER="apt"
        INSTALL_CMD="sudo apt update && sudo apt install -y"
    elif command_exists dnf; then
        PKG_MANAGER="dnf"
        INSTALL_CMD="sudo dnf install -y"
    elif command_exists yum; then
        PKG_MANAGER="yum"
        INSTALL_CMD="sudo yum install -y"
    elif command_exists pacman; then
        PKG_MANAGER="pacman"
        INSTALL_CMD="sudo pacman -S --noconfirm"
    elif command_exists zypper; then
        PKG_MANAGER="zypper"
        INSTALL_CMD="sudo zypper install -y"
    else
        PKG_MANAGER="unknown"
        INSTALL_CMD=""
    fi
    
    if [ -n "$PKG_MANAGER" ]; then
        echo -e "Package Manager: ${CYAN}$PKG_MANAGER${NC}"
    else
        print_error "Could not detect package manager. You may need to install dependencies manually."
    fi
    
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
    DISTRO="macos"
    echo -e "Detected: ${CYAN}macOS${NC}"
    
    # Check if Homebrew is installed
    if command_exists brew; then
        PKG_MANAGER="brew"
        INSTALL_CMD="brew install"
    else
        print_error "Homebrew not found. Please install Homebrew first: https://brew.sh/"
        PKG_MANAGER="unknown"
        INSTALL_CMD=""
    fi
else
    OS="unknown"
    DISTRO="unknown"
    PKG_MANAGER="unknown"
    INSTALL_CMD=""
    print_error "Unsupported operating system: $OSTYPE"
fi

# Create installation directory
print_header "Creating Installation Directory"
mkdir -p "$INSTALL_DIR"
mkdir -p "$SCRIPTS_DIR"

if [ -d "$INSTALL_DIR" ]; then
    print_success "Created directory: $INSTALL_DIR"
else
    print_error "Failed to create installation directory."
    exit 1
fi

# Install Python and dependencies
print_header "Installing Required Dependencies"

# Python is required
if ! command_exists python3; then
    echo -e "Python 3 not found. Installing..."
    if [ -n "$INSTALL_CMD" ]; then
        $INSTALL_CMD python3 || {
            print_error "Failed to install Python 3."
            exit 1
        }
    else
        print_error "Please install Python 3 manually."
        exit 1
    fi
else
    echo -e "Python 3 is already installed: $(python3 --version)"
fi

# Install pip if not available
if ! command_exists pip3 && ! command_exists pip; then
    echo -e "Pip not found. Installing..."
    if [ "$PKG_MANAGER" = "apt" ]; then
        $INSTALL_CMD python3-pip || {
            print_error "Failed to install pip."
            exit 1
        }
    elif [ "$PKG_MANAGER" = "dnf" ] || [ "$PKG_MANAGER" = "yum" ]; then
        $INSTALL_CMD python3-pip || {
            print_error "Failed to install pip."
            exit 1
        }
    elif [ "$PKG_MANAGER" = "pacman" ]; then
        $INSTALL_CMD python-pip || {
            print_error "Failed to install pip."
            exit 1
        }
    elif [ "$PKG_MANAGER" = "brew" ]; then
        $INSTALL_CMD python || {
            print_error "Failed to install Python with pip."
            exit 1
        }
    else
        print_error "Please install pip manually."
        exit 1
    fi
fi

# Determine pip command
if command_exists pip3; then
    PIP_CMD="pip3"
elif command_exists pip; then
    PIP_CMD="pip"
else
    print_error "Pip not found. Please install pip manually."
    exit 1
fi

# Set up virtual environment
print_header "Setting Up Virtual Environment"
if ! command_exists python3 -m venv; then
    echo -e "Python venv module not found. Installing..."
    if [ "$PKG_MANAGER" = "apt" ]; then
        $INSTALL_CMD python3-venv || {
            print_error "Failed to install python3-venv."
            exit 1
        }
    elif [ "$PKG_MANAGER" = "dnf" ] || [ "$PKG_MANAGER" = "yum" ]; then
        $INSTALL_CMD python3-venv || {
            print_error "Failed to install python3-venv."
            exit 1
        }
    fi
fi

# Create virtual environment
python3 -m venv "$INSTALL_DIR/venv" || {
    print_error "Failed to create virtual environment."
    exit 1
}
print_success "Created virtual environment at $INSTALL_DIR/venv"

# Install Python packages
print_header "Installing Python Packages"
source "$INSTALL_DIR/venv/bin/activate" || {
    print_error "Failed to activate virtual environment."
    exit 1
}

echo -e "Installing required packages..."

# First ensure setuptools is installed (provides pkg_resources)
"$INSTALL_DIR/venv/bin/pip" install -U setuptools wheel || {
    print_error "Failed to install setuptools."
    exit 1
}

# Auto-update requirements.txt file with latest package versions
if [ -f requirements.txt ]; then
    echo -e "Upgrading packages from requirements.txt with latest versions..."
    TEMP_REQUIREMENTS=$(mktemp)
    while IFS= read -r line || [ -n "$line" ]; do
        if [[ -n "$line" && ! "$line" =~ ^# ]]; then
            # Extract package name without version constraints
            PACKAGE=$(echo "$line" | sed -E 's/([a-zA-Z0-9_-]+).*/\1/')
            if [ -n "$PACKAGE" ]; then
                echo "$PACKAGE" >> "$TEMP_REQUIREMENTS"
            else
                echo "$line" >> "$TEMP_REQUIREMENTS"
            fi
        else
            echo "$line" >> "$TEMP_REQUIREMENTS"
        fi
    done < requirements.txt
    
    # Install latest versions of the packages
    "$INSTALL_DIR/venv/bin/pip" install -U -r "$TEMP_REQUIREMENTS" || {
        print_error "Failed to install required Python packages."
        rm -f "$TEMP_REQUIREMENTS"
        exit 1
    }
    
    # Update requirements.txt with latest versions
    echo -e "Updating requirements.txt with latest versions..."
    "$INSTALL_DIR/venv/bin/pip" freeze | grep -E "$(cat "$TEMP_REQUIREMENTS" | grep -v '^$' | paste -sd '|' -)" > requirements.txt.new
    mv requirements.txt.new requirements.txt
    rm -f "$TEMP_REQUIREMENTS"
    
    print_success "Installed and updated packages with latest versions"
else
    # Install google-generativeai and distro packages directly
    "$INSTALL_DIR/venv/bin/pip" install -U google-generativeai distro || {
        print_error "Failed to install required Python packages."
        exit 1
    }
    
    # Create requirements.txt with current versions
    "$INSTALL_DIR/venv/bin/pip" freeze | grep -E "google-generativeai|distro" > "$INSTALL_DIR/requirements.txt"
    print_success "Installed required Python packages and created requirements.txt"
fi

# Copy files to installation directory
print_header "Installing Terminal Assistant"

# Copy main script
cp terminal_assistant.py "$SCRIPT_PATH" || {
    print_error "Failed to copy terminal_assistant.py to installation directory."
    exit 1
}
chmod +x "$SCRIPT_PATH" || {
    print_error "Failed to make the script executable."
    exit 1
}
print_success "Installed Terminal Assistant to $SCRIPT_PATH"

# Copy additional files if they exist
if [ -f "README.md" ]; then
    cp README.md "$INSTALL_DIR/README.md"
fi

if [ -d "examples" ]; then
    mkdir -p "$INSTALL_DIR/examples"
    cp -r examples/* "$INSTALL_DIR/examples/" 2>/dev/null
fi

# Set up the configuration
print_header "Setting Up Configuration"

# Ask for API key
echo -e "To use Terminal Assistant, you need a Gemini API key."
echo -e "You can get one from ${CYAN}https://ai.google.dev/${NC}"
echo -e "Please enter your Gemini API key (or press Enter to skip for now):"
read -r API_KEY

# Create config file
if [ -n "$API_KEY" ]; then
    cat > "$CONFIG_PATH" <<EOL
{
  "api_key": "$API_KEY",
  "model": "gemini-2.5-pro-preview-05-06",
  "scripts_dir": "$SCRIPTS_DIR",
  "auto_confirm_safe": false,
  "safety_level": "high"
}
EOL
    print_success "Created configuration file with API key"
else
    cat > "$CONFIG_PATH" <<EOL
{
  "model": "gemini-2.5-pro-preview-05-06",
  "scripts_dir": "$SCRIPTS_DIR",
  "auto_confirm_safe": false,
  "safety_level": "high"
}
EOL
    print_error "No API key provided. You'll need to add one later."
    echo -e "You can set the API key later by:"
    echo -e "1. Editing ${CYAN}$CONFIG_PATH${NC}"
    echo -e "2. Setting the environment variable: ${CYAN}export GEMINI_API_KEY='your-api-key'${NC}"
    echo -e "3. Using the --api-key parameter when running the assistant"
fi

# Set up shell integration
print_header "Setting Up Shell Integration"

# Determine shell
SHELL_NAME=$(basename "$SHELL")
RC_FILE=""

if [ "$SHELL_NAME" = "bash" ]; then
    RC_FILE="$HOME/.bashrc"
elif [ "$SHELL_NAME" = "zsh" ]; then
    RC_FILE="$HOME/.zshrc"
elif [ "$SHELL_NAME" = "fish" ]; then
    RC_FILE="$HOME/.config/fish/config.fish"
else
    echo -e "Unsupported shell: $SHELL_NAME"
    echo -e "You'll need to manually add the Terminal Assistant alias to your shell configuration."
    RC_FILE=""
fi

if [ -n "$RC_FILE" ]; then
    # Create wrapper function/alias
    if [ "$SHELL_NAME" = "fish" ]; then
        ALIAS_SCRIPT="function $ALIAS_CMD; $INSTALL_DIR/venv/bin/python $SCRIPT_PATH --config $CONFIG_PATH \$argv; end"
    else
        ALIAS_SCRIPT="alias $ALIAS_CMD='$INSTALL_DIR/venv/bin/python $SCRIPT_PATH --config $CONFIG_PATH'"
    fi
    
    # Check if alias already exists
    if grep -q "$ALIAS_CMD=" "$RC_FILE" || grep -q "function $ALIAS_CMD" "$RC_FILE"; then
        print_error "Alias '$ALIAS_CMD' already exists in $RC_FILE. Skipping shell integration."
    else
        # Add alias to shell config
        echo "" >> "$RC_FILE"
        echo "# Terminal Assistant" >> "$RC_FILE"
        echo "$ALIAS_SCRIPT" >> "$RC_FILE"
        print_success "Added '$ALIAS_CMD' alias to $RC_FILE"
    fi
    
    echo -e "You can use Terminal Assistant by typing ${CYAN}$ALIAS_CMD${NC} in your terminal."
else
    echo -e "To use Terminal Assistant, run: ${CYAN}$INSTALL_DIR/venv/bin/python $SCRIPT_PATH --config $CONFIG_PATH${NC}"
fi

# Create uninstaller
print_header "Creating Uninstaller"
cat > "$INSTALL_DIR/uninstall.sh" <<EOL
#!/bin/bash
# Terminal Assistant Uninstaller

echo "Uninstalling Terminal Assistant..."

# Remove configuration file
rm -f "$CONFIG_PATH"

# Remove shell integration
if [ -f "$RC_FILE" ]; then
    sed -i '/# Terminal Assistant/d' "$RC_FILE"
    sed -i '/alias $ALIAS_CMD=/d' "$RC_FILE"
    sed -i '/function $ALIAS_CMD/d' "$RC_FILE"
fi

# Remove installation directory
rm -rf "$INSTALL_DIR"

echo "Terminal Assistant has been uninstalled."
EOL
chmod +x "$INSTALL_DIR/uninstall.sh"
print_success "Created uninstaller at $INSTALL_DIR/uninstall.sh"

print_header "Installation Complete!"
echo -e "Terminal Assistant has been installed successfully!"
echo -e ""
echo -e "To use Terminal Assistant:"
echo -e "1. Restart your terminal or run: ${CYAN}source $RC_FILE${NC}"
echo -e "2. Then simply type: ${CYAN}$ALIAS_CMD${NC} in your terminal"
echo -e ""
echo -e "Examples:"
echo -e "${CYAN}$ALIAS_CMD -i${NC} (interactive mode)"
echo -e "${CYAN}$ALIAS_CMD \"explain: ls -la\"${NC}"
echo -e "${CYAN}$ALIAS_CMD \"auto-install: htop\"${NC}"
echo -e "${CYAN}$ALIAS_CMD \"system-info\"${NC}"
echo -e ""
echo -e "To uninstall:"
echo -e "${CYAN}$INSTALL_DIR/uninstall.sh${NC}"
echo -e ""
echo -e "${GREEN}Thank you for installing Terminal Assistant!${NC}" 