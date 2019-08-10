# Windows PowerShell
# Setting my computer up

param($dummy)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$WarningPreference = "Continue"
$VerbosePreference = "Continue"
$DebugPreference = "Continue"

######################################################################
### Functions
######################################################################

function Enable-HyperV() {
    if ((Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V)[0].State -ne "Enabled") {
        Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
    }
}

function Install-Chocolatey() {
    $installPath = "$env:ProgramData\Chocolatey"

    if (Test-Path "$installPath" -PathType Leaf) {
        throw "Install-Chocolatey: Same name file with Chocolatey installation folder already exists. [$installLocation]"
    }
    if (Test-Path "$installPath" -PathType Container) {
        Write-Warning "***** Uninstall existing Chocolatey *****"
        Remove-Item "$installPath" -Recurse -Force
    }
    New-Item "$installPath" -ItemType Directory

    Write-Host "***"
    Write-Host "*** Chocolatey Location: $installPath"
    Write-Host "***"
    [System.Environment]::SetEnvironmentVariable($chocInstallVariableName, "$installPath", [System.EnvironmentVariableTarget]::Machine)
    [System.Environment]::SetEnvironmentVariable($chocInstallVariableName, "$installPath", [System.EnvironmentVariableTarget]::Process)

    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadString('https://chocolatey.org/install.ps1') | Invoke-Expression
}

function Install-Vagrant() {
    Chocolatey install --yes vagrant
}

function Install-Packer() {
    Chocolatey install --yes packer
}

function Install-Hidemaru() {
    Chocolatey install --yes hidemaru-editor --params "'/type:64 /exit'"

    # #### CAUTION: Uninstallation ####
    #
    # hidemaru-editor seems not to support chocolatey uninstall.
    # Since you need to uninstall the hidemaru-editor in the program and features.
    # Before that, you need to remove chocolatey entry with a command below:
    # ---
    # Chocolatey uninstall hidemaru-editor -n --skipautouninstaller
    # ---
}

######################################################################
### Process
######################################################################

###
### Preprocess
###

$baseDir = Convert-Path $(Split-Path $MyInvocation.InvocationName -Parent)
$psName = Split-Path $MyInvocation.InvocationName -Leaf
$psBaseName = $psName -replace "\.ps1$", ""
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

Write-Verbose "$psName Start"

###
### Main process
###

Set-ExecutionPolicy RemoteSigned

Install-Chocolatey
Enable-HyperV
Install-Vagrant
Install-Packer
Install-Hidemaru

###
### Postprocess
###

Write-Verbose "$psName End"