######## It does following tasks: ######## 

# Download git helpers as zip file

# Extract git helpers to a temp folder

# Find destination directory of git helpers through git --exec-path

# Copy git helpers to destination directory

# variables
$url = "https://github.com/adazzle/PowershellScripts/blob/b95531ec6bd4b5bbf40483ee52e2b1a926a091ae/"
$githelpersTempDir = Join-Path $env:TEMP "githelpers"
$tempDir = Join-Path $githelpersTempDir "githelpersInstall"
if (![System.IO.Directory]::Exists($tempDir)) {[System.IO.Directory]::CreateDirectory($tempDir)}
$file = Join-Path $tempDir "git-create-pr.zip"

function Download-File {
param (
  [string]$url,
  [string]$file
 )
  Write-Host "Downloading $url to $file"
  $downloader = new-object System.Net.WebClient
  $downloader.DownloadFile($url, $file)
}

# download the package
Download-File 'https://github.com/adazzle/PowershellScripts/blob/b95531ec6bd4b5bbf40483ee52e2b1a926a091ae/git-create-pr.zip?raw=true' $file

# download 7zip
Write-Host "Download 7Zip commandline tool"
$7zaExe = Join-Path $tempDir '7za.exe'
Download-File 'https://github.com/chocolatey/chocolatey/blob/master/src/tools/7za.exe?raw=true' "$7zaExe"

# unzip the package
Write-Host "Extracting $file to $tempDir..."
$tempDir = Join-Path $tempDir "unzipped"
if (![System.IO.Directory]::Exists($tempDir)) {[System.IO.Directory]::CreateDirectory($tempDir)}
Start-Process "$7zaExe" -ArgumentList "x -o`"$tempDir`" -y `"$file`"" -Wait

#Get destination folder
$destination = git --exec-path
$tempDir  = Join-Path $tempDir "\*"
Write-Host "Copying 'git create-pr helper' to $destination"
Copy-Item -Force -Path $tempDir -Destination $destination
