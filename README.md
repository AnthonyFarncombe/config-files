# Configuration Files Repository

This repository contains personal configuration files for various development tools and environments, including shell configurations, editor settings, and a Docker development environment.

## Repository Overview

Configuration files for:
- **Shell Environments**: Bash/Zsh configurations for WSL, macOS, and PopOS
- **Neovim**: Complete Neovim setup with Lazy.nvim package manager
- **VSCode**: Settings and keybindings for Mac and Windows
- **PowerShell**: Custom profile with utility functions
- **Docker**: Ubuntu-based development container with modern development tools
- **IntelliJ IDEA**: IDE configuration files

## Key Files Structure

```
.
├── .aliases-mac              # macOS shell aliases and functions
├── .bashrc-wsl              # WSL bash configuration
├── .bashrc-pop              # PopOS bash configuration
├── Microsoft.PowerShell_profile.ps1  # Windows PowerShell profile
├── nvim/                    # Neovim configuration directory
├── vscode-settings-mac.json    # VSCode settings for macOS
├── vscode-settings-windows.json # VSCode settings for Windows
├── vscode-keybindings-*.json   # Platform-specific VSCode keybindings
├── Dockerfile               # Development container configuration
└── intellij-settings.jar   # IntelliJ IDEA settings export
```

## Docker Development Environment

The included Dockerfile provides a comprehensive Ubuntu 24.04 based development environment with modern tooling for C++, .NET, and JavaScript/TypeScript development.

### Included Development Stack

- **Base OS**: Ubuntu 24.04
- **C++ Development**: 
  - CMake build system
  - GDB debugger
  - GCC/G++ compilers (build-essential)
  - Libraries: OpenCV, ZeroMQ, Poco, fmt, libusb
- **.NET Development**: .NET 9 SDK
- **JavaScript/TypeScript**: 
  - Node.js 22
  - Bun runtime
- **Package Management**: apt, npm, dotnet CLI

### Building the Docker Image

```bash
# Build the development container
docker build -t dev-env -f Dockerfile .
```

### Running the Container

```bash
# Run interactively with current directory mounted
docker run -it --rm -v $(pwd):/workspace dev-env

# Run with specific ports exposed (e.g., for web development)
docker run -it --rm -p 3000:3000 -v $(pwd):/workspace dev-env

# Run with .NET development environment
docker run -it --rm -v $(pwd):/workspace -w /workspace dev-env dotnet new console

# Run with Node.js/Bun
docker run -it --rm -v $(pwd):/workspace -w /workspace dev-env bun init
```

### IDE Integration

#### Visual Studio Code
1. Install the "Dev Containers" extension
2. Open your project folder
3. Run "Dev Containers: Reopen in Container" from command palette
4. VSCode will use the Dockerfile to create a development environment

#### JetBrains IDEs (CLion/Rider)
1. Go to Settings → Build, Execution, Deployment → Docker
2. Configure Docker connection
3. For toolchains, add a new Docker toolchain pointing to `dev-env` image
4. Configure CMake/MSBuild to use the Docker toolchain

### Customizing the Docker Environment

To add additional packages or tools, modify the Dockerfile:

```dockerfile
# Add to the apt-get install section
RUN apt-get update && apt-get install -y \
    your-package-name \
    another-package \
    && rm -rf /var/lib/apt/lists/*
```

Then rebuild the image with your changes.

## Platform-Specific Configurations

### macOS Setup
```bash
# Link aliases
ln -sf $(pwd)/.aliases-mac ~/.aliases-mac
echo "source ~/.aliases-mac" >> ~/.zshrc

# VSCode settings
cp vscode-settings-mac.json ~/Library/Application\ Support/Code/User/settings.json
cp vscode-keybindings-mac.json ~/Library/Application\ Support/Code/User/keybindings.json
```

### Windows Setup
```powershell
# PowerShell profile
Copy-Item Microsoft.PowerShell_profile.ps1 $PROFILE

# VSCode settings
Copy-Item vscode-settings-windows.json "$env:APPDATA\Code\User\settings.json"
Copy-Item vscode-keybindings-windows.json "$env:APPDATA\Code\User\keybindings.json"
```

### Linux/WSL Setup
```bash
# WSL bashrc
ln -sf $(pwd)/.bashrc-wsl ~/.bashrc

# PopOS bashrc
ln -sf $(pwd)/.bashrc-pop ~/.bashrc
```

### Neovim Setup
```bash
# Link Neovim configuration
ln -sf $(pwd)/nvim ~/.config/nvim

# Install Lazy.nvim (will auto-install plugins on first run)
nvim
```

## Custom Functions and Aliases

### PowerShell Functions
- `New-MachineRepo` - Creates private GitHub repositories for TwinCAT projects
- `Get-MachineRepo` - Clones TwinCAT machine repositories with proper structure
- `Remove-SshKnownHostEntry` - Removes SSH known host entries by IP address
- `Repair-Cursor` - Fixes Cursor editor conflicts with VSCode

### Shell Aliases (macOS)
- `nmr` - Creates private GitHub repos (bash equivalent of New-MachineRepo)
- `pn`/`pw` - Pin command output to clipboard
- `dw`/`dws` - Dotnet watch shortcuts for development
- Various git aliases for common operations

## Requirements

- **Docker**: For using the development container
- **Git**: For cloning this repository
- **Platform-specific shells**: 
  - macOS: Zsh (default) or Bash
  - Windows: PowerShell 5.1+
  - Linux: Bash

## Tips

- The Docker container is designed for ephemeral use - mount your source code as volumes
- Use platform-specific configuration files for native development
- The Neovim configuration uses Lazy.nvim for automatic plugin management
- PowerShell functions include error handling and parameter validation

## Troubleshooting

### Docker Container Issues
```bash
# Verify installations in container
docker run --rm dev-env dotnet --version
docker run --rm dev-env node --version
docker run --rm dev-env bun --version

# Check available tools
docker run --rm dev-env which cmake gdb gcc g++
```

### Configuration File Issues
- Ensure proper line endings (LF for Unix, CRLF for Windows)
- Check file permissions for shell scripts
- Verify paths in configuration files match your system

## Contributing

This is a personal configuration repository. Feel free to fork and adapt for your own use.

## License

Personal use - adapt as needed for your own configurations.