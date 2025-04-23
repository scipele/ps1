# Mapping of local folders to remote URLs
$repos = @{
    "c:\dev\asm"     = "https://github.com/scipele/asm.git"
    "c:\dev\cpp"     = "https://github.com/scipele/cpp.git"
    "c:\dev\cpp_vs"  = "https://github.com/scipele/cpp_vs.git"
    "c:\dev\ps1"     = "https://github.com/scipele/ps1.git"
    "c:\dev\py"      = "https://github.com/scipele/py.git"
    "c:\dev\vba"     = "https://github.com/scipele/vba.git"
    "c:\dev\sql"     = "https://github.com/scipele/sql_access.git"
}

# Loop through each repository
foreach ($repo in $repos.GetEnumerator()) {
    $localPath = $repo.Key
    $remoteUrl = $repo.Value
    Write-Host "Processing $localPath..."

    # Change to repository directory
    Set-Location -Path $localPath -ErrorAction SilentlyContinue
    if ($? -eq $false) {
        Write-Host "Failed to access $localPath. Skipping."
        continue
    }

    # Verify it's a Git repository
    if (Test-Path -Path ".git") {
        # Backup the repository
        $backupDir = "${localPath}_backup"
        Write-Host "Backing up to $backupDir..."
        Copy-Item -Path $localPath -Destination $backupDir -Recurse -Force

        # Remove .git directory
        Remove-Item -Path ".git" -Recurse -Force

        # Initialize new Git repository
        git init

        # Add all files and commit
        git add .
        git commit -m "Initial commit with latest files"

        # Optional: Clean untracked files
        git clean -fd

        # Optional: Reconnect to remote and force-push
        Write-Host "Reconnecting to $remoteUrl..."
        git remote add origin $remoteUrl
        git push -f origin main

        Write-Host "$localPath cleaned successfully."
    } else {
        Write-Host "$localPath is not a Git repository. Skipping."
    }

    # Return to parent directory
    Set-Location -Path "c:\dev"
}

Write-Host "All repositories processed."