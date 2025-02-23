# Script PowerShell pour effectuer un wipe sécurisé sur un disque ou clé USB
# Remplacer 'X' par la lettre de votre disque ou clé USB (ex: "D", "E", etc.)

$diskPath = "D:\"  # Remplacez par le chemin du disque à effacer (par exemple, "E:\")
$blockSize = 4096  # Taille du bloc à écrire (4096 octets)
$passes = 3  # Nombre de passes de suppression (0xFF, 0x00, puis données aléatoires)

# Définir la taille du volume (en bytes, ici 1 Go pour l'exemple)
# # 1 Gb = 1024 Mb = 1024 * 1024 Kb = 1024 * 1024 * 1024 bytes = 1073741824 bytes = 8 589 934 592 bits
$data_volume_size = 1GB # 1 Go en bytes

# TODO: implement DOD policy (DOD 5220.22-M)
# https://www.dcsa.mil/about/news/Article/2955986/dcsa-oversight-of-nispom-rules-sead-3-requirements-began-march-1/
# https://www.dcsa.mil/Industrial-Security/National-Industrial-Security-Program-Oversight/32-CFR-Part-117-NISPOM-Rule/
# https://www.federalregister.gov/documents/2020/12/21/2020-27698/national-industrial-security-program-operating-manual-nispom

#########################################################################################
# 
# https://learn.microsoft.com/fr-fr/powershell/module/microsoft.powershell.utility/get-random?view=powershell-7.5
#
# /!\ IMPORTANT Get-Random ne garantit pas la sécurité par chiffrement aléatoire. La valeur initiale est utilisée pour la commande active et pour toutes les commandes de Get-Random suivantes dans la session active jusqu’à ce que vous utilisiez SetSeed à nouveau ou fermez la session. Vous ne pouvez pas réinitialiser la valeur initiale à sa valeur par défaut.
# La définition délibérée de la valeur initiale entraîne un comportement non aléatoire et reproductible. Il doit être utilisé uniquement lors de la tentative de reproduction du comportement, par exemple lors du débogage ou de l’analyse d’un script qui inclut des commandes Get-Random. N’oubliez pas que la valeur initiale peut être définie par d’autres codes dans la même session, comme un module importé.

# PowerShell 7.4 inclut Get-SecureRandom, ce qui garantit une sécurité par chiffrement aléatoire.
# https://learn.microsoft.com/fr-fr/powershell/module/microsoft.powershell.utility/get-securerandom?view=powershell-7.5

# Script pour effacer un disque/clé USB en utilisant un chiffrement aléatoire sécurisé
# Cette méthode génère des données aléatoires sécurisées pour écraser un disque/clé USB.
function Get-SecureByte {
    # Utilisation de Get-SecureRandom pour garantir un chiffrement sécurisé
    $secureByte = [System.Security.Cryptography.RandomNumberGenerator]::GetBytes(1)
    return $secureByte[0]
}

$progress = 0

# Créer un fichier ou accéder au disque cible
# Remplacez ce chemin par le chemin vers le disque ou la clé USB
$diskPath = "D:\"

# Créer un flux pour écrire les données sécurisées
$fileStream = [System.IO.File]::OpenWrite($diskPath)

# Boucle pour écrire les données sécurisées sur le disque
for ($i = 0; $i -lt $data_volume_size; $i++) {
    $byte = Get-SecureByte
    $fileStream.WriteByte($byte)

    # Affichage de la progression
    $progress = ($i / $data_volume_size) * 100
    Write-Progress -PercentComplete $progress -Activity "Effacement en cours" -Status "$progress% terminé"
}

# Fermer le flux une fois terminé
$fileStream.Close()
Write-Host "Effacement sécurisé terminé."