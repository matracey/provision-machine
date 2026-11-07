function Test-GitCheckout {
    param(
        [Parameter(Mandatory)][string]$Target,
        [string]$Repository,
        [string]$Ref = 'HEAD'
    )

    if (-not (Test-Path -LiteralPath (Join-Path $Target '.git'))) { return $false }
    $origin = (& git -C $Target remote get-url origin 2>$null)
    if ($LASTEXITCODE -ne 0) { return $false }
    if ($Repository -and $origin.TrimEnd('/') -ne $Repository.TrimEnd('/')) { return $false }
    $remote = (& git -C $Target ls-remote origin $Ref 2>$null) -split '\s+' | Select-Object -First 1
    $local = & git -C $Target rev-parse HEAD 2>$null
    return $LASTEXITCODE -eq 0 -and $remote -and $local -eq $remote
}

function Sync-GitCheckout {
    param(
        [Parameter(Mandatory)][string]$Target,
        [string]$Repository,
        [string]$Branch,
        [string]$GistId
    )

    if ([bool]$Repository -eq [bool]$GistId) {
        throw 'Specify either Repository or GistId.'
    }
    if (Test-Path -LiteralPath $Target) {
        if (-not (Test-Path -LiteralPath (Join-Path $Target '.git'))) {
            throw "Target exists but is not a Git repository: $Target"
        }
        if ($Repository) {
            $origin = (& git -C $Target remote get-url origin).TrimEnd('/')
            if ($origin -ne $Repository.TrimEnd('/')) {
                throw "Target uses unexpected origin '$origin'."
            }
            & git -C $Target pull --ff-only origin $Branch
        } else {
            & git -C $Target pull --ff-only
        }
    } elseif ($Repository) {
        & git clone --branch $Branch --single-branch $Repository $Target
    } else {
        & gh gist clone $GistId $Target
    }
    if ($LASTEXITCODE -ne 0) { throw "Unable to synchronize Git checkout: $Target" }
}

function Get-MatchingFiles {
    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][string[]]$Patterns
    )

    @(Get-ChildItem -LiteralPath $Root -File | Where-Object {
        $name = $_.Name
        @($Patterns | Where-Object { $name -like $_ }).Count -gt 0
    } | Sort-Object Name -Unique)
}

function Test-FileMirror {
    param(
        [Parameter(Mandatory)][string]$SourceRoot,
        [Parameter(Mandatory)][string[]]$DestinationRoots,
        [Parameter(Mandatory)][string[]]$Patterns
    )

    $files = Get-MatchingFiles -Root $SourceRoot -Patterns $Patterns
    if ($files.Count -eq 0) { throw "No files matched in $SourceRoot." }
    foreach ($directory in $DestinationRoots) {
        foreach ($file in $files) {
            $destination = Join-Path $directory $file.Name
            if (-not (Test-Path -LiteralPath $destination) -or
                (Get-FileHash -LiteralPath $file.FullName).Hash -ne
                (Get-FileHash -LiteralPath $destination).Hash) {
                return $false
            }
        }
    }
    return $true
}

function Sync-FileMirror {
    param(
        [Parameter(Mandatory)][string]$SourceRoot,
        [Parameter(Mandatory)][string[]]$DestinationRoots,
        [Parameter(Mandatory)][string[]]$Patterns
    )

    $files = Get-MatchingFiles -Root $SourceRoot -Patterns $Patterns
    if ($files.Count -eq 0) { throw "No files matched in $SourceRoot." }
    foreach ($directory in $DestinationRoots) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
        foreach ($file in $files) {
            Copy-Item -LiteralPath $file.FullName -Destination (Join-Path $directory $file.Name) -Force
        }
    }
}
