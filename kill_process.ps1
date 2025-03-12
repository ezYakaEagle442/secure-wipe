Import-Module Microsoft.PowerShell.Utility

#############################################################################
#
# usage: pwsh.exe -NoProfile -ExecutionPolicy Bypass "./kill_process.ps1"
#
# PowerShell 7 utilise pwsh.exe
# powershell.exe lance toujours la version 5.1.
# 
#############################################################################

#############################################################################
#
# Pre-requis
#
# PowerShell 7 utilise pwsh.exe
# powershell.exe lance toujours la version 5.1.
# 
#############################################################################

$PSH_VER="7.5.0"
Write-Host "PowerShell Version : $PSH_VER"
Write-Host ""
Write-Host "You must download & install https://github.com/PowerShell/PowerShell/releases/download/v$PSH_VER/PowerShell-$PSH_VER-win-x64.msi"
Write-Host ""
$PSVersionTable.PSVersion
pwsh.exe -v
Write-Host ""

#Log File
$LogPath = "$env:windir\Temp"
$LogFile = "$LogPath\wipe.log"

#Script
$ScriptName = $MyInvocation.MyCommand.Name
$ScriptPath = split-path $SCRIPT:MyInvocation.MyCommand.Path -parent

#Return codes
$ReturnCodes = @{"OK" = 0;
				"PIN-SYS-1" = 196; # This OS is not supported.
				"PIN_ERR_001_ACCESS_DENIED" = 1603; # Access to the path 'D:\' is denied.				
				}

#$OutputEncoding = New-Object -typename System.Text.UTF8Encoding
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
# $OutputEncoding = [Console]::OutputEncoding
#[Console]::OutputEncoding=[Text.Encoding]::Unicode

Function Write-Log {
	Param ([string]$logstring)
	Add-content $LogFile -value $logstring
	Write-Host $logstring
}

Function Write-Log-Step {
	Param ([string]$logstring)
	$Separator = "#" * ($logstring.length + 25)
	Write-Log $Separator
	Write-Log "$(Get-Date -Format G) - $logstring"
	Write-Log $Separator
}

Function Write-Log-Sub-Step {
	Param ([string]$logstring)
	$Separator = "-" * ($logstring.length + 25)
	Write-Log $Separator
	Write-Log "$(Get-Date -Format G) - $logstring"
	Write-Log $Separator
}

function CheckOS {
	Write-Log-Step "Check OS"
	$OS = Get-WmiObject -class Win32_OperatingSystem
	Write-Log "OS detected: $($OS.Caption) $($OS.OSArchitecture)"
	if (($OS.Version -match "10.0.26100") -and ($OS.OSArchitecture -match "64")){
		Write-Log "This OS is supported"
		# http://www.samlogic.net/articles/sysnative-folder-64-bit-windows.htm
		if ((Test-Path -Path $env:windir\SysNative) -eq $true) {
			Write-Log "32-bit environment of execution detected!"
			return 32 ;
		}
		else {
			Write-Log "This x64 OS is supported"
			return 64 ;
		}
	}
	else {
		if (($OS.Version -match "10.0.26100") -and ($OS.OSArchitecture -match "32")) {
			Write-Log "This x86 OS is supported"
			return 32 ;
		}
		else {
			Write-Log "This OS is not supported."
			TerminateScript "PIN-SYS-1"
		}
	}
}


#*********************************************************************
# Kill Process
#*********************************************************************
function KillProcess() {
	Write-Log-Step "KillProcess START"
	for ($attempt = 1; $attempt -le 10; $attempt++) {
		Write-Log-Sub-Step "Searching for running XXX processes (attempt #$attempt)..."
		#Write-Log "Attempt #$attempt"
		# $RunningProcesses = Get-Process | Where {($_.name -match "javaw") -or ($_.name -match "javaws") -or ($_.name -match "jp2launcher") -or ($_.name -match "jusched")}
        $RunningProcesses = Get-Process | Where {($_.name -match "iexplore") -or ($_.name -match "toto") -or ($_.name -match "chrome")}
        if ($RunningProcesses.Count -gt 0) {
			Write-Log "Found the following running xxxxx processes:"
			ForEach ($xProcess in $RunningProcesses) {
				Write-Log $xProcess.Name
			}
			Write-Log-Sub-Step "Closing all running XXX processes..."
			ForEach ($xProcess in $RunningProcesses) {
				Write-Log "$(Get-Date -Format G) - Stopping ""$($xProcess.Name)"" process..."
				$xProcess | Stop-Process -Force
				Write-Log "$(Get-Date -Format G) - Process stopped"
			}
			#Write-Log "All xxxx processes are now closed"
			Start-Sleep -Seconds 2
		}
		else {
			Write-Log "Found no running xxx processes"
			Break
		}
	}
	Write-Log-Step "KillProcess END"
}

[int]$osBits = CheckOS
Write-Host ""

Write-Host "Have you read carefully the README file ?[Yes/No]: "
$READ_CHECK = Read-Host
Write-Host ""

if ($READ_CHECK -eq 'y' -or $READ_CHECK -eq 'Yes') {
    Write-Log-Step MAIN WIPE START
    Write-Host ""
    
    Write-Log-Sub-Step "ScriptName: $ScriptName"
    Write-Log-Sub-Step "ScriptPath: $ScriptPath"

    KillProcess

    Write-Host ""
    Write-Log-Step MAIN WIPE END
} else {
    Write-Log-Step "You should read carefully the README file ..."
}

exit $LastExitCode