# Flattens nested-SVG structure produced by DiceBear style=circle avataaars.
# flutter_svg 2.x does not support nested <svg> elements, so the wrapper
# that adds the outer circle clip is stripped. Visual rounding is reinstated
# via ClipOval in the AvatarImage widget.
#
# Run from project root:
#   powershell -ExecutionPolicy Bypass -File tool/flatten_avatars.ps1

$ErrorActionPreference = 'Stop'

$dir = Join-Path $PSScriptRoot '..\assets\avatars'
$dir = (Resolve-Path $dir).Path
$files = Get-ChildItem -Path $dir -Filter 'avatar_*.svg'
Write-Host "Flattening $($files.Count) avatar SVGs in $dir"

$wrapperOpen = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512"><defs><clipPath id="fc"><circle cx="256" cy="256" r="256"></circle></clipPath></defs><g clip-path="url(#fc)">'
$wrapperClose = '</g></svg>'
$injected = '<svg xmlns="http://www.w3.org/2000/svg" viewBox='

$ok = 0
$skip = 0
foreach ($f in $files) {
  $content = Get-Content -Path $f.FullName -Raw -Encoding UTF8
  if (-not $content.StartsWith($wrapperOpen)) {
    Write-Host "  [skip] $($f.Name) - no outer wrapper"
    $skip++
    continue
  }
  $stripped = $content.Substring($wrapperOpen.Length)
  if ($stripped.EndsWith($wrapperClose)) {
    $stripped = $stripped.Substring(0, $stripped.Length - $wrapperClose.Length)
  }
  $stripped = $stripped -replace '^<svg viewBox=', $injected
  [System.IO.File]::WriteAllText($f.FullName, $stripped, [System.Text.UTF8Encoding]::new($false))
  $ok++
  Write-Host "  [ok]   $($f.Name)"
}

Write-Host ""
Write-Host "Done - $ok flattened, $skip skipped." -ForegroundColor Green
