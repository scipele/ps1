# | Item	     | Powershell Script Documentation Notes                       |
# |--------------|-------------------------------------------------------------|
# | Filename     | list.ps1                                                    |
# | Purpose      | create an html listing of files in a picked path            |
# | Inputs       | path location pick                                          |
# | Outputs      | FileList.html                                               |
# | Dependencies | none                                                        |
# | By Name,Date | T.Sciple, 4/20/2025 (grok3), inspired by d. landry bowling  |


# Add .NET Windows Forms for folder picker dialog
Add-Type -AssemblyName System.Windows.Forms

# Create folder picker dialog
$folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
$folderDialog.Description = "Select the folder to list files from"
$folderDialog.ShowNewFolderButton = $false

# Show dialog and get selected path
if ($folderDialog.ShowDialog() -eq "OK") {
    $selectedDir = $folderDialog.SelectedPath
} else {
    Write-Host "No folder selected. Exiting."
    exit
}

# Define output file in the selected directory
$outputFile = Join-Path -Path $selectedDir -ChildPath "FileList.html"

# HTML header with dark mode styling
$htmlHeader = @"
<!DOCTYPE html>
<html lang='en'>
<head>
    <meta charset='UTF-8'>
    <title>File List - $selectedDir</title>
    <style>
        body { 
            font-family: Arial, sans-serif; 
            margin: 20px; 
            background-color: #1e1e1e; 
            color: #e0e0e0; 
        }
        table { 
            border-collapse: collapse; 
            width: 100%; 
        }
        th, td { 
            border: 1px solid #444; 
            padding: 8px; 
            text-align: left; 
        }
        th { 
            background-color: #2d2d2d; 
            color: #ffffff; 
        }
        .parent-path { 
            color: #a0a0a0; 
        }
        .indent { 
            padding-left: 20px; 
        }
        a { 
            color: #4da8ff; 
            text-decoration: none; 
        }
        a:hover { 
            text-decoration: underline; 
        }
        .sequence-no { 
            width: 80px; 
            text-align: center; 
        }
        .open-folder { 
            width: 120px; 
            text-align: center; 
        }
    </style>
</head>
<body>
<h2>File List - $selectedDir</h2>
<table>
    <tr>
        <th>Seq No</th>
        <th>Parent Path</th>
        <th>Open Folder</th>
        <th>File Name</th>
        <th>Last Save Date</th>
    </tr>
"@

# Get all files recursively and create HTML rows with sequence numbers and folder links
$sequenceNo = 0
$htmlRows = Get-ChildItem -Path $selectedDir -Recurse -File | ForEach-Object {
    $sequenceNo++
    $file = $_
    $relativePath = $file.FullName.Substring($selectedDir.Length + 1)
    $parentPath = Split-Path -Path $relativePath -Parent
    $fileName = $file.Name
    $fileLink = $file.FullName -replace '\\', '/'
    $lastSaveDate = $file.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
    $parentFolder = Split-Path -Path $file.FullName -Parent
    $parentFolderLink = "file://localhost/$($parentFolder -replace '\\', '/')"
    
    # Calculate indentation based on directory depth
    $indentLevel = ($parentPath -split '\\').Count
    $indentStyle = if ($parentPath) { "style='padding-left: $($indentLevel * 20)px;'" } else { "" }
    
    # Create table row with target="_blank" for hyperlinks
    @"
    <tr>
        <td class='sequence-no'>$sequenceNo</td>
        <td class='parent-path' $indentStyle>$parentPath</td>
        <td class='open-folder'><a href='$parentFolderLink' target='_blank'>Open Folder</a></td>
        <td><a href='file:///$fileLink' target='_blank'>$fileName</a></td>
        <td>$lastSaveDate</td>
    </tr>
"@
}

# Combine HTML parts
$htmlFooter = @"
</table>
</body>
</html>
"@
$htmlContent = $htmlHeader + ($htmlRows -join "`n") + $htmlFooter

# Write to output file
$htmlContent | Out-File -FilePath $outputFile -Encoding UTF8

# Open the HTML file in the default browser
Start-Process $outputFile