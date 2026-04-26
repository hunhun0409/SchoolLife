Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$outDir = Join-Path $root "game\resources\ui\panels"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

function New-Color([string]$hex, [int]$alpha = 255) {
    $h = $hex.TrimStart("#")
    return [System.Drawing.Color]::FromArgb(
        $alpha,
        [Convert]::ToInt32($h.Substring(0, 2), 16),
        [Convert]::ToInt32($h.Substring(2, 2), 16),
        [Convert]::ToInt32($h.Substring(4, 2), 16)
    )
}

function New-RoundRectPath([float]$x, [float]$y, [float]$w, [float]$h, [float]$r) {
    $path = [System.Drawing.Drawing2D.GraphicsPath]::new()
    $d = $r * 2.0
    $path.AddArc($x, $y, $d, $d, 180, 90)
    $path.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
    $path.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
    $path.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
    $path.CloseFigure()
    return $path
}

function Save-Panel(
    [string]$name,
    [string]$top,
    [string]$bottom,
    [string]$border,
    [string]$accent,
    [int]$borderWidth,
    [int]$radius,
    [int]$shadowAlpha,
    [bool]$titleSheen
) {
    $size = 128
    $scale = 4
    $canvas = $size * $scale
    $bmp = [System.Drawing.Bitmap]::new($canvas, $canvas, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.Clear([System.Drawing.Color]::FromArgb(0, 0, 0, 0))

    $outer = New-RoundRectPath 8 8 ($canvas - 16) ($canvas - 18) ($radius * $scale)
    $shadow = New-RoundRectPath 10 14 ($canvas - 20) ($canvas - 20) ($radius * $scale)
    $inner = New-RoundRectPath (8 + $borderWidth * $scale) (8 + $borderWidth * $scale) ($canvas - 16 - $borderWidth * 2 * $scale) ($canvas - 18 - $borderWidth * 2 * $scale) (($radius - $borderWidth) * $scale)

    $shadowBrush = [System.Drawing.SolidBrush]::new((New-Color "#1F6FD6" $shadowAlpha))
    $g.FillPath($shadowBrush, $shadow)

    $borderBrush = [System.Drawing.SolidBrush]::new((New-Color $border 235))
    $g.FillPath($borderBrush, $outer)

    $fillBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
        [System.Drawing.RectangleF]::new(0, 0, $canvas, $canvas),
        (New-Color $top 232),
        (New-Color $bottom 238),
        [System.Drawing.Drawing2D.LinearGradientMode]::Vertical
    )
    $g.FillPath($fillBrush, $inner)

    $highlightPath = New-RoundRectPath (14 * $scale) (14 * $scale) (($size - 28) * $scale) (26 * $scale) (($radius - 5) * $scale)
    $highlightBrush = [System.Drawing.SolidBrush]::new((New-Color "#FFFFFF" 78))
    $g.FillPath($highlightBrush, $highlightPath)

    if ($titleSheen) {
        $accentPen = [System.Drawing.Pen]::new((New-Color $accent 170), 2.0 * $scale)
        $g.DrawLine($accentPen, 24 * $scale, 27 * $scale, 104 * $scale, 27 * $scale)
        $accentPen.Dispose()
    }

    $innerLinePen = [System.Drawing.Pen]::new((New-Color "#FFFFFF" 155), 1.0 * $scale)
    $g.DrawPath($innerLinePen, $inner)

    $outerLinePen = [System.Drawing.Pen]::new((New-Color "#1F6FD6" 115), 1.0 * $scale)
    $g.DrawPath($outerLinePen, $outer)

    $small = [System.Drawing.Bitmap]::new($size, $size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $sg = [System.Drawing.Graphics]::FromImage($small)
    $sg.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $sg.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $sg.DrawImage($bmp, 0, 0, $size, $size)

    $path = Join-Path $outDir $name
    $small.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)

    $sg.Dispose()
    $small.Dispose()
    $outerLinePen.Dispose()
    $innerLinePen.Dispose()
    $highlightBrush.Dispose()
    $fillBrush.Dispose()
    $borderBrush.Dispose()
    $shadowBrush.Dispose()
    $outer.Dispose()
    $shadow.Dispose()
    $inner.Dispose()
    $highlightPath.Dispose()
    $g.Dispose()
    $bmp.Dispose()
}

$panels = @(
    @{ Name = "panel_popup_blue.png"; Top = "#F7FBFF"; Bottom = "#CFEAFF"; Border = "#4CB8FF"; Accent = "#36E2FF"; BorderWidth = 3; Radius = 18; ShadowAlpha = 46; TitleSheen = $true },
    @{ Name = "panel_dialogue_soft.png"; Top = "#F7FBFF"; Bottom = "#DDF1FF"; Border = "#A8E1FF"; Accent = "#5EE6FF"; BorderWidth = 2; Radius = 16; ShadowAlpha = 34; TitleSheen = $false },
    @{ Name = "panel_card_light.png"; Top = "#FFFFFF"; Bottom = "#EAF6FF"; Border = "#CFEAFF"; Accent = "#7FD2FF"; BorderWidth = 2; Radius = 14; ShadowAlpha = 24; TitleSheen = $false },
    @{ Name = "panel_accent_cyan.png"; Top = "#EAF6FF"; Bottom = "#A8E1FF"; Border = "#00C6FF"; Accent = "#2D9CFF"; BorderWidth = 3; Radius = 16; ShadowAlpha = 42; TitleSheen = $true }
)

foreach ($panel in $panels) {
    Save-Panel `
        -name $panel.Name `
        -top $panel.Top `
        -bottom $panel.Bottom `
        -border $panel.Border `
        -accent $panel.Accent `
        -borderWidth $panel.BorderWidth `
        -radius $panel.Radius `
        -shadowAlpha $panel.ShadowAlpha `
        -titleSheen $panel.TitleSheen
}

Write-Host "Generated UI panel textures in $outDir"
Write-Host "Recommended Godot 9-slice/StyleBoxTexture margins: left=24, top=24, right=24, bottom=24"
