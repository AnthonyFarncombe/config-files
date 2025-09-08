# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This repository contains personal configuration files for various development tools and environments including:
- Bash/shell configurations for WSL, macOS, and PopOS
- Neovim configuration with Lazy.nvim package manager
- VSCode settings and keybindings for Mac and Windows
- PowerShell profile with custom functions
- Docker development environment setup
- IntelliJ IDEA configuration

## Key Files and Their Purpose

- `.aliases-mac` - macOS-specific shell aliases and functions
- `.bashrc-wsl` / `.bashrc-pop` - Linux shell configurations
- `Microsoft.PowerShell_profile.ps1` - Windows PowerShell profile with custom functions
- `nvim/` - Neovim configuration using Lazy.nvim
- `vscode-settings-*.json` - VSCode settings for different platforms
- `Dockerfile` - Ubuntu 24.04 based development container with .NET 9, Node.js 22, and Bun

## Platform-Specific Configurations

The repository maintains separate configurations for:
- macOS (aliases, VSCode settings/keybindings)
- Windows (PowerShell profile, VSCode settings/keybindings)
- Linux/WSL (bashrc configurations)

## Custom Functions

### PowerShell Functions
- `New-MachineRepo` - Creates private GitHub repos for TwinCAT projects
- `Get-MachineRepo` - Clones TwinCAT machine repositories
- `Remove-SshKnownHostEntry` - Removes SSH known host entries by IP
- `Repair-Cursor` - Fixes Cursor editor conflicts with VSCode

### Shell Aliases/Functions (macOS)
- `nmr` - Creates private GitHub repos (bash equivalent of New-MachineRepo)
- `pn`/`pw` - Clipboard utilities for pin command output
- `dw`/`dws` - Dotnet watch shortcuts

## Development Environment

The Dockerfile creates a development container with:
- Ubuntu 24.04 base
- C++ build tools (cmake, gdb, build-essential)
- .NET 9 SDK
- Node.js 22
- Bun runtime
- Various development libraries (OpenCV, ZMQ, Poco, fmt)