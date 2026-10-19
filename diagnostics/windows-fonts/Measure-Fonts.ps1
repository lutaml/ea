param([string]$OutputDirectory = "$PSScriptRoot/results")
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force $OutputDirectory | Out-Null
function Save-Json($Name, $Value) {
    $Value | ConvertTo-Json -Depth 30 | Set-Content -Encoding utf8 (Join-Path $OutputDirectory $Name)
}
Add-Type -Path "$PSScriptRoot/GdiProbe.cs"
$smoke = [GdiProbe]::Measure('Arial', -13, 400, $false, [byte]1, 'Hello')
if ($smoke.Width -le 0 -or $smoke.ActualFace -ne 'Arial') { throw 'Arial GDI smoke failed' }
if ($smoke.DpiX -ne 96 -or $smoke.DpiY -ne 96) { throw "Expected 96 DPI: $($smoke.DpiX),$($smoke.DpiY)" }
Save-Json 'smoke.json' $smoke
$requirementsPath = Join-Path $PSScriptRoot 'requirements.json'
$requirements = Get-Content -Raw $requirementsPath | ConvertFrom-Json
Copy-Item $requirementsPath (Join-Path $OutputDirectory 'requirements.json')
$registry = @{}
foreach ($key in @('FontLink\SystemLink', 'FontSubstitutes', 'Fonts')) {
    $path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\$key"
    $registry[$key] = if (Test-Path $path) { Get-ItemProperty $path | Select-Object * -ExcludeProperty PS* } else { $null }
}
Save-Json 'registry.json' $registry
Add-Type -AssemblyName System.Drawing
$installed = New-Object System.Drawing.Text.InstalledFontCollection
Save-Json 'installed-families.json' @($installed.Families.Name | Sort-Object)
$installed.Dispose()
$fontFiles = @(Get-ChildItem "$env:WINDIR/Fonts" -File | ForEach-Object {
    [ordered]@{name=$_.Name; length=$_.Length; sha256=(Get-FileHash $_.FullName -Algorithm SHA256).Hash; version=$_.VersionInfo.FileVersion}
})
Save-Json 'font-files.json' $fontFiles
Save-Json 'environment.json' ([ordered]@{
    timestamp=(Get-Date).ToUniversalTime().ToString('o'); os=(Get-CimInstance Win32_OperatingSystem | Select-Object Caption,Version,BuildNumber)
    culture=(Get-Culture).Name; uiCulture=(Get-UICulture).Name; systemLocale=(Get-WinSystemLocale).Name
    powershell=$PSVersionTable.PSVersion.ToString(); runnerImage=$env:ImageOS; runnerVersion=$env:ImageVersion
    commit=$env:GITHUB_SHA; runId=$env:GITHUB_RUN_ID; requirementsSha256=(Get-FileHash $requirementsPath -Algorithm SHA256).Hash
    supplementalFonts=(Get-WindowsCapability -Online -Name 'Language.Fonts.Jpan~~~und-JPAN~0.0.1.0' | Select-Object Name,State)
})
$fontDirectory = Join-Path $env:RUNNER_TEMP 'carlito-probe-private'
New-Item -ItemType Directory -Force $fontDirectory | Out-Null
$fontCommit = '47d54ca1ebb14fd864695f1d39dc734f39017c33'
$fontSources = @()
$registered = @()
try {
    foreach ($style in @('Regular', 'Bold', 'Italic', 'BoldItalic')) {
        $name = "Carlito-$style.ttf"
        $url = "https://raw.githubusercontent.com/google/fonts/$fontCommit/ofl/carlito/$name"
        $path = Join-Path $fontDirectory $name
        Invoke-WebRequest -Uri $url -OutFile $path
        $count = [GdiProbe]::RegisterFont($path)
        if ($count -lt 1) { throw "Private font registration failed: $name" }
        $registered += $path
        $fontSources += [ordered]@{name=$name; source=$url; sha256=(Get-FileHash $path -Algorithm SHA256).Hash; registeredFaces=$count}
    }
    Save-Json 'private-font-sources.json' $fontSources
    $measurements = [System.Collections.Generic.List[object]]::new()
    $index = 0
    foreach ($target in $requirements.targets) {
        foreach ($face in $requirements.faces_to_measure) {
            $measurement = [GdiProbe]::Measure($face, -[int]$target.logical_height_px, [int]$target.weight, $false, [byte]1, $target.text)
            $measurements.Add([ordered]@{targetIndex=$index; target=$target; measurement=$measurement})
        }
        $index++
    }
    Save-Json 'targets.json' $measurements.ToArray()
    # One combined string per face/config measures each exact codepoint once.
    $characters = [System.Collections.Generic.SortedSet[int]]::new()
    foreach ($target in $requirements.targets) {
        foreach ($point in $target.codepoints) { [void]$characters.Add([Convert]::ToInt32($point.Substring(2),16)) }
    }
    $allCharacters = -join @($characters | ForEach-Object { [char]::ConvertFromUtf32($_) })
    $glyphs = [System.Collections.Generic.List[object]]::new()
    foreach ($face in $requirements.faces_to_measure) {
        foreach ($height in $requirements.logical_heights_px) {
            foreach ($weight in $requirements.weights) {
                foreach ($italic in $requirements.italic) {
                    $glyphs.Add([GdiProbe]::Measure($face, -[int]$height, [int]$weight, [bool]$italic, [byte]1, $allCharacters))
                }
            }
        }
    }
    Save-Json 'glyphs.json' $glyphs.ToArray()
    Save-Json 'manifest.json' ([ordered]@{
        targetCount=$requirements.targets.Count; targetMeasurements=$measurements.Count
        uniqueCodepoints=$characters.Count; glyphConfigurations=$glyphs.Count
        fullStringPolicy='Each target uses only its own height/weight, nonitalic; measured across requested faces.'
        glyphPolicy='All exact codepoints, across requested calibration matrix; no target Cartesian expansion.'
        missingGlyphPolicy='Widths for missing glyphs are diagnostic fallback values, not evidence of selected-face coverage.'
        outlineBoldPolicy='Real versus synthesized bold unresolved; requested and selected tmWeight recorded.'
        result='complete'
    })
} finally {
    foreach ($path in $registered) { [GdiProbe]::UnregisterFont($path) }
    Remove-Item -Recurse -Force $fontDirectory -ErrorAction SilentlyContinue
}
