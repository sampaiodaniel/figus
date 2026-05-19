# Generates the OpenGraph card (1200x630) shown as the WhatsApp/Twitter
# link preview. Dark Figus background with the gold logo on the left and
# brand text on the right — matches the Figuritas-style preview Daniel
# asked for ("logo menor, fundo preto, mensagem ao final").

Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$logoPath = Join-Path $root "assets\figus-logo-square.png"
$outAssets = Join-Path $root "assets\figus-og-card.png"
$outWeb = Join-Path $root "web\figus-og-card.png"

$logo = [System.Drawing.Image]::FromFile($logoPath)

$bmp = New-Object System.Drawing.Bitmap 1200, 630
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

# Background — Figus brand dark.
$bgColor = [System.Drawing.Color]::FromArgb(255, 19, 16, 14)
$bgBrush = New-Object System.Drawing.SolidBrush $bgColor
$g.FillRectangle($bgBrush, 0, 0, 1200, 630)

# Subtle gold ring on the left half (like a stadium spotlight) so the
# layout feels designed, not flat.
$ringColor = [System.Drawing.Color]::FromArgb(40, 229, 177, 75)
$ringBrush = New-Object System.Drawing.SolidBrush $ringColor
$g.FillEllipse($ringBrush, -120, 65, 500, 500)

# Logo on the left.
$logoSize = 280
$logoX = 80
$logoY = (630 - $logoSize) / 2
$g.DrawImage($logo, $logoX, $logoY, $logoSize, $logoSize)

# Brand text on the right.
$titleFont = New-Object System.Drawing.Font ("Segoe UI", 72, [System.Drawing.FontStyle]::Bold)
$subFont = New-Object System.Drawing.Font ("Segoe UI", 30, [System.Drawing.FontStyle]::Regular)
$mutedFont = New-Object System.Drawing.Font ("Segoe UI", 22, [System.Drawing.FontStyle]::Regular)

$goldBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 229, 177, 75))
$whiteBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 245, 240, 232))
$mutedBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 154, 143, 130))

$textX = 440

$g.DrawString("Figus", $titleFont, $goldBrush, $textX, 175)
$g.DrawString("Controle sua coleção", $subFont, $whiteBrush, $textX, 285)
$g.DrawString("de figurinhas", $subFont, $whiteBrush, $textX, 330)
$g.DrawString("Copa 2026  ·  grátis  ·  offline", $mutedFont, $mutedBrush, $textX, 410)

# Save (twice — assets for the app, web for the OG preview).
$bmp.Save($outAssets, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Save($outWeb, [System.Drawing.Imaging.ImageFormat]::Png)

$g.Dispose()
$bmp.Dispose()
$logo.Dispose()
Write-Host "Saved: $outAssets"
Write-Host "Saved: $outWeb"
