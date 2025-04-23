# if in c:\scripts folder run as follows:
# C:\dev\ps1\remove_dups.ps1
# Set the directory path
$directory = "C:\Users\mscip\Desktop\Tony"

# Function to calculate MD5 hash of a file
function Get-FileMD5 {
    param ([string]$filePath)
    $md5 = New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
    $hash = [System.BitConverter]::ToString($md5.ComputeHash([System.IO.File]::ReadAllBytes($filePath))).Replace("-","")
    return $hash
}

# Get all files in the directory and subdirectories
$files = Get-ChildItem -Path $directory -Recurse -File

# Create a hashtable to store file hashes
$hashTable = @{}

# Iterate through files to find duplicates
foreach ($file in $files) {
    try {
        $hash = Get-FileMD5 -filePath $file.FullName
        if ($hashTable.ContainsKey($hash)) {
            # Duplicate found, delete the current file
            Write-Host "Deleting duplicate: $($file.FullName)"
            Remove-Item -Path $file.FullName -Force
        } else {
            # Add hash and file path to hashtable
            $hashTable[$hash] = $file.FullName
        }
    } catch {
        Write-Warning "Error processing $($file.FullName): $_"
    }
}

Write-Host "Duplicate removal complete."