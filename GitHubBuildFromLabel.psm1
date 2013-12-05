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
		$BaseBranch = "dev",
		
		[Parameter(Mandatory = $false)]
		[ValidatePattern('^\*$|^none$|^\d+$')] 
		$Milestone = "*"
	)

	# Install PsGet & Posh Git if not already installed.
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
	
	# Setup Github access
	Write-Host "Setup github access"
	New-GitHubOAuthToken -Username $UserName -Password $Password

	# Fetch requested issues
	$labelNames = $Labels.split(",")
	$issues = @()
	foreach ($labelName in $labelNames) {
		Write-Host "Getting open issues for $labelName in milestone $Milestone..."
		Get-GitHubIssues -Owner $RepoOwner -Repository $Repo -Labels $labelName -Milestone $Milestone -State "open"
		$issues = @($issues) + @($GITHUB_API_OUTPUT)
		if(!$?) {
			Write-Host "Getting issues for label $labelName failed"
			exit
		}
	}

	#having to use user:password form in origin to get round password prompts
	#must be a better way..
	git config remote.origin.url https://$UserName":"$Password@github.com/$RepoOwner/$Repo.git

	# Checkout base branch and branch off it OR checkout existing branch
	git checkout $BaseBranch
	git pull
	if($ForceTempBranch) {
		Write-Host "Deleting branch '$TempBranchName' if it exists..."
		git branch -D $TempBranchName
		# Only delete locally (not remotely) if we're not going to be pushing a replacement tag to GitHub.
		if($PushToGitHub) {
			git push origin :$TempBranchName
		}
	   
		Write-Host "Creating branch '$TempBranchName'..."
		git checkout -b $TempBranchName
	}
	else {
		Write-Host "Check out branch '$TempBranchName'"
		git show-ref --verify --quiet refs/heads/$TempBranchName
		if (-not $?) {
			# Branch does not exist
			$message = "Branch '$TempBranchName' does not exist - try 'ForceTempBranch'"
			$exception = New-Object InvalidOperationException $message
			$errorID = 'BranchDoesNotExist'
			$errorCategory = [Management.Automation.ErrorCategory]::InvalidOperation
			$target = $Path
			$errorRecord = New-Object Management.Automation.ErrorRecord $exception, $errorID,
			$errorCategory, $target
			$PSCmdlet.ThrowTerminatingError($errorRecord)
		}
		git checkout $TempBranchName
	}

	Write-Host "Looping issues..."
	foreach ($issue in $issues) {
		$issueNumber = $issue.number
		$remoteBranch = "refs/pull/" + $issueNumber + "/merge"
		$branchName = "pr-$issueNumber"
		
		# If PR branch exists (locally) from a previous run, delete it.
		git show-ref --verify --quiet refs/heads/$branchName
		if ($?) {
			Write-Host "Deleting existing temp pr branch '$branchName'..."
			git branch -D $branchName
		}
		
		# Create PR branch
		write-host "Merging " $remoteBranch " as " $branchName
		git fetch origin $remoteBranch":"$branchName

		# Merge PR branch into base branch
		git merge $branchName --verbose --progress
		
		# Check all ok
		if(git status --porcelain) {
			$FilePathsWithConflicts = git diff --name-only --diff-filter=U | Out-String
			if ($FilePathsWithConflicts.length -gt 0) {
				write-host "Merge conflicts on $remoteBranch - aborting "
				write-host "Either remove the $Labels label from $remoteBranch " $issue.title
				write-host "OR resolve the cause of the conflict on $remoteBranch, push the changes and then rerun"
				$issue.url | clip
				Write-host "The link to the GitHub issue is now in your clipboard"
				exit 1
			}
			else {
				git commit -am "Merge $branchName into $TempBranchName after RERERE conflict resolution."
				write-host "Merge completed using previous rerere resolution"
			}
		}
		else {
			write-host "Merge was ok"
		}
	}

	# Push (or not) to GitHub
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
