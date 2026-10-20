param([string]$OutputDirectory = "$PSScriptRoot/results")
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force $OutputDirectory | Out-Null
function Save-Json($Name, $Value) {
    $Value | ConvertTo-Json -Depth 30 | Set-Content -Encoding utf8 (Join-Path $OutputDirectory $Name)
}
Add-Type -Path "$PSScriptRoot/GdiProbe.cs"
$requirementsPath = Join-Path $PSScriptRoot 'requirements.json'
$requirements = Get-Content -Raw $requirementsPath | ConvertFrom-Json
Copy-Item $requirementsPath (Join-Path $OutputDirectory 'requirements.json')
$smoke = [GdiProbe]::Measure('Arial', -13, 400, $false, [byte]1, 'Hello')
if ($smoke.ActualFace -ne 'Arial' -or $smoke.Width -le 0) { throw 'Arial smoke failed' }
if ($smoke.DpiX -ne 96 -or $smoke.DpiY -ne 96) { throw '96 DPI required' }
Save-Json 'smoke.json' $smoke
Save-Json 'environment.json' ([ordered]@{
    timestamp=(Get-Date).ToUniversalTime().ToString('o')
    os=(Get-CimInstance Win32_OperatingSystem | Select-Object Caption,Version,BuildNumber)
    runnerImage=$env:ImageOS; runnerVersion=$env:ImageVersion
    commit=$env:GITHUB_SHA; runId=$env:GITHUB_RUN_ID
    requirementsSha256=(Get-FileHash $requirementsPath -Algorithm SHA256).Hash
    probeSha256=(Get-FileHash "$PSScriptRoot/GdiProbe.cs" -Algorithm SHA256).Hash
})
$fontFiles = @(Get-ChildItem "$env:WINDIR/Fonts" -File | Where-Object {
    $_.Name -match '^(msgothic|cambria|cambriab|cambriai|cambriaz)\.'
} | ForEach-Object {
    [ordered]@{name=$_.Name; sha256=(Get-FileHash $_.FullName -Algorithm SHA256).Hash; version=$_.VersionInfo.FileVersion}
})
Save-Json 'font-files.json' $fontFiles
$measurements = [System.Collections.Generic.List[object]]::new()
foreach ($face in $requirements.faces) {
    foreach ($height in $requirements.logical_heights) {
        foreach ($weight in $requirements.weights) {
            foreach ($charset in $requirements.charsets) {
                foreach ($text in @($requirements.glyph_text) + @($requirements.text_samples)) {
                    $measurement = [GdiProbe]::Measure($face, -[int]$height, [int]$weight, $false, [byte]$charset, $text)
                    if ($measurement.ActualFace -ne $face) { throw "Face substituted: $face -> $($measurement.ActualFace)" }
                    if ($measurement.DpiX -ne 96 -or $measurement.DpiY -ne 96) { throw '96 DPI required' }
                    # Missing glyphs under Cambria remain diagnostic; MS UI Gothic is measured directly.
                    if ($face -eq 'MS UI Gothic' -and $measurement.MissingUtf16Indices.Count -ne 0) {
                        throw 'Requested MS UI Gothic glyph coverage unavailable'
                    }
                    foreach ($point in $measurement.Codepoints) {
                        if ($point.WidthStatus -ne 'ok') { throw "Advance measurement failed: $($point.Unicode)" }
                    }
                    $measurements.Add($measurement)
                }
            }
        }
    }
}
Save-Json 'measurements.json' $measurements.ToArray()
Save-Json 'manifest.json' ([ordered]@{
    measurementCount=$measurements.Count
    result='complete'
    contract='Exact GDI advances for requested configurations; does not identify original EA exporter fallback face or selected logical height.'
})
