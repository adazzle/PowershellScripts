$ErrorActionPreference = 'SilentlyContinue'

function Install-Prerequisite()
{
	if (2 -ge $host.version.major) { 
		cinst powershell
	}else{ 
		"Powershell 3 is already installed" 
	}

	if($(Get-Module -ListAvailable | Where-Object { $_.name -eq "Posh-Github" }))
	{
		Write-Host "Posh-Github is already installed" 
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

#insufficient Posh-Github function Get-GitHubPullRequests so have to create our own
function Find-ExistingPullRequest()
{
	Param([string]$Base,
		  [string]$Owner,
		  [string]$Repository,
		  [string]$State)
		  
	$totalCount = 0
	
	#get head
	$localUser = git remote -v show |
      ? { $_ -match 'origin\t.*github.com\/(.*)\/.* \((fetch|push)\)' } |
      % { $matches[1] } |
      Select -First 1

    $branchName = git symbolic-ref -q HEAD |
      % { $_ -replace 'refs/heads/', ''}

    $Head = "$($localUser):$($branchName)"
	
	#Write-Host "Getting $State pull requests for $Owner/$Repository from $head to $base"
	$uri = "https://api.github.com/repos/$Owner/$Repository/pulls?access_token=${Env:\GITHUB_OAUTH_TOKEN}&base=$Base&head=$Head&state=$State"
	$global:GITHUB_API_OUTPUT = Invoke-RestMethod -Uri $uri
	
	$global:GITHUB_API_OUTPUT |
    % {
      $totalCount++
      $created = [DateTime]::Parse($_.created_at)
      $updated = [DateTime]::Parse($_.updated_at)
      $open = ([DateTime]::Now - $created).ToString('%d')
      Write-Host "`n$($_.number) from $($_.user.login) - $($_.title) "
      Write-Host "`tOpen for $open day(s) / Last Updated - $($updated.ToString('g'))"
      Write-Host "`t$($_.issue_url)"
    }
	Write-Host "`nFound $totalCount $State pull requests for $Owner/$Repository"
	return $totalCount
}

# Install powershell 3 and Posh-Github if not already installed
Install-Prerequisite
# Git\Set Github and Jira username\passwords
$JiraUserName = Initialize-JiraGithubCredentials -envariable "jira_username" -message "Jira username"
$JiraPassword = Initialize-JiraGithubCredentials -envariable "jira_password" -message "Jira password"

$JiraBaseUrl = "https://adazzle.atlassian.net"

Write-Host ${Env:\GITHUB_OAUTH_TOKEN}
if(!${Env:\GITHUB_OAUTH_TOKEN})
{
	$UserName = Read-Host "Please provide Github username"
	$Password = Read-Host "Please provide Github password"
	New-GitHubOAuthToken -Username $UserName -Password $Password
}

$TotalExistingPRs = Find-ExistingPullRequest -Base 'dev' -Owner "adazzle" -Repository "mediaAppSln" -State "open"
if ($TotalExistingPRs -eq "0") 
{
	Write-Host "Create new PR"
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

			New-GitHubPullRequest -Title "[$JiraIssue] - $summary" -Body "$JiraBaseUrl/browse/$JiraIssue" -Base 'dev' -Owner "adazzle" -Repository "mediaAppSln"	
			
			$html_url = "PR:" + ($GITHUB_API_OUTPUT | Select -ExpandProperty html_url)
			$commits_url = "Commits:" + ($GITHUB_API_OUTPUT | Select -ExpandProperty commits_url)
			
			[Uri]$uri = "$JiraBaseUrl/rest/api/2/issue/$JiraIssue/comment"
			 $issue = @{
					body = "$html_url $commits_url"
				} | ConvertTo-Json
			#Write-Host $issue
			Write-Host "Going to create PR link Jira issue"
			$result=Invoke-RestMethod -Uri $uri -Headers ($headers) -Method Post -Body $issue -ContentType "application/json"
			Write-Host "PR link created in Jira issue"
		}else{
		Write-Host "This is not a valid Jira issue"
		}
	}else{
		Write-Host "With no Jira issue provided, this git helper is useless so Please create PR in Github."
	}
}else{
	Write-Host "One PR already exists - another cannot be created."
}