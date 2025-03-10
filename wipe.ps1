Import-Module Microsoft.PowerShell.Utility

#############################################################################
#
# usage: pwsh.exe -NoProfile -ExecutionPolicy Bypass "./wipe.ps1"
#
# PowerShell 7 utilise pwsh.exe
# powershell.exe lance toujours la version 5.1.
#
# To set PS7 as default in WSL2 Terminal, read:
# https://learn.microsoft.com/en-us/powershell/scripting/dev-cross-plat/vscode/using-vscode?view=powershell-7.5#adding-your-own-powershell-paths-to-the-session-menu
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

# Script PowerShell pour effectuer un wipe sécurisé sur un disque ou clé USB
# Remplacer 'X' par la lettre de votre disque ou clé USB (ex: "D", "E", etc.)

$diskPath = "D"  # Remplacez par le chemin du disque à effacer (par exemple, "E:\")
$blockSize = 65536 # Taille du bloc à écrire 64 Ko (ou 4096 octets mais c'est plus lent)
$passes = 3  # Nombre de passes de suppression (0xFF, 0x00, puis données aléatoires)
$WIPE_OUT = "wipe.txt"

#$DISK_ID=1 # (Get-Partition -DriveLetter ${diskPath}).DiskNumber
$FILE_SYSTEM = "NTFS" # "NTFS" | "FAT32"
$FILE_SYSTEM_LABEL = "Renne_4Gb" # "Pinpin_xxxGb"

# Définir la taille du volume (en bytes, ici 1 Go pour l'exemple)
# # 1 Gb = 1024 Mb = 1024 * 1024 Kb = 1024 * 1024 * 1024 bytes = 1073741824 bytes = 8 589 934 592 bits
# $DISK_SIZE = 4GB # 1 Go en bytes 

$DISK_SIZE = $(Get-Disk -Number 1 | Select-Object @{Name="Size"; Expression={$_.Size * 8}}).Size
echo $DISK_SIZE

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
        $RunningProcesses = Get-Process | Where {($_.name -match "iexplore") -or ($_.name -match "firefox") -or ($_.name -match "chrome")}
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

# TODO: implement DOD policy (DOD 5220.22-M)
# https://www.dcsa.mil/about/news/Article/2955986/dcsa-oversight-of-nispom-rules-sead-3-requirements-began-march-1/
# https://www.dcsa.mil/Industrial-Security/National-Industrial-Security-Program-Oversight/32-CFR-Part-117-NISPOM-Rule/
# https://www.federalregister.gov/documents/2020/12/21/2020-27698/national-industrial-security-program-operating-manual-nispom
# https://www.blancco.com/resources/blog-dod-5220-22-m-wiping-standard-method/#When-and-why-was-DoD-5220.22-M-adopted?
#  ISO/IEC 27040:2024: https://www.iso.org/standard/80194.html

#########################################################################################
# 
# https://learn.microsoft.com/fr-fr/powershell/module/microsoft.powershell.utility/get-random?view=powershell-7.5
#
# /!\ IMPORTANT Get-Random ne garantit pas la sécurité par chiffrement aléatoire. La valeur initiale est utilisée pour la commande active et pour toutes les commandes de Get-Random suivantes dans la session active jusqu’à ce que vous utilisiez SetSeed à nouveau ou fermez la session. Vous ne pouvez pas réinitialiser la valeur initiale à sa valeur par défaut.
# La définition délibérée de la valeur initiale entraîne un comportement non aléatoire et reproductible. Il doit être utilisé uniquement lors de la tentative de reproduction du comportement, par exemple lors du débogage ou de l’analyse d’un script qui inclut des commandes Get-Random. N’oubliez pas que la valeur initiale peut être définie par d’autres codes dans la même session, comme un module importé.

# PowerShell 7.4 inclut Get-SecureRandom, ce qui garantit une sécurité par chiffrement aléatoire.
# https://learn.microsoft.com/fr-fr/powershell/module/microsoft.powershell.utility/get-securerandom?view=powershell-7.5

# Fonction pour écrire des données sécurisées sur le disque
function Wipe {
    param (
        [string]$path,
        [long]$size
    )

    Write-Log-Step "+++ Wipe START"
    Write-Log-Step "+++ Wipe path: ${path}"
    Write-Log-Step "+++ Wipe size: ${size}"

    # Crée ou ouvre le fichier en mode ajout
    $stream = [System.IO.File]::Open($path, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write)

    try {
        $buffer = New-Object byte[] $blockSize  # Utilisation d'un buffer de 4 Ko ou 64 Ko
        $bytesWritten = 0

        while ($bytesWritten -lt $size) {
            # Remplir le buffer avec des données sécurisées
            # Get-SecureRandom -Count $blockSize retourne un tableau d'entiers (System.Object[] contenant des entiers Int32), 
            # mais la méthode .Write() attend un tableau de bytes (System.Byte[]).
            # $secureRandomBytes = Get-SecureRandom -Count $blockSize
            # $secureRandomBytes = [byte[]](Get-SecureRandom -Count $blockSize)
            # $secureRandomBytes = Get-SecureRandom -Minimum 0 -Maximum 255 -Count $blockSize | ForEach-Object { [byte]$_ }

            # https://learn.microsoft.com/en-us/dotnet/api/system.security.cryptography.randomnumbergenerator?view=net-9.0
            $secureRandomBytes = New-Object byte[] $blockSize
            [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($secureRandomBytes)

            $stream.Write($secureRandomBytes, 0, $secureRandomBytes.Length)
            $bytesWritten += $secureRandomBytes.Length
            Write-Progress -Activity "Wiping" -Status "Writing $bytesWritten / $size bytes" -PercentComplete ($bytesWritten / $size * 100)
        }
    }
    finally {
        $stream.Close()
        Write-Log-Step "+++ Wipe END"
    }
}


function Wipe2 {
    param (
        [string]$path,
        [long]$size,
        [int]$pass
    )

    Write-Log-Step "+++ Wipe2 START"

    Write-Log-Step "+++ Wipe2 path: ${path}"
    Write-Log-Step "+++ Wipe2 size: ${size}"
    Write-Log-Step "+++ Wipe2 pass: ${pass}"

    # Crée ou ouvre le fichier en mode ajout
    $stream = [System.IO.File]::Open($path, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write)

    try {
        $bytesWritten = 0
        $buffer = New-Object byte[] $blockSize  # Utilisation d'un buffer de 64 Ko
        $rand = Get-SecureRandom # New-Object Get-SecureRandom

        # Remplir le buffer avec des données spécifiques pour chaque passe
        switch ($pass) {
            1 {
                Write-Log-Sub-Step "+++ Wipe2 pass 1: 0xFF"
                # Première passe : remplir avec 0xFF https://learn.microsoft.com/en-us/answers/questions/1152118/recycle-bin-i-file-header-0xff

                # https://learn.microsoft.com/en-us/powershell/scripting/learn/deep-dives/everything-about-arrays?view=powershell-7.5#initialize-with-0
                # https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_arrays?view=powershell-7.5
                # https://learn.microsoft.com/en-us/dotnet/api/system.array.fill?view=net-7.0
                [Array]::Fill($buffer, 0xFF, 0)
            }
            2 {
                Write-Log-Sub-Step "+++ Wipe2 pass 2: 0x00"
                # Deuxième passe : remplir avec 0x00 https://learn.microsoft.com/en-us/answers/questions/1152118/recycle-bin-i-file-header-0xff
                [Array]::Fill($buffer, 0x00, 0)
            }
            default {
                 Write-Log-Sub-Step "+++ Wipe2 pass 3+: Random"
                # Dernière passe : Remplir le buffer avec des données aléatoires
                # $rand.NextBytes($buffer) # Method invocation failed because [System.Int32] does not contain a method named 'NextBytes'.
                [System.Security.Cryptography.RandomNumberGenerator]::Fill($buffer)
                #[void](Get-Random -SetSeed (Get-SecureRandom) -Minimum 0 -Maximum 255) | ForEach-Object {
                #    $buffer[$_] = [byte](Get-SecureRandom -Minimum 0 -Maximum 255)
                #}
            }
        }

        # Écrire sur le Drive
        while ($bytesWritten -lt $size) {
            $stream.Write($buffer, 0, $buffer.Length)
            $bytesWritten += $buffer.Length
        }
    }
    finally {
        $stream.Close()
        Write-Log-Step "+++ Wipe2 END"
    }
}

[int]$osBits = CheckOS
Write-Host ""
Get-Volume -DriveLetter "${diskPath}"
Write-Host ""
Get-Disk
Write-Host ""

# Set-Disk -Number 1 -IsReadOnly $false

Write-Host "Have you read carefully the README file ?[Yes/No]: "
$READ_CHECK = Read-Host
Write-Host ""

if ($READ_CHECK -eq 'y' -or $READ_CHECK -eq 'Yes') {
    Write-Log-Step MAIN WIPE START
    Write-Host ""
    
    Write-Log-Sub-Step "ScriptName: $ScriptName"
    Write-Log-Sub-Step "ScriptPath: $ScriptPath"

    $diskNumber = (Get-Partition -DriveLetter "${diskPath}").DiskNumber
    Write-Log-Sub-Step "diskNumber: ${diskNumber}"
    Get-Disk -Number ${diskNumber} | Select Number, IsReadOnly
    Set-Disk -Number ${diskNumber} -IsReadOnly $false

    Write-Log-Sub-Step "diskPath : ${diskPath}:"
    Write-Log-Sub-Step "OUTPUT WIPE FILE: ${diskPath}:/${WIPE_OUT}"
    Add-content "${diskPath}:/${WIPE_OUT}" -value ""
    Write-Log-Sub-Step "blockSize: $blockSize"
    Write-Log-Sub-Step "passes: $passes"
    Write-Log-Sub-Step "DISK_SIZE: $DISK_SIZE"
    Write-Log-Sub-Step ""
    
    for ($i = 1; $i -le $passes; $i++) {
        Write-Log-Sub-Step "I. Pass $i / $passes"
        Wipe -path "${diskPath}:/${WIPE_OUT}" -size $DISK_SIZE
        Write-Progress -Activity "Secure Wipe" -Status "Pass $i / $passes" -PercentComplete ($i / $passes * 100)
        Write-Log-Sub-Step "I. Pass OUTPUT WIPE FILE: ${diskPath}:/${WIPE_OUT} DELETED."
        Remove-Item "${diskPath}:/${WIPE_OUT}"
        Write-Log-Sub-Step "I. Pass OUTPUT WIPE FILE: ${diskPath}:/${WIPE_OUT} REMOVED."
        #Clear-Disk -Number $DISK_ID -RemoveData -Confirm:$false
        #Write-Host "I. Pass OUTPUT WIPE : ${diskPath} CLEARED."
        Format-Volume -Full -DriveLetter ${diskPath} -FileSystem $FILE_SYSTEM -NewFileSystemLabel $FILE_SYSTEM_LABEL -Confirm:$false
        Write-Log-Sub-Step "I. Pass ${diskPath}: FORMATED."
    }

    for ($i = 1; $i -le $passes; $i++) {
        Write-Log-Sub-Step "II. Pass $i / $passes"
        Wipe2 -path "${diskPath}:/${WIPE_OUT}" -size $DISK_SIZE -pass $i
        Write-Progress -Activity "Secure Wipe2" -Status "Pass $i / $passes" -PercentComplete ($i / $passes * 100)
        Remove-Item "${diskPath}:/${WIPE_OUT}"
        Write-Log-Sub-Step "II. Pass OUTPUT WIPE FILE: ${diskPath}:/${WIPE_OUT} DELETED."
        Format-Volume -Full -DriveLetter ${diskPath} -FileSystem $FILE_SYSTEM -NewFileSystemLabel $FILE_SYSTEM_LABEL -Confirm:$false
        Write-Log-Sub-Step "II. Pass ${diskPath}: FORMATED."        
    }

    Write-Log-Step "The data ont Disk/Drive ${diskPath}: have been securely wiped."
    Write-Host ""
    Write-Log-Step MAIN WIPE END
} else {
    Write-Log-Step "You should read carefully the README file ..."
}

exit $LastExitCode