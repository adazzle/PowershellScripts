function Install-Prerequisite()
{
	if (2 -ge $host.version.major) { 
		cinst powershell
	}else{ 
		"Powershell 3 already installed" 
	}

	if(-not(Get-Module -name "Posh-Github")) {
		Write-Host "Posh-Github is not installed so install it" 
		cinst Posh-GitHub
	}else{
		Write-Host "Posh-Github is installed"
	}
  return $null
}

# Install powershell 3 and Posh-Github if not already installed
Install-Prerequisite

$AnswerPRneeded = Read-Host "Confirm - there is no existing PR (y/n)"
while("y","n" -notcontains $AnswerPRneeded)
{
	$AnswerPRneeded = Read-Host "Confirm - there is no existing PR (y/n)"
}

if ($AnswerPRneeded -eq "y") 
{
	$JiraIssue = Read-Host "Specify Jira issue no(example: AD-1234)"
	if ($JiraIssue)
	{
		$JiraBaseUrl = "https://adazzle.atlassian.net"
		$JiraUserName = [environment]::GetEnvironmentVariable("jira_username","User")
		$JiraPassword = [environment]::GetEnvironmentVariable("jira_password","User")
		$headers = @{Authorization="Basic " + [Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("${JiraUserName}:$JiraPassword"))}
		
		[Uri]$uri = "$JiraBaseUrl/rest/api/2/issue/$JiraIssue/"
		#Write-Host $issue
		try{
			$result=Invoke-RestMethod -Uri $uri -Headers ($headers) -ContentType "application/json"
		}catch{}

		if($result){
			#Write-Host "Get title for PR"
			$summary = ($result | Select -ExpandProperty fields) | Select -ExpandProperty summary
			#Write-Host "$summary"

			$UserName=[environment]::GetEnvironmentVariable("github_username","User")
			$Password=[environment]::GetEnvironmentVariable("github_password","User")
			New-GitHubOAuthToken -Username $UserName -Password $Password
			New-GitHubPullRequest -Title "[$JiraIssue] - $summary" -Body "$JiraBaseUrl/browse/$JiraIssue" -Base 'dev' -Owner "adazzle" -Repository "mediaAppSln"	
			
			$html_url = "PR:" + ($GITHUB_API_OUTPUT | Select -ExpandProperty html_url)
			$commits_url = "Commits:" + ($GITHUB_API_OUTPUT | Select -ExpandProperty commits_url)
			[Uri]$uri = "$JiraBaseUrl/rest/api/2/issue/$JiraIssue/comment"
			 $issue = @{
					body = "$html_url $commits_url"
				} | ConvertTo-Json
			#Write-Host $issue
			$result=Invoke-RestMethod -Uri $uri -Headers ($headers) -Method Post -Body $issue -ContentType "application/json"
			Write-Host "PR link created in Jira issue"
		}else{
		Write-Host "This is not a valid Jira issue"
		}
	}else{
		Write-Host "With no Jira issue provided, this helper is useless so Please create PR in Github"
	}
}