Add-Type -AssemblyName System.Drawing

$projectRoot = Split-Path -Parent $PSScriptRoot
$assetsDir = Join-Path $projectRoot 'assets\branding'
$androidResDir = Join-Path $projectRoot 'android\app\src\main\res'

New-Item -ItemType Directory -Force -Path $assetsDir | Out-Null

function New-RoundedRectPath {
    param(
        [float]$X,
        [float]$Y,
        [float]$Width,
        [float]$Height,
        [float]$Radius
    )

    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $diameter = $Radius * 2

    $path.AddArc($X, $Y, $diameter, $diameter, 180, 90)
    $path.AddArc($X + $Width - $diameter, $Y, $diameter, $diameter, 270, 90)
    $path.AddArc(
        $X + $Width - $diameter,
        $Y + $Height - $diameter,
        $diameter,
        $diameter,
        0,
        90
    )
    $path.AddArc($X, $Y + $Height - $diameter, $diameter, $diameter, 90, 90)
    $path.CloseFigure()

    return $path
}

function New-BrandBitmap {
    param([int]$Size)

    $bitmap = New-Object System.Drawing.Bitmap($Size, $Size)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    $graphics.Clear([System.Drawing.Color]::FromArgb(11, 11, 13))

    $outerMargin = [int]($Size * 0.09)
    $panelSize = $Size - ($outerMargin * 2)
    $shadowOffset = [int]($Size * 0.018)
    $panelRadius = [int]($Size * 0.18)

    $shadowPath = New-RoundedRectPath `
        -X ($outerMargin + $shadowOffset) `
        -Y ($outerMargin + $shadowOffset) `
        -Width $panelSize `
        -Height $panelSize `
        -Radius $panelRadius
    $shadowBrush = New-Object System.Drawing.SolidBrush(
        [System.Drawing.Color]::FromArgb(72, 0, 0, 0)
    )
    $graphics.FillPath($shadowBrush, $shadowPath)

    $panelPath = New-RoundedRectPath `
        -X $outerMargin `
        -Y $outerMargin `
        -Width $panelSize `
        -Height $panelSize `
        -Radius $panelRadius

    $gradientBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        [System.Drawing.PointF]::new($outerMargin, $outerMargin),
        [System.Drawing.PointF]::new($Size - $outerMargin, $Size - $outerMargin),
        [System.Drawing.Color]::FromArgb(112, 12, 26),
        [System.Drawing.Color]::FromArgb(239, 47, 79)
    )

    $blend = New-Object System.Drawing.Drawing2D.ColorBlend
    $blend.Colors = @(
        [System.Drawing.Color]::FromArgb(52, 8, 16),
        [System.Drawing.Color]::FromArgb(126, 18, 35),
        [System.Drawing.Color]::FromArgb(239, 47, 79)
    )
    $blend.Positions = @(0.0, 0.58, 1.0)
    $gradientBrush.InterpolationColors = $blend

    $graphics.FillPath($gradientBrush, $panelPath)

    $strokePen = New-Object System.Drawing.Pen(
        [System.Drawing.Color]::FromArgb(62, 255, 255, 255),
        [Math]::Max(4, [int]($Size * 0.008))
    )
    $graphics.DrawPath($strokePen, $panelPath)

    $innerStrokePath = New-RoundedRectPath `
        -X ($outerMargin + [int]($Size * 0.03)) `
        -Y ($outerMargin + [int]($Size * 0.03)) `
        -Width ($panelSize - [int]($Size * 0.06)) `
        -Height ($panelSize - [int]($Size * 0.06)) `
        -Radius ([int]($panelRadius * 0.72))
    $innerPen = New-Object System.Drawing.Pen(
        [System.Drawing.Color]::FromArgb(24, 255, 255, 255),
        [Math]::Max(2, [int]($Size * 0.004))
    )
    $graphics.DrawPath($innerPen, $innerStrokePath)

    $letterColor = [System.Drawing.Color]::FromArgb(252, 246, 242)
    $letterShadow = New-Object System.Drawing.SolidBrush(
        [System.Drawing.Color]::FromArgb(78, 0, 0, 0)
    )
    $letterBrush = New-Object System.Drawing.SolidBrush($letterColor)
    $badgeFill = New-Object System.Drawing.SolidBrush(
        [System.Drawing.Color]::FromArgb(195, 17, 17, 21)
    )
    $badgeStroke = New-Object System.Drawing.Pen(
        [System.Drawing.Color]::FromArgb(48, 255, 255, 255),
        [Math]::Max(3, [int]($Size * 0.006))
    )

    $fontName = 'Segoe UI Semibold'
    $fontRSize = [float]($Size * 0.48)
    $fontOneSize = [float]($Size * 0.17)
    $fontR = New-Object System.Drawing.Font(
        $fontName,
        $fontRSize,
        [System.Drawing.FontStyle]::Bold,
        [System.Drawing.GraphicsUnit]::Pixel
    )
    $fontOne = New-Object System.Drawing.Font(
        $fontName,
        $fontOneSize,
        [System.Drawing.FontStyle]::Bold,
        [System.Drawing.GraphicsUnit]::Pixel
    )

    $format = New-Object System.Drawing.StringFormat
    $format.Alignment = [System.Drawing.StringAlignment]::Center
    $format.LineAlignment = [System.Drawing.StringAlignment]::Center

    $rRect = [System.Drawing.RectangleF]::new(
        $Size * 0.13,
        $Size * 0.15,
        $Size * 0.50,
        $Size * 0.58
    )
    $rShadowRect = [System.Drawing.RectangleF]::new(
        $rRect.X + ($Size * 0.012),
        $rRect.Y + ($Size * 0.012),
        $rRect.Width,
        $rRect.Height
    )
    $graphics.DrawString('R', $fontR, $letterShadow, $rShadowRect, $format)
    $graphics.DrawString('R', $fontR, $letterBrush, $rRect, $format)

    $badgeDiameter = $Size * 0.27
    $badgeRect = [System.Drawing.RectangleF]::new(
        $Size * 0.57,
        $Size * 0.20,
        $badgeDiameter,
        $badgeDiameter
    )
    $graphics.FillEllipse($badgeFill, $badgeRect)
    $graphics.DrawEllipse($badgeStroke, $badgeRect)

    $oneRect = [System.Drawing.RectangleF]::new(
        $badgeRect.X,
        $badgeRect.Y + ($Size * 0.01),
        $badgeRect.Width,
        $badgeRect.Height
    )
    $graphics.DrawString('1', $fontOne, $letterBrush, $oneRect, $format)

    $accentBrush = New-Object System.Drawing.SolidBrush(
        [System.Drawing.Color]::FromArgb(48, 255, 255, 255)
    )
    $graphics.FillRectangle(
        $accentBrush,
        [System.Drawing.RectangleF]::new(
            $Size * 0.19,
            $Size * 0.73,
            $Size * 0.34,
            $Size * 0.022
        )
    )

    $graphics.Dispose()
    $shadowPath.Dispose()
    $panelPath.Dispose()
    $innerStrokePath.Dispose()
    $shadowBrush.Dispose()
    $gradientBrush.Dispose()
    $strokePen.Dispose()
    $innerPen.Dispose()
    $letterShadow.Dispose()
    $letterBrush.Dispose()
    $badgeFill.Dispose()
    $badgeStroke.Dispose()
    $accentBrush.Dispose()
    if ($null -ne $fontR) {
        $fontR.Dispose()
    }
    if ($null -ne $fontOne) {
        $fontOne.Dispose()
    }
    $format.Dispose()

    return $bitmap
}

function Save-ScaledPng {
    param(
        [System.Drawing.Bitmap]$Source,
        [int]$Size,
        [string]$Path
    )

    $target = New-Object System.Drawing.Bitmap($Size, $Size)
    $graphics = [System.Drawing.Graphics]::FromImage($target)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.DrawImage($Source, 0, 0, $Size, $Size)
    $graphics.Dispose()

    $directory = Split-Path -Parent $Path
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
    $target.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    $target.Dispose()
}

$brandBitmap = New-BrandBitmap -Size 1024
$brandAssetPath = Join-Path $assetsDir 'r1_mark.png'
$brandBitmap.Save($brandAssetPath, [System.Drawing.Imaging.ImageFormat]::Png)

$iconTargets = @{
    'mipmap-mdpi' = 48
    'mipmap-hdpi' = 72
    'mipmap-xhdpi' = 96
    'mipmap-xxhdpi' = 144
    'mipmap-xxxhdpi' = 192
}

foreach ($folder in $iconTargets.Keys) {
    $targetPath = Join-Path $androidResDir "$folder\ic_launcher.png"
    Save-ScaledPng -Source $brandBitmap -Size $iconTargets[$folder] -Path $targetPath
}

$brandBitmap.Dispose()
Write-Output "Generated brand asset: $brandAssetPath"
