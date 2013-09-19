function Invoke_GitHubBuildFromLabel {
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
Write-Host "do install? $InstallPreReqs "

   if(-not(Get-Module -name "PsGet")) {
        Write-Host "PsGet is not installed so install it" 
        (new-object Net.WebClient).DownloadString("http://psget.net/GetPsGet.ps1") | iex 
    }else{
        Write-Host "PsGet is installed"
    }
    Install-Module -ModuleUrl "https://raw.github.com/Iristyle/Posh-GitHub/master/Posh-Github.psm1"

}

Write-Host "Setup github access"
New-GitHubOAuthToken -Username $UserName -Password $Password

Write-Host "Getting issues for $Labels"
Get-GitHubIssues -Owner $RepoOwner -Repository $Repo -Labels $Labels
$issues = $GITHUB_API_OUTPUT
if(!$?) {
Write-Host "Getting Labels Failed"
exit
}
#having to use user:password form in origin to get round password prompts
#must be a better way..
git config remote.origin.url https://$UserName":"$Password@github.com/$RepoOwner/$Repo.git

git checkout $BaseBranch
git pull
if($ForceTempBranch) {
   Write-Host "deleting temp branch"
   git branch -D $TempBranchName
}
Write-Host "Creating temp branch"
git checkout -b $TempBranchName

Write-Host "Looping issues"

foreach ($issue in $issues) {
$issueNumber = $issue.number
$remoteBranch = "refs/pull/" + $issueNumber + "/merge"
$branchName = "pr-$issueNumber"
write-host "Merging " $remoteBranch " as " $branchName
git fetch origin $remoteBranch":"$branchName

#TODO check if fetch was ok (fails if have that branch name)
git merge $branchName --quiet
#check all ok
if(git status --porcelain) {
write-host "Merge conflicts on $remoteBranch - aborting "
write-host "Either remove the $Labels label from $remoteBranch " $issue.title
write-host "OR resolve the cause of the conflict on $remoteBranch, push the changes and then rerun"
$issue.url | clip
Write-host "The link to the GitHub issue is now in your clipboard"
exit 1
}
else {
write-host "Merge was ok"
}
}

if($PushToGitHub) {

Write-Host "Push to GitHub"
git push --force --set-upstream origin $TempBranchName

}
else {

Write-Host "Done, but not pushed"

}

Write-Host "All Done"
}



Export-ModuleMember -Function Invoke_GitHubBuildFromLabel
