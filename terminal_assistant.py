#!/usr/bin/env python3

import os
import sys
import json
import argparse
import subprocess
import platform
import re
import datetime
import shlex
import distro
from typing import Optional, Dict, Any, List, Tuple

# Version information
VERSION = "1.1.0"
MIN_REQUIRED_GENAI_VERSION = "0.8.5"

# Gracefully handle missing dependencies
MISSING_DEPENDENCIES = False
try:
    import google.generativeai as genai
    import distro
    
    # Try to import pkg_resources, but don't fail if it's not available
    try:
        import pkg_resources
        HAVE_PKG_RESOURCES = True
    except ImportError:
        HAVE_PKG_RESOURCES = False
        
except ImportError:
    MISSING_DEPENDENCIES = True

# Configuration 
DEFAULT_CONFIG_PATH = os.path.expanduser("~/.terminal_assistant_config.json")
API_KEY = os.environ.get("GEMINI_API_KEY", "")

# Critical commands that require explicit user confirmation
CRITICAL_COMMANDS = [
    'rm', 'sudo', 'mkfs', 'dd', 'format', 'fdisk', 'parted', 'chmod', 'chown',
    'passwd', 'adduser', 'deluser', 'usermod', 'groupmod', 'mount', 'umount',
    'shutdown', 'reboot', 'init', 'systemctl'
]

# Package managers by OS/distribution
PACKAGE_MANAGERS = {
    # Debian-based
    'debian': 'apt',
    'ubuntu': 'apt',
    'linuxmint': 'apt',
    'pop': 'apt',
    'elementary': 'apt',
    # Red Hat-based
    'fedora': 'dnf',
    'rhel': 'dnf',
    'centos': 'dnf',
    'rocky': 'dnf',
    'almalinux': 'dnf',
    # Arch-based
    'arch': 'pacman',
    'manjaro': 'pacman',
    'endeavouros': 'pacman',
    # SUSE
    'opensuse': 'zypper',
    'suse': 'zypper',
    # macOS
    'darwin': 'brew',
}

# Installation commands by package manager
INSTALL_COMMANDS = {
    'apt': 'sudo apt update && sudo apt install -y {}',
    'dnf': 'sudo dnf install -y {}',
    'pacman': 'sudo pacman -S --noconfirm {}',
    'zypper': 'sudo zypper install -y {}',
    'brew': 'brew install {}',
    'pkg': 'pkg install {}',  # FreeBSD
    'apk': 'apk add {}',      # Alpine
    'yum': 'sudo yum install -y {}',  # Older Red Hat
    'emerge': 'sudo emerge {}',  # Gentoo
    'xbps': 'sudo xbps-install -y {}',  # Void Linux
}

def check_dependencies() -> bool:
    """Check if all required dependencies are installed."""
    if MISSING_DEPENDENCIES:
        print("Error: required packages are not installed.")
        print("Please install them using one of these methods:")
        print("1. pip install -r requirements.txt")
        print("2. pip install google-generativeai distro")
        print("3. sudo apt install python3-pip && pip install google-generativeai distro")
        return False
    
    # Check if google-generativeai version is compatible
    if HAVE_PKG_RESOURCES:
        try:
            genai_version = pkg_resources.get_distribution("google-generativeai").version
            if pkg_resources.parse_version(genai_version) < pkg_resources.parse_version(MIN_REQUIRED_GENAI_VERSION):
                print(f"Warning: Your google-generativeai version ({genai_version}) is older than the recommended minimum ({MIN_REQUIRED_GENAI_VERSION}).")
                print("Some features might not work correctly.")
                print("To update, run: ./update_dependencies.sh")
                print("Or manually: pip install -U google-generativeai")
        except Exception:
            # Skip version check if there's an error
            pass
        
    return True

def load_config(config_path: Optional[str] = None) -> Dict[str, Any]:
    """Load configuration from file."""
    config_path = config_path or DEFAULT_CONFIG_PATH
    config = {}
    
    # Try environment variable first
    if API_KEY:
        config["api_key"] = API_KEY
    
    # Then try config file
    if os.path.exists(config_path):
        try:
            with open(config_path, 'r') as f:
                file_config = json.load(f)
                config.update(file_config)
        except (json.JSONDecodeError, IOError) as e:
            print(f"Warning: Couldn't load config file: {e}")
    
    return config

# Initialize Gemini
def initialize_genai(api_key: Optional[str] = None) -> bool:
    """Initialize the Gemini AI client with API key."""
    if MISSING_DEPENDENCIES:
        return False
        
    # Use provided key or check configuration/environment
    key_to_use = api_key or API_KEY or load_config().get('api_key', '')
    
    if not key_to_use:
        print("Warning: No Gemini API key found.")
        print("Please set it using one of these methods:")
        print("1. export GEMINI_API_KEY='your-api-key'")
        print("2. Create a config file at ~/.terminal_assistant_config.json")
        print("3. Pass --api-key parameter when running the assistant")
        print("You can get an API key from https://ai.google.dev/")
        return False
    
    genai.configure(api_key=key_to_use)
    return True


class SystemDetector:
    """Detects system information and provides system-specific commands."""
    
    def __init__(self):
        """Initialize the system detector."""
        self.os_name = platform.system().lower()
        self.os_release = platform.release()
        self.os_version = platform.version()
        self.package_manager = self._detect_package_manager()
        self.detailed_info = self._get_detailed_info()
        
    def _detect_package_manager(self) -> str:
        """Detect the appropriate package manager for this system."""
        if self.os_name == 'linux':
            try:
                # Use distro to get the ID
                dist_id = distro.id().lower()
                return PACKAGE_MANAGERS.get(dist_id, 'apt')  # Default to apt if unknown
            except Exception:
                # Fallback method
                try:
                    with open('/etc/os-release', 'r') as f:
                        for line in f:
                            if line.startswith('ID='):
                                dist_id = line.split('=')[1].strip().strip('"').lower()
                                return PACKAGE_MANAGERS.get(dist_id, 'apt')
                except Exception:
                    pass
                return 'apt'  # Default fallback for Linux
        elif self.os_name == 'darwin':
            return 'brew'  # macOS
        elif self.os_name == 'windows':
            return 'choco'  # Windows with Chocolatey
        return 'unknown'
    
    def _get_detailed_info(self) -> Dict[str, str]:
        """Get detailed system information."""
        info = {
            'os': self.os_name,
            'os_version': self.os_version,
            'os_release': self.os_release,
            'package_manager': self.package_manager,
            'arch': platform.machine(),
            'python_version': platform.python_version(),
            'processor': platform.processor(),
        }
        
        # Add distribution information for Linux
        if self.os_name == 'linux':
            try:
                info['distribution'] = distro.id()
                info['distribution_version'] = distro.version()
                info['distribution_name'] = distro.name()
                info['distribution_codename'] = distro.codename()
                info['distribution_like'] = distro.like()
            except Exception:
                # Fallback if distro module fails
                info['distribution'] = self._get_linux_distribution()
        
        return info
    
    def _get_linux_distribution(self) -> str:
        """Fallback method to get Linux distribution information."""
        try:
            if os.path.exists('/etc/os-release'):
                with open('/etc/os-release', 'r') as f:
                    lines = f.readlines()
                    for line in lines:
                        if line.startswith('ID='):
                            return line.split('=')[1].strip().strip('"')
        except Exception:
            pass
        return ""
    
    def get_install_command(self, package: str) -> str:
        """Get the appropriate install command for the package on this system."""
        cmd_template = INSTALL_COMMANDS.get(self.package_manager)
        if not cmd_template:
            return ""
        
        return cmd_template.format(package)
    
    def get_system_info(self) -> Dict[str, str]:
        """Get all system information as a dictionary."""
        return self.detailed_info


class TerminalAssistant:
    """Terminal assistant that helps with command-line tasks using Gemini AI."""
    
    def __init__(self, api_key: Optional[str] = None, config_path: Optional[str] = None):
        """Initialize the terminal assistant."""
        self.config = load_config(config_path)
        self.api_ready = initialize_genai(api_key or self.config.get('api_key'))
        self.system_detector = SystemDetector()
        self.system_info = self.system_detector.get_system_info()
        self.scripts_dir = self.config.get('scripts_dir', os.path.expanduser("~/scripts"))
        # Safety settings
        self.auto_confirm_safe = self.config.get('auto_confirm_safe', False)
        self.safety_level = self.config.get('safety_level', 'high')  # high, medium, low
    
    def _generate_prompt(self, prompt_type: str, user_input: str) -> str:
        """Generate context-aware prompt for Gemini based on the prompt type."""
        system_info = json.dumps(self.system_info, indent=2)
        
        prompts = {
            "explain": f"""
You are a helpful terminal assistant explaining a shell command.
Based on this system information: {system_info}

Explain what this command does in detail, including:
- What each flag and argument means
- Any potential risks or side effects
- Common use cases and variations

COMMAND: {user_input}
""",
            "install": f"""
You are a helpful terminal assistant providing installation instructions.
Based on this system information: {system_info}

Provide detailed, step-by-step instructions for installing {user_input}. Include:
1. The most appropriate installation method for this OS ({self.system_info['os']}, {self.system_info.get('distribution', '')})
2. All commands needed, ready to copy and paste
3. Any post-installation steps required
4. How to verify the installation was successful
""",
            "auto_install": f"""
You are a helpful terminal assistant that generates installation commands.
Based on this system information: {system_info}

Generate the exact commands needed to install {user_input} on this system.
The system is: {self.system_info['os']} {self.system_info.get('distribution', '')} {self.system_info.get('distribution_version', '')}
The package manager is: {self.system_info['package_manager']}

Return ONLY the commands, one per line, with no explanations.
Each command should be ready to execute.
""",
            "script": f"""
You are a helpful terminal assistant that generates shell scripts.
Based on this system information: {system_info}

Create a shell script that accomplishes this task: {user_input}

The script should:
- Include proper error handling and comments
- Be efficient and follow best practices
- Work specifically on this system ({self.system_info['os']}, {self.system_info.get('distribution', '')})
- Be ready to save and execute

Return ONLY the script with appropriate shebang line.
""",
            "errorlog": f"""
You are a helpful terminal assistant analyzing error logs.
Based on this system information: {system_info}

Analyze this error log and provide:
1. The root cause of the error
2. Step-by-step instructions to fix it specifically for this system ({self.system_info['os']}, {self.system_info.get('distribution', '')})
3. Any preventative measures for the future

ERROR LOG:
{user_input}
""",
            "fix": f"""
You are a helpful terminal assistant that generates commands to fix an issue.
Based on this system information: {system_info}

Generate the exact commands needed to fix this problem: {user_input}
The commands should be specifically for this system: {self.system_info['os']} {self.system_info.get('distribution', '')} {self.system_info.get('distribution_version', '')}
The package manager is: {self.system_info['package_manager']}

Return the commands, one per line, ready to execute.
Include any necessary explanation as comments (# prefix).
""",
            "chat": f"""
You are a helpful terminal assistant answering system-related questions.
Based on this system information: {system_info}

The user asks: {user_input}

Provide a helpful, accurate, and concise response focused on their terminal/system question.
Make sure your answer is specifically tailored to this system: {self.system_info['os']} {self.system_info.get('distribution', '')}.
""",
        }
        
        return prompts.get(prompt_type, prompts["chat"])
    
    def _call_gemini(self, prompt: str) -> str:
        """Call Gemini API with the given prompt."""
        if MISSING_DEPENDENCIES:
            return "Error: google-generativeai package is not installed. Please install it to use this feature."
            
        if not self.api_ready:
            return "Error: Gemini API not initialized. Please check your API key."
        
        try:
            model_name = self.config.get('model', 'gemini-2.5-pro-preview-05-06')
            model = genai.GenerativeModel(model_name)
            response = model.generate_content(prompt)
            return response.text
        except Exception as e:
            return f"Error calling Gemini API: {str(e)}"
    
    def _is_command_critical(self, command: str) -> bool:
        """Determine if a command requires explicit user confirmation based on safety level."""
        # In low safety mode, only truly dangerous commands require confirmation
        if self.safety_level.lower() == 'low':
            dangerous_commands = ['rm -rf /', 'mkfs', 'dd if=', 'shutdown', 'halt', 'poweroff']
            for dangerous in dangerous_commands:
                if dangerous in command:
                    return True
            return False
            
        # Medium safety - most root/system commands need confirmation
        if self.safety_level.lower() == 'medium':
            if 'sudo' in command and any(cmd in command for cmd in ['rm', 'mkfs', 'dd']):
                return True
            if any(cmd in command for cmd in ['shutdown', 'reboot', 'init']):
                return True
            return False
            
        # High safety (default) - any potentially system-altering command needs confirmation
        command_parts = shlex.split(command)
        base_cmd = command_parts[0]
        
        # Check for sudoed commands
        if base_cmd == 'sudo' and len(command_parts) > 1:
            actual_cmd = command_parts[1]
            return actual_cmd in CRITICAL_COMMANDS or base_cmd in CRITICAL_COMMANDS
        
        return base_cmd in CRITICAL_COMMANDS or 'sudo' in command
    
    def _execute_command(self, command: str, confirm_critical: bool = True) -> Tuple[int, str]:
        """Execute a shell command and return its output."""
        try:
            # Check if command is critical and requires confirmation
            if confirm_critical and self._is_command_critical(command):
                print(f"WARNING: This command may make critical system changes:")
                print(f"  {command}")
                confirmation = input("Are you sure you want to proceed? (yes/no): ").strip().lower()
                if confirmation not in ["yes", "y"]:
                    return 0, "Command execution cancelled (critical command)."
            
            result = subprocess.run(
                command, 
                shell=True, 
                capture_output=True, 
                text=True
            )
            return result.returncode, result.stdout + result.stderr
        except Exception as e:
            return 1, f"Error executing command: {str(e)}"
    
    def _extract_shell_script(self, response: str) -> str:
        """Extract shell script from response with code blocks."""
        # Look for code blocks with ```
        code_block_pattern = r"```(?:bash|sh)?\n([\s\S]*?)\n```"
        matches = re.findall(code_block_pattern, response)
        
        if matches:
            return matches[0].strip()
        
        # If no code blocks found, try to extract the script directly
        if response.startswith("#!"):
            lines = response.split("\n")
            if lines and lines[0].startswith("#!"):
                return response.strip()
        
        return response.strip()
    
    def _save_script(self, script_content: str, description: str) -> Tuple[bool, str]:
        """Save a shell script to disk."""
        # Create directory if it doesn't exist
        os.makedirs(self.scripts_dir, exist_ok=True)
        
        # Generate filename from description
        safe_desc = re.sub(r'[^a-zA-Z0-9_-]', '_', description.lower())
        safe_desc = re.sub(r'_+', '_', safe_desc)  # Replace multiple underscores with one
        timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"{safe_desc[:30]}_{timestamp}.sh"
        filepath = os.path.join(self.scripts_dir, filename)
        
        try:
            with open(filepath, 'w') as f:
                f.write(script_content)
            
            # Make the script executable
            os.chmod(filepath, 0o755)
            return True, filepath
        except Exception as e:
            return False, str(e)
    
    def explain_command(self, command: str) -> str:
        """Explain what a shell command does."""
        prompt = self._generate_prompt("explain", command)
        return self._call_gemini(prompt)
    
    def installation_guide(self, package: str) -> str:
        """Provide installation instructions for a package."""
        prompt = self._generate_prompt("install", package)
        return self._call_gemini(prompt)
    
    def auto_install(self, package: str) -> str:
        """Automatically install a package by generating and executing commands."""
        # First, try using system detection for direct installation
        system_install_cmd = self.system_detector.get_install_command(package)
        
        if system_install_cmd:
            print(f"System detection found the following installation command:")
            print(f"  {system_install_cmd}")
            confirmation = input("Use this command? (yes/no/custom): ").strip().lower()
            
            if confirmation in ["yes", "y"]:
                print(f"\nExecuting: {system_install_cmd}")
                return_code, output = self._execute_command(system_install_cmd)
                status = "successfully" if return_code == 0 else "with errors"
                return f"Installation completed {status}.\nOutput:\n{output}"
            elif confirmation in ["no", "n", "custom"]:
                print("Using AI to generate installation commands instead...")
            else:
                return "Installation cancelled."
        
        # If we get here, we're using AI to generate commands
        prompt = self._generate_prompt("auto_install", package)
        commands_response = self._call_gemini(prompt)
        
        # Extract commands (one per line)
        commands = [cmd.strip() for cmd in commands_response.strip().split('\n') if cmd.strip()]
        
        if not commands:
            return f"Error: Could not generate installation commands for {package}."
        
        # Display commands to user
        print(f"The following commands will be used to install {package}:")
        for i, cmd in enumerate(commands, 1):
            print(f"{i}. {cmd}")
        print()
        
        # Ask for confirmation
        confirmation = input("Do you want to proceed with the installation? (yes/no): ").strip().lower()
        
        if confirmation not in ["yes", "y"]:
            return "Installation cancelled."
        
        # Execute commands one by one
        results = []
        for cmd in commands:
            print(f"\nExecuting: {cmd}")
            return_code, output = self._execute_command(cmd)
            results.append((cmd, return_code, output))
            
            # If a command fails, stop execution
            if return_code != 0:
                results.append(("INSTALLATION FAILED", return_code, "Stopping installation process due to error."))
                break
        
        # Format results
        result_str = "\n" + "-" * 50 + "\n"
        result_str += "INSTALLATION SUMMARY:\n" + "-" * 50 + "\n"
        success_count = sum(1 for _, code, _ in results if code == 0)
        result_str += f"Commands completed successfully: {success_count}/{len(commands)}\n\n"
        
        for cmd, return_code, output in results:
            status = "SUCCESS" if return_code == 0 else "FAILED"
            result_str += f"Command: {cmd}\nStatus: {status}\n"
            if return_code != 0:
                result_str += f"Output:\n{output}\n\n"
        
        if success_count == len(commands):
            result_str += f"\n{package} was successfully installed!"
        
        return result_str
    
    def generate_script(self, description: str) -> str:
        """Generate a shell script from a description."""
        prompt = self._generate_prompt("script", description)
        response = self._call_gemini(prompt)
        
        # Extract script content
        script_content = self._extract_shell_script(response)
        
        # Ask user if they want to save the script
        print("\n" + script_content + "\n")
        print(f"Do you want to save this script? (yes/no)")
        save_confirmation = input("> ").strip().lower()
        
        if save_confirmation in ("yes", "y"):
            success, result = self._save_script(script_content, description)
            if success:
                return f"Script saved to: {result}\nYou can run it with: {result}"
            else:
                return f"Failed to save script: {result}\n\nScript content:\n{script_content}"
        
        return "Script not saved."
    
    def analyze_error(self, error_log: str) -> str:
        """Analyze an error log and suggest fixes."""
        prompt = self._generate_prompt("errorlog", error_log)
        return self._call_gemini(prompt)
    
    def fix_issue(self, problem: str) -> str:
        """Generate and execute commands to fix an issue."""
        # Generate commands to fix the issue
        prompt = self._generate_prompt("fix", problem)
        response = self._call_gemini(prompt)
        
        # Extract commands (each line that isn't a comment)
        commands = []
        for line in response.strip().split('\n'):
            if line.strip() and not line.strip().startswith('#'):
                commands.append(line.strip())
        
        if not commands:
            return f"Could not generate fix commands for the issue: {problem}"
        
        # Display commands to user
        print(f"The following commands are suggested to fix the issue:")
        for i, cmd in enumerate(commands, 1):
            print(f"{i}. {cmd}")
            # Print any comment that might explain this command
            for comment_line in response.strip().split('\n'):
                if comment_line.strip().startswith('#') and cmd in comment_line:
                    print(f"   {comment_line.strip()}")
        print()
        
        # Ask for confirmation
        confirmation = input("Do you want to execute these commands? (yes/no): ").strip().lower()
        
        if confirmation not in ["yes", "y"]:
            return "Fix operation cancelled."
        
        # Execute commands one by one
        results = []
        for cmd in commands:
            print(f"\nExecuting: {cmd}")
            return_code, output = self._execute_command(cmd)
            results.append((cmd, return_code, output))
            
            # If a command fails, ask if user wants to continue
            if return_code != 0:
                print(f"Command failed with error:\n{output}")
                continue_confirmation = input("Continue with remaining commands? (yes/no): ").strip().lower()
                if continue_confirmation not in ["yes", "y"]:
                    break
        
        # Format results
        result_str = "\n" + "-" * 50 + "\n"
        result_str += "FIX OPERATION SUMMARY:\n" + "-" * 50 + "\n"
        success_count = sum(1 for _, code, _ in results if code == 0)
        result_str += f"Commands completed successfully: {success_count}/{len(commands)}\n\n"
        
        for cmd, return_code, output in results:
            status = "SUCCESS" if return_code == 0 else "FAILED"
            result_str += f"Command: {cmd}\nStatus: {status}\n"
            if output:
                result_str += f"Output:\n{output}\n\n"
        
        return result_str
    
    def chat(self, question: str) -> str:
        """Answer a general question about the system."""
        prompt = self._generate_prompt("chat", question)
        return self._call_gemini(prompt)
    
    def run_with_confirmation(self, command: str) -> str:
        """Run a command after user confirmation."""
        print(f"Do you want to execute: {command} (yes/no)")
        confirmation = input("> ").strip().lower()
        
        if confirmation in ("yes", "y"):
            return_code, output = self._execute_command(command)
            status = "successfully" if return_code == 0 else "with errors"
            return f"Command executed {status}.\nOutput:\n{output}"
        else:
            return "Command execution cancelled."

    def set_safety_level(self, level: str) -> str:
        """Change the safety level for command execution."""
        level = level.lower().strip()
        if level not in ['high', 'medium', 'low']:
            return f"Invalid safety level: {level}. Valid options are: high, medium, low"
            
        self.safety_level = level
        return f"Safety level changed to: {level} {self._get_safety_icon()}"
    
    def _get_safety_icon(self) -> str:
        """Return an icon representing the current safety level."""
        if self.safety_level.lower() == 'high':
            return "🔒"  # Locked padlock
        elif self.safety_level.lower() == 'medium':
            return "🔓"  # Unlocked padlock
        else:  # Low
            return "⚠️"  # Warning sign

    def process_input(self, user_input: str) -> str:
        """Process user input and route to appropriate handler."""
        if user_input.startswith("explain:"):
            command = user_input[len("explain:"):].strip()
            return self.explain_command(command)
        
        elif user_input.startswith("install:"):
            package = user_input[len("install:"):].strip()
            return self.installation_guide(package)
        
        elif user_input.startswith("auto-install:"):
            package = user_input[len("auto-install:"):].strip()
            return self.auto_install(package)
        
        elif user_input.startswith("script:"):
            description = user_input[len("script:"):].strip()
            return self.generate_script(description)
        
        elif user_input.startswith("errorlog:"):
            error_log = user_input[len("errorlog:"):].strip()
            return self.analyze_error(error_log)
        
        elif user_input.startswith("fix:"):
            problem = user_input[len("fix:"):].strip()
            return self.fix_issue(problem)
        
        elif user_input.startswith("exec:"):
            command = user_input[len("exec:"):].strip()
            return self.run_with_confirmation(command)
        
        elif user_input.startswith("system-info"):
            info = self.system_info.copy()
            info['terminal_assistant'] = {
                'safety_level': self.safety_level,
                'auto_confirm_safe': self.auto_confirm_safe,
                'scripts_dir': self.scripts_dir,
                'model': self.config.get('model', 'gemini-2.5-pro-preview-05-06')
            }
            return json.dumps(info, indent=2)
            
        elif user_input.startswith("safety-level:"):
            level = user_input[len("safety-level:"):].strip()
            return self.set_safety_level(level)
        
        else:
            return self.chat(user_input)

def main():
    """Main entry point for the terminal assistant."""
    # Check dependencies first
    if not check_dependencies() and not MISSING_DEPENDENCIES:
        sys.exit(1)
    
    parser = argparse.ArgumentParser(description=f"Terminal Assistant v{VERSION} powered by Gemini AI")
    parser.add_argument("query", nargs="*", help="Your query or command")
    parser.add_argument("-i", "--interactive", action="store_true", help="Run in interactive mode")
    parser.add_argument("--api-key", help="Gemini API key (overrides environment and config)")
    parser.add_argument("--config", help=f"Path to config file (default: {DEFAULT_CONFIG_PATH})")
    parser.add_argument("--scripts-dir", help="Directory to save generated scripts")
    parser.add_argument("--auto-confirm-safe", action="store_true", help="Auto-confirm non-critical commands")
    parser.add_argument("--version", action="version", version=f"Terminal Assistant v{VERSION}")
    
    args = parser.parse_args()
    
    if MISSING_DEPENDENCIES and args.query:
        print("Cannot process query due to missing dependencies.")
        check_dependencies()
        sys.exit(1)
    
    # Load config
    config = load_config(args.config)
    if args.scripts_dir:
        config['scripts_dir'] = args.scripts_dir
    if args.auto_confirm_safe:
        config['auto_confirm_safe'] = True
    
    assistant = TerminalAssistant(api_key=args.api_key, config_path=args.config)
    
    if args.interactive:
        print(f"Terminal Assistant v{VERSION} (powered by Gemini AI)")
        print("Type 'exit' or 'quit' to exit")
        print("Commands: explain:, install:, auto-install:, script:, errorlog:, fix:, exec:, system-info, safety-level:")
        print("Or just ask any question about your system.")
        print()
        
        while True:
            try:
                user_input = input("> ")
                if user_input.lower() in ("exit", "quit"):
                    break
                if not user_input.strip():
                    continue
                    
                response = assistant.process_input(user_input)
                print("\n" + response + "\n")
            except KeyboardInterrupt:
                print("\nExiting...")
                break
            except Exception as e:
                print(f"Error: {str(e)}")
    
    elif args.query:
        user_input = " ".join(args.query)
        response = assistant.process_input(user_input)
        print(response)
    
    else:
        parser.print_help()

if __name__ == "__main__":
    main() 