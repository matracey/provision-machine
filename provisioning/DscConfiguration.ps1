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
