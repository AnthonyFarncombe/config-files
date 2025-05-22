function pwdc { (Get-Location).Path | Set-Clipboard }

function dw { dotnet watch --no-hot-reload }

function dws { dotnet watch --no-hot-reload --launch-profile https }

function pn {
    param([int]$arg)
    $output = pin $arg
    $parts = $output -split '\s+'
    Set-Clipboard -Value $parts[0]
}

function pw {
    param([int]$arg)
    $output = pin $arg
    $parts = $output -split '\s+'
    Set-Clipboard -Value $parts[1]
}

$homeDir = $env:USERPROFILE
$projectsDir = $env:USERPROFILE + "\Projects"

if ((Get-Location).Path -eq $homeDir -and (Test-Path $projectsDir)) {
    Set-Location $projectsDir
}

function Restart-WordPress {
    <#
.SYNOPSIS
Restarts the WordPress EC2 instance.

.DESCRIPTION
This function prompts for confirmation before rebooting the WordPress EC2 instance.
It uses the AWS CLI to send a reboot command to the specified instance.

.EXAMPLE
Restart-WordPress
Prompts for confirmation and reboots the WordPress instance if confirmed.
#>
    [CmdletBinding()]
    param()

    $confirmation = Read-Host "Are you sure you want to reboot the WordPress instance? (y/n)"
    if ($confirmation -eq "y") {
        aws ec2 reboot-instances --instance-ids i-037e313001ed9d6b5
    }
    else {
        Write-Host "Reboot aborted."
    }
}

function Repair-Cursor {
    <#
.SYNOPSIS
Repairs Cursor installation by removing conflicting files.

.DESCRIPTION
This function removes the symlink to the code executable and the code.cmd file
in the Cursor installation directory to prevent conflicts with the VS Code installation.

.EXAMPLE
Repair-Cursor
Removes conflicting files from the Cursor installation directory.
#>
    [CmdletBinding()]
    param()

    # Remove the symlink to the code executable
    # and the code.cmd file in the Cursor installation directory
    # to prevent conflicts with the VS Code installation
    $filePaths = @(
        "$env:LOCALAPPDATA\Programs\cursor\resources\app\bin\code",
        "$env:LOCALAPPDATA\Programs\cursor\resources\app\bin\code.cmd"
    )
    foreach ($filePath in $filePaths) {
        if (Test-Path $filePath) {
            Remove-Item $filePath -Force
            Write-Host "Removed: $filePath"
        }
        else {
            Write-Host "File not found: $filePath"
        }
    }
}

function New-MachineRepo {
    <#
.SYNOPSIS
Creates a private GitHub repository for a specific machine and grants push access to the 'machines' team.

.DESCRIPTION
This function takes a machine number as input and performs the following actions:
1. Creates a private GitHub repository named "machineNumber_TwinCAT" under the "vancebuild" organization.
2. Grants "push" permission to the "machines" team within the "vancebuild" organization for the newly created repository.

.PARAMETER MachineNumber
The unique identifier for the machine. This will be used in the repository name.

.EXAMPLE
New-MachineRepo -MachineNumber 1234
Creates a repository named "vancebuild/1234_TwinCAT" and grants the 'machines' team push access.
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$MachineNumber
    )

    $repoName = "vancebuild/$($MachineNumber)_TwinCAT"

    Write-Host "Creating private repository: $repoName"
    gh repo create $repoName --private

    Write-Host "Granting 'push' permission to the 'machines' team for repository: $repoName"
    gh api --method PUT "/orgs/vancebuild/teams/machines/repos/$repoName" -f permission=push

    Write-Host "Repository '$repoName' created and permissions set."
    Write-Host "Click here to open the repository on GitHub: $($repoUrl)"
}

function Get-MachineRepo {
    <#
.SYNOPSIS
Clones the repo of a private GitHub repository for a specific machine.

.DESCRIPTION
This function takes a machine number as input and clones the corresponding private GitHub repository.

.PARAMETER MachineNumber
The unique identifier for the machine. This will be used in the repository name.

.EXAMPLE
Get-MachineRepo -MachineNumber 1234
Clones the repository named "vancebuild/1234_TwinCAT".
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$MachineNumber
    )

    # Get the full path to the machine directory
    $machineDir = [System.IO.Path]::Combine($env:USERPROFILE, "Projects", "TwinCAT", "$($MachineNumber)_TwinCAT")
  
    # Check if the machine directory already exists, and abort if it does
    if (Test-Path $machineDir) {
        Write-Host "Directory '$machineDir' already exists. Aborting clone operation."
        return
    }

    # Clone the repository
    $repoName = "vancebuild/$($MachineNumber)_TwinCAT"
    gh repo clone $repoName $machineDir

    # Change to the machine directory
    Set-Location $machineDir

    Write-Host "Repository '$repoName' cloned."
}