function Install-Prerequisite()
{
	if (2 -ge $host.version.major) { 
		cinst powershell
	}else{ 
		"Powershell 3 already installed" 
	}

	if($(Get-Module -ListAvailable | Where-Object { $_.name -eq "Posh-Github" }))
	{
		Write-Host "Posh-Github is installed" 
	}else{
		Write-Host "Posh-Github is not installed so install it" 
		cinst Posh-GitHub
	}
  return $null
}

function Initialize-JiraGithubCredentials()
{
	Param([string]$envariable,
		  [string]$message)
	
	$envvalue = [environment]::GetEnvironmentVariable($envariable,"User")
	if(!$envvalue)
	{
		$envvalue = Read-Host "Please provide $message "
		[Environment]::SetEnvironmentVariable($envariable, $envvalue, "User")
	}
	return $envvalue
}

# Install powershell 3 and Posh-Github if not already installed
Install-Prerequisite
# Git\Set Github and Jira username\passwords
$JiraUserName = Initialize-JiraGithubCredentials -envariable "jira_username" -message "Jira username"
$JiraPassword = Initialize-JiraGithubCredentials -envariable "jira_password" -message "Jira password"
$UserName = Initialize-JiraGithubCredentials -envariable "github_username" -message "Github username"
$Password = Initialize-JiraGithubCredentials -envariable "github_password" -message "Github password"

$JiraBaseUrl = "https://adazzle.atlassian.net"

$AnswerPRneeded = Read-Host "Do you have any existing PR to dev for this branch?(y/n)"
while("y","n" -notcontains $AnswerPRneeded)
{
	$AnswerPRneeded = Read-Host "Do you have any existing PR to dev for this branch?(y/n)"
}

if ($AnswerPRneeded -eq "n") 
{
	$JiraIssue = Read-Host "Specify Jira issue no(example: AD-1234)"
	if ($JiraIssue)
	{
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
		Write-Host "With no Jira issue provided, this git helper is useless so Please create PR in Github."
	}
}else{
	Write-Host "This git helper cannot create another PR."
}