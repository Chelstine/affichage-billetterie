[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$HostName,

    [Parameter(Mandatory = $true)]
    [string]$UserName,

    [Parameter(Mandatory = $true)]
    [string]$RemoteDir,

    [int]$Port = 22,

    [string]$IdentityFile,

    [string]$EnvFile,

    [switch]$RunDeploy
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Quote-Posix {
    param([Parameter(Mandatory = $true)][string]$Value)
    $escapedSingleQuote = "'" + '"' + "'" + '"' + "'"
    return "'" + $Value.Replace("'", $escapedSingleQuote) + "'"
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$deployIgnorePath = Join-Path $repoRoot ".deployignore"

if (-not (Test-Path $deployIgnorePath)) {
    throw "Fichier .deployignore introuvable."
}

if ($EnvFile) {
    $resolvedEnvFile = (Resolve-Path $EnvFile).Path
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$archiveName = "affichage-billetterie-$timestamp.tar.gz"
$archivePath = Join-Path ([System.IO.Path]::GetTempPath()) $archiveName
$remoteArchivePath = "/tmp/$archiveName"

$excludeArgs = New-Object System.Collections.Generic.List[string]
Get-Content $deployIgnorePath | ForEach-Object {
    $pattern = $_.Trim()
    if ($pattern -and -not $pattern.StartsWith("#")) {
        $excludeArgs.Add("--exclude")
        $excludeArgs.Add($pattern)
    }
}

Push-Location $repoRoot
try {
    if (Test-Path $archivePath) {
        Remove-Item $archivePath -Force
    }

    & tar -czf $archivePath @excludeArgs .
    if ($LASTEXITCODE -ne 0) {
        throw "La creation de l'archive a echoue."
    }
}
finally {
    Pop-Location
}

$sshArgs = New-Object System.Collections.Generic.List[string]
$scpArgs = New-Object System.Collections.Generic.List[string]

if ($Port -ne 22) {
    $sshArgs.Add("-p")
    $sshArgs.Add([string]$Port)
    $scpArgs.Add("-P")
    $scpArgs.Add([string]$Port)
}

if ($IdentityFile) {
    $resolvedIdentityFile = (Resolve-Path $IdentityFile).Path
    $sshArgs.Add("-i")
    $sshArgs.Add($resolvedIdentityFile)
    $scpArgs.Add("-i")
    $scpArgs.Add($resolvedIdentityFile)
}

$destination = "$UserName@$HostName"

$prepareRemoteCommand = @(
    "mkdir -p $(Quote-Posix $RemoteDir)",
    "find $(Quote-Posix $RemoteDir) -mindepth 1 -maxdepth 1 ! -name '.env' ! -name '.env.production' -exec rm -rf {} +"
) -join " && "

& ssh @sshArgs $destination $prepareRemoteCommand
if ($LASTEXITCODE -ne 0) {
    throw "La preparation du dossier distant a echoue."
}

& scp @scpArgs $archivePath "${destination}:${remoteArchivePath}"
if ($LASTEXITCODE -ne 0) {
    throw "L'envoi de l'archive a echoue."
}

$extractRemoteCommand = @(
    "tar -xzf $(Quote-Posix $remoteArchivePath) -C $(Quote-Posix $RemoteDir)",
    "rm -f $(Quote-Posix $remoteArchivePath)"
) -join " && "

& ssh @sshArgs $destination $extractRemoteCommand
if ($LASTEXITCODE -ne 0) {
    throw "L'extraction de l'archive a echoue."
}

if ($EnvFile) {
    & scp @scpArgs $resolvedEnvFile "${destination}:$(Quote-Posix "$RemoteDir/.env.production")"
    if ($LASTEXITCODE -ne 0) {
        throw "L'envoi du fichier d'environnement a echoue."
    }
}

if ($RunDeploy) {
    $deployRemoteCommand = "cd $(Quote-Posix $RemoteDir) && ENV_FILE=.env.production bash scripts/deploy-vps.sh"
    & ssh @sshArgs $destination $deployRemoteCommand
    if ($LASTEXITCODE -ne 0) {
        throw "Le deploiement distant a echoue."
    }
}

Write-Host "Archive envoyee dans $RemoteDir sur $HostName."
if ($EnvFile) {
    Write-Host "Fichier d'environnement copie vers $RemoteDir/.env.production."
}
if ($RunDeploy) {
    Write-Host "Deploiement lance sur le VPS."
}
