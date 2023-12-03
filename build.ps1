$LatestJSON = ((Invoke-WebRequest "https://api.github.com/repos/appleboy/CodeGPT/releases/latest").Content | ConvertFrom-Json)

$ReleaseNotes  = $LatestJSON.body.Replace("`r`n`r`n", "`r`n").Replace("&", "&amp;").Replace("<", "&lt;").Replace(">", "&gt;")

$LatestVersion = $LatestJSON.tag_name -replace "v" -replace ""
$LatestVersion | Out-File -FilePath "LatestVersion.txt" -Encoding UTF8

$LatestChocoVersion = "0.0.0"
$AllChocoVersions = (choco search codegpt --limit-output --all-versions --exact | C:\Windows\System32\sort.exe /r)

Write-Output AllChocoVersions = $AllChocoVersions

if ($AllChocoVersions -eq $null) {
  $AllChocoVersions = "codegpt|0.0.0"
}

if ($AllChocoVersions.GetType().FullName -eq 'System.String') {
  $LatestChocoVersion = ($AllChocoVersions -split '\|')[1]
} else {
  $LatestChocoVersion = ($AllChocoVersions[0] -split '\|')[1]
}

Write-Output LatestChocoVersion = $LatestChocoVersion

$LatestChocoVersion | Out-File -FilePath "LatestChocoVersion.txt" -Encoding UTF8

$x64_link = $LatestJSON.assets | ForEach-Object -Process {
  if ($_.name -like '*-windows-amd64.exe'){ $_.browser_download_url }
}

$ProgressPreference = 'SilentlyContinue'
Invoke-WebRequest -OutFile "CodeGPT.exe" -Uri $x64_link
$ProgressPreference = 'Continue'

$x64_sha256 = (Get-FileHash .\CodeGPT.exe).Hash

Remove-Item .\CodeGPT.exe

@"
<?xml version="1.0" encoding="utf-8"?>
<package xmlns="http://schemas.microsoft.com/packaging/2015/06/nuspec.xsd">
  <metadata>
    <id>codegpt</id>
    <version>$LatestVersion</version>
    <packageSourceUrl>https://github.com/doggy8088/chocolatey-codegpt</packageSourceUrl>
    <owners>Will 保哥</owners>
    <title>codegpt</title>
    <authors>codegpt</authors>
    <projectUrl>https://github.com/appleboy/CodeGPT</projectUrl>
    <iconUrl>https://avatars1.githubusercontent.com/u/6357982?s=40&amp;v=4</iconUrl>
    <copyright>The CodeGPT Authors</copyright>
    <licenseUrl>https://github.com/appleboy/CodeGPT/blob/master/LICENSE</licenseUrl>
    <requireLicenseAcceptance>false</requireLicenseAcceptance>
    <projectSourceUrl>https://github.com/appleboy/CodeGPT</projectSourceUrl>
    <bugTrackerUrl>https://github.com/appleboy/CodeGPT/issues</bugTrackerUrl>
    <tags>CodeGPT OpenAI go</tags>
    <summary>A CLI written in Go language that writes git commit messages or do a code review brief for you using ChatGPT AI (gpt-3.5-turbo, gpt-4 model) and automatically installs a git prepare-commit-msg hook.</summary>
    <description>A CLI written in Go language that writes git commit messages or do a code review brief for you using ChatGPT AI (gpt-3.5-turbo, gpt-4 model) and automatically installs a git prepare-commit-msg hook.</description>
    <releaseNotes>$ReleaseNotes</releaseNotes>
  </metadata>
  <files>
    <file src="tools\**" target="tools" />
  </files>
</package>
"@ | Out-File -FilePath codegpt.nuspec -Encoding UTF8

@"
`$ErrorActionPreference = 'Stop';

`$packageName= 'CodeGPT'
`$toolsDir   = "`$(Split-Path -parent `$MyInvocation.MyCommand.Definition)"
`$url64      = '$x64_link'
`$toolsDir   = "`$(Split-Path -parent `$MyInvocation.MyCommand.Definition)"

`$packageArgs = @{
  packageName   = `$packageName

  url64bit      = `$url64

  softwareName  = 'codegpt'

  checksum64    = '$x64_sha256'
  checksumType64= 'sha256'

  fileFullPath  = "`$toolsDir\CodeGPT.exe"

  validExitCodes= @(0)
}

Get-ChocolateyWebFile @packageArgs
"@ | Out-File -FilePath tools\chocolateyinstall.ps1 -Encoding UTF8

choco pack

# choco install codegpt -d -s . -y
# choco uninstall codegpt -d -s .

@"
Set-ExecutionPolicy Unrestricted -Force
Install-Module -Name PoshSemanticVersion -Force

`$LatestChocoVersion = Get-Content LatestChocoVersion.txt
`$LatestVersion = Get-Content LatestVersion.txt

Write-Output LatestChocoVersion = `$LatestChocoVersion
Write-Output LatestVersion = `$LatestVersion

`$Precedence = (Compare-SemanticVersion -ReferenceVersion `$LatestChocoVersion -DifferenceVersion `$LatestVersion).Precedence;

if (`$Precedence -eq '>' -or `$Precedence -eq '=')
{
  Write-Output "因為 Chocolatey 的 codegpt 套件版本(`$LatestChocoVersion) 大於等於 codegpt `$LatestVersion 版本，因此不需要發行套件！"
  Write-Output "##vso[task.setvariable variable=CodeGPTVersion]canceled"
  echo "##vso[task.complete result=Canceled;]DONE"
  Exit 0
}
else
{
  Write-Output "##vso[task.setvariable variable=CodeGPTVersion]${LatestVersion}"
  Write-Output "準備發行 codegpt `$LatestVersion 版本到 Chocolatey Gallery"
  choco push codegpt.`$LatestVersion.nupkg --source https://push.chocolatey.org/ --key=#{CHOCO_APIKEY}#
}
"@ | Out-File -FilePath "publish.ps1" -Encoding UTF8
