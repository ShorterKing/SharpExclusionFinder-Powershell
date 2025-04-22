# Enhanced Windows Defender Exclusion Scanner
# PowerShell Implementation

# Display menu and get scan type
function Show-Menu {
    Clear-Host
    Write-Host "Windows Defender Exclusion Scanner" -ForegroundColor Yellow
    Write-Host "==================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Select scanning option:" -ForegroundColor White
    Write-Host "1. Scan entire PC (all drives)" -ForegroundColor Cyan
    Write-Host "2. Scan specific folder" -ForegroundColor Cyan
    Write-Host "Q. Quit" -ForegroundColor Red
    Write-Host ""
    
    $choice = Read-Host "Enter your choice (1, 2, or Q)"
    return $choice
}

# Check if a folder is excluded by Windows Defender
function Test-FolderExclusion {
    param (
        [string]$FolderPath
    )
    
    try {
        # Run MpCmdRun to check if folder is excluded
        $command = "& '$env:ProgramFiles\Windows Defender\MpCmdRun.exe' -Scan -ScanType 3 -File `"$FolderPath\|*`""
        $output = Invoke-Expression $command 2>&1
        
        # Check if folder was skipped (indicating it's excluded)
        if ($output -match "was skipped") {
            return $true
        } else {
            return $false
        }
    }
    catch {
        if ($verboseLevel -gt 0) {
            Write-Host "Error checking $FolderPath`: $_" -ForegroundColor Red
        }
        return $false
    }
}

# Get all subfolders from a directory
function Get-AllSubfolders {
    param (
        [string]$Path
    )
    
    $folders = New-Object System.Collections.ArrayList
    $null = $folders.Add($Path)
    
    try {
        # First try with native Get-ChildItem for better reliability
        Write-Host "Finding all subfolders... (this may take some time)" -ForegroundColor Cyan
        
        # Use -Directory switch to only get directories
        $subfolders = Get-ChildItem -Path $Path -Directory -Recurse -ErrorAction SilentlyContinue | 
                  Select-Object -ExpandProperty FullName
        
        foreach ($subfolder in $subfolders) {
            $null = $folders.Add($subfolder)
        }
    }
    catch {
        Write-Host "Error finding subfolders: $_" -ForegroundColor Red
    }
    
    return $folders
}

# Scan a folder and its subfolders
function Scan-Folder {
    param (
        [string]$FolderPath,
        [string]$OutputFile,
        [int]$VerboseLevel,
        [bool]$StopOnFirst,
        [bool]$IncludeSubfolders
    )
    
    Write-Host "Starting scan of: $FolderPath" -ForegroundColor Yellow
    
    # Start timing
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    # Initialize counters
    $excludedFolders = @()
    
    # Get directories to scan
    $allFolders = New-Object System.Collections.ArrayList
    $null = $allFolders.Add($FolderPath)
    
    if ($IncludeSubfolders) {
        $allFolders = Get-AllSubfolders -Path $FolderPath
    }
    
    $totalFolders = $allFolders.Count
    if ($IncludeSubfolders) {
        Write-Host "Found $totalFolders folders to scan (including subfolders)." -ForegroundColor Cyan
    } else {
        Write-Host "Scanning 1 folder (subfolders excluded)." -ForegroundColor Cyan
    }
    
    # Process each folder
    $currentFolder = 0
    foreach ($folder in $allFolders) {
        $currentFolder++
        
        # Show progress based on verbosity
        if ($VerboseLevel -ge 2 -or ($currentFolder % 50 -eq 0 -or $currentFolder -eq 1)) {
            $percentComplete = [math]::Round(($currentFolder / $totalFolders) * 100, 1)
            Write-Progress -Activity "Scanning Folders" -Status "$percentComplete% Complete" -PercentComplete $percentComplete -CurrentOperation "Checking: $folder"
            
            if ($VerboseLevel -ge 2) {
                Write-Host "Scanning folder $currentFolder of $totalFolders - $folder" -ForegroundColor White
            }
        }
        
        # Check if folder is excluded
        if (Test-FolderExclusion -FolderPath $folder) {
            if ($VerboseLevel -ge 1) {
                Write-Host "[+] Folder $folder is excluded" -ForegroundColor Green
            }
            $excludedFolders += $folder
            
            # Log to file if output file specified
            if ($OutputFile) {
                "[+] Folder $folder is excluded" | Out-File -FilePath $OutputFile -Append
            }
            
            # Stop if requested and found at least one exclusion
            if ($StopOnFirst) {
                Write-Host "`nFound excluded folder. Stopping scan as requested." -ForegroundColor Yellow
                break
            }
        }
    }
    
    # Stop timing
    $stopwatch.Stop()
    $elapsed = $stopwatch.Elapsed.TotalSeconds.ToString("F2")
    
    # Clear progress bar
    Write-Progress -Activity "Scanning Folders" -Completed
    
    # Display results
    Write-Host "`nScan Complete!" -ForegroundColor Green
    Write-Host "==================" -ForegroundColor Green
    Write-Host "Found $($excludedFolders.Count) excluded directories out of $totalFolders total." -ForegroundColor Yellow
    Write-Host "Total scan time: $elapsed seconds" -ForegroundColor Yellow
    
    # Display excluded directories
    if ($excludedFolders.Count -gt 0) {
        Write-Host "`nExcluded Directories:" -ForegroundColor Cyan
        foreach ($dir in $excludedFolders) {
            Write-Host " - $dir" -ForegroundColor White
        }
    }
}

# Scan all drives
function Scan-AllDrives {
    param (
        [string]$OutputFile,
        [int]$VerboseLevel,
        [bool]$StopOnFirst
    )
    
    # Get all drives
    $drives = Get-PSDrive -PSProvider FileSystem | Select-Object -ExpandProperty Root
    Write-Host "Found drives: $($drives -join ', ')" -ForegroundColor Cyan
    
    # Scan each drive
    foreach ($drive in $drives) {
        # For full drive scans, we always include subfolders
        Scan-Folder -FolderPath $drive -OutputFile $OutputFile -VerboseLevel $VerboseLevel -StopOnFirst $StopOnFirst -IncludeSubfolders $true
        
        # If we're stopping on first and already found one
        if ($StopOnFirst -and $OutputFile -and (Test-Path -Path $OutputFile) -and ((Get-Content -Path $OutputFile -ErrorAction SilentlyContinue).Count -gt 0)) {
            break
        }
    }
}

# Main script execution
$choice = Show-Menu

if ($choice -in "1", "2") {
    # Get verbosity level
    Write-Host "`nVerbosity Levels:" -ForegroundColor Yellow
    Write-Host "0 - Show only summary and excluded folders at the end" -ForegroundColor Cyan
    Write-Host "1 - Show excluded folders as they are found" -ForegroundColor Cyan
    Write-Host "2 - Show all scanning activity in real-time" -ForegroundColor Cyan
    
    $verboseLevel = Read-Host "Enter verbosity level (0-2, default: 1)"
    if (-not $verboseLevel -or $verboseLevel -eq "") {
        $verboseLevel = 1
    }
    else {
        try {
            $verboseLevel = [int]$verboseLevel
            if ($verboseLevel -lt 0 -or $verboseLevel -gt 2) {
                Write-Host "Invalid verbosity level. Using default (1)." -ForegroundColor Yellow
                $verboseLevel = 1
            }
        }
        catch {
            Write-Host "Invalid verbosity level. Using default (1)." -ForegroundColor Yellow
            $verboseLevel = 1
        }
    }
    
    # Ask if should stop on first exclusion found
    $stopOnFirstResponse = Read-Host "Stop scanning when first excluded folder is found? (Y/N, default: N)"
    $stopOnFirst = $stopOnFirstResponse -eq "Y" -or $stopOnFirstResponse -eq "y"
}

switch ($choice) {
    "1" {
        # Scan all drives
        $outputFile = Read-Host "Enter output file path (leave blank for no output file)"
        Scan-AllDrives -OutputFile $outputFile -VerboseLevel $verboseLevel -StopOnFirst $stopOnFirst
    }
    "2" {
        # Scan specific folder
        $folderPath = Read-Host "Enter the folder path to scan"
        
        if (-not (Test-Path -Path $folderPath -PathType Container)) {
            Write-Host "Invalid folder path. Please try again." -ForegroundColor Red
            break
        }
        
        # Ask if subfolders should be included
        $includeSubfoldersResponse = Read-Host "Include subfolders in scan? (Y/N, default: Y)"
        $includeSubfolders = $includeSubfoldersResponse -ne "N" -and $includeSubfoldersResponse -ne "n"
        
        $outputFile = Read-Host "Enter output file path (leave blank for no output file)"
        Scan-Folder -FolderPath $folderPath -OutputFile $outputFile -VerboseLevel $verboseLevel -StopOnFirst $stopOnFirst -IncludeSubfolders $includeSubfolders
    }
    "Q" {
        Write-Host "Exiting..."
        return
    }
    default {
        Write-Host "Invalid choice. Please try again." -ForegroundColor Red
    }
}

Write-Host "`nPress any key to exit..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
