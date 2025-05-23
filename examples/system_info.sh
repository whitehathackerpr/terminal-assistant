#!/usr/bin/env bash

# System Information Script
# Generated by Terminal Assistant
# Description: Collect and display system information

# Exit on error
set -e

# Function to print section headers
print_header() {
    echo
    echo "===== $1 ====="
    echo
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo "Warning: Some information may be limited without root privileges."
    echo "Consider running with sudo for complete information."
    echo
fi

# OS Information
print_header "OS INFORMATION"
if [ -f /etc/os-release ]; then
    cat /etc/os-release
else
    uname -a
fi

# Hardware Information
print_header "HARDWARE INFORMATION"
echo "CPU Information:"
lscpu | grep -E 'Model name|Socket|Core|Thread|MHz'

echo "Memory Information:"
free -h

echo "Disk Usage:"
df -h | grep -v "tmpfs\|udev"

# Network Information
print_header "NETWORK INFORMATION"
echo "Network Interfaces:"
ip -br addr show

echo "Listening Ports:"
ss -tuln | grep LISTEN

# Process Information
print_header "PROCESS INFORMATION"
echo "Top 5 CPU Processes:"
ps aux --sort=-%cpu | head -6

echo "Top 5 Memory Processes:"
ps aux --sort=-%mem | head -6

# System Load
print_header "SYSTEM LOAD"
uptime

# Last Login Information
print_header "LAST LOGIN INFORMATION"
last | head -5

# Package Information
print_header "PACKAGE INFORMATION"
if command -v apt > /dev/null; then
    echo "Installed Packages: $(apt list --installed 2>/dev/null | wc -l)"
    echo "Upgradable Packages: $(apt list --upgradable 2>/dev/null | grep -v "Listing" | wc -l)"
elif command -v dnf > /dev/null; then
    echo "Installed Packages: $(dnf list installed | wc -l)"
    echo "Upgradable Packages: $(dnf check-update | grep -v "Last metadata" | wc -l)"
elif command -v pacman > /dev/null; then
    echo "Installed Packages: $(pacman -Q | wc -l)"
    echo "Upgradable Packages: $(pacman -Qu | wc -l)"
else
    echo "Unknown package manager"
fi

print_header "REPORT COMPLETE"
echo "Generated on: $(date)"
echo
echo "Use this information for troubleshooting or system documentation." 