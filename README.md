# Terminal Assistant

A command-line tool powered by Google's Gemini AI that helps with common terminal tasks.

## Quick Installation

Run this command to automatically install Terminal Assistant:

```bash
curl -sSL https://raw.githubusercontent.com/alvin/terminal-assistant/main/install.sh | bash
```

Or if you've already downloaded the repository:

```bash
./install.sh
```

The installer will:
1. Set up a Python virtual environment
2. Install all required dependencies
3. Automatically update packages to their latest versions
4. Create a configuration file
5. Add a convenient alias to your shell
6. Provide an easy way to uninstall if needed

## Features

- **Command Explanations**: Understand what shell commands do with `explain: <command>`
- **Installation Guides**: Get installation instructions tailored to your OS with `install: <package>`
- **Automated Installation**: Let the assistant install packages for you with `auto-install: <package>`
- **Error Analysis**: Troubleshoot error logs with `errorlog: <paste error here>`
- **Automated Fixes**: Generate and execute commands to fix issues with `fix: <problem description>`
- **Script Generation**: Create shell scripts from plain English with `script: <description>` (with option to save)
- **Command Execution**: Run commands safely after confirmation with `exec: <command>`
- **OS Detection**: Automatically detects your operating system and provides the right commands
- **Chat Mode**: Ask any system-related questions in natural language
- **Safety Controls**: Change command execution safety level with `safety-level: <high|medium|low>`

## Manual Installation

If you prefer to install manually:

1. Install the required packages:

```bash
pip install -U -r requirements.txt
```

Or install directly:

```bash
pip install -U google-generativeai distro
```

2. Get a Gemini API key from [Google AI Studio](https://ai.google.dev/)

3. Set your API key using one of these methods:
   - Environment variable: `export GEMINI_API_KEY='your-api-key'`
   - Create a config file at `~/.terminal_assistant_config.json`
   - Use the `--api-key` parameter when running the assistant

4. Make the script executable:

```bash
chmod +x terminal_assistant.py
```

## Keeping Dependencies Updated

To ensure your Terminal Assistant is using the latest versions of all dependencies, you can use the update script:

```bash
./update_dependencies.sh
```

This script will:
1. Activate the Terminal Assistant virtual environment
2. Update all dependencies to their latest versions
3. Update the requirements.txt file with the new versions
4. Display the currently installed versions

Alternatively, you can manually update the packages:

```bash
pip install -U google-generativeai distro
```

## Configuration

You can create a configuration file in JSON format at `~/.terminal_assistant_config.json` with these options:

```json
{
  "api_key": "your-gemini-api-key-here",
  "model": "gemini-2.5-pro-preview-05-06",
  "scripts_dir": "~/scripts",
  "auto_confirm_safe": false,
  "safety_level": "high",
  "history_size": 10,
  "colors": {
    "enabled": true,
    "prompt": "green",
    "response": "cyan",
    "error": "red"
  }
}
```

Alternatively, you can specify a custom config path with the `--config` parameter.

## Usage

After installation, you can use the `ta` command (or your custom alias):

```bash
ta "explain: ls -la"
ta -i  # Interactive mode
```

### Interactive Mode

```bash
ta -i
```

This opens an interactive prompt where you can enter commands and queries.

### Single Query Mode

```bash
ta "explain: ls -la"
ta "install: docker"
ta "auto-install: python3-pip"
ta "fix: python package installation fails with externally-managed-environment"
ta "script: backup my home directory to an external drive"
ta "system-info"
ta "safety-level: medium"
ta "How do I check disk space on Linux?"
```

### Command-line Options

```
-i, --interactive       Run in interactive mode
--api-key KEY           Gemini API key (overrides environment and config)
--config PATH           Path to config file (default: ~/.terminal_assistant_config.json)
--scripts-dir DIR       Directory to save generated scripts (default: ~/scripts)
--auto-confirm-safe     Auto-confirm non-critical commands
-h, --help              Show help message and exit
```

## OS Detection

The terminal assistant automatically detects your operating system and package manager to provide the correct commands. Supported systems include:

- **Debian-based**: Ubuntu, Debian, Linux Mint, Pop!_OS, Elementary OS
- **Red Hat-based**: Fedora, RHEL, CentOS, Rocky Linux, AlmaLinux
- **Arch-based**: Arch Linux, Manjaro, EndeavourOS
- **SUSE**: openSUSE, SUSE Linux
- **macOS**: Using Homebrew
- **Other Linux**: Detects various other distributions

You can view your system information by using the `system-info` command.

## Safety Features

The terminal assistant includes safety features to protect your system:

- **Critical Command Detection**: Commands that could make system-wide changes (like `rm`, `sudo`, etc.) are automatically detected and require explicit confirmation.
- **Command Previewing**: For installation and fixes, all commands are shown before execution so you can review them.
- **Step-by-step Execution**: Commands are executed one at a time, allowing you to stop if something goes wrong.
- **Error Handling**: If a command fails, you're asked if you want to continue with the remaining commands.

## Examples

```
> explain: sudo apt update
> install: nodejs
> auto-install: ffmpeg
> fix: broken apt package dependencies
> script: find all log files larger than 100MB and compress them
> errorlog: error: externally-managed-environment
> exec: echo "Hello, world!"
> system-info
> safety-level: medium
> How do I monitor CPU usage in real-time?
```

## Automated Installation

When using the `auto-install:` command, the assistant will:

1. Detect your OS and package manager
2. Suggest the appropriate installation command
3. Ask if you want to use the suggested command or generate alternative commands with AI
4. Show you the commands it plans to execute
5. Ask for your confirmation before proceeding
6. Execute the commands one by one
7. Show you a summary of the installation results

If an installation step fails, the process will stop and show you the error.

## Automated Fixes

When using the `fix:` command, the assistant will:

1. Generate commands to address the issue you described, specific to your OS
2. Show you the commands along with explanatory comments
3. Ask for your confirmation before proceeding
4. Execute the commands one by one
5. If a command fails, ask if you want to continue with the remaining commands
6. Show you a summary of the fix operation

## Script Generation

When using the `script:` command, the assistant will:

1. Generate a shell script based on your description, tailored to your OS
2. Display the script in the terminal
3. Ask if you want to save it
4. If confirmed, save it to your scripts directory (default: `~/scripts`)
5. Make the script executable automatically

Scripts are named based on your description with a timestamp, for example: `backup_home_directory_20230615_123045.sh`.

## Uninstallation

To uninstall Terminal Assistant:

```bash
~/.terminal-assistant/uninstall.sh
```

This will remove all installed files, configuration, and shell aliases.

## Improvements & Future Work

- Add support for more LLM providers
- Add colorful terminal output
- Implement command history and suggestions
- Add support for custom user templates
- Support for multiple script templates
- Enhanced safety features for sensitive operations
- Support for more operating systems and package managers

## License

MIT 