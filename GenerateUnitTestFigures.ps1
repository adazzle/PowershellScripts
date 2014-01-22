Function Get-Latest-TeamCity-Build([string]$teamCityBaseUrl, [string]$projectId) {

    $url = "${teamCityBaseUrl}guestAuth/app/rest/buildTypes/id:${projectId}/builds?status=SUCCESS"
    #Write-host $url
    $xml = [xml](invoke-RestMethod -Uri $url -Method GET)
    $xpath = "/builds/build[1]"
    $latestBuild = Select-xml -xpath $xpath -xml $xml
    $BuildId = $latestBuild.Node.GetAttribute("id");
    $url = "${teamCityBaseUrl}/guestAuth/app/rest/builds/id:$BuildId"
    #Write-host $url
    $xml = [xml](invoke-RestMethod -Uri $url -Method GET)
    $csharptests =($xml.build | select @{ L = ' '; E = { $_.statusText } }) | Select-String -Pattern '\d+' | ForEach-Object {$_.Matches[0].Value}
    Write-Host "******$csharptests*****"
}

$buildurl = [environment]::GetEnvironmentVariable("buildurl","User")
Write-Host $buildurl
#Get total number of passed c# tests in last build
Get-Latest-TeamCity-Build $buildurl "bt4" | Write-Output 
#Get total number of passed js tests in last build
Get-Latest-TeamCity-Build $buildurl "bt5" | Write-Output 


