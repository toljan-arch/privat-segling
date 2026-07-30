@echo off
title Update Site (Photos & Music)
powershell -NoProfile -ExecutionPolicy Bypass -Command "& {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $projectRoot = Split-Path -Parent $scriptDir
    $htmlFile = Join-Path $projectRoot 'index.html'

    Write-Host '=== Site Updater (Photos & Music) ===' -ForegroundColor Cyan

    # Sailing-themed names for both images and audio
    $sailingNames = @(
        'sunset-sail', 'harbor-view', 'calm-waters', 'morning-breeze', 'distant-horizon', 
        'golden-hour', 'peaceful-sea', 'wind-and-wave', 'open-water', 'twilight-cruise', 
        'blue-lagoon', 'sea-mist', 'anchor-drop', 'tide-turning', 'coastal-light', 
        'sail-unfurled', 'quiet-bay', 'dawn-patrol', 'starlit-sea', 'gentle-current'
    )

    # === 1. PROCESS IMAGES ===
    $imagesDir = Join-Path $projectRoot 'images'
    if (Test-Path $imagesDir) {
        Write-Host '' -ForegroundColor White
        Write-Host '[Images]' -ForegroundColor Yellow
        
        $existingCount = (Get-ChildItem $imagesDir | Where-Object { $_.Name -match '^(' + ($sailingNames -join '|') + ')' }).Count
        $nextIdx = $existingCount

        $newPhotos = Get-ChildItem -Path $imagesDir | Where-Object { 
            $_.Extension.ToLower() -match '\.(jpg|jpeg|png|webp)' -and 
            ($_.Name -match '^IMG_' -or $_.Name -match '^DSC' -or $_.Name -match '^P')
        } | Sort-Object Name

        foreach ($photo in $newPhotos) {
            $nameIdx = $nextIdx % $sailingNames.Length
            $baseName = $sailingNames[$nameIdx]
            if ($nextIdx -ge $sailingNames.Length) { $suffix = [math]::Floor($nextIdx / $sailingNames.Length) + 1; $baseName = "${baseName}-${suffix}" }
            
            $newName = "$baseName$($photo.Extension)"
            $counter = 1
            while (Test-Path (Join-Path $imagesDir $newName)) { $newName = "${baseName}-${counter}$($photo.Extension)"; $counter++ }

            Rename-Item -LiteralPath $photo.FullName -NewName $newName
            Write-Host "  $($photo.Name) -> $newName" -ForegroundColor Green
            $nextIdx++
        }
    }

    # === 2. PROCESS AUDIO ===
    $audioDir = Join-Path $projectRoot 'audio'
    if (Test-Path $audioDir) {
        Write-Host '' -ForegroundColor White
        Write-Host '[Audio]' -ForegroundColor Yellow
        
        $existingCount = (Get-ChildItem $audioDir | Where-Object { $_.Name -match '^(' + ($sailingNames -join '|') + ')' }).Count
        $nextIdx = $existingCount

        $newTracks = Get-ChildItem -Path $audioDir | Where-Object { 
            $_.Extension.ToLower() -match '\.(mp3|m4a|ogg|wav)' -and 
            ($_.Name -match '^IMG_' -or $_.Name -match '^DSC' -or $_.Name -match '^P' -or $_.Name -match '^\d')
        } | Sort-Object Name

        foreach ($track in $newTracks) {
            $nameIdx = $nextIdx % $sailingNames.Length
            $baseName = $sailingNames[$nameIdx]
            if ($nextIdx -ge $sailingNames.Length) { $suffix = [math]::Floor($nextIdx / $sailingNames.Length) + 1; $baseName = "${baseName}-${suffix}" }
            
            $newName = "$baseName$($track.Extension)"
            $counter = 1
            while (Test-Path (Join-Path $audioDir $newName)) { $newName = "${baseName}-${counter}$($track.Extension)"; $counter++ }

            Rename-Item -LiteralPath $track.FullName -NewName $newName
            Write-Host "  $($track.Name) -> $newName" -ForegroundColor Green
            $nextIdx++
        }
    }

    # === 3. UPDATE index.html ARRAYS ===
    $htmlContent = Get-Content $htmlFile -Raw -Encoding UTF8

    # Update galleryImages array
    if (Test-Path $imagesDir) {
        $allImages = Get-ChildItem -Path $imagesDir | Where-Object { $_.Extension.ToLower() -match '\.(jpg|jpeg|png|webp)' } | Sort-Object Name
        $imgList = ($allImages.Name | ForEach-Object { "            '$_'," }) -join "`n"
        $newImgArray = @"
        const galleryImages = [
$imgList
        ];
"@
        $htmlContent = $htmlContent -replace '(const\s+galleryImages\s*=\s*\[)[\s\S]*?(\];)', "`${1}`n$newImgArray.Trim()`n`${2}"
    }

    # Update audioTracks array
    if (Test-Path $audioDir) {
        $allAudio = Get-ChildItem -Path $audioDir | Where-Object { $_.Extension.ToLower() -match '\.(mp3|m4a|ogg|wav)' } | Sort-Object Name
        $audList = ($allAudio.Name | ForEach-Object { "            '$_'," }) -join "`n"
        $newAudArray = @"
        const audioTracks = [
$audList
        ];
"@
        $htmlContent = $htmlContent -replace '(const\s+audioTracks\s*=\s*\[)[\s\S]*?(\];)', "`${1}`n$newAudArray.Trim()`n`${2}"
    }

    Set-Content -Path $htmlFile -Value $htmlContent -Encoding UTF8 -NoNewline
    Write-Host '' -ForegroundColor White
    Write-Host 'index.html updated.' -ForegroundColor Green

    # === 4. GIT COMMIT & PUSH ===
    Set-Location $projectRoot
    git add .
    git commit -m 'Update site with new photos and music'
    git push
    
    Write-Host ''
    Write-Host 'Done! Site is live.' -ForegroundColor Green
}"
pause
