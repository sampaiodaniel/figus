param(
    [string]$Message = "Deploy web build"
)

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot

Write-Host "Building Flutter web..." -ForegroundColor Cyan
Set-Location $root
& C:\flutter\bin\flutter.bat build web --release --base-href /figus/
if ($LASTEXITCODE -ne 0) { throw "Build failed" }

# Clean up any stale worktree
if (Test-Path "$root\.ghpages") {
    git worktree remove --force .ghpages 2>$null
    Remove-Item -Recurse -Force "$root\.ghpages" -ErrorAction SilentlyContinue
}
git branch -D deploy-temp 2>$null

Write-Host "Deploying to gh-pages..." -ForegroundColor Cyan
git fetch origin gh-pages
git worktree add .ghpages -b deploy-temp origin/gh-pages

Get-ChildItem .ghpages -Exclude ".git" | Remove-Item -Recurse -Force
Get-ChildItem build\web | Copy-Item -Destination .ghpages -Recurse -Force

Set-Location .ghpages
git add -A
git commit -m $Message
git push origin HEAD:gh-pages

Set-Location $root
git worktree remove .ghpages
git branch -D deploy-temp 2>$null

Write-Host "Done! https://sampaiodaniel.github.io/figus/" -ForegroundColor Green
