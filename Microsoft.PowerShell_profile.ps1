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

function Remove-SshKnownHostEntry {
    [CmdletBinding(
        SupportsShouldProcess = $true, # Allows -WhatIf and -Confirm
        ConfirmImpact = 'Medium'
    )]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$IPAddress
    )

    Begin {
        $knownHostsPath = Join-Path -Path $env:USERPROFILE -ChildPath ".ssh\known_hosts"
        if (-not (Test-Path -Path $knownHostsPath)) {
            Write-Warning "known_hosts file not found at '$knownHostsPath'. No action taken."
            return
        }
    }

    Process {
        # Read the current content
        $originalContent = Get-Content -Path $knownHostsPath

        # Filter out lines matching the IP address
        $newContent = $originalContent | Where-Object { $_ -notmatch [regex]::Escape($IPAddress) }

        # Check if any changes were made
        if ($originalContent.Count -eq $newContent.Count) {
            Write-Host "No entries found for IP address '$IPAddress' in '$knownHostsPath'."
            return
        }

        # Perform the write operation with ShouldProcess for safety
        if ($PSCmdlet.ShouldProcess("Remove entries for '$IPAddress' from '$knownHostsPath'", "Remove Known Host Entry")) {
            try {
                Set-Content -Path $knownHostsPath -Value $newContent -Force
                Write-Host "Successfully removed entries for '$IPAddress' from '$knownHostsPath'."
            }
            catch {
                Write-Error "Failed to update known_hosts file: $($_.Exception.Message)"
            }
        }
    }

    End {
        # Clean up if necessary (not much needed here)
    }
}

function Switch-EthernetIp {
    <#
.SYNOPSIS
Toggles the Ethernet adapter between a machine-network static IP and DHCP.

.DESCRIPTION
Switches the Ethernet interface between 192.168.25.213/24 and DHCP.
No default gateway is set on the static address so Wi-Fi keeps the default route.
Changing IP configuration requires administrator privileges; if this session is
not elevated, a UAC prompt is shown and the change runs as administrator.

.PARAMETER Static
Force the machine-network static address instead of toggling.

.PARAMETER Dhcp
Force DHCP instead of toggling.

.PARAMETER InterfaceAlias
Name of the adapter to configure. Defaults to Ethernet.

.PARAMETER IPAddress
Static IPv4 address to apply. Defaults to 192.168.25.213.

.PARAMETER PrefixLength
Subnet prefix length. Defaults to 24.

.EXAMPLE
Switch-EthernetIp
Toggles Ethernet between static 192.168.25.213/24 and DHCP.

.EXAMPLE
Switch-EthernetIp -Static
Sets Ethernet to 192.168.25.213/24.

.EXAMPLE
Switch-EthernetIp -Dhcp
Restores DHCP on Ethernet.
#>
    [CmdletBinding(DefaultParameterSetName = 'Toggle', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param(
        [Parameter(ParameterSetName = 'Static')]
        [switch]$Static,

        [Parameter(ParameterSetName = 'Dhcp')]
        [switch]$Dhcp,

        [Parameter()]
        [string]$InterfaceAlias = 'Ethernet',

        [Parameter()]
        [ipaddress]$IPAddress = '192.168.25.213',

        [Parameter()]
        [ValidateRange(1, 32)]
        [int]$PrefixLength = 24
    )

    $adapter = Get-NetAdapter -Name $InterfaceAlias -ErrorAction SilentlyContinue
    if (-not $adapter) {
        $available = (Get-NetAdapter | Select-Object -ExpandProperty Name) -join ', '
        Write-Error "Adapter '$InterfaceAlias' was not found. Available adapters: $available"
        return
    }

    if ($adapter.Status -ne 'Up') {
        Write-Warning "Adapter '$InterfaceAlias' is $($adapter.Status). The address will still be saved."
    }

    $ipInterface = Get-NetIPInterface -InterfaceAlias $InterfaceAlias -AddressFamily IPv4
    $staticIpText = $IPAddress.IPAddressToString
    $currentAddresses = @(
        Get-NetIPAddress -InterfaceAlias $InterfaceAlias -AddressFamily IPv4 -ErrorAction SilentlyContinue |
            Where-Object { $_.IPAddress -notlike '169.254.*' }
    )

    if ($Static) {
        $useStatic = $true
    }
    elseif ($Dhcp) {
        $useStatic = $false
    }
    else {
        $useStatic = $ipInterface.Dhcp -ne 'Disabled'
    }

    if ($useStatic) {
        $alreadyStatic = $currentAddresses |
            Where-Object { $_.IPAddress -eq $staticIpText -and $_.PrefixLength -eq $PrefixLength }
        if (($ipInterface.Dhcp -eq 'Disabled') -and $alreadyStatic) {
            Write-Host "$InterfaceAlias is already static ($staticIpText/$PrefixLength)."
            return
        }
    }
    elseif ($ipInterface.Dhcp -eq 'Enabled') {
        Write-Host "$InterfaceAlias is already using DHCP."
        return
    }

    $targetDescription = if ($useStatic) {
        "static $staticIpText/$PrefixLength"
    }
    else {
        'DHCP'
    }

    if (-not $PSCmdlet.ShouldProcess($InterfaceAlias, "Set $targetDescription")) {
        return
    }

    $applyScript = @'
param(
    [string]$InterfaceAlias,
    [string]$StaticIp,
    [int]$PrefixLength,
    [ValidateSet('Static', 'Dhcp')]
    [string]$Mode,
    [string]$LogFile
)

$ErrorActionPreference = 'Stop'

try {
    Get-NetIPAddress -InterfaceAlias $InterfaceAlias -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue

    Get-NetRoute -InterfaceAlias $InterfaceAlias -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object { $_.DestinationPrefix -eq '0.0.0.0/0' } |
        Remove-NetRoute -Confirm:$false -ErrorAction SilentlyContinue

    if ($Mode -eq 'Static') {
        Set-NetIPInterface -InterfaceAlias $InterfaceAlias -AddressFamily IPv4 -Dhcp Disabled
        New-NetIPAddress -InterfaceAlias $InterfaceAlias -IPAddress $StaticIp -PrefixLength $PrefixLength -AddressFamily IPv4 |
            Out-Null
        Set-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -ResetServerAddresses
    }
    else {
        Set-NetIPInterface -InterfaceAlias $InterfaceAlias -AddressFamily IPv4 -Dhcp Enabled
        Set-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -ResetServerAddresses
    }

    if ($LogFile) {
        'SUCCESS' | Set-Content -Path $LogFile
    }
}
catch {
    if ($LogFile) {
        "ERROR: $($_.Exception.Message)" | Set-Content -Path $LogFile
    }
    throw
}
'@

    $logFile = Join-Path $env:TEMP 'Switch-EthernetIp.log'
    $scriptFile = Join-Path $env:TEMP 'Switch-EthernetIp.ps1'
    $applyScript | Set-Content -Path $scriptFile -Encoding UTF8
    if (Test-Path $logFile) {
        Remove-Item -Path $logFile -Force
    }

    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )

    $applyParams = @{
        InterfaceAlias = $InterfaceAlias
        StaticIp       = $staticIpText
        PrefixLength   = $PrefixLength
        Mode           = $(if ($useStatic) { 'Static' } else { 'Dhcp' })
        LogFile        = $logFile
    }

    if ($isAdmin) {
        try {
            & $scriptFile @applyParams
        }
        catch {
            Write-Error "Failed to set $InterfaceAlias to $targetDescription`: $($_.Exception.Message)"
            return
        }
    }
    else {
        $exe = (Get-Process -Id $PID).Path
        $arguments = @(
            '-NoProfile'
            '-ExecutionPolicy', 'Bypass'
            '-File', $scriptFile
            '-InterfaceAlias', $InterfaceAlias
            '-StaticIp', $staticIpText
            '-PrefixLength', "$PrefixLength"
            '-Mode', $(if ($useStatic) { 'Static' } else { 'Dhcp' })
            '-LogFile', $logFile
        )

        try {
            $proc = Start-Process -FilePath $exe -Verb RunAs -Wait -PassThru -ArgumentList $arguments
        }
        catch {
            Write-Error "Elevation was cancelled or failed: $($_.Exception.Message)"
            return
        }

        $logText = if (Test-Path $logFile) { (Get-Content -Path $logFile -Raw).Trim() } else { '' }
        if ($logText -like 'ERROR:*') {
            Write-Error "Failed to set $InterfaceAlias to $targetDescription`: $($logText.Substring(6).Trim())"
            return
        }
        if ($proc.ExitCode -ne 0 -and $logText -ne 'SUCCESS') {
            Write-Error "Failed to set $InterfaceAlias to $targetDescription (exit code $($proc.ExitCode))."
            return
        }
    }

    $resultInterface = Get-NetIPInterface -InterfaceAlias $InterfaceAlias -AddressFamily IPv4
    $resultAddresses = @(
        Get-NetIPAddress -InterfaceAlias $InterfaceAlias -AddressFamily IPv4 -ErrorAction SilentlyContinue |
            Where-Object { $_.IPAddress -notlike '169.254.*' } |
            Select-Object -ExpandProperty IPAddress
    )
    $mode = if ($resultInterface.Dhcp -eq 'Enabled') { 'DHCP' } else { 'Static' }
    $addressText = if ($resultAddresses.Count -gt 0) { $resultAddresses -join ', ' } else { 'no IPv4 address yet' }
    Write-Host "$InterfaceAlias is now $mode ($addressText)."
}
