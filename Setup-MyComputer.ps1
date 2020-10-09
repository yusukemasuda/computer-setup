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
        Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart
    }
}

function Enable-WindowsSubsystemLinux2() {
    if ((Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux)[0].State -ne "Enabled") {
        
        Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -All -NoRestart
    }
    if ((Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform)[0].State -ne "Enabled") {
        
        Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -All -NoRestart
    }
    wsl --set-default-version 2
}

function Update-WslKernelComponent() {

    $uri = New-Object System.Uri("https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi")
    $file = Split-Path $uri.AbsolutePath -Leaf
    $MsiPath = "$env:TEMP\$file"

    Write-Host "*** WSL Kernel Component: Downloading: $MsiPath"
    Invoke-WebRequest -Uri $uri -OutFile "$MsiPath" -UseBasicParsing
    Write-Host "*** WSL Kernel Component: Completed downloading."

    $Arguments = @("/c", "`"msiexec /i `"$MsiPath`" /quiet /norestart`"" )
    $process = Start-Process -FilePath "cmd.exe" -ArgumentList $Arguments -Wait -PassThru
    $exitCode = $process.ExitCode
    if ($exitCode -eq 0 -or $exitCode -eq 3010)
    {
        Write-Host -Object "Installation successful"
        Remove-Item "$MsiPath"
        Write-Host -Object "Cleaned up file: `"$MsiPath`""
    }
    else
    {
        Write-Host -Object "Non zero exit code returned by the installation process : $exitCode."
    }
}

function Install-Ubuntu2004() {

    Enable-WindowsSubsystemLinux2
    Update-WslKernelComponent

    $uri = New-Object System.Uri("https://aka.ms/wslubuntu2004")
    $appxPath = "$env:TEMP\Ubuntu_2004_x64.appx"

    Write-Host "*** Ubuntu-20.04: Downloading: $appxPath"
    Invoke-WebRequest -Uri $uri -OutFile "$appxPath" -UseBasicParsing
    Write-Host "*** Ubuntu-20.04: Completed downloading."

    Add-AppxPackage -Path "$appxPath"
    Write-Host "*** Ubuntu-20.04: completed installation."
}

function Install-DockerWindows() {
   $DockerURL = "https://download.docker.com/win/stable/Docker%20Desktop%20Installer.exe"
   $exitCode = -1
   $FilePath = "${env:Temp}\Docker Desktop Installer.exe"

   Write-Host "Downloading Docker Desktop for Windows ..."
   Remove-Item -Path "$FilePath"
   Invoke-WebRequest -Uri "$DockerURL" -OutFile "$FilePath"
   $process = Start-Process -FilePath "`"$FilePath`"" -ArgumentList ("install", "--quiet") -Wait -PassThru
   $exitCode = $process.ExitCode
   if ($exitCode -eq 0)
   {
       Write-Host "Installed Docker Desktop for Windows successfully." -ForegroundColor Cyan
       return $exitCode
   }
   else
   {
       Write-Host -Object "Non zero exit code returned by the installation process : $exitCode."
       # this wont work because of log size limitation in extension manager
       # Get-Content $customLogFilePath | Write-Host
       exit $exitCode
   }
}


function Install-Chocolatey() {
    $chocInstallVariableName = "ChocolateyInstall"
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

function Install-VsCode() {
    Chocolatey install --yes vscode
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
Install-VsCode
Install-Hidemaru
Install-Ubuntu2004

###
### Postprocess
###

Write-Verbose "$psName End"