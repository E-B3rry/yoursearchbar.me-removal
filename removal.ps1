# Ensure admin privileges or self-elevate
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
        Write-Host "The script will ask for admin privileges. Do you want to continue? [Y/N]" -ForegroundColor Green
        if ((Read-Host).ToUpper() -ne "Y") {
            Write-Host "Aborting..." -ForegroundColor Red
            exit
        }
        $CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
        Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
        Exit
    }
}

# Start a transcript to log the script output
Stop-Transcript -ErrorAction SilentlyContinue | Out-Null
Start-Transcript -Path "removal.log" -Append -Force -ErrorAction SilentlyContinue

Clear-Host
Write-Host "======================================="  -ForegroundColor Magenta
Write-Host "= Removal script for yoursearchbar.me ="  -ForegroundColor Magenta
Write-Host "======================================="  -ForegroundColor Magenta

# Ask for user confirmation before continuing
Write-Host "This script will attempt to remove yoursearchbar.me extension malware from your computer."
Write-Host "The script should work with the extension version 9.8, and it may take a while to complete."
Write-Host "Chrome and Edge will be closed now - please save your work before proceeding."
Write-Host "WARNING: Microsoft Edge might not work properly after running this script."  -ForegroundColor Yellow
Write-Host "Do you want to continue? [Y/N]"  -ForegroundColor Green
if ((Read-Host).ToUpper() -ne "Y") {
    Write-Host "Aborting..."  -ForegroundColor Red
    exit
}

# Verify that the three .dll files are present and verify their integrity with SHA256 checksums
Write-Host "`nVerifying integrity of required files..."
$fileChecksums = @{
    "generic-core-msedge.dll" = "34f4a2f2291be56203db3831620750f34a37af1f168bd337f292be8bd6bbb438"
    "generic-msedge.dll" = "34f4a2f2291be56203db3831620750f34a37af1f168bd337f292be8bd6bbb438"
    "generic-webview-msedge.dll" = "cd156e02e75c9f465bb4b94f0ea21cc736c6439a1691297cbd378084f7187c54"
}
$userAgreeDownload = $false

# Iterate over each file in the hashtable
foreach ($file in $fileChecksums.Keys) {
    $filePath = Join-Path -Path (Get-Location) -ChildPath $file
    $expectedChecksum = $fileChecksums[$file]
    $fileExists = Test-Path $filePath
    $checksumMatch = $false

    # If the file exists, verify its checksum
    if ($fileExists) {
        $actualChecksum = Get-FileHash -Path $filePath -Algorithm SHA256 | Select-Object -ExpandProperty Hash
        $checksumMatch = $actualChecksum -eq $expectedChecksum
    }

    # If the file does not exist or the checksum does not match, download the file from GitHub
    if (-Not $fileExists -or -Not $checksumMatch) {
        if (-Not $userAgreeDownload) {
            Write-Host @'
WARNING: At least one of the required .dll files is missing or has an invalid checksum.
This is probably because you downloaded the script following the simple solution
explained on the GitHub page, however because of limitations of GitHub with large files,
they are not properly included with the archive you downloaded.
Downloading them may take a while depending on your internet connection (all the 3 files ~= 1gb).
Do you allow the script to download the missing or corrupted file(s) itself? [Y/N]
'@  -ForegroundColor Yellow
            if ((Read-Host).ToUpper() -ne "Y") {
                Write-Host "Aborting..."  -ForegroundColor Red
                exit
            }
            $userAgreeDownload = $true
        }

        if (-Not $fileExists) {
            Write-Host "- File $file is missing and will be downloaded."  -ForegroundColor Yellow
        } elseif (-Not $checksumMatch) {
            Write-Host "- File $file has an invalid checksum and will be re-downloaded."  -ForegroundColor Yellow
        }

        $url = "https://github.com/E-B3rry/yoursearchbar.me-removal/raw/master/$file"
        try {
            Invoke-WebRequest -Uri $url -OutFile $filePath

            # Verify the downloaded file's checksum
            $actualChecksum = Get-FileHash -Path $filePath -Algorithm SHA256 | Select-Object -ExpandProperty Hash
            if ($actualChecksum -eq $expectedChecksum) {
                Write-Host "File $file downloaded and verified successfully."  -ForegroundColor Green
            } else {
                Write-Host "[!] Fatal Error: File $file could not be verified after download. Checksum does not match.`nAborting..."  -ForegroundColor Red
                exit
            }
        } catch {
            Write-Host "[!] Fatal Error: File $file could not be downloaded: $_`nAborting..."  -ForegroundColor Red
            exit
        }
    }
}
Write-Host "All required files are present and verified."  -ForegroundColor Green

# Kill all chrome.exe and msedge.exe processes
Write-Host "`nKilling Chrome and Edge processes..."
taskkill /IM chrome.exe /F 1>$null 2>&1
taskkill /IM msedge.exe /F 1>$null 2>&1
taskkill /IM msteams.exe /F 1>$null 2>&1
taskkill /IM msedgewebview2.exe 1>$null 2>&1

# Search for .ps1 scripts containing "nvoptimize.com" in the Windows folder
Write-Host "`nSearching for infected scripts..."
$infectedScripts = Get-ChildItem -Path "C:\Windows" -Filter *.ps1 -Recurse -Force -ErrorAction SilentlyContinue | Select-String -Pattern "nvoptimize.com" | Select-Object -ExpandProperty Path

# If infected scripts are found, ask for user confirmation before removing them
if ($infectedScripts.Count -gt 0) {
    Write-Host "The following files are potentially infected:"
    $infectedScripts | ForEach-Object { Write-Host $_ }

    Write-Host "`nDo you want to remove them? [Y/N]"  -ForegroundColor WARNING

    if ((Read-Host).ToUpper() -ne "Y") {
        Write-Host "Aborting..."  -ForegroundColor Red
        exit
    }

    # Remove all the infected scripts
    $infectedScripts | ForEach-Object { Remove-Item $_ }
    Write-Host "Infected scripts removed."  -ForegroundColor Green
} else {
    Write-Host "No infected scripts found."  -ForegroundColor Green
}

# Remove the registry keys
Write-Host "`nRemoving registry keys..."
$chromeRegPath = "HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist"
$edgeRegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist"

if (Test-Path $chromeRegPath) {
    Remove-Item $chromeRegPath -Force
}

if (Test-Path $edgeRegPath) {
    Remove-Item $edgeRegPath -Force
}
Write-Host "Forced extensions registry keys removed for both Chrome and Edge."

# Search for shortcuts pointing to chrome.exe and msedge.exe and remove malicious arguments
Write-Host "`nSearching for infected shortcuts on your entire C: drive... (this may take a while)"
$shortcuts = Get-ChildItem -Path "C:\" -Include *.lnk -Recurse -Force -ErrorAction SilentlyContinue
$shell = New-Object -ComObject WScript.Shell

Write-Host "Removing potential malicious arguments on shortcuts:"
foreach ($shortcut in $shortcuts) {
    $lnk = $shell.CreateShortcut($shortcut.FullName)
    if ($lnk.TargetPath -match "chrome.exe" -or $lnk.TargetPath -match "msedge.exe") {
        $lnk.Arguments = ""
        $lnk.Save()
        Write-Host "- Fixed shortcut $shortcut"
    }
}
Write-Host "Done."

# Deletes the content of the extension folder if it exists
$internalKernelGrid4Path = "C:\Windows\InternalKernelGrid4"
if (Test-Path $internalKernelGrid4Path) {
    Write-Host "`nFound malicious folder '$internalKernelGrid4Path'!"  -ForegroundColor Yellow
    Remove-Item -Path "$internalKernelGrid4Path\*" -Recurse -Force
    Remove-Item -Path $internalKernelGrid4Path -Force
    Write-Host "Folder '$internalKernelGrid4Path' has been deleted."  -ForegroundColor Green
}

# Deletes the extension folder if it exists from local app data
$chromeExtensionsPath = Join-Path -Path $env:LOCALAPPDATA -ChildPath "Google\Chrome\User Data\Default\Extensions"
$extensionID = "dafkaabahcikblhbogbnbjodajmhbini"

# Full path to the extension folder
$extensionFolderPath = Join-Path -Path $chromeExtensionsPath -ChildPath $extensionID

# Check if the extension folder exists and delete it
if (Test-Path -Path $extensionFolderPath) {
    Write-Host "`nFound malicious extension folder '$extensionID' in '$chromeExtensionsPath'!"  -ForegroundColor Yellow
    Remove-Item -Path $extensionFolderPath -Recurse -Force
    Write-Host "Extension folder '$extensionID' has been deleted from '$chromeExtensionsPath'"  -ForegroundColor Green
}

# Deletes the corrupted msedge.dll files
Write-Host "`nSearching for msedge.dll files..."
$corruptedDlls = Get-ChildItem -Path "C:\Program Files (x86)\Microsoft\" -Recurse -Force -ErrorAction SilentlyContinue | Where-Object {
    $_.Name -eq "msedge.dll"
}

if ($corruptedDlls.Count -eq 0)
{
    $corruptedDlls = Get-ChildItem -Path "C:\" -Recurse -Force -ErrorAction SilentlyContinue | Where-Object {
        $_.Name -eq "msedge.dll"
    } | Select-Object Fullname
}

if ($corruptedDlls.Count -gt 0)
{
    # Ask for user confirmation with all the found paths
    Write-Host "The following files are potentially corrupted:"  -ForegroundColor Yellow
    $corruptedDlls | ForEach-Object { Write-Host $_.Fullname  -ForegroundColor Yellow}

    Write-Host "`nDo you want to try replacing them with a non corrupted DLL? This could break Microsoft Edge but it is required to remove the malware. [Y/N]"  -ForegroundColor Yellow
    if ((Read-Host).ToUpper() -ne "Y") {
        Write-Host "Aborting..."  -ForegroundColor Red
        exit
    }

    # Replace the corrupted DLLs with a non corrupted one
    Write-Host "`nReplacing corrupted DLLs:"
    foreach ($f in $corruptedDlls){
        Remove-Item -Path $f.Fullname -Force -ErrorAction SilentlyContinue
        # After removing the file, copy the most appropriate DLL (kind of a hack but it "works")
        if ($f.Fullname -match "^C:\\Program Files \(x86\)\\Microsoft\\EdgeCore\\") {
            Copy-Item -Path "generic-core-msedge.dll" -Destination $f.Fullname -Force -ErrorAction SilentlyContinue
        } elseif ($f.Fullname -match "^C:\\Program Files \(x86\)\\Microsoft\\EdgeWebView\\") {
            Copy-Item -Path "generic-webview-msedge.dll" -Destination $f.Fullname -Force -ErrorAction SilentlyContinue
        } else {
            Copy-Item -Path "generic-msedge.dll" -Destination $f.Fullname -Force -ErrorAction SilentlyContinue
        }
        Write-Host "- Replaced $($f.Fullname) with a non corrupted DLL."
    }
    Write-Host "Done."  -ForegroundColor Green
} else {
    Write-Host "No msedge.dll files found."
}

Write-Host "`nThe yoursearchbar.me extension should be removed now. Please restart your computer."
Write-Host "If Microsoft Edge doesn't work properly anymore, please try to repair it: https://support.microsoft.com/en-us/microsoft-edge/what-to-do-if-microsoft-edge-isn-t-working-cc0657a6-acd2-cbbd-1528-c0335c71312a"
Stop-Transcript
Read-Host
