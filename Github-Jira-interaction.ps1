if (2 -ge $host.version.major) { "Get http://chocolatey.org/ and cinst powershell" } else { "Powershell 3 already installed" }

Write-Host "install PsGet if it is not installed"
if(-not(Get-Module -name "Posh-Github")) {
	Write-Host "Posh-Github is not installed so install it" 
	cinst Posh-GitHub
}else{
	Write-Host "PsGet is installed"
}

$UserName=[environment]::GetEnvironmentVariable("github_username","User")
$Password=[environment]::GetEnvironmentVariable("github_password","User")
New-GitHubOAuthToken -Username $UserName -Password $Password
Write-Host $GITHUB_API_OUTPUT

Write-Host "Create new PR"
New-GitHubPullRequest -Title 'Automated PR creation testing' -Body 'More detail' -Base 'dev' -Owner "adazzle" -Repository "mediaAppSln"

$JiraUserName = [environment]::GetEnvironmentVariable("jira_username","User")
$JiraPassword = [environment]::GetEnvironmentVariable("jira_password","User")
$headers = @{Authorization="Basic " + [Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("${JiraUserName}:$JiraPassword"))}
[Uri]$uri = "https://adazzle.atlassian.net/rest/api/2/issue/AD-1763/comment"
$issue = ConvertTo-Json -InputObject @('"body": "This is a comment I want to post."')
 $issue = @{
		body = "This is an automated comment"
	} | ConvertTo-Json
Write-Host $issue
Invoke-RestMethod -Uri $uri -Headers ($headers) -Method Post -Body $issue -ContentType "application/json"