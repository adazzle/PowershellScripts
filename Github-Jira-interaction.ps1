if (2 -ge $host.version.major) { "Get http://chocolatey.org/ and cinst powershell" } else { "Powershell 3 already installed" }

Write-Host "install PsGet if it is not installed"
if(-not(Get-Module -name "PsGet")) {
	Write-Host "PsGet is not installed so install it" 
	(new-object Net.WebClient).DownloadString("http://psget.net/GetPsGet.ps1") | iex 
}else{
	Write-Host "PsGet is installed"
}

Write-Host "Install Posh-Github module"
Install-Module -ModuleUrl "https://raw.github.com/Iristyle/Posh-GitHub/master/Posh-Github.psm1"


$UserName=[environment]::GetEnvironmentVariable("github_username","User")
$Password=[environment]::GetEnvironmentVariable("github_password","User")

New-GitHubOAuthToken -Username $UserName -Password $Password
Write-Host $GITHUB_API_OUTPUT

Write-Host "Create new PR"
New-GitHubPullRequest -Title 'Automated PR creation testing' -Body 'More detail' -Base 'dev' -Owner "adazzle" -Repository "mediaAppSln"



