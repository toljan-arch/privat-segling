# Rename camera photos to sailing-themed names and update gallery in index.html
# Usage: .\update-gallery.ps1 "C:\path\to\your\photos"

param(
    [Parameter(Mandatory=$true)]
    [string]$PhotoFolder
)

$imagesDir = Join-Path $PSScriptRoot "images"
$htmlFile = Join-Path $PSScriptRoot "index.html"

# Beautiful sailing-themed names (Swedish + English mix)
$sailingNames = @(
    "sunset-sail",
    "harbor-view", 
    "calm-waters",
    "morning-breeze",
    "distant-horizon",
    "golden-hour",
    "peaceful-sea",
    "wind-and-wave",
    "open-water",
    "twilight-cruise",
    "blue-lagoon",
    "sea-mist",
    "anchor-drop",
    "tide-turning",
    "coastal-light",
    "sail-unfurled",
    "quiet-bay",
    "dawn-patrol",
    "starlit-sea",
    "gentle-current"
)

# Get all image files from source folder
$extensions = @('.jpg', '.jpeg', '.png', '.webp')
$photos = Get-ChildItem -Path $PhotoFolder | Where-Object { 
    $_.Extension.ToLower() -in $extensions 
} | Sort-Object Name

if ($photos.Count -eq 0) {
    Write-Host "No photos found in $PhotoFolder" -ForegroundColor Red
    exit 1
}

Write-Host "Found $($photos.Count) photo(s)" -ForegroundColor Green

# Create images directory if it doesn't exist
if (-not (Test-Path $imagesDir)) {
    New-Item -ItemType Directory -Path $imagesDir | Out-Null
}

$galleryList = @()

for ($i = 0; $i -lt $photos.Count; $i++) {
    $photo = $photos[$i]
    
    # Get sailing name (cycle through if we have more photos than names)
    $nameIndex = $i % $sailingNames.Length
    $baseName = $sailingNames[$nameIndex]
    
    # Add number suffix if we exceed the list
    if ($i -ge $sailingNames.Length) {
        $suffix = [math]::Floor($i / $sailingNames.Length) + 1
        $baseName = "${baseName}-${suffix}"
    }
    
    $newName = "$baseName$($photo.Extension)"
    $destPath = Join-Path $imagesDir $newName
    
    # Copy and rename
    Copy-Item -Path $photo.FullName -Destination $destPath -Force
    
    Write-Host "  $($photo.Name) -> $newName" -ForegroundColor Cyan
    $galleryList += "`"$newName`","
}

# Update galleryImages array in index.html
$htmlContent = Get-Content $htmlFile -Raw -Encoding UTF8

$newArray = @"
        const galleryImages = [
            $($galleryList -join "`n            ")
        ];
"@

# Replace the galleryImages array
$htmlContent = $htmlContent -replace '(const galleryImages = \[)[^\]]*\];', $newArray.Trim()

Set-Content -Path $htmlFile -Value $htmlContent -Encoding UTF8 -NoNewline

Write-Host "`nGallery updated with $($photos.Count) photo(s)" -ForegroundColor Green
Write-Host "Now run: git add . && git commit -m 'Add photos' && git push" -ForegroundColor Yellow
