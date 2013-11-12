$Headers = @{}
$JiraUserName=[environment]::GetEnvironmentVariable("jira_username","User")
$JiraPassword=[environment]::GetEnvironmentVariable("jira_password","User")
$b64 = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("${JiraUserName}:${JiraPassword}"))
$Headers["Authorization"] = "Basic $b64"
$BaseURI = "https://adazzle.atlassian.net"
$Issue = "AD-1763"
$uri = "$BaseURI/rest/api/2/issue/$Issue/comment"

$body = ConvertTo-Json -InputObject @('"body": "This is a comment I want to post."')
Write-Host $body

# works fine
#Invoke-RestMethod -uri $uri -Headers $headers -ContentType "application/json"

# results in errors
Invoke-RestMethod -uri $uri -Headers $headers -ContentType "application/json" -Method Post -Body $body


