# Funciones compartidas para builds y publicación en Google Play (Closed Testing).
$ErrorActionPreference = 'Stop'

function Get-PlayReleasePaths {
    $repoRoot = Split-Path -Parent $PSScriptRoot
    $flutterDir = Join-Path $repoRoot 'eternalxi_front'
    $androidDir = Join-Path $flutterDir 'android'
    $keyProperties = Join-Path $androidDir 'key.properties'
    $pubspec = Join-Path $flutterDir 'pubspec.yaml'
    $aabPath = Join-Path $flutterDir 'build\app\outputs\bundle\release\app-release.aab'
    $defaultCredentials = Join-Path $env:USERPROFILE '.local\eternalxi\google-play-service-account.json'

    [PSCustomObject]@{
        RepoRoot            = $repoRoot
        FlutterDir          = $flutterDir
        AndroidDir          = $androidDir
        KeyProperties       = $keyProperties
        Pubspec             = $pubspec
        AabPath             = $aabPath
        DefaultCredentials  = $defaultCredentials
        CredentialsPath     = if ($env:GOOGLE_PLAY_JSON_KEY) { $env:GOOGLE_PLAY_JSON_KEY } else { $defaultCredentials }
        FastlaneDir         = Join-Path $androidDir 'fastlane'
    }
}

function Read-KeyPropertiesFile {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        throw "No existe $Path"
    }

    $props = @{}
    Get-Content $Path | ForEach-Object {
        $line = $_.Trim()
        if ($line -eq '' -or $line.StartsWith('#')) { return }
        $idx = $line.IndexOf('=')
        if ($idx -lt 1) { return }
        $key = $line.Substring(0, $idx).Trim()
        $value = $line.Substring($idx + 1).Trim()
        $props[$key] = $value
    }
    return $props
}

function Resolve-KeystorePath {
    param(
        [string]$StoreFile,
        [string]$AndroidDir
    )

    if ([System.IO.Path]::IsPathRooted($StoreFile)) {
        return $StoreFile
    }
    return Join-Path $AndroidDir $StoreFile
}

function Get-PubspecVersionInfo {
    param([string]$PubspecPath)

    if (-not (Test-Path $PubspecPath)) {
        throw "No existe $PubspecPath"
    }

    $content = Get-Content $PubspecPath -Raw
    if ($content -notmatch 'version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)') {
        throw "pubspec.yaml: formato version inválido (esperado: x.y.z+code)"
    }

    return [PSCustomObject]@{
        Major       = [int]$Matches[1]
        Minor       = [int]$Matches[2]
        Patch       = [int]$Matches[3]
        VersionCode = [int]$Matches[4]
        VersionName = "$($Matches[1]).$($Matches[2]).$($Matches[3])"
        VersionLine = $Matches[0].Trim()
    }
}

function Update-PubspecVersion {
    param([string]$PubspecPath)

    $info = Get-PubspecVersionInfo -PubspecPath $PubspecPath
    $newPatch = $info.Patch + 1
    $newCode = $info.VersionCode + 1
    $newVersionName = "$($info.Major).$($info.Minor).$newPatch"
    $newVersionLine = "version: $newVersionName+$newCode"

    $lines = Get-Content $PubspecPath
    $updated = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^\s*version:\s*\d+\.\d+\.\d+\+\d+\s*$') {
            $lines[$i] = $newVersionLine
            $updated = $true
            break
        }
    }

    if (-not $updated) {
        throw "No se encontró la línea version: en pubspec.yaml"
    }

    Set-Content -Path $PubspecPath -Value $lines -Encoding utf8

    return [PSCustomObject]@{
        VersionName = $newVersionName
        VersionCode = $newCode
        VersionLine = $newVersionLine
    }
}

function Get-FastlaneCommand {
    $paths = Get-PlayReleasePaths
    $gemfile = Join-Path $paths.AndroidDir 'Gemfile'

    $fastlane = Get-Command fastlane -ErrorAction SilentlyContinue
    if ($fastlane) {
        return @{
            Executable = $fastlane.Source
            Arguments  = @()
            Display    = 'fastlane'
        }
    }

    $bundle = Get-Command bundle -ErrorAction SilentlyContinue
    if ($bundle -and (Test-Path $gemfile)) {
        return @{
            Executable = $bundle.Source
            Arguments  = @('exec', 'fastlane')
            Display    = 'bundle exec fastlane'
        }
    }

    return $null
}

function Add-PlayReleaseCheck {
    param(
        [System.Collections.Generic.List[object]]$Checks,
        [ref]$AllOk,
        [string]$Name,
        [bool]$Ok,
        [string]$Detail
    )

    $Checks.Add([PSCustomObject]@{ Name = $Name; Ok = $Ok; Detail = $Detail }) | Out-Null
    if (-not $Ok) { $AllOk.Value = $false }
}

function Test-PlayReleasePrerequisites {
    param(
        [switch]$RequireAab
    )

    $paths = Get-PlayReleasePaths
    $checks = [System.Collections.Generic.List[object]]::new()
    $allOk = $true

    # key.properties
    $keyOk = Test-Path $paths.KeyProperties
    Add-PlayReleaseCheck -Checks $checks -AllOk ([ref]$allOk) -Name 'key.properties' -Ok $keyOk `
        -Detail $(if ($keyOk) { $paths.KeyProperties } else { "Falta: $($paths.KeyProperties)" })

    # keystore
    $keystoreOk = $false
    $keystoreDetail = 'key.properties no disponible'
    if ($keyOk) {
        try {
            $props = Read-KeyPropertiesFile -Path $paths.KeyProperties
            $required = @('storePassword', 'keyPassword', 'keyAlias', 'storeFile')
            $missing = $required | Where-Object { -not $props.ContainsKey($_) -or [string]::IsNullOrWhiteSpace($props[$_]) }
            if ($missing.Count -gt 0) {
                $keystoreDetail = "Faltan claves en key.properties: $($missing -join ', ')"
            } else {
                $keystorePath = Resolve-KeystorePath -StoreFile $props['storeFile'] -AndroidDir $paths.AndroidDir
                $keystoreOk = Test-Path $keystorePath
                $keystoreDetail = if ($keystoreOk) { $keystorePath } else { "Keystore no encontrado: $keystorePath" }
            }
        } catch {
            $keystoreDetail = $_.Exception.Message
        }
    }
    Add-PlayReleaseCheck -Checks $checks -AllOk ([ref]$allOk) -Name 'keystore release' -Ok $keystoreOk -Detail $keystoreDetail

    # credenciales Google Play
    $credOk = Test-Path $paths.CredentialsPath
    $credDetail = if ($credOk) { $paths.CredentialsPath } else {
        if ($env:GOOGLE_PLAY_JSON_KEY) {
            "GOOGLE_PLAY_JSON_KEY apunta a un archivo inexistente: $($paths.CredentialsPath)"
        } else {
            "Falta: $($paths.DefaultCredentials) (o define GOOGLE_PLAY_JSON_KEY)"
        }
    }
    Add-PlayReleaseCheck -Checks $checks -AllOk ([ref]$allOk) -Name 'service account JSON' -Ok $credOk -Detail $credDetail

    # Fastlane
    $fastlaneCmd = Get-FastlaneCommand
    $fastlaneOk = $null -ne $fastlaneCmd
    $fastlaneDetail = if ($fastlaneOk) { $fastlaneCmd.Display } else {
        'Instala Ruby + fastlane (gem install fastlane) o bundle exec desde eternalxi_front/android/'
    }
    Add-PlayReleaseCheck -Checks $checks -AllOk ([ref]$allOk) -Name 'Fastlane' -Ok $fastlaneOk -Detail $fastlaneDetail

    # pubspec version
    $versionOk = $false
    $versionDetail = 'pubspec.yaml no disponible'
    try {
        $version = Get-PubspecVersionInfo -PubspecPath $paths.Pubspec
        $versionOk = $true
        $versionDetail = "$($version.VersionName) (versionCode $($version.VersionCode))"
    } catch {
        $versionDetail = $_.Exception.Message
    }
    Add-PlayReleaseCheck -Checks $checks -AllOk ([ref]$allOk) -Name 'pubspec version' -Ok $versionOk -Detail $versionDetail

    # AAB opcional
    if ($RequireAab) {
        $aabOk = Test-Path $paths.AabPath
        Add-PlayReleaseCheck -Checks $checks -AllOk ([ref]$allOk) -Name 'AAB release' -Ok $aabOk `
            -Detail $(if ($aabOk) { (Resolve-Path $paths.AabPath).Path } else { "No generado: $($paths.AabPath)" })
    } elseif (Test-Path $paths.AabPath) {
        Add-PlayReleaseCheck -Checks $checks -AllOk ([ref]$allOk) -Name 'AAB release (opcional)' -Ok $true `
            -Detail (Resolve-Path $paths.AabPath).Path
    } else {
        Add-PlayReleaseCheck -Checks $checks -AllOk ([ref]$allOk) -Name 'AAB release (opcional)' -Ok $true `
            -Detail "Aún no generado: $($paths.AabPath)"
    }

    return [PSCustomObject]@{
        Ok     = $allOk
        Checks = $checks
        Paths  = $paths
        FastlaneCommand = $fastlaneCmd
    }
}

function Write-PlayReleaseCheckReport {
    param($Result)

    foreach ($check in $Result.Checks) {
        $icon = if ($check.Ok) { '[OK]' } else { '[FALTA]' }
        $color = if ($check.Ok) { 'Green' } else { 'Red' }
        Write-Host "$icon $($check.Name): $($check.Detail)" -ForegroundColor $color
    }
}
