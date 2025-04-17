# usage:
# save this script in the 'c:\scripts' folder 
# rename file with 'remove_dups_w_log.ps1' extension
#
# run: get into powershell in any path and past the following full pathed command inside the single quotes ''
# 'C:\scripts\remove_dups_w_log.ps1'
#
# Set the directory path to remove the duplicates
$directory = "c:\t\temp"
$logFile = "T:\Estimates\duplicate_log.txt"

# Function to calculate MD5 hash of a file
function Get-FileMD5 {
    param ([string]$filePath)
    $md5 = New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
    $hash = [System.BitConverter]::ToString($md5.ComputeHash([System.IO.File]::ReadAllBytes($filePath))).Replace("-","")
    return $hash
}

# Initialize log file
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
"Duplicate Removal Log - Started at $timestamp" | Out-File -FilePath $logFile -Encoding utf8
"Directory: $directory" | Out-File -FilePath $logFile -Append -Encoding utf8
"----------------------------------------" | Out-File -FilePath $logFile -Append -Encoding utf8

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
            $deleteTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            "Deleted: $($file.FullName) (Hash: $hash) at $deleteTime" | Out-File -FilePath $logFile -Append -Encoding utf8
            Remove-Item -Path $file.FullName -Force
        } else {
            # Add hash and file path to hashtable
            $hashTable[$hash] = $file.FullName
        }
    } catch {
        Write-Warning "Error processing $($file.FullName): $_"
        $errorTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        "Error processing $($file.FullName) at $errorTime : $($_.Exception.Message)" | Out-File -FilePath $logFile -Append -Encoding utf8
    }
}

# Finalize log
$endTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
"Duplicate removal complete at $endTime" | Out-File -FilePath $logFile -Append -Encoding utf8
Write-Host "Duplicate removal complete. Log saved to $logFile"