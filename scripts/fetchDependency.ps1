[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$Dependency
)

$scriptsDir = split-path -parent $script:MyInvocation.MyCommand.Definition
. "$scriptsDir\VcpkgPowershellUtils.ps1"

Write-Verbose "Fetching dependency: $Dependency"
$vcpkgRootDir = vcpkgFindFileRecursivelyUp $scriptsDir .vcpkg-root

$downloadsDir = "$vcpkgRootDir\downloads"

function SelectProgram([Parameter(Mandatory=$true)][string]$Dependency)
{
    # Enums (without resorting to C#) are only available on powershell 5+.
    $ExtractionType_NO_EXTRACTION_REQUIRED = 0
    $ExtractionType_ZIP = 1
    $ExtractionType_SELF_EXTRACTING_7Z = 2

    if($Dependency -eq "cmake")
    {
        $requiredVersion = "3.10.2"
        $downloadVersion = "3.10.2"
        $url = "https://cmake.org/files/v3.10/cmake-3.10.2-win32-x86.zip"
        $downloadPath = "$downloadsDir\cmake-3.10.2-win32-x86.zip"
        $expectedDownloadedFileHash = "f5f7e41a21d0e9b655aca58498b08e17ecd27796bf82837e2c84435359169dd6"
        $executableFromDownload = "$downloadsDir\cmake-3.10.2-win32-x86\bin\cmake.exe"
        $extractionType = $ExtractionType_ZIP
    }
    elseif($Dependency -eq "nuget")
    {
        $requiredVersion = "4.4.0"
        $downloadVersion = "4.4.0"
        $url = "https://dist.nuget.org/win-x86-commandline/v4.4.0/nuget.exe"
        $downloadPath = "$downloadsDir\nuget-$downloadVersion\nuget.exe"
        $expectedDownloadedFileHash = "2cf9b118937eef825464e548f0c44f7f64090047746de295d75ac3dcffa3e1f6"
        $executableFromDownload = $downloadPath
        $extractionType = $ExtractionType_NO_EXTRACTION_REQUIRED
    }
    elseif($Dependency -eq "vswhere")
    {
        $requiredVersion = "2.3.2"
        $downloadVersion = "2.3.2"
        $url = "https://github.com/Microsoft/vswhere/releases/download/2.3.2/vswhere.exe"
        $downloadPath = "$downloadsDir\vswhere-$downloadVersion\vswhere.exe"
        $expectedDownloadedFileHash = "103f2784c4b2c8e70c7c1c03687abbf22bce052aae30639406e4e13ffa29ee04"
        $executableFromDownload = $downloadPath
        $extractionType = $ExtractionType_NO_EXTRACTION_REQUIRED
    }
    elseif($Dependency -eq "git")
    {
        $requiredVersion = "2.16.2"
        $downloadVersion = "2.16.2"
        $url = "https://github.com/git-for-windows/git/releases/download/v2.16.2.windows.1/MinGit-2.16.2-32-bit.zip"
        $downloadPath = "$downloadsDir\MinGit-2.16.2-32-bit.zip"
        $expectedDownloadedFileHash = "322c727e482aa97522c64a5ac68bdda3780111e8670bcfb532beac8e11ece5da"
        # There is another copy of git.exe in MinGit\bin. However, an installed version of git add the cmd dir to the PATH.
        # Therefore, choosing the cmd dir here as well.
        $executableFromDownload = "$downloadsDir\MinGit-2.16.2-32-bit\cmd\git.exe"
        $extractionType = $ExtractionType_ZIP
    }
    elseif($Dependency -eq "installerbase")
    {
        $requiredVersion = "3.1.81"
        $downloadVersion = "3.1.81"
        $url = "https://github.com/podsvirov/installer-framework/releases/download/cr203958-9/QtInstallerFramework-win-x86.zip"
        $downloadPath = "$downloadsDir\QtInstallerFramework-win-x86.zip"
        $expectedDownloadedFileHash = "f2ce23cf5cf9fc7ce409bdca49328e09a070c0026d3c8a04e4dfde7b05b83fe8"
        $executableFromDownload = "$downloadsDir\QtInstallerFramework-win-x86\bin\installerbase.exe"
        $extractionType = $ExtractionType_ZIP
    }
    else
    {
        throw "Unknown program requested"
    }

    if (!(Test-Path $downloadPath))
    {
        Write-Host "Downloading $Dependency..."
        vcpkgDownloadFile $url $downloadPath
        Write-Host "Downloading $Dependency has completed successfully."
    }

    $downloadedFileHash = vcpkgGetSHA256 $downloadPath
    vcpkgCheckEqualFileHash -filePath $downloadPath -expectedHash $expectedDownloadedFileHash -actualHash $downloadedFileHash

    if ($extractionType -eq $ExtractionType_NO_EXTRACTION_REQUIRED)
    {
        # do nothing
    }
    elseif($extractionType -eq $ExtractionType_ZIP)
    {
        if (-not (Test-Path $executableFromDownload))
        {
            $outFilename = (Get-ChildItem $downloadPath).BaseName
            Write-Host "Extracting $Dependency..."
            vcpkgExtractFile -File $downloadPath -DestinationDir $downloadsDir -outFilename $outFilename
            Write-Host "Extracting $Dependency has completed successfully."
        }
    }
    elseif($extractionType -eq $ExtractionType_SELF_EXTRACTING_7Z)
    {
        if (-not (Test-Path $executableFromDownload))
        {
            vcpkgInvokeCommand $downloadPath "-y"
        }
    }
    else
    {
        throw "Invalid extraction type"
    }

    if (-not (Test-Path $executableFromDownload))
    {
        throw ("Could not detect or download " + $Dependency)
    }

    return $executableFromDownload
}

$path = SelectProgram $Dependency
Write-Verbose "Fetching dependency: $Dependency. Done."
return "<sol>::$path::<eol>"
