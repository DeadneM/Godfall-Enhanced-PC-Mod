# Godfall Enhanced H35 - OFFLINE FRONTEND RESOURCE LOCATOR
# Performs read-only inventory of the local GAME INSTALLATION ONLY.
# Makes no network requests. Does not open saves, modify the game,
# invoke Unreal code, read credentials, or extract/edit PAK files.
# Writes one report next to this script. PowerShell 5.1 compatible.
$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$report = Join-Path $here "GodfallFrontendAssetsReport.txt"
$root = $here
$dir = $here
$foundPaks = $false
for ($depth=0; $depth -lt 5; $depth++) {
    if ((Test-Path -LiteralPath (Join-Path $dir "Content\Paks") -PathType Container) -or
        (Test-Path -LiteralPath (Join-Path $dir "Aperion\Content\Paks") -PathType Container)) {
        $root = $dir
        $foundPaks = $true
        break
    }
    $parent = [System.IO.Directory]::GetParent($dir)
    if ($null -eq $parent) { break }
    $dir = $parent.FullName
}
# If no Paks directory was found, use the script folder; never scan a
# drive root or user profile as a fallback.
if (-not $foundPaks) { $root = $here }
$lines = New-Object 'System.Collections.Generic.List[string]'
[void]$lines.Add("GODFALL_FRONTEND_ASSETS_REPORT H35")
[void]$lines.Add("ScanRoot=" + $(if ($foundPaks) { "GAME_CONTENT_ROOT" } else { "SCRIPT_DIRECTORY_ONLY" }))
[void]$lines.Add("Privacy=relative_paths_only; no hosts; no saves; no external uploads")
[void]$lines.Add("Mutation=report_file_only; game_files_unchanged")
[void]$lines.Add("REACT_HINT=settings,character-select")
[void]$lines.Add("COHERENT_HINT=UE_DATABRIDGE")
[void]$lines.Add("")
$all = @()
try {
    $all = @(Get-ChildItem -LiteralPath $root -Recurse -File -ErrorAction SilentlyContinue)
}
catch {
    [void]$lines.Add("EnumerationWarning=some_files_not_accessible")
}
function RelName([System.IO.FileInfo]$file) {
    $p = $file.FullName
    if ($p.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $p.Substring($root.Length).TrimStart([char]'\',[char]'/')
    }
    return "[UNAVAILABLE]"
}
function SizeLabel([long]$length) {
    return [string]([math]::Round($length / 1MB, 2)) + "MB"
}
$packs = @($all | Where-Object { $_.Extension -in @(".pak",".ucas",".utoc") } | Sort-Object FullName)
[void]$lines.Add("PACKAGED_GAME_DATA count=" + $packs.Count)
foreach ($f in ($packs | Select-Object -First 100)) {
    [void]$lines.Add("PACKAGE " + (RelName $f) + " size=" + (SizeLabel $f.Length))
}
if ($packs.Count -gt 100) { [void]$lines.Add("PACKAGE_LIST_TRUNCATED excess=" + ($packs.Count - 100)) }
[void]$lines.Add("")
# Match file names without reading proprietary cooked asset content.
$assetRx = '(?i)(coherent|react|frontend|ui[_/-]|cosmetic|skin|character.select|character_select|menu|bridge|bundle|widget)'
$assetNames = @($all | Where-Object {
    $_.Extension -in @(".uasset",".uexp",".ubulk",".html",".htm",".js",".css",".json",".map",".xml") -and
    ($_.Name -match $assetRx -or $_.DirectoryName -match '(?i)[\\/](?:Coherent|Frontend|UI|Menus|React)[\\/]')
} | Sort-Object FullName)
[void]$lines.Add("FRONTEND_NAMED_ASSETS count=" + $assetNames.Count)
foreach ($f in ($assetNames | Select-Object -First 180)) {
    [void]$lines.Add("ASSET " + (RelName $f) + " size=" + (SizeLabel $f.Length))
}
if ($assetNames.Count -gt 180) { [void]$lines.Add("ASSET_LIST_TRUNCATED excess=" + ($assetNames.Count - 180)) }
[void]$lines.Add("")
# Search small, loose frontend text files for marker NAMES ONLY.
# No contents or surrounding lines are copied to the report.
$textExtensions = @(".js",".json",".html",".htm",".css",".map",".xml")
$sourceFiles = @($all | Where-Object {
    $_.Extension -in $textExtensions -and $_.Length -le 12582912 -and
    $_.FullName -notmatch '(?i)[\\/]ue4ss[\\/]'
} | Sort-Object FullName)
$tokens = @("UE_DATABRIDGE","character-select","ReactCharacterSelectURL",
    "ReactSettingsURL","cosmetics/collection","MacrosCosmetic",
    "CoherentUIGT","gratitude","Hinterclaw")
$totalHits = 0
$checked = 0
[void]$lines.Add("LOOSE_TEXT_FILE_SCAN available=" + $sourceFiles.Count + " max_files=300")
foreach ($f in ($sourceFiles | Select-Object -First 300)) {
    $checked++
    try {
        $text = [System.IO.File]::ReadAllText($f.FullName)
        $hits = New-Object 'System.Collections.Generic.List[string]'
        foreach ($token in $tokens) {
            if ($text.IndexOf($token,[System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
                [void]$hits.Add($token)
            }
        }
        if ($hits.Count -gt 0) {
            $totalHits++
            [void]$lines.Add("TEXT_MARKERS " + (RelName $f) + " matches=" + ($hits -join ","))
        }
    }
    catch {
        [void]$lines.Add("TEXT_SCAN_SKIPPED " + (RelName $f))
    }
}
[void]$lines.Add("TEXT_SCAN_SUMMARY checked=" + $checked + " matched_files=" + $totalHits)
if ($sourceFiles.Count -gt 300) {
    [void]$lines.Add("TEXT_SCAN_TRUNCATED excess=" + ($sourceFiles.Count - 300))
}
[void]$lines.Add("")
if ($assetNames.Count -eq 0 -and $totalHits -eq 0 -and $packs.Count -gt 0) {
    [void]$lines.Add("NEXT_STEP=Frontend_data_probably_packaged_in_PAK_or_IoStore; manifest_or_targeted_extraction_needed")
} elseif ($totalHits -gt 0) {
    [void]$lines.Add("NEXT_STEP=Inspect_only_marked_loose_frontend_resources")
} else {
    [void]$lines.Add("NEXT_STEP=Inspect_named_assets_or_package_index_before_any_new_in_game_scans")
}
[void]$lines.Add("END_REPORT")
[System.IO.File]::WriteAllLines($report,$lines,[System.Text.Encoding]::UTF8)
Write-Host "H35: report written: GodfallFrontendAssetsReport.txt"
Write-Host "Packages:" $packs.Count "  Named assets:" $assetNames.Count "  Marker files:" $totalHits
Write-Host "Send the report file only. No game files were modified."
