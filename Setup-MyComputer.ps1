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

function Get-StandardPackageProviders() {
    Get-PackageProvider -Force -Name Chocolatey
    Get-PackageProvider -Force -Name NuGet

    $ChocolateyBin = ($env:ChocolateyPath + "\bin")
    if ($env:Path.IndexOf($ChocolateyBin) -lt 0) {
        if ($env:Path.Substring($env:Path.Length - 1, 1) -ne ";") {
            $env:Path += ";"
        }
        $env:Path += $ChocolateyBin
        [System.Environment]::SetEnvironmentVariable("Path", $env:Path, "Machine")
    }
}

function Enable-HyperV() {
    if ((Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V)[0].State -ne "Enabled") {
        Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
    }
}

function Install-Vagrant() {
    Install-Package -Name vagrant -Force
}

function Install-Packer() {
    Install-Package -Name packer -Force
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

Get-StandardPackageProviders
Enable-HyperV
Install-Vagrant
Install-Packer

###
### Postprocess
###

Write-Verbose "$psName End"