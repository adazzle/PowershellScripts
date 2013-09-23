#Requires -Version 3.0

function New_GitHubBranchFromLabel {
[CmdletBinding()]
param(
[Parameter(Mandatory = $true)]
[string]
$UserName,

[Parameter(Mandatory = $true)]
[string]
$Password,


[Parameter(Mandatory = $true)]
[string]
$TempBranchName,

[Parameter(Mandatory = $true)]
[string]
$RepoOwner,

[Parameter(Mandatory = $true)]
[string]
$Repo,


[Parameter(Mandatory = $false)]
[string]
$Labels = "Ready",


[Parameter(Mandatory = $false)]
[switch]
$ForceTempBranch = $true,

[Parameter(Mandatory = $false)]
[switch]
$PushToGitHub = $false,

[Parameter(Mandatory = $false)]
[switch]
$InstallPreReqs = $true,

[Parameter(Mandatory = $false)]
[string]
$BaseBranch = "dev"
)
if($InstallPreReqs) {
Write-Host "Installing pre requisites "
if(-not(Get-Module Posh-GitHub)) {
    cinst Posh-GitHub
}
}

Write-Host "Setup github access"
New-GitHubOAuthToken -Username $UserName -Password $Password


  Write-Host "All Done"
}

Export-ModuleMember -Function  New-GithubBranchFromLabel
