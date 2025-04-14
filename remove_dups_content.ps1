# Define directories
$newDir = "C:\t\new"
$origDir = "C:\t\orig"

# Function to extract Excel content for hashing (ignores metadata)
function Get-ExcelContentHash {
    param ([string]$filePath)
    try {
        Add-Type -AssemblyName DocumentFormat.OpenXml
        $hashAlgo = [System.Security.Cryptography.SHA256]::Create()
        $stream = [System.IO.File]::OpenRead($filePath)
        $package = [DocumentFormat.OpenXml.Packaging.SpreadsheetDocument]::Open($stream, $false)
        $workbookPart = $package.WorkbookPart
        $sheets = $workbookPart.Workbook.Descendants([DocumentFormat.OpenXml.Spreadsheet.Sheet])
        $content = ""

        foreach ($sheet in $sheets) {
            $worksheetPart = $workbookPart.GetPartById($sheet.Id)
            $cells = $worksheetPart.Worksheet.Descendants([DocumentFormat.OpenXml.Spreadsheet.Cell])
            foreach ($cell in $cells) {
                $value = if ($cell.CellValue) { $cell.CellValue.Text } else { "" }
                $content += $value + "|"
            }
        }

        $package.Close()
        $stream.Close()
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($content)
        $hash = [System.BitConverter]::ToString($hashAlgo.ComputeHash($bytes)).Replace("-","")
        return $hash
    }
    catch {
        Write-Warning "Error processing Excel content for $filePath : $($_.Exception.Message)"
        return $null
    }
}

# Function to extract Word content for hashing (ignores metadata)
function Get-WordContentHash {
    param ([string]$filePath)
    try {
        Add-Type -AssemblyName DocumentFormat.OpenXml
        $hashAlgo = [System.Security.Cryptography.SHA256]::Create()
        $stream = [System.IO.File]::OpenRead($filePath)
        $package = [DocumentFormat.OpenXml.Packaging.WordprocessingDocument]::Open($stream, $false)
        $mainPart = $package.MainDocumentPart
        $textElements = $mainPart.Document.Descendants([DocumentFormat.OpenXml.Wordprocessing.Text])
        $content = [System.String]::Join("", ($textElements | ForEach-Object { $_.Text }))

        $package.Close()
        $stream.Close()
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($content)
        $hash = [System.BitConverter]::ToString($hashAlgo.ComputeHash($bytes)).Replace("-","")
        return $hash
    }
    catch {
        Write-Warning "Error processing Word content for $filePath : $($_.Exception.Message)"
        return $null
    }
}

# Function to calculate SHA-256 hash of a file (for non-Excel/Word files)
function Get-FileHash {
    param ([string]$filePath)
    try {
        $hashAlgo = [System.Security.Cryptography.SHA256]::Create()
        $fileStream = [System.IO.File]::OpenRead($filePath)
        $hash = [System.BitConverter]::ToString($hashAlgo.ComputeHash($fileStream)).Replace("-","")
        $fileStream.Close()
        return $hash
    }
    catch {
        Write-Warning "Error calculating hash for $filePath : $($_.Exception.Message)"
        return $null
    }
}

# Function to get hash based on file type
function Get-ContentHash {
    param ([string]$filePath)
    $extension = [System.IO.Path]::GetExtension($filePath).ToLower()
    if ($extension -eq ".xlsx") {
        return Get-ExcelContentHash -filePath $filePath
    }
    elseif ($extension -eq ".docx") {
        return Get-WordContentHash -filePath $filePath
    }
    else {
        return Get-FileHash -filePath $filePath
    }
}

# Get all files in orig directory and subdirectories
$origFiles = Get-ChildItem -Path $origDir -Recurse -File
# Create a hashtable to store hashes of original files
$origHashes = @{}

# Calculate hashes for all files in orig
foreach ($file in $origFiles) {
    $hash = Get-ContentHash -filePath $file.FullName
    if ($null -ne $hash) {
        $origHashes[$hash] = $file.FullName
    }
}

# Get all files in new directory and subdirectories
$newFiles = Get-ChildItem -Path $newDir -Recurse -File

# Check for duplicates in new and delete if found in orig
foreach ($file in $newFiles) {
    $hash = Get-ContentHash -filePath $file.FullName
    if ($null -ne $hash -and $origHashes.ContainsKey($hash)) {
        Write-Host "Deleting duplicate: $($file.FullName) (matches $($origHashes[$hash]))"
        Remove-Item -Path $file.FullName -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "Duplicate removal complete."