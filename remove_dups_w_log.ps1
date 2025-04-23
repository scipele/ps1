# | Item	     | Powershell Script Documentation Notes                       |
# |--------------|-------------------------------------------------------------|
# | Filename     | remove_dups_w_log.ps1                                       |
# | Purpose      | remove duplicate files in a given path                      |
# | Inputs       | hard coded file path                                        |
# | Outputs      | deletes redundant files determined from MD5 hash of binary  |
# | Dependencies | none                                                        |
# | By Name,Date | T.Sciple, 4/20/2025                                         |
# | usage:       | save this script in the 'c:\scripts' folder
# |              |
# | run:         | right click and say run with powershell
# | 
# hard code the directory to delete the duplicates
$directory = "T:\Estimates\2025\1.ME\Air Liquide\25-0354 27058 Corpus Christi FEED H2 Membrane skid RFP\1. RFP"
# hard code the directory where you want to put the duplicate log
$logFile = "c:\t\dup_log.txt"

# Function to calculate MD5 hash of a file
function Get_FileSHA1 {
    param ([string]$filePath)
    $sha1 = New-Object -TypeName System.Security.Cryptography.SHA1CryptoServiceProvider
    $hash = [System.BitConverter]::ToString($sha1.ComputeHash([System.IO.File]::ReadAllBytes($filePath))).Replace("-","")
    return $hash
}

# Initialize log file
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
"Duplicate Removal Log - Started at $timestamp" | Out-File -FilePath $logFile -Encoding utf8
"Directory: $directory" | Out-File -FilePath $logFile -Append -Encoding utf8
# Write table header
@"
`nThe following files were deleted since exact duplicates based on SHA1 hash were found:
+------------------------------------------+---------------------+----------------------------------------------------------------------------------------
| Sha1 Hash                                | Last Save Date      | FilePath                                                                             
+------------------------------------------+---------------------+----------------------------------------------------------------------------------------
"@ | Out-File -FilePath $logFile -Append -Encoding utf8

# Get all files in the directory and subdirectories
$files = Get-ChildItem -Path $directory -Recurse -File

# Create a hashtable to store file hashes
$hashTable = @{}

# Iterate through files to find duplicates
foreach ($file in $files) {
    try {
        $hash = Get_FileSHA1 -filePath $file.FullName
        if ($hashTable.ContainsKey($hash)) {
            # Duplicate found, log and delete the previously stored file
            Write-Host "Deleting duplicate: $($hashTable[$hash])"
            $deleteTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            "| $hash | $deleteTime | $($hashTable[$hash])" | Out-File -FilePath $logFile -Append -Encoding utf8
            Remove-Item -Path $hashTable[$hash] -Force
            # Update hashtable with the current file
            $hashTable[$hash] = $file.FullName
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
"+------------------------------------------+---------------------+---------------------------------------------------------------------------------------`n" | Out-File -FilePath $logFile -Append -Encoding utf8
"Duplicate removal complete at $endTime" | Out-File -FilePath $logFile -Append -Encoding utf8
Write-Host "Duplicate removal complete. Log saved to $logFile"

# Open the log file
Invoke-Item $logFile