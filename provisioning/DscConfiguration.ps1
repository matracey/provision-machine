function Read-DscDocument {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Executable
    )
    $content = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop
    try {
        # y2j toggles formats; already-valid JSON must bypass it.
        $document = $content | ConvertFrom-Json -AsHashtable -ErrorAction Stop
    } catch [System.ArgumentException] {
        $json = $content | & (Join-Path (Split-Path $Executable) 'y2j.exe')
        if ($LASTEXITCODE -ne 0) { throw "Cannot parse DSC document: $Path" }
        $document = ($json -join "`n") | ConvertFrom-Json -AsHashtable -ErrorAction Stop
    }
    if (-not $document -or -not $document.ContainsKey('resources')) {
        throw "No resources in DSC document: $Path"
    }
    return $document
}

function Get-DscConfiguration {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Executable,
        [string[]]$Only,
        [string[]]$Skip
    )
    $document = Read-DscDocument -Path $Path -Executable $Executable
    $root = Split-Path (Resolve-Path -LiteralPath $Path).Path
    $includes = @($document.resources | Where-Object type -EQ 'Microsoft.DSC/Include')
    $names = @($includes | ForEach-Object { Split-Path $_.properties.configurationFile -Leaf })
    foreach ($name in @($Only) + @($Skip)) {
        if ($name -and $name -notin $names) { throw "Unknown included module: $name" }
    }
    $document.resources = @($document.resources | Where-Object {
        if ($_.type -ne 'Microsoft.DSC/Include') { return -not $Only }
        $name = Split-Path $_.properties.configurationFile -Leaf
        return ($name -notin $Skip -and (-not $Only -or $name -in $Only))
    })
    if ($document.resources.Count -eq 0) { throw 'No DSC resources selected.' }
    foreach ($resource in $document.resources) {
        if ($resource.type -eq 'Microsoft.DSC/Include') {
            $resource.properties.configurationFile = (Resolve-Path -LiteralPath (
                Join-Path $root $resource.properties.configurationFile
            ) -ErrorAction Stop).Path
        }
    }
    return $document
}

function Save-DscBundle {
    param(
        [Parameter(Mandatory)][string]$Directory,
        [Parameter(Mandatory)][string]$GistId
    )
    $root = [IO.Path]::GetFullPath($Directory)
    $gist = Invoke-RestMethod -Uri "https://api.github.com/gists/$GistId" -Headers @{ 'User-Agent' = 'Provision-Machine' } -ErrorAction Stop
    $files = @($gist.files.PSObject.Properties | Where-Object Name -Like 'winget__*')
    if ($files.Count -eq 0) { throw 'The Gist contains no structured winget__ configuration files.' }
    foreach ($file in $files) {
        $relative = ($file.Name -split '__') -join [IO.Path]::DirectorySeparatorChar
        $path = [IO.Path]::GetFullPath((Join-Path $root $relative))
        if (-not $path.StartsWith("$root$([IO.Path]::DirectorySeparatorChar)", [StringComparison]::OrdinalIgnoreCase)) {
            throw "Invalid path in Gist bundle: $($file.Name)"
        }
        New-Item -ItemType Directory -Path (Split-Path $path) -Force -ErrorAction Stop | Out-Null
        Invoke-WebRequest -Uri $file.Value.raw_url -OutFile $path -ErrorAction Stop
    }
}

function Test-DscDrift {
    param($Value)
    foreach ($entry in @($Value)) {
        $result = $entry.result
        if ($result -is [array]) {
            if (Test-DscDrift $result) { return $true }
        } elseif ($result -is [System.Collections.IDictionary] -and
            $result.inDesiredState -is [bool] -and -not $result.inDesiredState) {
            return $true
        }
    }
    return $false
}

function Assert-DscCommandSuccess {
    param($Value)
    foreach ($entry in @($Value)) {
        $result = $entry.result
        if ($result -is [array]) {
            Assert-DscCommandSuccess $result
        } elseif ($entry.type -eq 'Microsoft.DSC.Transitional/RunCommandOnSet') {
            if ($result.beforeState -isnot [System.Collections.IDictionary] -or
                $result.afterState -isnot [System.Collections.IDictionary]) {
                throw "Invalid command result for '$($entry.name)'."
            }
            # This resource omits zero exit codes and does not set hadErrors on failure.
            $expected = if ($result.beforeState.Contains('exitCode')) { $result.beforeState.exitCode } else { 0 }
            $actual = if ($result.afterState.Contains('exitCode')) { $result.afterState.exitCode } else { 0 }
            if ($actual -ne $expected) {
                throw "DSC command '$($entry.name)' failed with exit code $actual (expected $expected)."
            }
        }
    }
}

function Invoke-DscConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Executable,
        [Parameter(Mandatory)][hashtable]$Configuration,
        [Parameter(Mandatory)][ValidateSet('get', 'test', 'set')][string]$Operation,
        [Parameter(Mandatory)][string]$LogRoot,
        [switch]$Preview
    )
    if ($Preview -and $Operation -ne 'set') { throw 'DSC what-if requires the set operation.' }
    New-Item -ItemType Directory -Path $LogRoot -Force -ErrorAction Stop | Out-Null
    $outputPath = Join-Path $LogRoot 'result.json'
    $tracePath = Join-Path $LogRoot 'trace.log'
    $arguments = @('config', $Operation, '--file', '-', '--output-format', 'json')
    if ($Preview) { $arguments += '--what-if' }
    $output = $Configuration | ConvertTo-Json -Depth 100 -Compress | & $Executable @arguments 2> $tracePath
    $exitCode = $LASTEXITCODE
    $output | Set-Content -LiteralPath $outputPath -Encoding utf8 -ErrorAction Stop
    if ($exitCode -ne 0) { throw "DSC failed with exit code $exitCode. See $tracePath and $outputPath." }
    if (-not $output) { throw "DSC returned no result. See $tracePath." }
    $result = ($output -join "`n") | ConvertFrom-Json -AsHashtable -ErrorAction Stop
    if ($result.hadErrors -isnot [bool] -or $result.results -isnot [array]) {
        throw "DSC returned an invalid configuration result. See $outputPath."
    }
    if ($result.hadErrors) { throw "DSC reported resource errors. See $outputPath." }
    if ($Operation -eq 'set' -and -not $Preview) { Assert-DscCommandSuccess $result.results }
    $drift = $Operation -eq 'test' -and (Test-DscDrift $result.results)
    [pscustomobject]@{
        Status = if ($drift) { 'DRIFT' } else { 'OK' }
        ExitCode = if ($drift) { 2 } else { 0 }
        ResultPath = $outputPath
        TracePath = $tracePath
        Result = $result
    }
}
