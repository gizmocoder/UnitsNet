# Requires Powershell 3.0 or later because of Version::Parse
#
# Updates the following TeamCity build parameters:
# * majorversion, minorversion, patchversion
# * semver_postfix (could be used for "alpha", "beta" builds etc.)
# * short_hash (make short hash available to other build steps)
# * buildNumber (TeamCity system parameter, the one showed per build in overview page)
# * productinformation_version (will be used to update ApplicationInformation.cs)
# * assemblyinfo.version.number (used by assemblyinfo path build step)
# * installer_version_number (version number used by installer step)
# * installer_file_name (file name used by installer step)

[CmdletBinding()]
Param(
[Parameter(Mandatory=$true)]
[string]$buildCounter,

[Parameter(Mandatory=$true)]
[string]$commitSha
)

$root=Resolve-Path "$PSScriptRoot\.."

try {
    [ xml ]$nuspecXml = Get-Content -Path "$root\Build\UnitsNet.nuspec"

    # Split "1.2.3-alpha" into ["1.2.3", "alpha"]
    # Split "1.2.3" into ["1.2.3"]
    $semVerVersionParts = $nuspecXml.package.metadata.version.Split('-')
    $currentVersion = [Version]::Parse($semVerVersionParts[0])
    $postfix = if ($semVerVersionParts.Length -eq 2) { "-" + $semVerVersionParts[1]} else { "" }

    $major = $currentVersion.Major
    $minor = $currentVersion.Minor
    $patch = $currentVersion.Build
    $hash = $commitSha
    $short_hash = $hash.substring(0,7)

    $fullVersion = "$major.$minor.$patch.$buildCounter"
    $versionWithHash = "$major.$minor.$patch.$short_hash"
    $semanticVersion = "$major.$minor.$patch"+"$postfix.$short_hash"   
  
    Write-Host "##teamcity[setParameter name='version' value='$fullVersion']"
    Write-Host "##teamcity[setParameter name='version.major' value='$major']"
    Write-Host "##teamcity[setParameter name='version.minor' value='$minor']"
    Write-Host "##teamcity[setParameter name='version.patch' value='$patch']"
    Write-Host "##teamcity[setParameter name='version.semver.postfix' value='$postfix']"
    Write-Host "##teamcity[setParameter name='build.vcs.shorthash' value='$short_hash']"
    Write-Host "##teamcity[buildNumber '$fullVersion (#$short_hash)']"
}
catch {    
    $myError = $_.Exception.ToString()

    Write-Error "##teamcity[buildStatus text='Failed to update buildnumber: `n$myError' ]"
    exit 1
}