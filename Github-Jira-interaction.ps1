if (2 -ge $host.version.major) { 
	cinst powershell
}else{ 
	"Powershell 3 already installed" 
}

Write-Host "install Posh-Github if it is not installed"
if(-not(Get-Module -name "Posh-Github")) {
	Write-Host "Posh-Github is not installed so install it" 
	cinst Posh-GitHub
}else{
	Write-Host "Posh-Github is installed"
}

$AnswerPRneeded = Read-Host "Confirm - there is no existing PR (y/n)"
while("y","n" -notcontains $AnswerPRneeded)
{
	$AnswerPRneeded = Read-Host "Confirm - there is no existing PR (y/n)"
}

if ($AnswerPRneeded -eq "y") 
{
	$JiraIssue = Read-Host "Specify Jira issue no:(example: AD-1234)"
	if ($JiraIssue)
	{
		$UserName=[environment]::GetEnvironmentVariable("github_username","User")
		$Password=[environment]::GetEnvironmentVariable("github_password","User")
		New-GitHubOAuthToken -Username $UserName -Password $Password
		Write-Host $GITHUB_API_OUTPUT

		Write-Host "Create Pull Request"
		$GITHUB_API_OUTPUT=""
		New-GitHubPullRequest -Title 'Automated PR creation testing' -Body 'More detail' -Base 'dev' -Owner "adazzle" -Repository "mediaAppSln"	
		
		#Get-GitHubPullRequests -Owner "adazzle" -Repository "mediaAppSln" -State open
		if($GITHUB_API_OUTPUT)
		{
			$JiraUserName = [environment]::GetEnvironmentVariable("jira_username","User")
			$JiraPassword = [environment]::GetEnvironmentVariable("jira_password","User")
			$headers = @{Authorization="Basic " + [Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("${JiraUserName}:$JiraPassword"))}
			$html_url = "PR:" + ($GITHUB_API_OUTPUT | Select -ExpandProperty html_url)
			$commits_url = "Commits:" + ($GITHUB_API_OUTPUT | Select -ExpandProperty commits_url)
			[Uri]$uri = "https://adazzle.atlassian.net/rest/api/2/issue/$JiraIssue/comment"
			 $issue = @{
					body = "$html_url $commits_url"
				} | ConvertTo-Json
			#Write-Host $issue
			Invoke-RestMethod -Uri $uri -Headers ($headers) -Method Post -Body $issue -ContentType "application/json"
		}
	}else{
		Write-Host "With no Jira issue provided to create link between PR and Jira issue, this helper is not very useful so Please create PR in Github"
	}
}