# >>> SLMN PROFILE SCRIPT BEGIN >>>
# ============================================
# SLMN FRONTEND STARTERS
# ============================================
# Usage:
#   . .\starters.ps1
#
#   slmn-starter
#
#   slmn-app "my-app"
#
#   slmn-full "my-app"
#
#   vanilla-project "my-site"
#   tailwind-project "tailwind-demo"
#   gsap-project "gsap-hero"
#   tailwind-gsap-project "animated"
#   react-project "portfolio"
#   react-ts-project "portfolio"
#   react-tailwind-gsap-project "motion-app"
#   react-tailwind-ts-project "typed-tailwind"
#   react-tailwind-gsap-ts-project "typed-motion"
#   react-tailwind-gsap-three-ts-project "typed-3d"
#   slmn-ts-app "typed-app"
#   vite-app "my-app"
#   next-app "my-next-app"
#   next-ts-app "my-next-ts-app"
# ============================================

$script:SlmnSourcePath = $PSCommandPath

function Get-SlmnInstallDirectory {
    if ([string]::IsNullOrWhiteSpace($env:USERPROFILE)) {
        throw 'USERPROFILE is not available; SLMN cannot determine its installation directory.'
    }

    return (Join-Path $env:USERPROFILE '.slmn')
}

function Get-SlmnConfigPath {
    return (Join-Path (Get-SlmnInstallDirectory) 'config.json')
}

function Initialize-SlmnStorage {
    $installDirectory = Get-SlmnInstallDirectory
    $configPath = Get-SlmnConfigPath

    New-Item -ItemType Directory -Path $installDirectory -Force | Out-Null
    if (-not (Test-Path -LiteralPath $configPath)) {
        @'
{
    "projectsPath": "%USERPROFILE%\\Desktop",
    "defaultStarter": "slmn-app",
    "openInVSCode": true,
    "autoStartDev": true
}
'@ | Set-Content -LiteralPath $configPath -Encoding utf8
    }

    return $configPath
}

function Get-SlmnConfiguration {
    $configPath = Initialize-SlmnStorage
    try {
        return (Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json)
    } catch {
        throw "SLMN configuration is invalid: $configPath. $($_.Exception.Message)"
    }
}

function Get-SlmnProjectsPath {
    param([string]$OverridePath)

    $projectsPath = if ([string]::IsNullOrWhiteSpace($OverridePath)) {
        (Get-SlmnConfiguration).projectsPath
    } else {
        $OverridePath
    }
    if ([string]::IsNullOrWhiteSpace($projectsPath)) {
        throw 'The SLMN projects path is empty. Set one with: slmn-config path "D:\Projects"'
    }

    $expandedPath = [Environment]::ExpandEnvironmentVariables($projectsPath)
    $resolvedPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($expandedPath)
    New-Item -ItemType Directory -Path $resolvedPath -Force | Out-Null
    return (Resolve-Path -LiteralPath $resolvedPath).Path
}

function slmn-config {
    param(
        [string]$Setting,
        [string]$Value
    )

    $configPath = Initialize-SlmnStorage
    $configuration = Get-SlmnConfiguration
    if ([string]::IsNullOrWhiteSpace($Setting)) {
        $configuration | ConvertTo-Json -Depth 3
        return
    }

    if ($Setting -ieq 'path' -or $Setting -ieq 'projectsPath') {
        if ([string]::IsNullOrWhiteSpace($Value)) {
            throw 'Provide a projects path. Example: slmn-config path "D:\Projects"'
        }

        $configuration.projectsPath = if ($Value -ieq 'desktop') { '%USERPROFILE%\Desktop' } else { $Value.Trim() }
        Get-SlmnProjectsPath -OverridePath $configuration.projectsPath | Out-Null
        $configuration | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath $configPath -Encoding utf8
        Write-Host "SLMN projects path: $(Get-SlmnProjectsPath)" -ForegroundColor Green
        return
    }

    if ([string]::IsNullOrWhiteSpace($Value)) {
        throw "Provide a value for '$Setting'. Use true/false, yes/no, or on/off."
    }

    $propertyName = if ($Setting -ieq 'openInVSCode') {
        'openInVSCode'
    } elseif ($Setting -ieq 'autoStartDev') {
        'autoStartDev'
    } else {
        throw 'Supported settings: path, openInVSCode, autoStartDev.'
    }

    $booleanValue = switch ($Value.Trim().ToLowerInvariant()) {
        { $_ -in @('true', 'yes', 'on', '1') } { $true; break }
        { $_ -in @('false', 'no', 'off', '0') } { $false; break }
        default { throw "Invalid value '$Value'. Use true/false, yes/no, or on/off." }
    }
    $configuration.$propertyName = $booleanValue
    $configuration | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath $configPath -Encoding utf8
    Write-Host "$propertyName`: $booleanValue" -ForegroundColor Green
}

function Get-SlmnProfilePath {
    $profilePaths = @($PROFILE, $PROFILE.CurrentUserAllHosts) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique
    $sourcePath = $script:SlmnSourcePath
    if (-not [string]::IsNullOrWhiteSpace($sourcePath) -and (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
        $resolvedSourcePath = (Resolve-Path -LiteralPath $sourcePath).Path
        foreach ($profilePath in $profilePaths) {
            $resolvedProfilePath = (Resolve-Path -LiteralPath $profilePath -ErrorAction SilentlyContinue).Path
            if ($resolvedSourcePath -ieq $resolvedProfilePath) {
                return $resolvedProfilePath
            }
        }
    }

    foreach ($profilePath in $profilePaths) {
        if (-not (Test-Path -LiteralPath $profilePath -PathType Leaf)) {
            continue
        }
        $content = Get-Content -LiteralPath $profilePath -Raw
        if ($content -match '(?m)# >>> SLMN PROFILE SCRIPT BEGIN >>>|# SLMN FRONTEND STARTERS|^\s*\.\s+["'']?\$env:USERPROFILE\\\.slmn\\starters\.ps1') {
            return (Resolve-Path -LiteralPath $profilePath).Path
        }
    }

    return $PROFILE.CurrentUserAllHosts
}

function Remove-SlmnProfileEntry {
    param([string]$ProfilePath)

    if (-not (Test-Path -LiteralPath $ProfilePath)) {
        return $false
    }

    $profileLinePattern = '^\s*\.\s+["'']?\$env:USERPROFILE\\\.slmn\\starters\.ps1["'']?\s*$'
    $lines = Get-Content -LiteralPath $ProfilePath
    $remainingLines = @($lines | Where-Object { $_ -notmatch $profileLinePattern })
    if ($remainingLines.Count -eq $lines.Count) {
        return $false
    }

    Set-Content -LiteralPath $ProfilePath -Value $remainingLines -Encoding utf8
    return $true
}

function Save-SlmnReleaseFile {
    param(
        [string]$FileName,
        [string]$DestinationPath
    )

    $releaseUri = "https://raw.githubusercontent.com/makssolomon2-hash/front-end-starters/main/$FileName"
    $isWindowsPowerShell = $PSVersionTable.PSVersion.Major -le 5
    $originalSecurityProtocol = $null

    try {
        if ($isWindowsPowerShell) {
            $originalSecurityProtocol = [Net.ServicePointManager]::SecurityProtocol
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        }

        $response = Invoke-WebRequest -Uri $releaseUri -UseBasicParsing -TimeoutSec 30 -ErrorAction Stop
        if ($response.StatusCode -ne 200) {
            throw "GitHub returned HTTP $($response.StatusCode)."
        }
        [System.IO.File]::WriteAllText($DestinationPath, $response.Content, [System.Text.UTF8Encoding]::new($true))
    } catch {
        throw "Unable to download SLMN release file '$FileName' from $releaseUri. $($_.Exception.Message)"
    } finally {
        if ($isWindowsPowerShell -and $null -ne $originalSecurityProtocol) {
            [Net.ServicePointManager]::SecurityProtocol = $originalSecurityProtocol
        }
    }
}

function Set-SlmnInstallationFiles {
    param([string]$SourcePath)

    $installDirectory = Get-SlmnInstallDirectory
    New-Item -ItemType Directory -Path $installDirectory -Force | Out-Null

    $stagingId = [Guid]::NewGuid().ToString('N')
    $stagedScriptPath = Join-Path $installDirectory "starters.$stagingId.tmp"
    $stagedHotkeysPath = Join-Path $installDirectory "slmn-hotkeys.$stagingId.tmp"
    $installedScriptPath = Join-Path $installDirectory 'starters.ps1'
    $installedHotkeysPath = Join-Path $installDirectory 'slmn-hotkeys.ahk'

    try {
        if ([string]::IsNullOrWhiteSpace($SourcePath)) {
            Save-SlmnReleaseFile -FileName 'starters.ps1' -DestinationPath $stagedScriptPath
            Save-SlmnReleaseFile -FileName 'slmn-hotkeys.ahk' -DestinationPath $stagedHotkeysPath
        } else {
            Copy-Item -LiteralPath $SourcePath -Destination $stagedScriptPath -Force -ErrorAction Stop
            $sourceHotkeysPath = Join-Path (Split-Path -Parent $SourcePath) 'slmn-hotkeys.ahk'
            if (Test-Path -LiteralPath $sourceHotkeysPath -PathType Leaf) {
                Copy-Item -LiteralPath $sourceHotkeysPath -Destination $stagedHotkeysPath -Force -ErrorAction Stop
            }
        }

        $tokens = $null
        $parseErrors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($stagedScriptPath, [ref]$tokens, [ref]$parseErrors) | Out-Null
        if ($null -ne $parseErrors -and $parseErrors.Count -gt 0) {
            throw "The downloaded starters.ps1 did not pass PowerShell syntax validation: $($parseErrors[0].Message)"
        }

        $scriptText = Get-Content -LiteralPath $stagedScriptPath -Raw
        if ($scriptText -notmatch '(?im)^\s*function\s+slmn-starter\b' -or $scriptText -notmatch '(?im)^\s*function\s+slmn-update\b') {
            throw 'The source file is not a valid SLMN Starters script.'
        }

        Move-Item -LiteralPath $stagedScriptPath -Destination $installedScriptPath -Force -ErrorAction Stop
        if (Test-Path -LiteralPath $stagedHotkeysPath -PathType Leaf) {
            Move-Item -LiteralPath $stagedHotkeysPath -Destination $installedHotkeysPath -Force -ErrorAction Stop
        }
    } finally {
        Remove-Item -LiteralPath $stagedScriptPath -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $stagedHotkeysPath -Force -ErrorAction SilentlyContinue
    }

    return $installedScriptPath
}

function Set-SlmnProfileLoader {
    $profilePath = Get-SlmnProfilePath
    New-Item -ItemType Directory -Path (Split-Path -Parent $profilePath) -Force | Out-Null
    if (-not (Test-Path -LiteralPath $profilePath)) {
        New-Item -ItemType File -Path $profilePath -Force | Out-Null
    }

    Remove-SlmnProfileEntry -ProfilePath $profilePath | Out-Null
    Add-Content -LiteralPath $profilePath -Value '. "$env:USERPROFILE\.slmn\starters.ps1"'
}

function Set-SlmnProfileScript {
    param([Parameter(Mandatory)][string]$ScriptPath)

    $profilePath = Get-SlmnProfilePath
    if (-not (Test-Path -LiteralPath $profilePath -PathType Leaf)) {
        return $false
    }

    $profileText = [System.IO.File]::ReadAllText($profilePath)
    $beginMatches = [regex]::Matches($profileText, '(?m)^# >>> SLMN PROFILE SCRIPT BEGIN >>>[ \t]*\r?$')
    $endMatches = [regex]::Matches($profileText, '(?m)^# <<< SLMN PROFILE SCRIPT END <<<[ \t]*\r?$')
    if ($beginMatches.Count -gt 0 -or $endMatches.Count -gt 0) {
        if ($beginMatches.Count -ne 1 -or $endMatches.Count -ne 1 -or $endMatches[0].Index -lt $beginMatches[0].Index) {
            throw "The SLMN markers in $profilePath are incomplete or out of order."
        }

        $beginIndex = $beginMatches[0].Index
        $endOfMarkerLine = $profileText.IndexOf("`n", $endMatches[0].Index + $endMatches[0].Length, [StringComparison]::Ordinal)
        $suffixStart = if ($endOfMarkerLine -ge 0) { $endOfMarkerLine + 1 } else { $profileText.Length }
        $updatedProfile = $profileText.Substring(0, $beginIndex) +
            [System.IO.File]::ReadAllText($ScriptPath) +
            $profileText.Substring($suffixStart)
        [System.IO.File]::WriteAllText($profilePath, $updatedProfile, [System.Text.UTF8Encoding]::new($true))
        return $true
    }

    $legacyStandaloneScript = $profileText -match '\A\s*# =+\r?\n# SLMN FRONTEND STARTERS\r?\n' -and
        $profileText -match '(?is)function\s+(?:next-ts-app|next-app)\s*\{.*?Complete-InteractiveProject\s+-Path\s+\$path\s+-Name\s+\$name\s+-Stack\s+Next\s*\}\s*\z'
    if ($legacyStandaloneScript) {
        [System.IO.File]::WriteAllText($profilePath, [System.IO.File]::ReadAllText($ScriptPath), [System.Text.UTF8Encoding]::new($true))
        return $true
    }

    return $false
}

function slmn-install {
    $sourcePath = $script:SlmnSourcePath
    if ([string]::IsNullOrWhiteSpace($sourcePath) -or -not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
        $sourcePath = $null
    } else {
        $sourcePath = (Resolve-Path -LiteralPath $sourcePath).Path
        $profilePath = Get-SlmnProfilePath
        $resolvedProfilePath = (Resolve-Path -LiteralPath $profilePath -ErrorAction SilentlyContinue).Path
        if ($sourcePath -ieq $resolvedProfilePath) {
            $sourcePath = $null
        }
    }

    $installedScriptPath = Set-SlmnInstallationFiles -SourcePath $sourcePath
    Initialize-SlmnStorage | Out-Null
    $profileScriptUpdated = Set-SlmnProfileScript -ScriptPath $installedScriptPath
    if (-not $profileScriptUpdated) {
        Set-SlmnProfileLoader
    }
    $script:SlmnSourcePath = $installedScriptPath

    if ($profileScriptUpdated) {
        Write-Host 'SLMN installed. The script in your PowerShell profile was refreshed in place.' -ForegroundColor Green
    } else {
        Write-Host 'SLMN installed. The profile now loads the managed copy from ~/.slmn.' -ForegroundColor Green
    }
    Write-Host 'Open a new PowerShell terminal to use the installed commands everywhere.' -ForegroundColor Green
}

function slmn-uninstall {
    $profilePath = Get-SlmnProfilePath
    if (Remove-SlmnProfileEntry -ProfilePath $profilePath) {
        Write-Host 'SLMN profile entry removed. The files in ~/.slmn were kept.' -ForegroundColor Green
    } else {
        Write-Host 'No SLMN profile entry was found.' -ForegroundColor Yellow
    }
}

function slmn-update {
    param([string]$SourcePath)

    if ($PSBoundParameters.ContainsKey('SourcePath')) {
        if ([string]::IsNullOrWhiteSpace($SourcePath) -or -not (Test-Path -LiteralPath $SourcePath -PathType Leaf)) {
            throw 'Provide a valid starters.ps1 file with: slmn-update -SourcePath "C:\path\to\starters.ps1"'
        }
        $SourcePath = (Resolve-Path -LiteralPath $SourcePath).Path
    } else {
        $SourcePath = $null
    }

    $installedScriptPath = Set-SlmnInstallationFiles -SourcePath $SourcePath
    Initialize-SlmnStorage | Out-Null
    $profileScriptUpdated = Set-SlmnProfileScript -ScriptPath $installedScriptPath
    if (-not $profileScriptUpdated) {
        Set-SlmnProfileLoader
        $profilePath = Get-SlmnProfilePath
        if ((Test-Path -LiteralPath $profilePath -PathType Leaf) -and
            (Get-Content -LiteralPath $profilePath -Raw) -match '# SLMN FRONTEND STARTERS') {
            Write-Warning "The installed copy was updated, but $profilePath contains an unmarked SLMN script mixed with other profile code. The managed loader was added after it; add the SLMN begin/end markers around the script to enable in-place profile updates."
        }
    }
    $script:SlmnSourcePath = $installedScriptPath

    if ($profileScriptUpdated) {
        Write-Host 'SLMN updated. The full script in your PowerShell profile was refreshed in place.' -ForegroundColor Green
    } else {
        if ([string]::IsNullOrWhiteSpace($SourcePath)) {
            Write-Host 'SLMN updated from the official GitHub main branch.' -ForegroundColor Green
        } else {
            Write-Host "SLMN updated from '$SourcePath'." -ForegroundColor Green
        }
    }
    Write-Host 'Open a new PowerShell terminal to load the updated commands.' -ForegroundColor Green
}

function Get-SlmnHotkeysPath {
    return (Join-Path (Get-SlmnInstallDirectory) 'slmn-hotkeys.ahk')
}

function Get-SlmnHotkeysStartupShortcutPath {
    return (Join-Path ([Environment]::GetFolderPath('Startup')) 'SLMN Hotkeys.lnk')
}

function slmn-install-hotkeys {
    $hotkeysPath = Get-SlmnHotkeysPath
    $sourcePath = $hotkeysPath
    if (-not (Test-Path -LiteralPath $sourcePath)) {
        if ([string]::IsNullOrWhiteSpace($script:SlmnSourcePath)) {
            throw 'slmn-hotkeys.ahk was not found in the managed install or next to starters.ps1.'
        }
        $sourceDirectory = Split-Path -Parent $script:SlmnSourcePath
        $sourcePath = Join-Path $sourceDirectory 'slmn-hotkeys.ahk'
        if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
            throw "slmn-hotkeys.ahk was not found in the managed install or next to starters.ps1: $sourcePath"
        }
    }

    $autoHotkeyCommand = Get-Command AutoHotkey64.exe, AutoHotkey.exe -ErrorAction SilentlyContinue | Select-Object -First 1
    $autoHotkeyPath = if ($autoHotkeyCommand) {
        $autoHotkeyCommand.Source
    } else {
        @(
            (Join-Path $env:ProgramFiles 'AutoHotkey\v2\AutoHotkey64.exe'),
            (Join-Path $env:ProgramFiles 'AutoHotkey\v2\AutoHotkey.exe'),
            (Join-Path ${env:ProgramFiles(x86)} 'AutoHotkey\v2\AutoHotkey.exe')
        ) | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
    }
    if (-not $autoHotkeyPath) {
        throw 'AutoHotkey v2 was not found. Install it from https://www.autohotkey.com/ and run slmn-install-hotkeys again.'
    }

    New-Item -ItemType Directory -Path (Get-SlmnInstallDirectory) -Force | Out-Null
    if ((Resolve-Path -LiteralPath $sourcePath).Path -ine (Resolve-Path -LiteralPath $hotkeysPath -ErrorAction SilentlyContinue).Path) {
        Copy-Item -LiteralPath $sourcePath -Destination $hotkeysPath -Force
    }

    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut((Get-SlmnHotkeysStartupShortcutPath))
    $shortcut.TargetPath = $autoHotkeyPath
    $shortcut.Arguments = '"' + $hotkeysPath + '"'
    $shortcut.WorkingDirectory = Get-SlmnInstallDirectory
    $shortcut.Save()

    Start-Process -FilePath $autoHotkeyPath -ArgumentList ('"' + $hotkeysPath + '"')
    Write-Host 'SLMN hotkeys installed and started. They will load automatically when you sign in.' -ForegroundColor Green
}

function slmn-uninstall-hotkeys {
    $hotkeysPath = Get-SlmnHotkeysPath
    $escapedPath = [regex]::Escape($hotkeysPath)
    Get-CimInstance Win32_Process -Filter "Name = 'AutoHotkey.exe' OR Name = 'AutoHotkey64.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -match $escapedPath } |
        ForEach-Object { Stop-Process -Id $_.ProcessId -Force }

    Remove-Item -LiteralPath (Get-SlmnHotkeysStartupShortcutPath) -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $hotkeysPath -Force -ErrorAction SilentlyContinue
    Write-Host 'SLMN hotkeys were removed.' -ForegroundColor Green
}

function Get-ResponsiveCss {
@'
* {
    box-sizing: border-box;
}

:root {
    --background: #171717;
    --surface: #242424;
    --text: #ffffff;
    --accent: #4f8cff;
    --page-padding: 1rem;
}

body {
    min-height: 100vh;
    margin: 0;
    background: var(--background);
    color: var(--text);
    font-family: system-ui, sans-serif;
}

main,
#root {
    min-height: 100vh;
    display: grid;
    place-items: center;
    padding: var(--page-padding);
}

h1 {
    margin: 0;
    font-size: clamp(2rem, 5vw, 4rem);
}

button {
    margin-top: 1rem;
    border: 0;
    border-radius: 0.375rem;
    padding: 0.75rem 1rem;
    background: var(--accent);
    color: var(--text);
    cursor: pointer;
    font: inherit;
}

button:hover {
    background: #3979e6;
}

/* tab: 768px */
@media (min-width: 48rem) {
    :root { --page-padding: 1.5rem; }
}

/* lap: 1024px */
@media (min-width: 64rem) {
    :root { --page-padding: 2rem; }
}

/* fhd: 1920px */
@media (min-width: 120rem) {
    :root { --page-padding: 3rem; }
}

/* 2k: 2560px */
@media (min-width: 160rem) {
    :root { --page-padding: 4rem; }
}

/* 4k: 3840px */
@media (min-width: 240rem) {
    :root { --page-padding: 5rem; }
}
'@
}

function Get-SlmnTechnologyInfo {
    param([string]$Name)

    $technologyMap = @{
        'HTML' = @{ Detail = 'Markup'; Href = 'https://developer.mozilla.org/docs/Web/HTML' }
        'CSS' = @{ Detail = 'Styling'; Href = 'https://developer.mozilla.org/docs/Web/CSS' }
        'JavaScript' = @{ Detail = 'Language'; Href = 'https://developer.mozilla.org/docs/Web/JavaScript' }
        'TypeScript' = @{ Detail = 'Language'; Href = 'https://www.typescriptlang.org/' }
        'Vite' = @{ Detail = 'Build tooling'; Href = 'https://vite.dev/' }
        'React' = @{ Detail = 'UI library'; Href = 'https://react.dev/' }
        'Next.js' = @{ Detail = 'React framework'; Href = 'https://nextjs.org/' }
        'Next.js Docs' = @{ Detail = 'Official documentation'; Href = 'https://nextjs.org/docs' }
        'Tailwind CSS' = @{ Detail = 'Utility styling'; Href = 'https://tailwindcss.com/' }
        'GSAP' = @{ Detail = 'Motion library'; Href = 'https://gsap.com/' }
        'Three.js' = @{ Detail = '3D library'; Href = 'https://threejs.org/' }
    }
    $technology = $technologyMap[$Name]
    if (-not $technology) {
        return [pscustomobject]@{ Name = $Name; Detail = 'Project tool'; Href = '#' }
    }

    return [pscustomobject]@{ Name = $Name; Detail = $technology.Detail; Href = $technology.Href }
}

function Set-StaticStarterScreen {
    param(
        [string]$Path,
        [string]$Name,
        [string[]]$Technologies,
        [switch]$UseVite,
        [switch]$UseGsap
    )

    $technologyCards = ($Technologies | ForEach-Object {
        $technology = Get-SlmnTechnologyInfo $_
@"
                    <a class="slmn-tech-card" href="$($technology.Href)" target="_blank" rel="noreferrer">
                        <span class="slmn-tech-mark" aria-hidden="true">$($technology.Name.Substring(0, 1))</span>
                        <span>
                            <span class="slmn-tech-name">$($technology.Name)</span>
                            <span class="slmn-tech-detail">$($technology.Detail)</span>
                        </span>
                    </a>
"@
    }) -join "`n"
    $rootStylesheetHref = if ($UseVite) { '/src/style.css' } else { './css/style.css' }
    $rootScriptTag = if ($UseVite) { '<script type="module" src="/src/script.js"></script>' } else { '<script src="./js/script.js" defer></script>' }
    $demoScriptTag = if ($UseVite) { '<script type="module" src="./main.js"></script>' } else { '<script src="./main.js" defer></script>' }
    $demoGsapScript = if ($UseGsap -and -not $UseVite) { '    <script src="https://cdnjs.cloudflare.com/ajax/libs/gsap/3.12.5/gsap.min.js"></script>' } else { '' }
    $screenClass = if ($UseGsap) { 'slmn-start slmn-use-gsap' } else { 'slmn-start' }
    $startDirectory = Join-Path $Path 'slmn-start'
    New-Item -ItemType Directory -Path $startDirectory -Force | Out-Null

    @"
<!doctype html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$Name</title>
    <link rel="stylesheet" href="$rootStylesheetHref">
</head>
<body>
    <main class="slmn-project-root">
        <h1>$Name</h1>
    </main>
    $rootScriptTag
</body>
</html>
"@ | Set-Content -LiteralPath (Join-Path $Path 'index.html') -Encoding utf8

    @"
<!doctype html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$Name - SLMN Start Screen</title>
    <link rel="stylesheet" href="./style.css">
</head>
<body>
    <main class="$screenClass">
        <section class="slmn-screen">
            <div class="slmn-copy">
                <p class="slmn-kicker" data-slmn-reveal>SLMN Starter</p>
                <h1 data-slmn-reveal>Build what is next.</h1>
                <p class="slmn-project" data-slmn-reveal>$Name</p>
                <p class="slmn-description" data-slmn-reveal>A clear starting point, shaped for this project's actual stack.</p>
                <div class="slmn-tech-list" data-slmn-reveal>
$technologyCards
                </div>
            </div>
            <div class="slmn-visual" data-slmn-visual data-slmn-reveal aria-hidden="true">
                <span class="slmn-visual-grid"></span>
                <div class="slmn-visual-signal">
                    <span class="slmn-visual-core">S</span>
                    <span class="slmn-visual-node slmn-visual-node-one"></span>
                    <span class="slmn-visual-node slmn-visual-node-two"></span>
                    <span class="slmn-visual-node slmn-visual-node-three"></span>
                </div>
                <span class="slmn-visual-scan"></span>
                <span class="slmn-visual-caption">SLMN / 01</span>
            </div>
        </section>
    </main>
$demoGsapScript
    $demoScriptTag
</body>
</html>
"@ | Set-Content -LiteralPath (Join-Path (Join-Path $Path 'slmn-start') 'index.html') -Encoding utf8

    @'
* {
    box-sizing: border-box;
}

:root {
    color: #171717;
    background: #ffffff;
    font-family: "Aptos", "Segoe UI", sans-serif;
}

body {
    min-width: 320px;
    min-height: 100vh;
    margin: 0;
}

.slmn-project-root {
    display: grid;
    min-height: 100svh;
    padding: 20px;
    place-items: center;
}

.slmn-project-root h1 {
    margin: 0;
    font-size: clamp(2rem, 5vw, 4rem);
    font-weight: 600;
}
'@ | ForEach-Object {
        $rootStylesheetPath = Join-Path $Path $(if ($UseVite) { 'src/style.css' } else { 'css/style.css' })
        New-Item -ItemType Directory -Path (Split-Path -Parent $rootStylesheetPath) -Force | Out-Null
        Set-Content -LiteralPath $rootStylesheetPath -Value $_ -Encoding utf8
    }

    $rootScriptPath = Join-Path $Path $(if ($UseVite) { 'src/script.js' } else { 'js/script.js' })
    $rootScript = if ($UseVite) { "import './style.css'`n" } else { "document.documentElement.dataset.slmnStarter = 'ready'`n" }
    New-Item -ItemType Directory -Path (Split-Path -Parent $rootScriptPath) -Force | Out-Null
    Set-Content -LiteralPath $rootScriptPath -Value $rootScript -Encoding utf8

    $legacyStartDirectory = Join-Path $Path $(if ($UseVite) { 'src/slmn-start' } else { 'js/slmn-start' })
    Remove-Item -LiteralPath $legacyStartDirectory -Recurse -Force -ErrorAction SilentlyContinue

    @'
* {
    box-sizing: border-box;
}

:root {
    color: #ffffff;
    background: #171717;
    font-family: "Aptos", "Segoe UI", sans-serif;
}

body {
    min-width: 320px;
    min-height: 100vh;
    margin: 0;
}

.slmn-start {
    display: grid;
    width: 100%;
    min-height: 100svh;
    padding: 20px;
    place-items: center;
    text-align: left;
    background-color: #171717;
    background-image: linear-gradient(rgb(255 255 255 / 0.035) 1px, transparent 1px), linear-gradient(90deg, rgb(255 255 255 / 0.035) 1px, transparent 1px);
    background-size: 3rem 3rem;
}

.slmn-screen {
    display: grid;
    width: 100%;
    max-width: 72rem;
    min-height: min(30rem, calc(100svh - 40px));
    padding: 0;
    margin: 0 auto;
    align-items: center;
    gap: 2.5rem;
}

.slmn-copy {
    max-width: 38rem;
}

.slmn-kicker {
    margin: 0 0 1rem;
    color: #93c5fd;
    font-size: 0.875rem;
    font-weight: 600;
    letter-spacing: 0.18em;
    text-transform: uppercase;
}

.slmn-screen h1 {
    margin: 0;
    font-size: 3rem;
    font-weight: 600;
    line-height: 1.1;
}

.slmn-project {
    margin: 1.25rem 0 0;
    color: #d4d4d4;
    font-size: 1.125rem;
}

.slmn-description {
    max-width: 32rem;
    margin: 0.75rem 0 0;
    color: #a3a3a3;
    font-size: 1rem;
    line-height: 1.65;
}

.slmn-tech-list {
    display: grid;
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 0.75rem;
    margin-top: 2.25rem;
}

.slmn-tech-card {
    display: flex;
    min-height: 5rem;
    gap: 0.75rem;
    align-items: center;
    padding: 0.875rem;
    color: #ffffff;
    font-size: 0.875rem;
    text-decoration: none;
    background: rgb(255 255 255 / 0.045);
    border: 1px solid rgb(255 255 255 / 0.1);
    transition: background-color 160ms ease, border-color 160ms ease, transform 160ms ease;
}

.slmn-tech-card:hover {
    background: rgb(255 255 255 / 0.09);
    border-color: rgb(125 211 252 / 0.72);
    transform: translateY(-2px);
}

.slmn-tech-card:focus-visible {
    outline: 2px solid #7dd3fc;
    outline-offset: 3px;
}

.slmn-tech-mark {
    display: grid;
    width: 1.8rem;
    height: 1.8rem;
    flex: 0 0 auto;
    place-items: center;
    color: #bae6fd;
    font-weight: 700;
    background: #0c4a6e;
}

.slmn-tech-name,
.slmn-tech-detail {
    display: block;
}

.slmn-tech-name {
    font-weight: 650;
}

.slmn-tech-detail {
    margin-top: 0.2rem;
    color: #a3a3a3;
    font-size: 0.75rem;
}

.slmn-visual {
    --slmn-pointer-x: 0px;
    --slmn-pointer-y: 0px;
    position: relative;
    min-height: 22rem;
    overflow: hidden;
    isolation: isolate;
    background: #1d2329;
    border: 1px solid rgb(255 255 255 / 0.11);
}

.slmn-visual-grid {
    position: absolute;
    inset: 0;
    background-image: linear-gradient(#26313a 1px, transparent 1px), linear-gradient(90deg, #26313a 1px, transparent 1px);
    background-size: 2rem 2rem;
    opacity: 0.85;
}

.slmn-visual-signal {
    position: absolute;
    top: 50%;
    left: 50%;
    width: 15rem;
    height: 15rem;
    transform: translate(calc(-50% + var(--slmn-pointer-x)), calc(-50% + var(--slmn-pointer-y)));
    transition: transform 180ms ease-out;
}

.slmn-visual-core,
.slmn-visual-node {
    position: absolute;
    display: block;
}

.slmn-visual-core {
    top: 50%;
    left: 50%;
    width: 5rem;
    height: 5rem;
    display: grid;
    place-items: center;
    color: #38bdf8;
    font-family: "Aptos", "Segoe UI", sans-serif;
    font-size: 5.25rem;
    font-weight: 700;
    line-height: 1;
    text-shadow: 0 0 1.5rem rgb(56 189 248 / 0.82);
    transform: translate(-50%, -50%);
    animation: slmn-core-pulse 2.8s ease-in-out infinite;
}

.slmn-visual-node {
    width: 0.75rem;
    height: 0.75rem;
    background: #f0f9ff;
    box-shadow: 0 0 1rem rgb(125 211 252 / 0.9);
}

.slmn-visual-node-one {
    top: 1.4rem;
    left: 2.1rem;
}

.slmn-visual-node-two {
    right: 1.8rem;
    bottom: 2.75rem;
}

.slmn-visual-node-three {
    top: 50%;
    right: -0.375rem;
}

.slmn-visual-scan {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 1px;
    background: #7dd3fc;
    box-shadow: 0 0 1rem #38bdf8;
    animation: slmn-scan 4.5s ease-in-out infinite;
}

.slmn-visual-caption {
    position: absolute;
    right: 1rem;
    bottom: 0.875rem;
    color: #bae6fd;
    font-size: 0.7rem;
    font-weight: 700;
    letter-spacing: 0.15em;
}

[data-slmn-reveal] {
    animation: slmn-reveal 650ms both;
}

.slmn-use-gsap [data-slmn-reveal] {
    animation: none;
}

@keyframes slmn-reveal {
    from { opacity: 0; transform: translateY(1rem); }
    to { opacity: 1; transform: translateY(0); }
}

@keyframes slmn-core-pulse {
    50% { opacity: 0.72; text-shadow: 0 0 2.25rem rgb(56 189 248 / 0.98); }
}

@keyframes slmn-scan {
    50% { transform: translateY(22rem); }
}

@media (min-width: 48rem) {
    .slmn-screen h1 {
        font-size: 4.5rem;
    }
}

@media (min-width: 64rem) {
    .slmn-screen {
        grid-template-columns: minmax(0, 1fr) minmax(20rem, 0.85fr);
        gap: 4rem;
    }

    .slmn-visual {
        min-height: 30rem;
    }

    @keyframes slmn-scan {
        50% { transform: translateY(30rem); }
    }
}
'@ | ForEach-Object {
    $startDirectory = Join-Path $Path 'slmn-start'
        $stylesheetPath = Join-Path $startDirectory 'style.css'
        New-Item -ItemType Directory -Path (Split-Path -Parent $stylesheetPath) -Force | Out-Null
        Set-Content -LiteralPath $stylesheetPath -Value $_ -Encoding utf8
    }

    $scriptPath = Join-Path $startDirectory 'main.js'
    New-Item -ItemType Directory -Path (Split-Path -Parent $scriptPath) -Force | Out-Null
    $screenReveal = @'
const screen = document.querySelector('.slmn-start')

if (screen) {
    screen.hidden = false
}
'@
    $styleLoader = if ($UseVite) {
        "import './style.css'`n"
    } else {
        ''
    }
    $pointerMotion = @'
const visual = document.querySelector('[data-slmn-visual]')

if (visual) {
    const resetPointer = () => {
        visual.style.setProperty('--slmn-pointer-x', '0px')
        visual.style.setProperty('--slmn-pointer-y', '0px')
    }

    visual.addEventListener('pointermove', (event) => {
        const bounds = visual.getBoundingClientRect()
        const pointerX = Math.round(((event.clientX - bounds.left) / bounds.width - 0.5) * 22)
        const pointerY = Math.round(((event.clientY - bounds.top) / bounds.height - 0.5) * 22)
        visual.style.setProperty('--slmn-pointer-x', `${pointerX}px`)
        visual.style.setProperty('--slmn-pointer-y', `${pointerY}px`)
    })

    visual.addEventListener('pointerleave', resetPointer)
}
'@
    $script = if ($UseGsap -and $UseVite) {
"$styleLoader`nimport gsap from 'gsap'`n`n$screenReveal`ngsap.from('[data-slmn-reveal]', {`n    y: 18,`n    opacity: 0,`n    duration: 0.55,`n    stagger: 0.1,`n    ease: 'power2.out',`n})`n" + $pointerMotion
    } elseif ($UseGsap) {
"$styleLoader`n$screenReveal`ngsap.from('[data-slmn-reveal]', {`n    y: 18,`n    opacity: 0,`n    duration: 0.55,`n    stagger: 0.1,`n    ease: 'power2.out',`n})`n" + $pointerMotion
    } elseif ($UseVite) {
        "$styleLoader`n$screenReveal`n$pointerMotion"
    } else {
        "$styleLoader`n$screenReveal`n$pointerMotion`nconsole.log('Page loaded')`n"
    }
    Set-Content -LiteralPath $scriptPath -Value $script -Encoding utf8
}

function Invoke-Npm {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)

    Write-SlmnStatus "Running npm $($Arguments -join ' ')"
    & npm @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "npm $($Arguments -join ' ') failed with exit code $LASTEXITCODE."
    }
}

function Invoke-NpmDevInstall {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Packages)

    Write-SlmnStatus "Installing development packages: $($Packages -join ', ')"
    & npm install --save-dev @Packages
    if ($LASTEXITCODE -ne 0) {
        throw "npm install --save-dev $($Packages -join ' ') failed with exit code $LASTEXITCODE."
    }
}

function Write-ProjectAgentInstructions {
    param([string]$Path)

    $instructions = @'
# AGENTS.md

> **Starter Blueprint**\
> Fill the questions below.\
> Once answered, this file becomes the single source of truth for every AI coding agent (and for you).\
> Aim for the density and clarity of a production-grade agents.md (see the Vertex-style example for the finished quality bar).

---

## 0. Agent Role (keep or rewrite)

You are a **principal-level frontend / full-stack engineer and AI implementation agent**.\
Your job is to understand the request, respect the boundaries defined in this file, write a clear implementation plan when asked, get approval if required, then implement cleanly.

---

## 1. Project Intent (answer these first – 5–10 minutes)

**One-sentence product description**\
What are we building?

**Primary user & job-to-be-done**\
Who is it for and what is the main thing they come here to accomplish?

**Core experience / screens for v1**\
List the 3–7 most important pages or flows that must exist in the first version.

**What makes this product special?**\
The one or two things that differentiate it (search, animation, 3D, real-time, etc.).

**Explicit non-goals for v1**\
What are we deliberately *not* building right now?

**Definition of done for the first vertical slice**\
What does “good enough to show / ship” look like?

---

## 2. How the agent should work

Describe the preferred loop (or keep the default below and adjust):

1. Read this file completely.
2. Inspect existing code and config before assuming anything.
3. Ask at most one focused clarifying question if genuinely ambiguous.
4. (Optional) Write a short implementation prompt before coding large features.
5. Implement strictly within the boundaries defined here.
6. Run the checks listed in section 7.
7. Report briefly: What I did / How to test / Needs attention.

---

## 3. Architecture & Boundaries (critical)

**High-level structure**\
(e.g. single Vite app, Next.js App Router, monorepo with web + studio, etc.)

**Server vs Client rules**\
What must stay on the server? What is allowed in the browser?

**Data access rules**\
Who can read what? Who can write what? Any tokens that must never reach the client?

**Third-party services & their boundaries**\
(Auth, CMS, analytics, AI, video, etc. — name them and state the hard rules)

---

## 4. Tech Stack (exact versions if known)

List every important package and any non-negotiable choices:

- Framework / bundler:
- Styling:
- Animation / 3D:
- State / data fetching:
- Auth:
- CMS / content:
- Analytics:
- AI / search:
- Other:

---

## 5. Key Decisions already made

Write the important product and technical decisions that the agent must not re-litigate.\
Examples: “Search returns structured cards, never a chatbox”, “All video playback stays on-site via embed”, “Progress is written only through a server route”, etc.

---

## 6. Data / Content Model (if applicable)

Describe the main entities and their relationships at a high level.\
What is stored where? What is derived vs stored?

---

## 7. Checks the agent must run

- Type-check
- Lint
- Production build (when relevant)
- Manual test steps for the feature just built

---

## 8. Things that will trip you up / Hard constraints

List the gotchas, security rules, and non-obvious constraints that are easy to violate.

---

## 9. When in doubt

Keep it small.\
Respect the server/client boundaries.\
Do not invent features outside the Project Intent.\
Prefer existing patterns and components in the codebase.\
Ask before expanding scope.

---

**After you finish answering the questions above, delete this instruction block and any unused sections.**\
The resulting file should feel dense, decisive, and production-ready.
'@

    Set-Content -LiteralPath (Join-Path $Path 'AGENTS.md') -Value $instructions -Encoding utf8
}

function Open-ProjectEditor {
    param(
        [string]$Path,
        [switch]$SkipAgentInstructions
    )

    Write-SlmnSuccess "Project created: $Path"
    if (-not $SkipAgentInstructions) {
        Write-ProjectAgentInstructions -Path $Path
    }

    if (-not (Get-SlmnConfiguration).openInVSCode) {
        Write-Host 'VS Code opening is disabled in SLMN configuration.' -ForegroundColor DarkGray
        return
    }

    if (Get-Command code -ErrorAction SilentlyContinue) {
        Write-SlmnStatus 'Opening the project in VS Code...'
        & code $Path
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "VS Code could not open: $Path"
        } else {
            Start-Sleep -Milliseconds 400
            Write-SlmnStatus 'Focusing AGENTS.md...'
            & code --reuse-window (Join-Path $Path 'AGENTS.md')
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "VS Code could not open AGENTS.md in: $Path"
            }
        }
    } else {
        Write-Warning "VS Code CLI ('code') was not found. Open manually: $Path"
    }
}

function Test-SlmnUrlReady {
    param([Parameter(Mandatory)][string]$Url)

    $request = [System.Net.HttpWebRequest]::Create($Url)
    $request.Method = 'GET'
    $request.Timeout = 1200
    $request.ReadWriteTimeout = 1200
    $request.Proxy = $null

    try {
        $response = $request.GetResponse()
        $response.Close()
        return $true
    } catch [System.Net.WebException] {
        if ($_.Exception.Response) {
            $_.Exception.Response.Close()
            return $true
        }
        return $false
    }
}

function Get-SlmnAvailablePort {
    $portProbe = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, 0)
    try {
        $portProbe.Start()
        return $portProbe.LocalEndpoint.Port
    } finally {
        $portProbe.Stop()
    }
}

function Wait-SlmnForPreview {
    param(
        [Parameter(Mandatory)]$Job,
        [Parameter(Mandatory)][string]$Url,
        [Parameter(Mandatory)][string]$Description,
        [int]$TimeoutSeconds = 120
    )

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $spinner = @('|', '/', '-', '\')
    $frameIndex = 0
    $lastOutput = ''

    while ($stopwatch.Elapsed.TotalSeconds -lt $TimeoutSeconds) {
        if (Test-SlmnUrlReady -Url $Url) {
            Write-Host ("`r" + (' ' * 90) + "`r") -NoNewline
            return $Url
        }

        if ($Job.State -in @('Completed', 'Failed', 'Stopped')) {
            break
        }

        $frame = $spinner[$frameIndex % $spinner.Count]
        Write-Host "`r  $frame  $Description" -NoNewline -ForegroundColor Cyan
        $frameIndex++
        Start-Sleep -Milliseconds 180
    }

    Write-Host ("`r" + (' ' * 90) + "`r") -NoNewline
    $lastOutput = Receive-Job -Job $Job -Keep -ErrorAction SilentlyContinue 2>&1 | Out-String
    $failureDetails = ($lastOutput -split "`r?`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Last 12) -join "`n"
    if ($Job.State -notin @('Completed', 'Failed', 'Stopped')) {
        Stop-Job -Job $Job -ErrorAction SilentlyContinue
    }
    Remove-Job -Job $Job -Force -ErrorAction SilentlyContinue
    if ([string]::IsNullOrWhiteSpace($failureDetails)) {
        throw "$Description did not become ready within $TimeoutSeconds seconds."
    }
    throw "$Description did not become ready within $TimeoutSeconds seconds. Last output:`n$failureDetails"
}

function Open-SlmnBrowser {
    param([Parameter(Mandatory)][string]$Url)

    Write-SlmnSuccess "App ready: $Url"
    Write-SlmnStatus 'Opening the preview in your browser...'
    try {
        Start-Process -FilePath $Url -ErrorAction Stop
    } catch {
        throw "The app is ready at $Url, but the default browser could not be opened: $($_.Exception.Message)"
    }
}

function Start-SlmnDevServer {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Get-SlmnConfiguration).autoStartDev) {
        Write-Host 'Automatic dev-server and browser preview are disabled in SLMN configuration.' -ForegroundColor DarkGray
        return
    }

    $npmCommand = Get-Command npm.cmd -ErrorAction SilentlyContinue
    if (-not $npmCommand) {
        throw "The npm.cmd command was not found. Install Node.js and npm to start the preview for $Path."
    }

    $isNextProject = Test-ProjectDependency -Path $Path -Name 'next'
    if (-not $isNextProject -and -not (Test-ProjectDependency -Path $Path -Name 'vite')) {
        throw "The project in $Path does not appear to use Vite or Next.js, so SLMN cannot select its preview URL safely."
    }
    $port = Get-SlmnAvailablePort
    $url = "http://127.0.0.1:$port/"

    Write-SlmnStatus 'Starting the development server and waiting for localhost...'
    $job = Start-Job -ScriptBlock {
        param($ProjectPath, $NpmPath, $UseNext, $Port)

        Set-Location -LiteralPath $ProjectPath
        if ($UseNext) {
            & $NpmPath run dev -- --hostname 127.0.0.1 --port $Port
        } else {
            & $NpmPath run dev -- --host 127.0.0.1 --port $Port --strictPort
        }
        if ($LASTEXITCODE -ne 0) {
            throw "npm run dev failed with exit code $LASTEXITCODE."
        }
    } -ArgumentList $Path, $npmCommand.Source, $isNextProject, $port

    $url = Wait-SlmnForPreview -Job $job -Url $url -Description "Starting $([System.IO.Path]::GetFileName($Path))"
    if ($null -eq $script:SlmnPreviewJobs) {
        $script:SlmnPreviewJobs = @{}
    }
    $script:SlmnPreviewJobs[$Path] = $job
    Open-SlmnBrowser -Url $url
}

function Start-SlmnStaticPreview {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Get-SlmnConfiguration).autoStartDev) {
        Write-Host 'Automatic dev-server and browser preview are disabled in SLMN configuration.' -ForegroundColor DarkGray
        return
    }

    $indexPath = Join-Path $Path 'index.html'
    if (-not (Test-Path -LiteralPath $indexPath)) {
        throw "Static preview requires an index.html file in $Path."
    }

    $nodeCommand = Get-Command node.exe -ErrorAction SilentlyContinue
    if (-not $nodeCommand) {
        Write-Warning 'Node.js was not found; opening the static project directly from disk instead of localhost.'
        Open-SlmnBrowser -Url ([System.Uri]$indexPath).AbsoluteUri
        return
    }

    $port = Get-SlmnAvailablePort

    $staticServerScript = @'
const http = require('http')
const fs = require('fs')
const path = require('path')

const root = path.resolve(process.argv[1])
const port = Number(process.argv[2])
const contentTypes = {
    '.css': 'text/css; charset=utf-8',
    '.html': 'text/html; charset=utf-8',
    '.ico': 'image/x-icon',
    '.js': 'text/javascript; charset=utf-8',
    '.json': 'application/json; charset=utf-8',
    '.svg': 'image/svg+xml',
}

http.createServer((request, response) => {
    if (request.method !== 'GET' && request.method !== 'HEAD') {
        response.writeHead(405).end()
        return
    }

    let pathname
    try {
        pathname = decodeURIComponent(new URL(request.url, 'http://localhost').pathname)
    } catch {
        response.writeHead(400).end()
        return
    }

    let filePath = path.resolve(root, `.${pathname}`)
    const relativePath = path.relative(root, filePath)
    if (relativePath === '..' || relativePath.startsWith(`..${path.sep}`) || path.isAbsolute(relativePath)) {
        response.writeHead(403).end()
        return
    }

    try {
        if (fs.statSync(filePath).isDirectory()) {
            filePath = path.join(filePath, 'index.html')
        }
    } catch (error) {
        response.writeHead(error.code === 'ENOENT' ? 404 : 500).end()
        return
    }

    fs.readFile(filePath, (error, content) => {
        if (error) {
            response.writeHead(error.code === 'ENOENT' ? 404 : 500).end()
            return
        }

        const type = contentTypes[path.extname(filePath).toLowerCase()] || 'application/octet-stream'
        response.writeHead(200, {
            'Cache-Control': 'no-store',
            'Content-Type': type,
            'X-Content-Type-Options': 'nosniff',
        })
        response.end(request.method === 'HEAD' ? undefined : content)
    })
}).listen(port, '127.0.0.1', () => {
    console.log(`http://127.0.0.1:${port}/`)
})
'@

    $job = Start-Job -ScriptBlock {
        param($NodePath, $ServerScript, $ProjectPath, $Port)

        & $NodePath -e $ServerScript $ProjectPath $Port
        if ($LASTEXITCODE -ne 0) {
            throw "The static preview server failed with exit code $LASTEXITCODE."
        }
    } -ArgumentList $nodeCommand.Source, $staticServerScript, $Path, $port

    $url = Wait-SlmnForPreview -Job $job -Url "http://127.0.0.1:$port/" -Description "Serving $([System.IO.Path]::GetFileName($Path))"
    if ($null -eq $script:SlmnPreviewJobs) {
        $script:SlmnPreviewJobs = @{}
    }
    $script:SlmnPreviewJobs[$Path] = $job
    Open-SlmnBrowser -Url $url
}

function Write-SlmnStatus {
    param([Parameter(Mandatory)][string]$Message)

    Write-Host "  > $Message" -ForegroundColor Cyan
}

function Write-SlmnSuccess {
    param([Parameter(Mandatory)][string]$Message)

    Write-Host "  [OK] $Message" -ForegroundColor Green
}

function Show-SlmnBanner {
    param([switch]$Animate)

    Write-Host ''
    Write-Host '  +------------------------------------------+' -ForegroundColor DarkCyan
    Write-Host '  |  ' -NoNewline -ForegroundColor DarkCyan
    $title = 'SLMN Starter'
    if ($Animate) {
        foreach ($character in $title.ToCharArray()) {
            Write-Host $character -NoNewline -ForegroundColor Cyan
            Start-Sleep -Milliseconds 14
        }
    } else {
        Write-Host $title -NoNewline -ForegroundColor Cyan
    }
    Write-Host '                         |' -ForegroundColor DarkCyan
    Write-Host '  +------------------------------------------+' -ForegroundColor DarkCyan
}

function Confirm-Feature {
    param([string]$Prompt)

    while ($true) {
        Write-Host "$Prompt [Y/N] " -NoNewline -ForegroundColor Cyan
        $key = [Console]::ReadKey($true)

        switch ($key.Key) {
            'Y' {
                Write-Host 'Y' -ForegroundColor Green
                return $true
            }
            'N' {
                Write-Host 'N' -ForegroundColor DarkGray
                return $false
            }
            default {
                Write-Host "`nPress Y for Yes or N for No." -ForegroundColor Yellow
            }
        }
    }
}

function Show-SlmnSettings {
    $selectedIndex = 0

    while ($true) {
        $configuration = Get-SlmnConfiguration
        $items = @(
            @{ Label = 'Projects folder'; Value = $configuration.projectsPath; Action = 'path' },
            @{ Label = 'Open projects in VS Code'; Value = if ($configuration.openInVSCode) { 'On' } else { 'Off' }; Action = 'openInVSCode' },
            @{ Label = 'Start preview and open browser'; Value = if ($configuration.autoStartDev) { 'On' } else { 'Off' }; Action = 'autoStartDev' },
            @{ Label = 'Back to starters'; Value = ''; Action = 'back' }
        )

        Clear-Host
        Show-SlmnBanner
        Write-Host '  Settings' -ForegroundColor White
        Write-Host '  Use Up/Down + Enter. Esc returns to the starter list.' -ForegroundColor DarkGray
        Write-Host ''

        for ($index = 0; $index -lt $items.Count; $index++) {
            if ($index -eq $selectedIndex) {
                Write-Host '  > ' -NoNewline -ForegroundColor Cyan -BackgroundColor DarkBlue
                Write-Host $items[$index].Label -NoNewline -ForegroundColor White -BackgroundColor DarkBlue
                if (-not [string]::IsNullOrWhiteSpace($items[$index].Value)) {
                    Write-Host "  |  $($items[$index].Value)" -ForegroundColor Cyan -BackgroundColor DarkBlue
                } else {
                    Write-Host ''
                }
            } else {
                Write-Host '    ' -NoNewline
                Write-Host $items[$index].Label -NoNewline -ForegroundColor White
                if (-not [string]::IsNullOrWhiteSpace($items[$index].Value)) {
                    Write-Host "  |  $($items[$index].Value)" -ForegroundColor DarkGray
                } else {
                    Write-Host ''
                }
            }
        }

        $keyInfo = [Console]::ReadKey($true)
        switch ($keyInfo.Key) {
            'UpArrow' {
                $selectedIndex = if ($selectedIndex -eq 0) { $items.Count - 1 } else { $selectedIndex - 1 }
            }
            'DownArrow' {
                $selectedIndex = if ($selectedIndex -eq ($items.Count - 1)) { 0 } else { $selectedIndex + 1 }
            }
            'Escape' {
                return
            }
            'Enter' {
                switch ($items[$selectedIndex].Action) {
                    'path' {
                        Write-Host ''
                        Write-Host "  Current folder: $($configuration.projectsPath)" -ForegroundColor DarkGray
                        $newPath = Read-Host '  New projects folder (Enter keeps the current folder)'
                        if (-not [string]::IsNullOrWhiteSpace($newPath)) {
                            slmn-config path $newPath.Trim()
                            Start-Sleep -Milliseconds 500
                        }
                    }
                    'openInVSCode' {
                        $nextValue = -not [bool]$configuration.openInVSCode
                        $nextValueText = $nextValue.ToString().ToLowerInvariant()
                        slmn-config openInVSCode $nextValueText
                        Start-Sleep -Milliseconds 500
                    }
                    'autoStartDev' {
                        $nextValue = -not [bool]$configuration.autoStartDev
                        $nextValueText = $nextValue.ToString().ToLowerInvariant()
                        slmn-config autoStartDev $nextValueText
                        Start-Sleep -Milliseconds 500
                    }
                    'back' {
                        return
                    }
                }
            }
        }
    }
}

function Select-StarterCommand {
    param([string]$InitialCommand)

    $options = @(
        @{ Group = 'CORE'; Label = 'Vanilla'; Shortcut = '1 / V'; Keys = @('1', 'v'); Badges = @(@{ Text = 'HTML'; Color = 'DarkYellow' }, @{ Text = 'CSS'; Color = 'Blue' }, @{ Text = 'JS'; Color = 'Yellow' }); Command = 'vanilla-project' },
        @{ Group = 'CORE'; Label = 'Tailwind CSS'; Shortcut = '2 / T'; Keys = @('2', 't'); Badges = @(@{ Text = 'TW'; Color = 'Cyan' }); Command = 'tailwind-project' },
        @{ Group = 'CORE'; Label = 'GSAP'; Shortcut = '3 / G'; Keys = @('3', 'g'); Badges = @(@{ Text = 'GS'; Color = 'Green' }); Command = 'gsap-project' },
        @{ Group = 'CORE'; Label = 'Tailwind CSS + GSAP'; Shortcut = '4 / TG'; Keys = @('4', 'tg'); Badges = @(@{ Text = 'TW'; Color = 'Cyan' }, @{ Text = 'GS'; Color = 'Green' }); Command = 'tailwind-gsap-project' },
        @{ Group = 'REACT / JAVASCRIPT'; Label = 'React'; Shortcut = '5 / R'; Keys = @('5', 'r'); Badges = @(@{ Text = 'R'; Color = 'Blue' }, @{ Text = 'JS'; Color = 'Yellow' }); Command = 'react-project' },
        @{ Group = 'REACT / JAVASCRIPT'; Label = 'React + Tailwind CSS'; Shortcut = '6 / RT'; Keys = @('6', 'rt'); Badges = @(@{ Text = 'R'; Color = 'Blue' }, @{ Text = 'JS'; Color = 'Yellow' }, @{ Text = 'TW'; Color = 'Cyan' }); Command = 'react-tailwind-project' },
        @{ Group = 'REACT / JAVASCRIPT'; Label = 'React + Tailwind CSS + GSAP'; Shortcut = '7 / RTG'; Keys = @('7', 'rtg'); Badges = @(@{ Text = 'R'; Color = 'Blue' }, @{ Text = 'JS'; Color = 'Yellow' }, @{ Text = 'TW'; Color = 'Cyan' }, @{ Text = 'GS'; Color = 'Green' }); Command = 'react-tailwind-gsap-project' },
        @{ Group = 'REACT / TYPESCRIPT'; Label = 'React'; Shortcut = 'RTS'; Keys = @('rts'); Badges = @(@{ Text = 'R'; Color = 'Blue' }, @{ Text = 'TS'; Color = 'Cyan' }); Command = 'react-ts-project' },
        @{ Group = 'REACT / TYPESCRIPT'; Label = 'React + Tailwind CSS'; Shortcut = 'RTTS'; Keys = @('rtts'); Badges = @(@{ Text = 'R'; Color = 'Blue' }, @{ Text = 'TS'; Color = 'Cyan' }, @{ Text = 'TW'; Color = 'Cyan' }); Command = 'react-tailwind-ts-project' },
        @{ Group = 'REACT / TYPESCRIPT'; Label = 'React + Tailwind CSS + GSAP'; Shortcut = 'RTGTS'; Keys = @('rtgts'); Badges = @(@{ Text = 'R'; Color = 'Blue' }, @{ Text = 'TS'; Color = 'Cyan' }, @{ Text = 'TW'; Color = 'Cyan' }, @{ Text = 'GS'; Color = 'Green' }); Command = 'react-tailwind-gsap-ts-project' },
        @{ Group = 'REACT / TYPESCRIPT'; Label = 'React + Tailwind + GSAP + Three.js'; Shortcut = '3DTS'; Keys = @('3dts'); Badges = @(@{ Text = 'R'; Color = 'Blue' }, @{ Text = 'TS'; Color = 'Cyan' }, @{ Text = '3D'; Color = 'Magenta' }); Command = 'react-tailwind-gsap-three-ts-project' },
        @{ Group = 'REACT / TYPESCRIPT'; Label = 'SLMN App (flagship)'; Shortcut = 'ATS'; Keys = @('ats'); Badges = @(@{ Text = 'S'; Color = 'Cyan' }, @{ Text = 'TS'; Color = 'Cyan' }); Command = 'slmn-ts-app' },
        @{ Group = 'FULL-STACK'; Label = 'SLMN Full (Full-stack)'; Shortcut = 'FTS'; Keys = @('fts'); Badges = @(@{ Text = 'N'; Color = 'White' }, @{ Text = 'TS'; Color = 'Cyan' }, @{ Text = 'DB'; Color = 'Green' }, @{ Text = 'AI'; Color = 'Magenta' }); Command = 'slmn-full' },
        @{ Group = 'FRAMEWORKS'; Label = 'SLMN App (JavaScript)'; Shortcut = '8 / A'; Keys = @('8', 'a'); Badges = @(@{ Text = 'S'; Color = 'Cyan' }, @{ Text = 'JS'; Color = 'Yellow' }); Command = 'slmn-app' },
        @{ Group = 'FRAMEWORKS'; Label = 'Vite (choose framework and variant)'; Shortcut = '9 / VITE'; Keys = @('9', 'vite'); Badges = @(@{ Text = 'V'; Color = 'Magenta' }); Command = 'vite-app' },
        @{ Group = 'FRAMEWORKS'; Label = 'Next.js (TypeScript)'; Shortcut = 'NTS'; Keys = @('nts'); Badges = @(@{ Text = 'N'; Color = 'White' }, @{ Text = 'TS'; Color = 'Cyan' }); Command = 'next-ts-app' },
        @{ Group = 'FRAMEWORKS'; Label = 'Next.js'; Shortcut = '0 / NEXT'; Keys = @('0', 'next'); Badges = @(@{ Text = 'N'; Color = 'White' }, @{ Text = 'JS'; Color = 'Yellow' }); Command = 'next-app' },
        @{ Group = 'SETTINGS'; Label = 'Settings'; Shortcut = 'S'; Keys = @('s'); Badges = @(@{ Text = 'CONFIG'; Color = 'Cyan' }); Command = '__settings__' }
    )
    $selectedIndex = 0
    if (-not [string]::IsNullOrWhiteSpace($InitialCommand)) {
        for ($index = 0; $index -lt $options.Count; $index++) {
            if ($options[$index].Command -eq $InitialCommand) {
                $selectedIndex = $index
                break
            }
        }
    }
    $shortcutBuffer = ''
    $animateBanner = $true

    while ($true) {
        Clear-Host
        Show-SlmnBanner -Animate:$animateBanner
        $animateBanner = $false
        Write-Host '  Create a clean project, ready for your next idea.' -ForegroundColor White
        Write-Host '  Use Up/Down + Enter, or type a shortcut.' -ForegroundColor DarkGray
        Write-Host ''

        $previousGroup = ''
        for ($index = 0; $index -lt $options.Count; $index++) {
            if ($options[$index].Group -ne $previousGroup) {
                Write-Host "  $($options[$index].Group)" -ForegroundColor DarkCyan
                $previousGroup = $options[$index].Group
            }

            if ($index -eq $selectedIndex) {
                Write-Host '  > ' -NoNewline -ForegroundColor Cyan -BackgroundColor DarkBlue
                Write-Host $options[$index].Label -NoNewline -ForegroundColor White -BackgroundColor DarkBlue
                Write-Host '  | ' -NoNewline -ForegroundColor DarkGray -BackgroundColor DarkBlue
                foreach ($badge in $options[$index].Badges) {
                    Write-Host " [$($badge.Text)]" -NoNewline -ForegroundColor $badge.Color -BackgroundColor DarkBlue
                }
                Write-Host "  |  $($options[$index].Shortcut)" -ForegroundColor DarkGray -BackgroundColor DarkBlue
            } else {
                Write-Host '    ' -NoNewline
                Write-Host $options[$index].Label -NoNewline -ForegroundColor White
                Write-Host '  | ' -NoNewline -ForegroundColor DarkGray
                foreach ($badge in $options[$index].Badges) {
                    Write-Host " [$($badge.Text)]" -NoNewline -ForegroundColor $badge.Color
                }
                Write-Host "  |  $($options[$index].Shortcut)" -ForegroundColor DarkGray
            }
        }
        Write-Host ''
        Write-Host '  Esc  Cancel' -ForegroundColor DarkGray

        $keyInfo = [Console]::ReadKey($true)
        switch ($keyInfo.Key) {
            'UpArrow' {
                $selectedIndex = if ($selectedIndex -eq 0) { $options.Count - 1 } else { $selectedIndex - 1 }
            }
            'DownArrow' {
                $selectedIndex = if ($selectedIndex -eq ($options.Count - 1)) { 0 } else { $selectedIndex + 1 }
            }
            'Enter' {
                return $options[$selectedIndex].Command
            }
            'Escape' {
                return $null
            }
            default {
                if ([char]::IsControl($keyInfo.KeyChar)) {
                    continue
                }

                $shortcutBuffer += $keyInfo.KeyChar.ToString().ToLowerInvariant()
                $matches = @($options | Where-Object { $_.Keys | Where-Object { $_.StartsWith($shortcutBuffer) } })
                if ($matches.Count -eq 0) {
                    $shortcutBuffer = ''
                    continue
                }

                $exactMatch = @($matches | Where-Object { $_.Keys -contains $shortcutBuffer })
                $hasLongerMatch = @($matches | Where-Object { $_.Keys | Where-Object { $_.Length -gt $shortcutBuffer.Length } }).Count -gt 0
                if ($exactMatch.Count -eq 1 -and -not $hasLongerMatch) {
                    return $exactMatch[0].Command
                }

                $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                while ($stopwatch.ElapsedMilliseconds -lt 650 -and -not [Console]::KeyAvailable) {
                    [System.Threading.Thread]::Sleep(25)
                }
                if ($exactMatch.Count -eq 1 -and -not [Console]::KeyAvailable) {
                    return $exactMatch[0].Command
                }
            }
        }
    }
}

function Read-SlmnProjectName {
    $name = New-Object System.Text.StringBuilder
    Write-Host '  Project name (Escape or Left Arrow returns to the starter menu): ' -NoNewline -ForegroundColor Cyan

    while ($true) {
        $keyInfo = [Console]::ReadKey($true)
        switch ($keyInfo.Key) {
            'Enter' {
                Write-Host ''
                return $name.ToString()
            }
            'Escape' {
                Write-Host ''
                return $null
            }
            'LeftArrow' {
                Write-Host ''
                return $null
            }
            'Backspace' {
                if ($name.Length -gt 0) {
                    $name.Remove($name.Length - 1, 1) | Out-Null
                    Write-Host "`b `b" -NoNewline
                }
            }
            default {
                if (-not [char]::IsControl($keyInfo.KeyChar)) {
                    [void]$name.Append($keyInfo.KeyChar)
                    Write-Host $keyInfo.KeyChar -NoNewline
                }
            }
        }
    }
}

function Test-ProjectDependency {
    param(
        [string]$Path,
        [string]$Name
    )

    $packagePath = Join-Path $Path 'package.json'
    if (-not (Test-Path -LiteralPath $packagePath)) {
        throw "package.json was not found in $Path"
    }

    $package = Get-Content -LiteralPath $packagePath -Raw | ConvertFrom-Json
    $dependencyNames = @()
    if ($package.dependencies) {
        $dependencyNames += $package.dependencies.PSObject.Properties.Name
    }
    if ($package.devDependencies) {
        $dependencyNames += $package.devDependencies.PSObject.Properties.Name
    }

    return $dependencyNames -contains $Name
}

function Initialize-ViteTailwind {
    param([string]$Path)

    if (Test-ProjectDependency -Path $Path -Name 'tailwindcss') {
        Write-Host 'Tailwind CSS is already installed.' -ForegroundColor DarkGray
        return
    }

    Push-Location $Path
    try {
        Invoke-NpmDevInstall tailwindcss @tailwindcss/vite
    } finally {
        Pop-Location
    }

    $configFile = Get-ChildItem -LiteralPath $Path -File |
        Where-Object { $_.Name -match '^vite\.config\.(js|ts|mjs|mts)$' } |
        Select-Object -First 1
    if (-not $configFile) {
        $configPath = Join-Path $Path 'vite.config.js'
        @'
import { defineConfig } from 'vite'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
    plugins: [tailwindcss()],
})
'@ | Set-Content -LiteralPath $configPath -Encoding utf8
    } else {
        $config = Get-Content -LiteralPath $configFile.FullName -Raw
        if ($config -notmatch '@tailwindcss/vite') {
            $config = "import tailwindcss from '@tailwindcss/vite'`n$config"
        }
        if ($config -notmatch 'tailwindcss\(\)') {
            if ($config -match 'plugins:\s*\[') {
                $config = [regex]::Replace($config, 'plugins:\s*\[', 'plugins: [tailwindcss(), ', 1)
            } elseif ($config -match 'defineConfig\(\{') {
                $config = [regex]::Replace($config, 'defineConfig\(\{', "defineConfig({`n    plugins: [tailwindcss()],", 1)
            } else {
                throw "Could not add the Tailwind Vite plugin to $($configFile.Name)"
            }
        }
        Set-Content -LiteralPath $configFile.FullName -Value $config -Encoding utf8
    }

    $sourcePath = Join-Path $Path 'src'
    $entryFile = Get-ChildItem -LiteralPath $sourcePath -File -ErrorAction SilentlyContinue |
        Where-Object { $_.BaseName -eq 'main' } |
        Select-Object -First 1
    $stylesheetPath = $null
    if ($entryFile) {
        $entry = Get-Content -LiteralPath $entryFile.FullName -Raw
        if ($entry -match 'import\s+[''"](?<stylesheet>[^''"]+\.css)[''"]') {
            $stylesheetPath = Join-Path $entryFile.DirectoryName ($Matches.stylesheet -replace '^\./', '')
        }
    }
    if (-not $stylesheetPath -or -not (Test-Path -LiteralPath $stylesheetPath)) {
        $stylesheetPath = Get-ChildItem -LiteralPath $sourcePath -Recurse -File -Filter '*.css' -ErrorAction SilentlyContinue |
            Select-Object -First 1 -ExpandProperty FullName
    }
    if (-not $stylesheetPath) {
        throw "Could not find a CSS entry file in $sourcePath"
    }

    $stylesheet = Get-Content -LiteralPath $stylesheetPath -Raw
    if ($stylesheet -notmatch '@import\s+["'']tailwindcss["'']') {
        Set-Content -LiteralPath $stylesheetPath -Value "@import `"tailwindcss`";`n`n$stylesheet" -Encoding utf8
    }
}

function Set-FullDemoPage {
    param(
        [string]$Path,
        [string]$Name
    )

    $appPath = @(
        (Join-Path $Path 'src/App.jsx'),
        (Join-Path $Path 'src/App.tsx')
    ) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
    if (-not $appPath) {
        throw "Full starter requires a React Vite project. Choose React in Vite's framework prompt."
    }

    $componentExtension = if ($appPath.EndsWith('.tsx')) { 'tsx' } else { 'jsx' }
    $isTypeScript = $componentExtension -eq 'tsx'
    $componentPath = Join-Path $Path 'src/components'
    $threeComponentPath = Join-Path $componentPath 'three'
    $stylesPath = Join-Path $Path 'src/styles'
    New-Item -ItemType Directory -Path $componentPath, $threeComponentPath, $stylesPath -Force | Out-Null

    $heroRef = if ($isTypeScript) { 'useRef<HTMLElement | null>(null)' } else { 'useRef(null)' }
    $titleRef = if ($isTypeScript) { 'useRef<HTMLHeadingElement | null>(null)' } else { 'useRef(null)' }
    $techPillProps = if ($isTypeScript) { ': { name: string; detail: string; href: string; Icon: IconType }' } else { '' }
    $techPillTypeImport = if ($isTypeScript) { "import type { IconType } from 'react-icons'`n" } else { '' }
    $canvasRef = if ($isTypeScript) { 'useRef<HTMLCanvasElement | null>(null)' } else { 'useRef(null)' }
    $pointerEventType = if ($isTypeScript) { ': PointerEvent' } else { '' }
    $languageName = if ($isTypeScript) { 'TypeScript' } else { 'JavaScript' }
    $languageHref = if ($isTypeScript) { 'https://www.typescriptlang.org/' } else { 'https://developer.mozilla.org/docs/Web/JavaScript' }
    $languageIconName = if ($isTypeScript) { 'SiTypescript' } else { 'SiJavascript' }

    @"
import Hero from './components/Hero.$componentExtension'

export default function App() {
    return <Hero />
}
"@ | Set-Content -LiteralPath $appPath -Encoding utf8

    @"
import { useLayoutEffect, useRef } from 'react'
import gsap from 'gsap'
import { SiGreensock, $languageIconName, SiReact, SiTailwindcss, SiThreedotjs, SiVite } from 'react-icons/si'
import TechPill from './TechPill.$componentExtension'
import ThreeScene from './three/ThreeScene.$componentExtension'
import '../styles/demo.css'

const technologies = [
    {
        name: 'Vite',
        detail: 'Build tooling',
        href: 'https://vite.dev/',
        Icon: SiVite,
    },
    {
        name: 'React',
        detail: 'UI library',
        href: 'https://react.dev/',
        Icon: SiReact,
    },
    {
        name: '$languageName',
        detail: 'Language',
        href: '$languageHref',
        Icon: $languageIconName,
    },
    {
        name: 'Tailwind CSS',
        detail: 'Responsive layout',
        href: 'https://tailwindcss.com/',
        Icon: SiTailwindcss,
    },
    {
        name: 'GSAP',
        detail: 'Entrance motion',
        href: 'https://gsap.com/',
        Icon: SiGreensock,
    },
    {
        name: 'Three.js',
        detail: 'Pointer controls',
        href: 'https://threejs.org/',
        Icon: SiThreedotjs,
    },
]

export default function Hero() {
    const heroRef = $heroRef
    const titleRef = $titleRef

    useLayoutEffect(() => {
        const context = gsap.context(() => {
            gsap.from(titleRef.current, {
                y: 28,
                opacity: 0,
                duration: 0.8,
                ease: 'power3.out',
            })
            gsap.from('[data-demo-reveal]', {
                y: 16,
                opacity: 0,
                duration: 0.55,
                stagger: 0.1,
                delay: 0.2,
                ease: 'power2.out',
            })
        }, heroRef)

        return () => context.revert()
    }, [])

    return (
        <section className="demo-shell p-5 text-white">
            <header ref={heroRef} className="demo-grid mx-auto grid items-center gap-8 lap:grid-cols-[1fr_0.9fr]">
                <div>
                    <p data-demo-reveal className="mb-4 text-sm font-semibold uppercase tracking-[0.18em] text-blue-300">
                        SLMN React Starter
                    </p>
                    <h1 ref={titleRef} className="max-w-xl text-4xl font-semibold leading-tight tab:text-5xl lap:text-6xl fhd:text-7xl">
                        Build Your Modern App.
                    </h1>
                    <p data-demo-reveal className="mt-5 max-w-lg text-base leading-7 text-neutral-300 tab:text-lg">
                        A removable preview for React, Tailwind CSS, GSAP, and a mouse-controlled Three.js model.
                    </p>
                    <div data-demo-reveal className="mt-8 grid gap-3 tab:grid-cols-2 lap:grid-cols-3">
                        {technologies.map((technology) => (
                            <TechPill key={technology.name} {...technology} />
                        ))}
                    </div>
                    <p data-demo-reveal className="mt-3 text-sm text-neutral-400">
                        Each card opens its official site in a new tab.
                    </p>
                </div>

                <ThreeScene />
            </header>
        </section>
    )
}
"@ | Set-Content -LiteralPath (Join-Path $componentPath "Hero.$componentExtension") -Encoding utf8

@"
$techPillTypeImport
export default function TechPill({ name, detail, href, Icon }$techPillProps) {
    return (
        <a
            href={href}
            target="_blank"
            rel="noreferrer"
            className="demo-tech-pill flex cursor-pointer items-start gap-3 border border-white/10 bg-white/5 p-4 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-300"
        >
            <Icon aria-hidden="true" className="mt-0.5 size-5 shrink-0 text-blue-300" />
            <span>
                <span className="block font-semibold text-white">{name}</span>
                <span className="mt-1 block text-sm text-neutral-400">{detail}</span>
            </span>
        </a>
    )
}
"@ | Set-Content -LiteralPath (Join-Path $componentPath "TechPill.$componentExtension") -Encoding utf8

@"
import { useEffect, useRef } from 'react'
import * as THREE from 'three'

export default function ThreeScene() {
    const canvasRef = $canvasRef

    useEffect(() => {
        const canvas = canvasRef.current
        if (!canvas) return undefined

        const scene = new THREE.Scene()
        const camera = new THREE.PerspectiveCamera(40, 1, 0.1, 100)
        camera.position.set(0, 0, 4)

        const renderer = new THREE.WebGLRenderer({ canvas, alpha: true, antialias: true })
        const geometry = new THREE.IcosahedronGeometry(1, 2)
        const material = new THREE.MeshStandardMaterial({
            color: 0x60a5fa,
            metalness: 0.45,
            roughness: 0.25,
        })
        const mesh = new THREE.Mesh(geometry, material)
        const wireframe = new THREE.LineSegments(
            new THREE.WireframeGeometry(geometry),
            new THREE.LineBasicMaterial({ color: 0xffffff, transparent: true, opacity: 0.28 }),
        )
        scene.add(mesh, wireframe)

        const keyLight = new THREE.DirectionalLight(0xffffff, 2.5)
        keyLight.position.set(2, 2, 3)
        scene.add(keyLight, new THREE.AmbientLight(0x4466aa, 1.5))

        const pointer = { x: 0, y: 0 }
        const resize = () => {
            const width = Math.max(canvas.clientWidth, 1)
            const height = Math.max(canvas.clientHeight, 1)
            renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2))
            renderer.setSize(width, height, false)
            camera.aspect = width / height
            camera.updateProjectionMatrix()
        }
        const handlePointerMove = (event$pointerEventType) => {
            const bounds = canvas.getBoundingClientRect()
            pointer.x = ((event.clientX - bounds.left) / bounds.width - 0.5) * 1.1
            pointer.y = ((event.clientY - bounds.top) / bounds.height - 0.5) * 0.8
        }
        const resetPointer = () => {
            pointer.x = 0
            pointer.y = 0
        }

        const resizeObserver = new ResizeObserver(resize)
        resizeObserver.observe(canvas)
        canvas.addEventListener('pointermove', handlePointerMove)
        canvas.addEventListener('pointerleave', resetPointer)

        let frameId = 0
        const render = () => {
            mesh.rotation.y += (pointer.x - mesh.rotation.y) * 0.04
            mesh.rotation.x += (-pointer.y - mesh.rotation.x) * 0.04
            mesh.rotation.z += 0.002
            wireframe.rotation.copy(mesh.rotation)
            renderer.render(scene, camera)
            frameId = requestAnimationFrame(render)
        }

        resize()
        render()

        return () => {
            cancelAnimationFrame(frameId)
            resizeObserver.disconnect()
            canvas.removeEventListener('pointermove', handlePointerMove)
            canvas.removeEventListener('pointerleave', resetPointer)
            geometry.dispose()
            material.dispose()
            wireframe.geometry.dispose()
            wireframe.material.dispose()
            renderer.dispose()
        }
    }, [])

    return (
        <div data-demo-reveal className="demo-scene relative overflow-hidden border border-white/10 bg-neutral-800 shadow-2xl shadow-black/25">
            <canvas
                ref={canvasRef}
                className="demo-canvas h-80 w-full tab:h-96"
                aria-label="Interactive 3D model. Move your pointer over the canvas to rotate it."
            />
            <div className="pointer-events-none absolute inset-x-0 bottom-0 flex items-center justify-between border-t border-white/10 bg-neutral-900/80 px-5 py-4 backdrop-blur">
                <span className="text-sm font-medium text-white">Move pointer to rotate</span>
                <span className="text-xs uppercase tracking-[0.16em] text-blue-300">WebGL active</span>
            </div>
        </div>
    )
}
"@ | Set-Content -LiteralPath (Join-Path $threeComponentPath "ThreeScene.$componentExtension") -Encoding utf8

@'
.demo-shell {
    min-height: 100vh;
    text-align: left;
    background-color: #171717;
    background-image: linear-gradient(rgb(255 255 255 / 0.035) 1px, transparent 1px), linear-gradient(90deg, rgb(255 255 255 / 0.035) 1px, transparent 1px);
    background-size: 3rem 3rem;
}

.demo-grid {
    position: relative;
    width: min(100%, 72rem);
    min-height: min(30rem, calc(100svh - 40px));
}

.demo-tech-pill {
    transition: border-color 160ms ease, background-color 160ms ease, transform 160ms ease;
}

.demo-tech-pill:hover {
    border-color: rgb(147 197 253 / 0.65);
    background: rgb(255 255 255 / 0.09);
    transform: translateY(-2px);
}

.demo-scene {
    isolation: isolate;
    background-color: #202020;
}

.demo-canvas {
    display: block;
    cursor: grab;
    touch-action: none;
}

.demo-canvas:active {
    cursor: grabbing;
}
'@ | Set-Content -LiteralPath (Join-Path $stylesPath 'demo.css') -Encoding utf8

    @'
@import "tailwindcss";

    @theme {
        --breakpoint-tab: 48rem;
        --breakpoint-lap: 64rem;
        --breakpoint-fhd: 120rem;
    }

    @layer base {
    body {
            @apply min-h-screen bg-neutral-900 font-sans text-white antialiased;
    }
}
'@ | Set-Content -LiteralPath (Join-Path $Path 'src/index.css') -Encoding utf8

    @"
<!doctype html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$Name</title>
</head>
<body>
    <div id="root"></div>
    <script type="module" src="/src/main$([System.IO.Path]::GetExtension($appPath))"></script>
</body>
</html>
"@ | Set-Content -LiteralPath (Join-Path $Path 'index.html') -Encoding utf8

    Remove-Item -LiteralPath (Join-Path $Path 'src/assets') -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath (Join-Path $Path 'src/App.css') -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath (Join-Path $Path 'public') -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath (Join-Path $stylesPath 'app.css') -Force -ErrorAction SilentlyContinue
}

function Set-ReactStarterDemo {
    param(
        [string]$Path,
        [string]$Name,
        [switch]$IncludeTailwind,
        [switch]$IncludeGsap
    )

    $appPath = @(
        (Join-Path $Path 'src/App.jsx'),
        (Join-Path $Path 'src/App.tsx')
    ) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
    if (-not $appPath) {
        throw "React starter files were not found in $Path"
    }

    $componentExtension = if ($appPath.EndsWith('.tsx')) { 'tsx' } else { 'jsx' }
    $techPillProps = if ($componentExtension -eq 'tsx') { ': { name: string; detail: string; href: string }' } else { '' }
    $componentsPath = Join-Path $Path 'src/components'
    $stylesPath = Join-Path $Path 'src/styles'
    New-Item -ItemType Directory -Path $componentsPath, $stylesPath -Force | Out-Null
    $indexStyles = if ($IncludeTailwind) {
@'
@import "tailwindcss";

@layer base {
    html {
        background-color: #171717;
    }

    body {
        min-width: 320px;
        min-height: 100svh;
        margin: 0;
        background-color: #171717;
        color: #ffffff;
        font-family: "Aptos", "Segoe UI", sans-serif;
    }
}
'@
    } else {
@'
html {
    background-color: #171717;
}

body {
    min-width: 320px;
    min-height: 100svh;
    margin: 0;
    background-color: #171717;
    color: #ffffff;
    font-family: "Aptos", "Segoe UI", sans-serif;
}
'@
    }
    Set-Content -LiteralPath (Join-Path $Path 'src/index.css') -Value $indexStyles -Encoding utf8

    $technologies = @(
        @{ Name = 'Vite'; Detail = 'Build tooling'; Href = 'https://vite.dev/' },
        @{ Name = 'React'; Detail = 'UI library'; Href = 'https://react.dev/' },
        @{ Name = $(if ($componentExtension -eq 'tsx') { 'TypeScript' } else { 'JavaScript' }); Detail = 'Language'; Href = $(if ($componentExtension -eq 'tsx') { 'https://www.typescriptlang.org/' } else { 'https://developer.mozilla.org/docs/Web/JavaScript' }) }
    )
    if ($IncludeTailwind) {
        $technologies += @{ Name = 'Tailwind CSS'; Detail = 'Utility styling'; Href = 'https://tailwindcss.com/' }
    }
    if ($IncludeGsap) {
        $technologies += @{ Name = 'GSAP'; Detail = 'Entrance motion'; Href = 'https://gsap.com/' }
    }
    $technologyItems = ($technologies | ForEach-Object {
@"
    {
        name: '$($_.Name)',
        detail: '$($_.Detail)',
        href: '$($_.Href)',
    },
"@
    }) -join ''
    $gsapImports = if ($IncludeGsap) { "import { useLayoutEffect, useRef } from 'react'`nimport gsap from 'gsap'" } else { '' }
    $heroReference = if ($IncludeGsap -and $componentExtension -eq 'tsx') {
        "    const heroRef = useRef<HTMLElement | null>(null)`n    const titleRef = useRef<HTMLHeadingElement | null>(null)`n"
    } elseif ($IncludeGsap) {
        "    const heroRef = useRef(null)`n    const titleRef = useRef(null)`n"
    } else { '' }
    $animation = if ($IncludeGsap) {
@'
    useLayoutEffect(() => {
        const context = gsap.context(() => {
            gsap.from(titleRef.current, {
                y: 28,
                opacity: 0,
                duration: 0.8,
                ease: 'power3.out',
            })
            gsap.from('[data-demo-reveal]', {
                y: 16,
                opacity: 0,
                duration: 0.55,
                stagger: 0.1,
                delay: 0.2,
                ease: 'power2.out',
            })
        }, heroRef)

        return () => context.revert()
    }, [])
'@
    } else { '' }
    $headerRef = if ($IncludeGsap) { ' ref={heroRef}' } else { '' }
    $titleRef = if ($IncludeGsap) { ' ref={titleRef}' } else { '' }
    $description = if ($IncludeGsap) { 'A removable preview for React with a focused GSAP entrance animation.' } elseif ($IncludeTailwind) { 'A removable preview for React with Tailwind CSS ready for your application.' } else { 'A removable preview for a clean React application.' }
    $shellClass = if ($IncludeGsap) { 'demo-shell demo-use-gsap' } else { 'demo-shell' }

    @"
import Hero from './components/Hero.$componentExtension'

export default function App() {
    return <Hero />
}
"@ | Set-Content -LiteralPath $appPath -Encoding utf8

    @"
$gsapImports
import TechPill from './TechPill.$componentExtension'
import StarterVisual from './StarterVisual.$componentExtension'
import '../styles/demo.css'

const technologies = [
$technologyItems]

export default function Hero() {
$heroReference$animation
    return (
        <section className="$shellClass">
            <header$headerRef className="demo-grid">
                <div className="demo-copy">
                    <p data-demo-reveal className="demo-eyebrow">SLMN React Starter</p>
                    <h1$titleRef>Build Your Modern App.</h1>
                    <p data-demo-reveal className="demo-description">
                        $description
                    </p>
                    <div data-demo-reveal className="demo-tech-list">
                        {technologies.map((technology) => (
                            <TechPill key={technology.name} {...technology} />
                        ))}
                    </div>
                    <p data-demo-reveal className="demo-note">
                        Each card opens its official site in a new tab.
                    </p>
                </div>
                <StarterVisual />
            </header>
        </section>
    )
}
"@ | Set-Content -LiteralPath (Join-Path $componentsPath "Hero.$componentExtension") -Encoding utf8

    @"
export default function TechPill({ name, detail, href }$techPillProps) {
    return (
        <a
            href={href}
            target="_blank"
            rel="noreferrer"
            className="demo-tech-pill"
        >
            <span className="demo-tech-mark" aria-hidden="true">{name.slice(0, 1)}</span>
            <span>
                <span className="demo-tech-name">{name}</span>
                <span className="demo-tech-detail">{detail}</span>
            </span>
        </a>
    )
}
"@ | Set-Content -LiteralPath (Join-Path $componentsPath "TechPill.$componentExtension") -Encoding utf8

    @'
export default function StarterVisual() {
    return (
        <div
            className="demo-visual"
            data-demo-reveal
            aria-hidden="true"
            onPointerMove={(event) => {
                const bounds = event.currentTarget.getBoundingClientRect()
                const pointerX = Math.round(((event.clientX - bounds.left) / bounds.width - 0.5) * 22)
                const pointerY = Math.round(((event.clientY - bounds.top) / bounds.height - 0.5) * 22)
                event.currentTarget.style.setProperty('--demo-pointer-x', `${pointerX}px`)
                event.currentTarget.style.setProperty('--demo-pointer-y', `${pointerY}px`)
            }}
            onPointerLeave={(event) => {
                event.currentTarget.style.setProperty('--demo-pointer-x', '0px')
                event.currentTarget.style.setProperty('--demo-pointer-y', '0px')
            }}
        >
            <span className="demo-visual-grid" />
            <div className="demo-visual-signal">
                <span className="demo-visual-core">S</span>
                <span className="demo-visual-node demo-visual-node-one" />
                <span className="demo-visual-node demo-visual-node-two" />
                <span className="demo-visual-node demo-visual-node-three" />
            </div>
            <span className="demo-visual-scan" />
            <span className="demo-visual-caption">SLMN / 01</span>
        </div>
    )
}
'@ | Set-Content -LiteralPath (Join-Path $componentsPath "StarterVisual.$componentExtension") -Encoding utf8

    @'
.demo-shell {
    box-sizing: border-box;
    display: grid;
    width: 100%;
    min-height: 100svh;
    padding: 20px;
    place-items: center;
    color: #ffffff;
    text-align: left;
    background-color: #171717;
    background-image: linear-gradient(rgb(255 255 255 / 0.035) 1px, transparent 1px), linear-gradient(90deg, rgb(255 255 255 / 0.035) 1px, transparent 1px);
    background-size: 3rem 3rem;
}

.demo-grid {
    display: grid;
    width: 100%;
    max-width: 72rem;
    min-height: min(30rem, calc(100svh - 40px));
    padding: 0;
    margin: 0 auto;
    align-items: center;
    gap: 2.5rem;
}

.demo-copy {
    max-width: 38rem;
}

.demo-eyebrow {
    margin: 0 0 1rem;
    color: #93c5fd;
    font-size: 0.875rem;
    font-weight: 600;
    letter-spacing: 0.18em;
    text-transform: uppercase;
}

.demo-copy h1 {
    max-width: 36rem;
    margin: 0;
    font-size: 3rem;
    font-weight: 600;
    line-height: 1.1;
}

.demo-description {
    max-width: 34rem;
    margin: 1.25rem 0 0;
    color: #d4d4d4;
    font-size: 1rem;
    line-height: 1.65;
}

.demo-tech-list {
    display: grid;
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 0.75rem;
    margin-top: 2.25rem;
}

.demo-tech-pill {
    display: flex;
    min-height: 5rem;
    gap: 0.75rem;
    align-items: center;
    padding: 0.875rem;
    color: inherit;
    text-decoration: none;
    background: rgb(255 255 255 / 0.045);
    border: 1px solid rgb(255 255 255 / 0.1);
    transition: border-color 160ms ease, background-color 160ms ease, transform 160ms ease;
}

.demo-tech-pill:hover {
    background: rgb(255 255 255 / 0.09);
    border-color: rgb(125 211 252 / 0.72);
    transform: translateY(-2px);
}

.demo-tech-pill:focus-visible {
    outline: 2px solid #7dd3fc;
    outline-offset: 3px;
}

.demo-tech-mark {
    display: grid;
    width: 1.8rem;
    height: 1.8rem;
    flex: 0 0 auto;
    place-items: center;
    color: #bae6fd;
    font-size: 0.75rem;
    font-weight: 700;
    background: #0c4a6e;
}

.demo-tech-name,
.demo-tech-detail {
    display: block;
}

.demo-tech-name {
    color: #ffffff;
    font-weight: 650;
}

.demo-tech-detail {
    margin-top: 0.2rem;
    color: #a3a3a3;
    font-size: 0.75rem;
}

.demo-note {
    margin: 0.75rem 0 0;
    color: #a3a3a3;
    font-size: 0.875rem;
}

.demo-visual {
    --demo-pointer-x: 0px;
    --demo-pointer-y: 0px;
    position: relative;
    min-height: 22rem;
    overflow: hidden;
    isolation: isolate;
    background: #1d2329;
    border: 1px solid rgb(255 255 255 / 0.11);
}

.demo-visual-grid {
    position: absolute;
    inset: 0;
    background-image: linear-gradient(#26313a 1px, transparent 1px), linear-gradient(90deg, #26313a 1px, transparent 1px);
    background-size: 2rem 2rem;
    opacity: 0.85;
}

.demo-visual-signal {
    position: absolute;
    top: 50%;
    left: 50%;
    width: 15rem;
    height: 15rem;
    transform: translate(calc(-50% + var(--demo-pointer-x)), calc(-50% + var(--demo-pointer-y)));
    transition: transform 180ms ease-out;
}

.demo-visual-core,
.demo-visual-node {
    position: absolute;
    display: block;
}

.demo-visual-core {
    top: 50%;
    left: 50%;
    width: 5rem;
    height: 5rem;
    display: grid;
    place-items: center;
    color: #38bdf8;
    font-family: "Aptos", "Segoe UI", sans-serif;
    font-size: 5.25rem;
    font-weight: 700;
    line-height: 1;
    text-shadow: 0 0 1.5rem rgb(56 189 248 / 0.82);
    transform: translate(-50%, -50%);
    animation: demo-core-pulse 2.8s ease-in-out infinite;
}

.demo-visual-node {
    width: 0.75rem;
    height: 0.75rem;
    background: #f0f9ff;
    box-shadow: 0 0 1rem rgb(125 211 252 / 0.9);
}

.demo-visual-node-one {
    top: 1.4rem;
    left: 2.1rem;
}

.demo-visual-node-two {
    right: 1.8rem;
    bottom: 2.75rem;
}

.demo-visual-node-three {
    top: 50%;
    right: -0.375rem;
}

.demo-visual-scan {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 1px;
    background: #7dd3fc;
    box-shadow: 0 0 1rem #38bdf8;
    animation: demo-scan 4.5s ease-in-out infinite;
}

.demo-visual-caption {
    position: absolute;
    right: 1rem;
    bottom: 0.875rem;
    color: #bae6fd;
    font-size: 0.7rem;
    font-weight: 700;
    letter-spacing: 0.15em;
}

[data-demo-reveal] {
    animation: demo-reveal 650ms both;
}

.demo-use-gsap [data-demo-reveal] {
    animation: none;
}

@keyframes demo-reveal {
    from { opacity: 0; transform: translateY(1rem); }
    to { opacity: 1; transform: translateY(0); }
}

@keyframes demo-core-pulse {
    50% { opacity: 0.72; text-shadow: 0 0 2.25rem rgb(56 189 248 / 0.98); }
}

@keyframes demo-scan {
    50% { transform: translateY(22rem); }
}

@media (min-width: 48rem) {
    .demo-copy h1 {
        font-size: 4.5rem;
    }
}

@media (min-width: 64rem) {
    .demo-grid {
        grid-template-columns: minmax(0, 1fr) minmax(20rem, 0.85fr);
        gap: 4rem;
    }

    .demo-visual {
        min-height: 30rem;
    }

    @keyframes demo-scan {
        50% { transform: translateY(30rem); }
    }
}
'@ | Set-Content -LiteralPath (Join-Path $stylesPath 'demo.css') -Encoding utf8

    @"
<!doctype html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$Name</title>
</head>
<body>
    <div id="root"></div>
    <script type="module" src="/src/main$([System.IO.Path]::GetExtension($appPath))"></script>
</body>
</html>
"@ | Set-Content -LiteralPath (Join-Path $Path 'index.html') -Encoding utf8

    Remove-Item -LiteralPath (Join-Path $Path 'src/assets') -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath (Join-Path $Path 'public') -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath (Join-Path $Path 'src/App.css') -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath (Join-Path $Path 'README.md') -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath (Join-Path $stylesPath 'app.css') -Force -ErrorAction SilentlyContinue
}

function Set-NextStarterScreen {
    param(
        [string]$Path,
        [string]$Name,
        [switch]$IncludeTailwind,
        [switch]$IncludeGsap
    )

    $appDirectory = @(
        (Join-Path $Path 'app'),
        (Join-Path $Path 'src/app')
    ) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
    if (-not $appDirectory) {
        Write-Warning 'Could not find a Next.js App Router directory; the generated Next.js start screen was not applied.'
        return
    }

    $pagePath = @('page.tsx', 'page.jsx', 'page.js') |
        ForEach-Object { Join-Path $appDirectory $_ } |
        Where-Object { Test-Path -LiteralPath $_ } |
        Select-Object -First 1
    if (-not $pagePath) {
        Write-Warning 'Could not find a Next.js page file; the generated Next.js start screen was not applied.'
        return
    }

    $componentExtension = if ($pagePath.EndsWith('.tsx')) { 'tsx' } else { 'jsx' }
    $componentsDirectory = Join-Path (Split-Path -Parent $appDirectory) 'components'
    New-Item -ItemType Directory -Path $componentsDirectory -Force | Out-Null
    $technologies = @('Next.js', 'Next.js Docs', 'React', $(if ($componentExtension -eq 'tsx') { 'TypeScript' } else { 'JavaScript' }))
    if ($IncludeTailwind) {
        $technologies += 'Tailwind CSS'
    }
    if ($IncludeGsap) {
        $technologies += 'GSAP'
    }
    $technologyCards = ($technologies | ForEach-Object {
        $technology = Get-SlmnTechnologyInfo $_
@"
                        <a className="slmn-next-tech-card" href="$($technology.Href)" target="_blank" rel="noreferrer">
                            <span className="slmn-next-tech-mark" aria-hidden="true">$($technology.Name.Substring(0, 1))</span>
                            <span>
                                <span className="slmn-next-tech-name">$($technology.Name)</span>
                                <span className="slmn-next-tech-detail">$($technology.Detail)</span>
                            </span>
                        </a>
"@
    }) -join "`n"
    $gsapImport = if ($IncludeGsap) { "import { useLayoutEffect, useRef } from 'react'`nimport gsap from 'gsap'" } else { '' }
    $screenRefDeclaration = if ($IncludeGsap -and $componentExtension -eq 'tsx') {
        '    const screenRef = useRef<HTMLElement | null>(null)'
    } else {
        '    const screenRef = useRef(null)'
    }
    $animation = if ($IncludeGsap) {
@"
$screenRefDeclaration

    useLayoutEffect(() => {
        const context = gsap.context(() => {
            gsap.from('[data-slmn-reveal]', {
                y: 18,
                opacity: 0,
                duration: 0.55,
                stagger: 0.1,
                ease: 'power2.out',
            })
        }, screenRef)

        return () => context.revert()
    }, [])
"@
    } else { '' }
    $screenReference = if ($IncludeGsap) { ' ref={screenRef}' } else { '' }
    $screenClass = if ($IncludeGsap) { 'slmn-next-shell slmn-next-use-gsap' } else { 'slmn-next-shell' }

    @"
'use client'

$gsapImport

export default function SlmnStartScreen() {
$animation
    return (
        <main$screenReference className="$screenClass">
            <section className="slmn-next-screen">
                <div className="slmn-next-copy">
                    <p className="slmn-next-kicker" data-slmn-next-reveal>SLMN Starter</p>
                    <h1 data-slmn-next-reveal>Build what is next.</h1>
                    <p className="slmn-next-project" data-slmn-next-reveal>$Name</p>
                    <p className="slmn-next-description" data-slmn-next-reveal>A clear starting point, shaped for this project's actual stack.</p>
                    <div className="slmn-next-tech-list" data-slmn-next-reveal>
$technologyCards
                    </div>
                </div>
                <div
                    className="slmn-next-visual"
                    data-slmn-next-reveal
                    aria-hidden="true"
                    onPointerMove={(event) => {
                        const bounds = event.currentTarget.getBoundingClientRect()
                        const pointerX = Math.round(((event.clientX - bounds.left) / bounds.width - 0.5) * 22)
                        const pointerY = Math.round(((event.clientY - bounds.top) / bounds.height - 0.5) * 22)
                        event.currentTarget.style.setProperty('--slmn-next-pointer-x', pointerX + 'px')
                        event.currentTarget.style.setProperty('--slmn-next-pointer-y', pointerY + 'px')
                    }}
                    onPointerLeave={(event) => {
                        event.currentTarget.style.setProperty('--slmn-next-pointer-x', '0px')
                        event.currentTarget.style.setProperty('--slmn-next-pointer-y', '0px')
                    }}
                >
                    <span className="slmn-next-visual-grid" />
                    <div className="slmn-next-visual-signal">
                        <span className="slmn-next-visual-core">S</span>
                        <span className="slmn-next-visual-node slmn-next-visual-node-one" />
                        <span className="slmn-next-visual-node slmn-next-visual-node-two" />
                        <span className="slmn-next-visual-node slmn-next-visual-node-three" />
                    </div>
                    <span className="slmn-next-visual-scan" />
                    <span className="slmn-next-visual-caption">SLMN / 01</span>
                </div>
            </section>
        </main>
    )
}
"@ | Set-Content -LiteralPath (Join-Path $componentsDirectory "SlmnStartScreen.$componentExtension") -Encoding utf8

    @"
import './slmn-start.css'
import SlmnStartScreen from '../components/SlmnStartScreen'

export default function Home() {
    return <SlmnStartScreen />
}
"@ | Set-Content -LiteralPath $pagePath -Encoding utf8

    $globalStyles = if ($IncludeTailwind) { "@import `"tailwindcss`";`n`n" } else { '' }
    $globalStyles += @'
* {
    box-sizing: border-box;
}

html,
body {
    min-width: 320px;
    min-height: 100svh;
    margin: 0;
    background-color: #171717;
    background-image: linear-gradient(rgb(255 255 255 / 0.035) 1px, transparent 1px), linear-gradient(90deg, rgb(255 255 255 / 0.035) 1px, transparent 1px);
    background-size: 3rem 3rem;
}
'@
    Set-Content -LiteralPath (Join-Path $appDirectory 'globals.css') -Value $globalStyles -Encoding utf8

    @'
.slmn-next-shell {
    --slmn-next-shell-padding-y: clamp(1rem, 4vh, 2rem);
    display: grid;
    width: 100%;
    min-height: 100dvh;
    padding: var(--slmn-next-shell-padding-y) 20px;
    color: #ffffff;
    text-align: left;
    background-color: #171717;
    background-image: linear-gradient(rgb(255 255 255 / 0.035) 1px, transparent 1px), linear-gradient(90deg, rgb(255 255 255 / 0.035) 1px, transparent 1px);
    background-size: 3rem 3rem;
    place-items: safe center;
}

.slmn-next-screen {
    display: grid;
    width: 100%;
    max-width: 72rem;
    min-height: min(30rem, calc(100dvh - var(--slmn-next-shell-padding-y) - var(--slmn-next-shell-padding-y)));
    padding: 0;
    margin: 0 auto;
    align-items: center;
    gap: 2.5rem;
}

.slmn-next-copy {
    max-width: 38rem;
}

.slmn-next-kicker {
    margin: 0 0 1rem;
    color: #93c5fd;
    font-size: 0.875rem;
    font-weight: 600;
    letter-spacing: 0.18em;
    text-transform: uppercase;
}

.slmn-next-copy h1 {
    margin: 0;
    font-size: 3rem;
    font-weight: 600;
    line-height: 1.1;
}

.slmn-next-project {
    margin: 1.25rem 0 0;
    color: #d4d4d4;
    font-size: 1.125rem;
}

.slmn-next-description {
    max-width: 32rem;
    margin: 0.75rem 0 0;
    color: #a3a3a3;
    font-size: 1rem;
    line-height: 1.65;
}

.slmn-next-tech-list {
    display: grid;
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 0.75rem;
    margin-top: 2.25rem;
}

.slmn-next-tech-card {
    display: flex;
    min-height: 5rem;
    gap: 0.75rem;
    align-items: center;
    padding: 0.875rem;
    color: inherit;
    font-size: 0.875rem;
    text-decoration: none;
    background: rgb(255 255 255 / 0.045);
    border: 1px solid rgb(255 255 255 / 0.1);
    transition: border-color 160ms ease, background-color 160ms ease, transform 160ms ease;
}

.slmn-next-tech-card:hover {
    background: rgb(255 255 255 / 0.09);
    border-color: rgb(125 211 252 / 0.72);
    transform: translateY(-2px);
}

.slmn-next-tech-card:focus-visible {
    outline: 2px solid #7dd3fc;
    outline-offset: 3px;
}

.slmn-next-tech-mark {
    display: grid;
    width: 1.8rem;
    height: 1.8rem;
    flex: 0 0 auto;
    place-items: center;
    color: #bae6fd;
    font-size: 0.75rem;
    font-weight: 700;
    background: #0c4a6e;
}

.slmn-next-tech-name,
.slmn-next-tech-detail {
    display: block;
}

.slmn-next-tech-name {
    font-weight: 650;
}

.slmn-next-tech-detail {
    margin-top: 0.2rem;
    color: #a3a3a3;
    font-size: 0.75rem;
}

.slmn-next-visual {
    --slmn-next-pointer-x: 0px;
    --slmn-next-pointer-y: 0px;
    position: relative;
    min-height: 22rem;
    overflow: hidden;
    isolation: isolate;
    background: #1d2329;
    border: 1px solid rgb(255 255 255 / 0.11);
}

.slmn-next-visual-grid {
    position: absolute;
    inset: 0;
    background-image: linear-gradient(#26313a 1px, transparent 1px), linear-gradient(90deg, #26313a 1px, transparent 1px);
    background-size: 2rem 2rem;
    opacity: 0.85;
}

.slmn-next-visual-signal {
    position: absolute;
    top: 50%;
    left: 50%;
    width: 15rem;
    height: 15rem;
    transform: translate(calc(-50% + var(--slmn-next-pointer-x)), calc(-50% + var(--slmn-next-pointer-y)));
    transition: transform 180ms ease-out;
}

.slmn-next-visual-core,
.slmn-next-visual-node {
    position: absolute;
    display: block;
}

.slmn-next-visual-core {
    top: 50%;
    left: 50%;
    width: 5rem;
    height: 5rem;
    display: grid;
    place-items: center;
    color: #38bdf8;
    font-family: "Aptos", "Segoe UI", sans-serif;
    font-size: 5.25rem;
    font-weight: 700;
    line-height: 1;
    text-shadow: 0 0 1.5rem rgb(56 189 248 / 0.82);
    transform: translate(-50%, -50%);
    animation: slmn-next-core-pulse 2.8s ease-in-out infinite;
}

.slmn-next-visual-node {
    width: 0.75rem;
    height: 0.75rem;
    background: #f0f9ff;
    box-shadow: 0 0 1rem rgb(125 211 252 / 0.9);
}

.slmn-next-visual-node-one {
    top: 1.4rem;
    left: 2.1rem;
}

.slmn-next-visual-node-two {
    right: 1.8rem;
    bottom: 2.75rem;
}

.slmn-next-visual-node-three {
    top: 50%;
    right: -0.375rem;
}

.slmn-next-visual-scan {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 1px;
    background: #7dd3fc;
    box-shadow: 0 0 1rem #38bdf8;
    animation: slmn-next-scan 4.5s ease-in-out infinite;
}

.slmn-next-visual-caption {
    position: absolute;
    right: 1rem;
    bottom: 0.875rem;
    color: #bae6fd;
    font-size: 0.7rem;
    font-weight: 700;
    letter-spacing: 0.15em;
}

[data-slmn-next-reveal] {
    animation: slmn-next-reveal 650ms both;
}

.slmn-next-use-gsap [data-slmn-next-reveal] {
    animation: none;
}

@keyframes slmn-next-reveal {
    from { opacity: 0; transform: translateY(1rem); }
    to { opacity: 1; transform: translateY(0); }
}

@keyframes slmn-next-core-pulse {
    50% { opacity: 0.72; text-shadow: 0 0 2.25rem rgb(56 189 248 / 0.98); }
}

@keyframes slmn-next-scan {
    50% { transform: translateY(22rem); }
}

@media (min-width: 48rem) {
    .slmn-next-copy h1 {
        font-size: 4.5rem;
    }
}

@media (min-width: 64rem) {
    .slmn-next-screen {
        grid-template-columns: minmax(0, 1fr) minmax(20rem, 0.85fr);
        gap: 4rem;
    }

    .slmn-next-visual {
        min-height: 30rem;
    }

    @keyframes slmn-next-scan {
        50% { transform: translateY(30rem); }
    }
}
'@ | Set-Content -LiteralPath (Join-Path $appDirectory 'slmn-start.css') -Encoding utf8
}

function Complete-InteractiveProject {
    param(
        [string]$Path,
        [string]$Name,
        [ValidateSet('Vite', 'Next')][string]$Stack
    )

    if (-not (Test-Path -LiteralPath (Join-Path $Path 'node_modules'))) {
        Push-Location $Path
        try {
            Invoke-Npm install
        } finally {
            Pop-Location
        }
    }

    if ($Stack -eq 'Vite' -and (Confirm-Feature 'Add Tailwind CSS?')) {
        Initialize-ViteTailwind $Path
    }

    if (Confirm-Feature 'Add GSAP?') {
        if (-not (Test-ProjectDependency -Path $Path -Name 'gsap')) {
            Push-Location $Path
            try {
                Invoke-Npm install gsap
            } finally {
                Pop-Location
            }
        }
    }

    if (Confirm-Feature 'Add Three.js?') {
        if (-not (Test-ProjectDependency -Path $Path -Name 'three')) {
            Push-Location $Path
            try {
                Invoke-Npm install three
            } finally {
                Pop-Location
            }
        }
    }

    if ($Stack -eq 'Vite') {
        $includesTailwind = Test-ProjectDependency -Path $Path -Name 'tailwindcss'
        $includesGsap = Test-ProjectDependency -Path $Path -Name 'gsap'
        $hasReactApp = (Test-Path -LiteralPath (Join-Path $Path 'src/App.jsx')) -or (Test-Path -LiteralPath (Join-Path $Path 'src/App.tsx'))
        if ($hasReactApp) {
            Set-ReactStarterDemo -Path $Path -Name $Name -IncludeTailwind:$includesTailwind -IncludeGsap:$includesGsap
        } elseif (Test-Path -LiteralPath (Join-Path $Path 'src/script.js')) {
            $technologies = @('Vite', 'JavaScript')
            if ($includesTailwind) {
                $technologies += 'Tailwind CSS'
            }
            if ($includesGsap) {
                $technologies += 'GSAP'
            }
            Set-StaticStarterScreen -Path $Path -Name $Name -Technologies $technologies -UseVite -UseGsap:$includesGsap
        }
    } else {
        Set-NextStarterScreen -Path $Path -Name $Name `
            -IncludeTailwind:(Test-ProjectDependency -Path $Path -Name 'tailwindcss') `
            -IncludeGsap:(Test-ProjectDependency -Path $Path -Name 'gsap')
    }

    Set-Location $Path
    Open-ProjectEditor $Path
    Start-SlmnDevServer -Path $Path
}

# -----------------------------
# 1. VANILLA (pure CSS, no npm)
# -----------------------------
function vanilla-project {
    param(
        [Parameter(Mandatory)][string]$name,
        [Alias('Path')][string]$ProjectRoot
    )

    $path = Join-Path (Get-SlmnProjectsPath -OverridePath $ProjectRoot) $name
    if (Test-Path -LiteralPath $path) {
        throw "Project already exists: $path"
    }

    New-Item -ItemType Directory -Path $path | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $path 'css'), (Join-Path $path 'js') | Out-Null

    @"
<!doctype html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$name</title>
    <link rel="stylesheet" href="./css/style.css">
</head>
<body>
    <main>
        <h1>SLMN Vanilla Starter</h1>
        <h2>$name</h2>
    </main>
    <script src="./js/script.js"></script>
</body>
</html>
"@ | Out-File (Join-Path $path 'index.html') -Encoding utf8

    Get-ResponsiveCss | Out-File (Join-Path $path 'css/style.css') -Encoding utf8
    Set-Content (Join-Path $path 'js/script.js') -Value "console.log('Page loaded')" -Encoding utf8

    Set-StaticStarterScreen -Path $path -Name $name -Technologies 'HTML', 'CSS', 'JavaScript'
    Open-ProjectEditor $path
    Start-SlmnStaticPreview -Path $path
}

# -----------------------------
# 2. TAILWIND (Vanilla + Vite)
# -----------------------------
function tailwind-project {
    param(
        [string]$name,
        [Alias('Path')][string]$ProjectRoot
    )

    $projectsRoot = Get-SlmnProjectsPath -OverridePath $ProjectRoot
    $path = Join-Path $projectsRoot $name
    if (Test-Path -LiteralPath $path) {
        throw "Project already exists: $path"
    }

    Set-Location $projectsRoot

    npm create vite@latest $name -- --no-interactive --template vanilla
    if ($LASTEXITCODE -ne 0) {
        throw "Vite scaffold failed for '$name'."
    }
    Set-Location $path

    Invoke-Npm install
    Invoke-Npm install tailwindcss @tailwindcss/vite

    @"
import { defineConfig } from 'vite'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
    plugins: [tailwindcss()],
})
"@ | Out-File "vite.config.js" -Encoding utf8

    @'
@import "tailwindcss";

@theme {
    --breakpoint-tab: 48rem;
    --breakpoint-lap: 64rem;
    --breakpoint-fhd: 120rem;
    --breakpoint-2k: 160rem;
    --breakpoint-4k: 240rem;
}

@layer base {
    body {
        @apply bg-neutral-900 text-white antialiased;
    }
}
'@ | Out-File "src/style.css" -Encoding utf8

    @'
import './style.css'

console.log('Page loaded')
'@ | Out-File "src/script.js" -Encoding utf8

    @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$name</title>
</head>
<body class="bg-neutral-900 text-white">
    <main class="grid min-h-screen place-items-center px-4">
        <h1>SLMN Tailwind Starter</h1>
        <h2 class="text-3xl font-semibold tab:text-4xl lap:text-5xl fhd:text-6xl 2k:text-7xl 4k:text-8xl">$name</h2>
    </main>
    <script type="module" src="/src/script.js"></script>
</body>
</html>
"@ | Out-File "index.html" -Encoding utf8

    Remove-Item "src/assets" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "src/counter.js" -Force -ErrorAction SilentlyContinue
    Remove-Item "public" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "README.md" -Force -ErrorAction SilentlyContinue

    Set-StaticStarterScreen -Path $path -Name $name -Technologies 'Vite', 'Tailwind CSS', 'JavaScript' -UseVite
    Open-ProjectEditor $path
    Start-SlmnDevServer -Path $path
}

# -----------------------------
# 3. GSAP (pure CSS, no Tailwind)
# -----------------------------
function gsap-project {
    param(
        [string]$name,
        [Alias('Path')][string]$ProjectRoot
    )

    $path = Join-Path (Get-SlmnProjectsPath -OverridePath $ProjectRoot) $name
    if (Test-Path -LiteralPath $path) {
        throw "Project already exists: $path"
    }

    New-Item -ItemType Directory -Path $path | Out-Null
    Set-Location $path

    New-Item -ItemType Directory -Path "css","js" -Force | Out-Null

    @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$name</title>
    <link rel="stylesheet" href="./css/style.css">
</head>
<body>
    <main>
        <h1 class="title">$name</h1>
    </main>

    <script src="https://cdnjs.cloudflare.com/ajax/libs/gsap/3.12.5/gsap.min.js"></script>
    <script src="./js/script.js"></script>
</body>
</html>
"@ | Out-File "index.html" -Encoding utf8

    Get-ResponsiveCss | Out-File "css/style.css" -Encoding utf8

    @"
gsap.from('.title', {
    y: 24,
    opacity: 0,
    duration: 0.6,
    ease: 'power2.out'
})
console.log('Page loaded')
"@ | Out-File "js/script.js" -Encoding utf8

    Set-StaticStarterScreen -Path $path -Name $name -Technologies 'HTML', 'CSS', 'JavaScript', 'GSAP' -UseGsap
    Open-ProjectEditor $path
    Start-SlmnStaticPreview -Path $path
}

# -----------------------------
# 4. TAILWIND + GSAP
# -----------------------------
function tailwind-gsap-project {
    param(
        [string]$name,
        [Alias('Path')][string]$ProjectRoot
    )

    $projectsRoot = Get-SlmnProjectsPath -OverridePath $ProjectRoot
    $path = Join-Path $projectsRoot $name
    if (Test-Path -LiteralPath $path) {
        throw "Project already exists: $path"
    }

    Set-Location $projectsRoot

    npm create vite@latest $name -- --no-interactive --template vanilla
    if ($LASTEXITCODE -ne 0) {
        throw "Vite scaffold failed for '$name'."
    }
    Set-Location $path

    Invoke-Npm install
    Invoke-Npm install tailwindcss @tailwindcss/vite
    Invoke-Npm install gsap

    @"
import { defineConfig } from 'vite'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
    plugins: [tailwindcss()],
})
"@ | Out-File "vite.config.js" -Encoding utf8

    @'
@import "tailwindcss";

@theme {
    --breakpoint-tab: 48rem;
    --breakpoint-lap: 64rem;
    --breakpoint-fhd: 120rem;
    --breakpoint-2k: 160rem;
    --breakpoint-4k: 240rem;
}

@layer base {
    body {
        @apply bg-neutral-900 text-white antialiased;
    }
}
'@ | Out-File "src/style.css" -Encoding utf8

    @'
import './style.css'
import gsap from 'gsap'

gsap.from('.title', {
    y: 24,
    opacity: 0,
    duration: 0.6,
    ease: 'power2.out'
})

console.log('Page loaded')
'@ | Out-File "src/script.js" -Encoding utf8

    @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$name</title>
</head>
<body class="bg-neutral-900 text-white">
    <main class="grid min-h-screen place-items-center px-4">
        <h1 class="title text-3xl font-semibold tab:text-4xl lap:text-5xl fhd:text-6xl 2k:text-7xl 4k:text-8xl">$name</h1>
    </main>
    <script type="module" src="/src/script.js"></script>
</body>
</html>
"@ | Out-File "index.html" -Encoding utf8

    Remove-Item "src/assets" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "src/counter.js" -Force -ErrorAction SilentlyContinue
    Remove-Item "public" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "README.md" -Force -ErrorAction SilentlyContinue

    Set-StaticStarterScreen -Path $path -Name $name -Technologies 'Vite', 'Tailwind CSS', 'JavaScript', 'GSAP' -UseVite -UseGsap
    Open-ProjectEditor $path
    Start-SlmnDevServer -Path $path
}

# -----------------------------
# 5. REACT
# -----------------------------
function react-project {
    param(
        [string]$name,
        [Alias('Path')][string]$ProjectRoot
    )

    $projectsRoot = Get-SlmnProjectsPath -OverridePath $ProjectRoot
    $path = Join-Path $projectsRoot $name
    if (Test-Path -LiteralPath $path) {
        throw "Project already exists: $path"
    }

    Set-Location $projectsRoot

    npm create vite@latest $name -- --no-interactive --template react
    if ($LASTEXITCODE -ne 0) {
        throw "Vite scaffold failed for '$name'."
    }
    Set-Location $path

    Invoke-Npm install
    @'
html {
    background: #171717;
}

body {
    min-width: 320px;
    min-height: 100vh;
    margin: 0;
    font-family: Arial, sans-serif;
}
'@ | Set-Content -LiteralPath "src/index.css" -Encoding utf8

    @"
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import App from './App.jsx'
import './index.css'

console.log('Page loaded')

createRoot(document.getElementById('root')).render(
    <StrictMode>
        <App />
    </StrictMode>
)
"@ | Out-File "src/main.jsx" -Encoding utf8

    Set-ReactStarterDemo -Path $path -Name $name

    Open-ProjectEditor $path
    Start-SlmnDevServer -Path $path
}

# -----------------------------
# 6. REACT + TAILWIND CSS
# -----------------------------
function react-tailwind-project {
    param(
        [string]$name,
        [Alias('Path')][string]$ProjectRoot
    )

    $projectsRoot = Get-SlmnProjectsPath -OverridePath $ProjectRoot
    $path = Join-Path $projectsRoot $name
    if (Test-Path -LiteralPath $path) {
        throw "Project already exists: $path"
    }

    Set-Location $projectsRoot

    npm create vite@latest $name -- --no-interactive --template react
    if ($LASTEXITCODE -ne 0) {
        throw "Vite scaffold failed for '$name'."
    }
    Set-Location $path

    Invoke-Npm install
    Invoke-Npm install -D tailwindcss @tailwindcss/vite

    @"
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
    plugins: [react(), tailwindcss()],
})
"@ | Out-File "vite.config.js" -Encoding utf8

    @'
@import "tailwindcss";

@theme {
    --breakpoint-tab: 48rem;
    --breakpoint-lap: 64rem;
    --breakpoint-fhd: 120rem;
    --breakpoint-2k: 160rem;
    --breakpoint-4k: 240rem;
}

@layer base {
    html {
        @apply bg-neutral-900;
    }

    body {
        @apply min-h-screen bg-neutral-900 text-white antialiased;
    }
}
'@ | Set-Content -LiteralPath "src/index.css" -Encoding utf8

    @'
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import App from './App.jsx'
import './index.css'

console.log('Page loaded')

createRoot(document.getElementById('root')).render(
    <StrictMode>
        <App />
    </StrictMode>
)
'@ | Out-File "src/main.jsx" -Encoding utf8

    Set-ReactStarterDemo -Path $path -Name $name -IncludeTailwind

    Open-ProjectEditor $path
    Start-SlmnDevServer -Path $path
}

# -----------------------------
# 7. REACT + TAILWIND CSS + GSAP
# -----------------------------
function react-tailwind-gsap-project {
    param(
        [string]$name,
        [Alias('Path')][string]$ProjectRoot
    )

    $projectsRoot = Get-SlmnProjectsPath -OverridePath $ProjectRoot
    $path = Join-Path $projectsRoot $name
    if (Test-Path -LiteralPath $path) {
        throw "Project already exists: $path"
    }

    Set-Location $projectsRoot
    npm create vite@latest $name -- --no-interactive --template react
    if ($LASTEXITCODE -ne 0) {
        throw "Vite scaffold failed for '$name'."
    }
    Set-Location $path

    Invoke-Npm install
    Initialize-ViteTailwind $path
    Invoke-Npm install gsap
    Set-ReactStarterDemo -Path $path -Name $name -IncludeTailwind -IncludeGsap

    Open-ProjectEditor $path
    Start-SlmnDevServer -Path $path
}

# -----------------------------
# 8. REACT + TAILWIND CSS + GSAP + THREE.JS
# -----------------------------
function react-tailwind-gsap-three-project {
    param(
        [string]$name,
        [Alias('Path')][string]$ProjectRoot
    )

    $projectsRoot = Get-SlmnProjectsPath -OverridePath $ProjectRoot
    $path = Join-Path $projectsRoot $name
    if (Test-Path -LiteralPath $path) {
        throw "Project already exists: $path"
    }

    Set-Location $projectsRoot
    npm create vite@latest $name -- --no-interactive --template react
    if ($LASTEXITCODE -ne 0) {
        throw "Vite scaffold failed for '$name'."
    }
    Set-Location $path

    Invoke-Npm install
    Initialize-ViteTailwind $path
    Invoke-Npm install gsap three react-icons
    Set-FullDemoPage -Path $path -Name $name

    Open-ProjectEditor $path
    Start-SlmnDevServer -Path $path
}

function New-ReactTsProject {
    param(
        [Parameter(Mandatory)][string]$Name,
        [string]$ProjectRoot,
        [switch]$IncludeTailwind,
        [switch]$IncludeGsap,
        [switch]$IncludeThree,
        [switch]$UseFullDemo
    )

    if ($IncludeThree -and (-not $IncludeTailwind -or -not $IncludeGsap)) {
        throw 'The Three.js TypeScript starter requires Tailwind CSS and GSAP.'
    }
    if ($UseFullDemo -and -not $IncludeThree) {
        throw 'The full SLMN demo requires the Three.js dependencies.'
    }

    $projectsRoot = Get-SlmnProjectsPath -OverridePath $ProjectRoot
    $path = Join-Path $projectsRoot $Name
    if (Test-Path -LiteralPath $path) {
        throw "Project already exists: $path"
    }

    Set-Location $projectsRoot
    Write-SlmnStatus "Scaffolding the React + TypeScript project '$Name'..."
    npm create vite@latest $Name -- --no-interactive --template react-ts
    if ($LASTEXITCODE -ne 0) {
        throw "Vite TypeScript scaffold failed for '$Name'."
    }

    if (-not (Test-Path -LiteralPath (Join-Path $path 'src/App.tsx')) -or
        -not (Test-Path -LiteralPath (Join-Path $path 'tsconfig.json'))) {
        throw "Vite did not create the expected React TypeScript project: $path"
    }

    Set-Location $path
    Invoke-Npm install
    if ($IncludeTailwind) {
        Initialize-ViteTailwind $path
    }
    if ($IncludeGsap) {
        Invoke-Npm install gsap
    }
    if ($IncludeThree) {
        Invoke-Npm install three react-icons
        Invoke-NpmDevInstall @types/three
    }
    if ($UseFullDemo) {
        Set-FullDemoPage -Path $path -Name $Name
    } else {
        Set-ReactStarterDemo -Path $path -Name $Name -IncludeTailwind:$IncludeTailwind -IncludeGsap:$IncludeGsap
    }

    Open-ProjectEditor $path
    Start-SlmnDevServer -Path $path
}

function react-ts-project {
    param(
        [Parameter(Mandatory)][string]$name,
        [Alias('Path')][string]$ProjectRoot
    )

    New-ReactTsProject -Name $name -ProjectRoot $ProjectRoot
}

function react-tailwind-ts-project {
    param(
        [Parameter(Mandatory)][string]$name,
        [Alias('Path')][string]$ProjectRoot
    )

    New-ReactTsProject -Name $name -ProjectRoot $ProjectRoot -IncludeTailwind
}

function react-tailwind-gsap-ts-project {
    param(
        [Parameter(Mandatory)][string]$name,
        [Alias('Path')][string]$ProjectRoot
    )

    New-ReactTsProject -Name $name -ProjectRoot $ProjectRoot -IncludeTailwind -IncludeGsap
}

function react-tailwind-gsap-three-ts-project {
    param(
        [Parameter(Mandatory)][string]$name,
        [Alias('Path')][string]$ProjectRoot
    )

    New-ReactTsProject -Name $name -ProjectRoot $ProjectRoot -IncludeTailwind -IncludeGsap -IncludeThree -UseFullDemo
}

function slmn-ts-app {
    param(
        [Parameter(Mandatory)][string]$name,
        [Alias('Path')][string]$ProjectRoot
    )

    $projectName = ($name.Trim().ToLowerInvariant() -replace '[^a-z0-9._-]+', '-').Trim([char[]]'.-_')
    if ([string]::IsNullOrWhiteSpace($projectName)) {
        throw 'Project name must contain at least one letter or number.'
    }

    if ($projectName -ne $name) {
        Write-Host "Using project folder name: $projectName" -ForegroundColor DarkGray
    }
    New-ReactTsProject -Name $projectName -ProjectRoot $ProjectRoot -IncludeTailwind -IncludeGsap -IncludeThree -UseFullDemo
}

# -----------------------------
# 9. INTERACTIVE VITE
# -----------------------------
function vite-app {
    param(
        [Parameter(Mandatory)][string]$name,
        [Alias('Path')][string]$ProjectRoot
    )

    $projectsRoot = Get-SlmnProjectsPath -OverridePath $ProjectRoot
    $path = Join-Path $projectsRoot $name
    if (Test-Path -LiteralPath $path) {
        throw "Project already exists: $path"
    }

    Set-Location $projectsRoot
    Write-Host 'Choose your Vite framework and variant. This command completes installation after your selection.' -ForegroundColor Cyan
    npm create vite@latest $name -- --no-immediate
    if ($LASTEXITCODE -ne 0) {
        throw "Vite setup failed for '$name'."
    }

    Complete-InteractiveProject -Path $path -Name $name -Stack Vite
}

# -----------------------------
# 10. SLMN APP (FLAGSHIP DEMO)
# -----------------------------
function slmn-app {
    param(
        [Parameter(Mandatory)][string]$name,
        [Alias('Path')][string]$ProjectRoot
    )

    $projectsRoot = Get-SlmnProjectsPath -OverridePath $ProjectRoot
    $projectName = ($name.Trim().ToLowerInvariant() -replace '[^a-z0-9._-]+', '-').Trim([char[]]'.-_')
    if ([string]::IsNullOrWhiteSpace($projectName)) {
        throw 'Project name must contain at least one letter or number.'
    }

    $path = Join-Path $projectsRoot $projectName
    if (Test-Path -LiteralPath $path) {
        throw "Project already exists: $path"
    }

    Set-Location $projectsRoot
    if ($projectName -ne $name) {
        Write-Host "Using project folder name: $projectName" -ForegroundColor DarkGray
    }
    Write-Host 'Creating the React JavaScript SLMN App, then installing Tailwind CSS, GSAP, Three.js, and React Icons.' -ForegroundColor Cyan
    npx --yes create-vite@latest $projectName --no-interactive --no-immediate --template react
    if ($LASTEXITCODE -ne 0) {
        throw "Vite setup failed for '$name'."
    }

    if (-not (Test-ProjectDependency -Path $path -Name 'react')) {
        throw 'Full starter requires the React template, but Vite did not create it.'
    }

    Push-Location $path
    try {
        Invoke-Npm install
        Initialize-ViteTailwind $path
        Invoke-Npm install gsap three react-icons
        if (Test-Path -LiteralPath (Join-Path $path 'src/App.tsx')) {
            Invoke-NpmDevInstall @types/three
        }
        Set-FullDemoPage -Path $path -Name $projectName
    } finally {
        Pop-Location
    }

    Set-Location $path
    Open-ProjectEditor $path
    Start-SlmnDevServer -Path $path
}

function full-app {
    param(
        [Parameter(Mandatory)][string]$name,
        [Alias('Path')][string]$ProjectRoot
    )

    slmn-app $name -Path $ProjectRoot
}

# -----------------------------
# 11. SLMN FULL (FULL-STACK FLAGSHIP)
# -----------------------------
function Write-SlmnFullFile {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$RelativePath,
        [Parameter(Mandatory)][string]$Content
    )

    $filePath = Join-Path $Path $RelativePath
    $directory = Split-Path -Parent $filePath
    New-Item -ItemType Directory -Path $directory -Force | Out-Null
    [System.IO.File]::WriteAllText($filePath, $Content, [System.Text.UTF8Encoding]::new($false))
}

function Write-SlmnFullProject {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name
    )

    Write-SlmnFullFile -Path $Path -RelativePath 'src/app/layout.tsx' -Content @'
import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Orbit — AI workspace",
  description: "A full-stack AI chat starter built with Next.js, Supabase, and the Vercel AI SDK.",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
'@

    Write-SlmnFullFile -Path $Path -RelativePath 'src/app/page.tsx' -Content @'
import ChatWorkspace from "@/components/chat-workspace";

export default function Home() {
  const isConfigured =
    Boolean(process.env.NEXT_PUBLIC_SUPABASE_URL) &&
    Boolean(process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY);

  if (!isConfigured) {
    return (
      <main className="setup-screen">
        <div className="setup-card">
          <span className="brand-mark">O</span>
          <p className="eyebrow">YOUR WORKSPACE IS READY</p>
          <h1>Connect your services to begin.</h1>
          <p>
            Copy <code>.env.example</code> to <code>.env.local</code>, add your Supabase
            project URL and publishable key, then restart the dev server.
          </p>
          <ol>
            <li>Create a Supabase project and run <code>database/schema.sql</code> in its SQL Editor.</li>
            <li>Add the Supabase values and your OpenAI key to <code>.env.local</code>.</li>
            <li>Restart with <code>npm run dev</code>.</li>
          </ol>
          <a href="https://supabase.com/dashboard" target="_blank" rel="noreferrer">Open Supabase dashboard ↗</a>
        </div>
      </main>
    );
  }

  return <ChatWorkspace />;
}
'@

    Write-SlmnFullFile -Path $Path -RelativePath 'src/lib/supabase/client.ts' -Content @'
"use client";

import { createBrowserClient } from "@supabase/ssr";
import type { SupabaseClient } from "@supabase/supabase-js";

let client: SupabaseClient | undefined;

export function createClient() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;
  if (!url || !key) {
    throw new Error("Set NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY in .env.local.");
  }

  client ??= createBrowserClient(url, key);
  return client;
}
'@

    Write-SlmnFullFile -Path $Path -RelativePath 'src/lib/supabase/server.ts' -Content @'
import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";

export async function createClient() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;
  if (!url || !key) {
    throw new Error("Supabase is not configured. Set its URL and publishable key in .env.local.");
  }

  const cookieStore = await cookies();
  return createServerClient(url, key, {
    cookies: {
      getAll() {
        return cookieStore.getAll();
      },
      setAll(cookiesToSet) {
        cookiesToSet.forEach(({ name, value, options }) => {
          cookieStore.set(name, value, options);
        });
      },
    },
  });
}
'@

    Write-SlmnFullFile -Path $Path -RelativePath 'src/app/api/chat/route.ts' -Content @'
import { createOpenAI } from "@ai-sdk/openai";
import { streamText } from "ai";
import { createClient } from "@/lib/supabase/server";

export async function POST(request: Request) {
  const supabase = await createClient();
  const { data: { user }, error: authError } = await supabase.auth.getUser();
  if (authError || !user) {
    return Response.json({ error: "Sign in to use chat." }, { status: 401 });
  }

  let payload: unknown;
  try {
    payload = await request.json();
  } catch {
    return Response.json({ error: "Request body must be valid JSON." }, { status: 400 });
  }

  if (typeof payload !== "object" || payload === null) {
    return Response.json({ error: "A conversation ID and message are required." }, { status: 400 });
  }
  const { conversationId, message } = payload as { conversationId?: unknown; message?: unknown };
  if (
    typeof conversationId !== "string" ||
    typeof message !== "string" ||
    !message.trim() ||
    message.length > 10000
  ) {
    return Response.json({ error: "Provide a message of 1–10,000 characters." }, { status: 400 });
  }

  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) {
    return Response.json({ error: "Set OPENAI_API_KEY in .env.local, then restart the app." }, { status: 503 });
  }

  const { data: conversation, error: conversationError } = await supabase
    .from("conversations")
    .select("id")
    .eq("id", conversationId)
    .eq("user_id", user.id)
    .maybeSingle();
  if (conversationError) {
    console.error("Unable to verify chat ownership:", conversationError);
    return Response.json({ error: "Could not access this conversation." }, { status: 500 });
  }
  if (!conversation) {
    return Response.json({ error: "Conversation not found." }, { status: 404 });
  }

  const { error: saveUserError } = await supabase.from("messages").insert({
    conversation_id: conversationId,
    role: "user",
    content: message.trim(),
  });
  if (saveUserError) {
    console.error("Unable to save the user message:", saveUserError);
    return Response.json({ error: "Could not save your message. Check the database setup." }, { status: 500 });
  }

  const { data: history, error: historyError } = await supabase
    .from("messages")
    .select("role, content")
    .eq("conversation_id", conversationId)
    .order("created_at", { ascending: false })
    .limit(20);
  if (historyError) {
    console.error("Unable to load chat history:", historyError);
    return Response.json({ error: "Could not load conversation history." }, { status: 500 });
  }

  const openai = createOpenAI({ apiKey });
  const result = streamText({
    model: openai(process.env.OPENAI_MODEL || "gpt-4.1-mini"),
    system: "You are Orbit, a thoughtful and practical AI assistant. Be clear, useful, and concise.",
    messages: (history ?? []).reverse().map((entry) => ({
      role: entry.role === "assistant" ? "assistant" as const : "user" as const,
      content: entry.content,
    })),
  });

  const encoder = new TextEncoder();
  const stream = new ReadableStream<Uint8Array>({
    async start(controller) {
      let answer = "";
      try {
        for await (const chunk of result.textStream) {
          answer += chunk;
          controller.enqueue(encoder.encode(chunk));
        }

        if (answer.trim()) {
          const { error: saveAssistantError } = await supabase.from("messages").insert({
            conversation_id: conversationId,
            role: "assistant",
            content: answer,
          });
          if (saveAssistantError) {
            console.error("Unable to save the assistant response:", saveAssistantError);
            throw new Error("The response arrived, but could not be saved to chat history.");
          }
        }
        controller.close();
      } catch (error) {
        console.error("AI response stream failed:", error);
        controller.error(error);
      }
    },
  });

  return new Response(stream, {
    headers: {
      "Content-Type": "text/plain; charset=utf-8",
      "Cache-Control": "no-cache, no-transform",
    },
  });
}
'@

    Write-SlmnFullFile -Path $Path -RelativePath 'src/components/chat-workspace.tsx' -Content @'
"use client";

import { useEffect, useRef, useState, type FormEvent } from "react";
import { ArrowUp, Bot, Check, LoaderCircle, LogOut, MessageSquarePlus, Send, Sparkles } from "lucide-react";
import { createClient } from "@/lib/supabase/client";

type Conversation = {
  id: string;
  title: string;
  updated_at: string;
};

type ChatMessage = {
  id: string;
  role: "user" | "assistant";
  content: string;
};

const suggestions = [
  "Help me shape an idea into a clear product brief",
  "Explain a tricky concept in plain language",
  "Give me a thoughtful starting point for today",
];

export default function ChatWorkspace() {
  const [user, setUser] = useState<{ id: string; email?: string } | null>(null);
  const [authLoading, setAuthLoading] = useState(true);
  const [authMode, setAuthMode] = useState<"signin" | "signup">("signin");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [notice, setNotice] = useState("");
  const [error, setError] = useState("");
  const [conversations, setConversations] = useState<Conversation[]>([]);
  const [activeId, setActiveId] = useState<string | null>(null);
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [draft, setDraft] = useState("");
  const [busy, setBusy] = useState(false);
  const [authBusy, setAuthBusy] = useState(false);
  const skipNextLoad = useRef<string | null>(null);
  const hasLoadedChats = useRef(false);
  const bottomRef = useRef<HTMLDivElement>(null);
  const supabase = createClient();
  const activeConversation = conversations.find((conversation) => conversation.id === activeId);

  useEffect(() => {
    let mounted = true;
    supabase.auth.getSession().then(({ data, error: sessionError }) => {
      if (!mounted) return;
      if (sessionError) setError(sessionError.message);
      setUser(data.session?.user ? { id: data.session.user.id, email: data.session.user.email } : null);
      setAuthLoading(false);
    }).catch((sessionError: unknown) => {
      if (!mounted) return;
      setError(sessionError instanceof Error ? sessionError.message : "Could not load your session.");
      setAuthLoading(false);
    });

    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setUser(session?.user ? { id: session.user.id, email: session.user.email } : null);
      setConversations([]);
      setActiveId(null);
      setMessages([]);
      hasLoadedChats.current = false;
      setAuthLoading(false);
      setError("");
      setNotice("");
    });

    return () => {
      mounted = false;
      subscription.unsubscribe();
    };
  }, [supabase]);

  useEffect(() => {
    if (!user) return;
    let cancelled = false;
    supabase
      .from("conversations")
      .select("id, title, updated_at")
      .order("updated_at", { ascending: false })
      .then(({ data, error: queryError }) => {
        if (cancelled) return;
        if (queryError) {
          setError(`Could not load saved chats: ${queryError.message}`);
          return;
        }
        const loaded = data ?? [];
        setConversations(loaded);
        if (!hasLoadedChats.current) {
          hasLoadedChats.current = true;
          if (loaded.length > 0) setActiveId(loaded[0].id);
        }
      });
    return () => {
      cancelled = true;
    };
  }, [user, supabase]);

  useEffect(() => {
    if (!activeId) return;
    if (skipNextLoad.current === activeId) {
      skipNextLoad.current = null;
      return;
    }

    let cancelled = false;
    supabase
      .from("messages")
      .select("id, role, content")
      .eq("conversation_id", activeId)
      .order("created_at", { ascending: true })
      .limit(100)
      .then(({ data, error: queryError }) => {
        if (cancelled) return;
        if (queryError) {
          setError(`Could not load messages: ${queryError.message}`);
          return;
        }
        setMessages((data ?? []).map((item) => ({
          id: item.id,
          role: item.role === "assistant" ? "assistant" : "user",
          content: item.content,
        })));
      });
    return () => {
      cancelled = true;
    };
  }, [activeId, supabase]);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth", block: "end" });
  }, [messages]);

  async function handleAuth(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setAuthBusy(true);
    setError("");
    setNotice("");
    try {
      const result = authMode === "signup"
        ? await supabase.auth.signUp({ email, password })
        : await supabase.auth.signInWithPassword({ email, password });
      if (result.error) {
        setError(result.error.message);
      } else if (authMode === "signup" && !result.data.session) {
        setNotice("Check your inbox to confirm your email, then sign in.");
      }
    } catch (authError) {
      setError(authError instanceof Error ? authError.message : "Authentication failed. Please try again.");
    } finally {
      setAuthBusy(false);
    }
  }

  async function createConversation(title: string) {
    if (!user) throw new Error("Sign in before creating a chat.");
    const { data, error: insertError } = await supabase
      .from("conversations")
      .insert({ user_id: user.id, title })
      .select("id, title, updated_at")
      .single();
    if (insertError) throw new Error(`Could not create a chat: ${insertError.message}`);
    skipNextLoad.current = data.id;
    setConversations((current) => [data, ...current]);
    setActiveId(data.id);
    setMessages([]);
    return data;
  }

  async function startNewChat() {
    setError("");
    try {
      await createConversation("New chat");
    } catch (createError) {
      setError(createError instanceof Error ? createError.message : "Could not create a chat.");
    }
  }

  async function signOut() {
    try {
      const { error: signOutError } = await supabase.auth.signOut();
      if (signOutError) setError(`Could not sign out: ${signOutError.message}`);
    } catch (signOutError) {
      setError(signOutError instanceof Error ? signOutError.message : "Could not sign out.");
    }
  }

  async function sendMessage(text: string) {
    if (busy || !text.trim()) return;
    setBusy(true);
    setError("");
    setDraft("");

    try {
      let conversationId = activeId;
      if (!conversationId) {
        const title = text.trim().replace(/\s+/g, " ").slice(0, 48);
        const conversation = await createConversation(title || "New chat");
        conversationId = conversation.id;
      }

      setMessages((current) => [
        ...current,
        { id: crypto.randomUUID(), role: "user", content: text.trim() },
        { id: crypto.randomUUID(), role: "assistant", content: "" },
      ]);

      const response = await fetch("/api/chat", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ conversationId, message: text.trim() }),
      });
      if (!response.ok) {
        const body = await response.json() as { error?: string };
        throw new Error(body.error || "The chat request failed.");
      }
      if (!response.body) throw new Error("The server did not return a response stream.");

      const reader = response.body.getReader();
      const decoder = new TextDecoder();
      while (true) {
        const { done, value } = await reader.read();
        if (done) break;
        const chunk = decoder.decode(value, { stream: true });
        setMessages((current) => current.map((item, index) =>
          index === current.length - 1 && item.role === "assistant"
            ? { ...item, content: item.content + chunk }
            : item,
        ));
      }
      const lastChunk = decoder.decode();
      if (lastChunk) {
        setMessages((current) => current.map((item, index) =>
          index === current.length - 1 && item.role === "assistant"
            ? { ...item, content: item.content + lastChunk }
            : item,
        ));
      }
      const { data: refreshed } = await supabase
        .from("conversations")
        .select("id, title, updated_at")
        .eq("id", conversationId)
        .single();
      if (refreshed) {
        setConversations((current) => [refreshed, ...current.filter((item) => item.id !== refreshed.id)]);
      }
    } catch (sendError) {
      setMessages((current) => current.filter((item, index) =>
        !(index === current.length - 1 && item.role === "assistant" && !item.content),
      ));
      setError(sendError instanceof Error ? sendError.message : "The chat request failed. Please try again.");
    } finally {
      setBusy(false);
    }
  }

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    void sendMessage(draft);
  }

  if (authLoading) {
    return <main className="loading-screen"><LoaderCircle className="spinner" size={22} /> Preparing your workspace</main>;
  }

  if (!user) {
    return (
      <main className="auth-screen">
        <div className="auth-glow auth-glow-one" />
        <div className="auth-glow auth-glow-two" />
        <section className="auth-card">
          <div className="auth-brand"><span className="brand-mark">O</span><span>orbit<span className="brand-dot">.</span></span></div>
          <p className="eyebrow">YOUR PRIVATE AI WORKSPACE</p>
          <h1>{authMode === "signin" ? "A little more clarity." : "Make room for ideas."}</h1>
          <p className="auth-subtitle">Thoughtful conversations, saved securely for the work ahead.</p>
          {error && <p className="form-message form-error" role="alert">{error}</p>}
          {notice && <p className="form-message form-notice" role="status">{notice}</p>}
          <form className="auth-form" onSubmit={handleAuth}>
            <label htmlFor="email">Email address</label>
            <input id="email" type="email" autoComplete="email" value={email} onChange={(event) => setEmail(event.target.value)} required />
            <label htmlFor="password">Password</label>
            <input id="password" type="password" autoComplete={authMode === "signin" ? "current-password" : "new-password"} minLength={8} value={password} onChange={(event) => setPassword(event.target.value)} required />
            <button className="primary-button auth-submit" type="submit" disabled={authBusy}>
              {authBusy ? <LoaderCircle className="spinner" size={17} /> : authMode === "signin" ? "Sign in" : "Create account"}
              {!authBusy && <ArrowUp size={16} className="button-arrow" />}
            </button>
          </form>
          <p className="auth-switch">
            {authMode === "signin" ? "New to Orbit?" : "Already have an account?"}{" "}
            <button type="button" onClick={() => { setAuthMode(authMode === "signin" ? "signup" : "signin"); setError(""); setNotice(""); }}>
              {authMode === "signin" ? "Create an account" : "Sign in"}
            </button>
          </p>
          <p className="auth-footnote"><Check size={13} /> Your chats are private to your account</p>
        </section>
      </main>
    );
  }

  return (
    <main className="workspace">
      <aside className="sidebar">
        <a className="sidebar-brand" href="#"><span className="brand-mark">O</span><span>orbit<span className="brand-dot">.</span></span></a>
        <button className="new-chat-button" onClick={() => void startNewChat()} disabled={busy}><MessageSquarePlus size={16} /> New conversation <span>⌘ K</span></button>
        <div className="sidebar-section-label">RECENT</div>
        <nav className="conversation-list" aria-label="Saved conversations">
          {conversations.map((conversation) => (
            <button
              key={conversation.id}
              className={`conversation-link${conversation.id === activeId ? " conversation-active" : ""}`}
              onClick={() => { setError(""); setActiveId(conversation.id); }}
              disabled={busy}
              title={conversation.title}
            >
              <MessageSquarePlus size={15} />
              <span>{conversation.title}</span>
            </button>
          ))}
          {conversations.length === 0 && <p className="sidebar-empty">Your conversations will appear here.</p>}
        </nav>
        <div className="sidebar-account">
          <div className="user-avatar">{user.email?.[0]?.toUpperCase() ?? "U"}</div>
          <div className="account-copy"><strong>{user.email?.split("@")[0] ?? "Your account"}</strong><span>{user.email}</span></div>
          <button className="icon-button signout-button" aria-label="Sign out" title="Sign out" onClick={() => void signOut()} disabled={busy}><LogOut size={16} /></button>
        </div>
      </aside>

      <section className="chat-panel">
        <header className="topbar">
          <div className="topbar-context"><span className="status-dot" /> PRIVATE WORKSPACE <span className="topbar-divider">/</span> {activeConversation?.title ?? "New conversation"}</div>
          <div className="powered-by"><Sparkles size={14} /> AI, with room to think</div>
        </header>

        <div className="conversation-scroll">
          <div className={`message-column${messages.length === 0 ? " message-column-empty" : ""}`}>
            {messages.length === 0 ? (
              <div className="welcome-block">
                <div className="welcome-icon"><Sparkles size={20} /></div>
                <p className="eyebrow">A CLEARER PLACE TO THINK</p>
                <h1>What’s on your mind?</h1>
                <p className="welcome-copy">Bring a question, a rough idea, or a blank page. We’ll work through it together.</p>
                <div className="suggestion-list">
                  {suggestions.map((suggestion, index) => (
                    <button key={suggestion} className="suggestion-card" onClick={() => setDraft(suggestion)}>
                      <span>{suggestion}</span><ArrowUp size={15} className={`suggestion-arrow suggestion-arrow-${index}`} />
                    </button>
                  ))}
                </div>
              </div>
            ) : (
              <div className="message-list">
                {messages.map((message) => (
                  <article className={`message-row message-${message.role}`} key={message.id}>
                    <div className={`message-avatar${message.role === "assistant" ? " assistant-avatar" : ""}`}>
                      {message.role === "assistant" ? <Bot size={17} /> : (user.email?.[0]?.toUpperCase() ?? "U")}
                    </div>
                    <div className="message-body">
                      <div className="message-author">{message.role === "assistant" ? "Orbit" : "You"}</div>
                      <p>{message.content || (busy ? <span className="thinking-indicator"><i /><i /><i /></span> : "")}</p>
                    </div>
                  </article>
                ))}
                <div ref={bottomRef} />
              </div>
            )}
          </div>
        </div>

        <div className="composer-area">
          {error && <p className="chat-error" role="alert">{error}</p>}
          <form className="composer" onSubmit={handleSubmit}>
            <textarea
              aria-label="Message Orbit"
              placeholder="Ask anything, or start with a thought..."
              value={draft}
              onChange={(event) => setDraft(event.target.value)}
              onKeyDown={(event) => {
                if (event.key === "Enter" && !event.shiftKey) {
                  event.preventDefault();
                  void sendMessage(draft);
                }
              }}
              rows={2}
              maxLength={10000}
              disabled={busy}
            />
            <div className="composer-footer">
              <span><Sparkles size={13} /> Responses stream live · Chats are saved</span>
              <button className="send-button" type="submit" aria-label="Send message" disabled={busy || !draft.trim()}>
                {busy ? <LoaderCircle size={17} className="spinner" /> : <Send size={16} />}
              </button>
            </div>
          </form>
          <p className="composer-disclaimer">Orbit can make mistakes. Check important details.</p>
        </div>
      </section>
    </main>
  );
}
'@

    Write-SlmnFullFile -Path $Path -RelativePath 'src/app/globals.css' -Content @'
@import "tailwindcss";

:root {
  color-scheme: dark;
  --ink: #f1f3f5;
  --muted: #8d939d;
  --line: rgba(255, 255, 255, .085);
  --panel: #111318;
  --accent: #a4f0c0;
}

* { box-sizing: border-box; }
html, body { min-height: 100%; }
body {
  margin: 0;
  background: #0d0f12;
  color: var(--ink);
  font-family: Arial, Helvetica, sans-serif;
  font-size: 14px;
  -webkit-font-smoothing: antialiased;
}
button, input, textarea { font: inherit; }
button { color: inherit; cursor: pointer; }
button:disabled { cursor: not-allowed; opacity: .55; }
a { color: inherit; text-decoration: none; }

.workspace { display: flex; min-height: 100svh; background: #0e1013; }
.sidebar {
  width: 268px; flex: 0 0 268px; display: flex; flex-direction: column;
  padding: 25px 15px 14px; background: #111317; border-right: 1px solid var(--line);
}
.sidebar-brand, .auth-brand { display: inline-flex; align-items: center; gap: 10px; font-size: 18px; font-weight: 650; letter-spacing: -.055em; }
.brand-mark {
  width: 28px; height: 28px; display: inline-grid; place-items: center; border-radius: 9px;
  background: linear-gradient(140deg, #c1f8d4, #71d99d); color: #0c1710; font-size: 16px; font-weight: 800;
  box-shadow: 0 3px 20px rgba(113, 217, 157, .16);
}
.brand-dot { color: #87e9aa; }
.new-chat-button {
  display: flex; align-items: center; gap: 9px; margin-top: 39px; padding: 11px 10px;
  color: #e7e9ec; border: 1px solid var(--line); border-radius: 9px; background: rgba(255,255,255,.025);
  text-align: left; transition: background .18s, border-color .18s;
}
.new-chat-button:hover { background: rgba(255,255,255,.06); border-color: rgba(255,255,255,.16); }
.new-chat-button svg { color: #9ce7b5; }
.new-chat-button span { margin-left: auto; color: #666c75; font-size: 11px; }
.sidebar-section-label { margin: 31px 8px 11px; color: #656b75; font-size: 10px; font-weight: 700; letter-spacing: .13em; }
.conversation-list { display: flex; flex: 1; flex-direction: column; gap: 3px; overflow: auto; }
.conversation-link {
  width: 100%; display: flex; align-items: center; gap: 9px; padding: 9px 9px; border: 0;
  border-radius: 7px; background: transparent; color: #989da6; text-align: left;
}
.conversation-link:hover, .conversation-active { color: #e9ebed; background: rgba(255,255,255,.055); }
.conversation-link svg { flex: 0 0 auto; color: #747b84; }
.conversation-link span { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.sidebar-empty { margin: 1px 8px; color: #686e77; font-size: 12px; line-height: 1.6; }
.sidebar-account { display: flex; align-items: center; gap: 10px; padding: 13px 2px 1px; border-top: 1px solid var(--line); }
.user-avatar, .message-avatar {
  width: 31px; height: 31px; display: grid; flex: 0 0 auto; place-items: center; border-radius: 50%;
  background: #29342d; color: #a9edbf; font-size: 12px; font-weight: 700;
}
.account-copy { display: flex; min-width: 0; flex: 1; flex-direction: column; gap: 3px; }
.account-copy strong { overflow: hidden; color: #dadddf; font-size: 12px; font-weight: 550; text-overflow: ellipsis; }
.account-copy span { overflow: hidden; color: #737983; font-size: 10px; text-overflow: ellipsis; }
.icon-button { display: grid; place-items: center; border: 0; background: transparent; color: #777e87; }
.icon-button:hover { color: #e5e8eb; }

.chat-panel { display: flex; min-width: 0; flex: 1; flex-direction: column; }
.topbar { height: 59px; display: flex; align-items: center; justify-content: space-between; padding: 0 33px; border-bottom: 1px solid var(--line); }
.topbar-context { display: flex; align-items: center; gap: 9px; overflow: hidden; color: #9da2a9; font-size: 10px; font-weight: 600; letter-spacing: .075em; text-overflow: ellipsis; white-space: nowrap; }
.status-dot { width: 6px; height: 6px; border-radius: 50%; background: #7ce3a2; box-shadow: 0 0 12px rgba(124,227,162,.6); }
.topbar-divider { color: #515761; }
.powered-by { display: flex; align-items: center; gap: 7px; color: #7f858e; font-size: 11px; }
.powered-by svg { color: #9be6b4; }
.conversation-scroll { display: flex; min-height: 0; flex: 1; justify-content: center; overflow-y: auto; padding: 0 28px; }
.message-column { width: min(100%, 760px); padding: 52px 0 28px; }
.message-column-empty { display: grid; align-content: center; padding-top: 30px; padding-bottom: 30px; }
.welcome-block { max-width: 570px; margin: 0 auto; }
.welcome-icon { width: 43px; height: 43px; display: grid; place-items: center; margin-bottom: 27px; border: 1px solid rgba(145,229,173,.2); border-radius: 14px; background: rgba(102,205,135,.08); color: #a2eeba; }
.eyebrow { margin: 0 0 12px; color: #8bd9a4; font-size: 10px; font-weight: 700; letter-spacing: .16em; }
.welcome-block h1, .auth-card h1, .setup-card h1 { margin: 0; color: #f1f3f4; font-size: clamp(31px, 4vw, 42px); font-weight: 520; letter-spacing: -.055em; line-height: 1.15; }
.welcome-copy { max-width: 440px; margin: 13px 0 28px; color: #969ca5; font-size: 14px; line-height: 1.7; }
.suggestion-list { display: grid; gap: 8px; }
.suggestion-card { display: flex; align-items: center; justify-content: space-between; gap: 16px; padding: 13px 14px; border: 1px solid var(--line); border-radius: 9px; background: rgba(255,255,255,.018); color: #c6cacf; text-align: left; transition: background .18s, border-color .18s; }
.suggestion-card:hover { border-color: rgba(151,229,175,.28); background: rgba(151,229,175,.045); }
.suggestion-arrow { color: #9097a0; transform: rotate(45deg); }
.suggestion-arrow-1 { color: #c2a4ef; }
.suggestion-arrow-2 { color: #a3c8f0; }
.message-list { display: flex; flex-direction: column; gap: 30px; }
.message-row { display: flex; align-items: flex-start; gap: 13px; }
.message-avatar { width: 29px; height: 29px; font-size: 11px; }
.assistant-avatar { border: 1px solid rgba(150,229,174,.17); background: rgba(115,208,145,.08); color: #a2eeba; }
.message-body { min-width: 0; flex: 1; padding-top: 2px; }
.message-author { margin-bottom: 7px; color: #e3e6e8; font-size: 12px; font-weight: 600; }
.message-body p { margin: 0; color: #c1c5cb; font-size: 14px; line-height: 1.8; white-space: pre-wrap; overflow-wrap: anywhere; }
.thinking-indicator { display: inline-flex; gap: 4px; padding: 6px 0; }
.thinking-indicator i { width: 5px; height: 5px; border-radius: 50%; background: #9ce7b5; animation: pulse 1s infinite ease-in-out; }
.thinking-indicator i:nth-child(2) { animation-delay: .14s; }
.thinking-indicator i:nth-child(3) { animation-delay: .28s; }
@keyframes pulse { 0%, 60%, 100% { opacity: .35; transform: translateY(0); } 30% { opacity: 1; transform: translateY(-3px); } }
.composer-area { width: min(100% - 48px, 760px); margin: 0 auto; padding: 10px 0 15px; }
.composer { padding: 11px 12px 9px 16px; border: 1px solid rgba(255,255,255,.13); border-radius: 13px; background: #17191e; box-shadow: 0 10px 40px rgba(0,0,0,.14); transition: border-color .2s; }
.composer:focus-within { border-color: rgba(147,226,170,.36); }
.composer textarea { width: 100%; min-height: 46px; resize: vertical; border: 0; outline: 0; background: transparent; color: #e8eaec; font-size: 13px; line-height: 1.6; }
.composer textarea::placeholder { color: #727882; }
.composer-footer { display: flex; align-items: center; justify-content: space-between; gap: 12px; }
.composer-footer > span { display: flex; align-items: center; gap: 6px; color: #737a83; font-size: 10px; }
.composer-footer > span svg { color: #91daa8; }
.send-button, .primary-button { display: grid; place-items: center; border: 0; border-radius: 8px; background: #a5edbd; color: #142018; transition: background .18s, transform .18s; }
.send-button { width: 31px; height: 31px; }
.send-button:hover:not(:disabled), .primary-button:hover:not(:disabled) { background: #bcf4ce; transform: translateY(-1px); }
.composer-disclaimer { margin: 9px 0 0; color: #626872; font-size: 10px; text-align: center; }
.chat-error, .form-message { padding: 10px 12px; border: 1px solid rgba(255,126,126,.18); border-radius: 8px; background: rgba(190,72,72,.09); color: #f2a9a9; font-size: 12px; line-height: 1.55; }
.form-notice { border-color: rgba(145,229,173,.2); background: rgba(102,205,135,.07); color: #a8e7b9; }

.auth-screen, .setup-screen, .loading-screen { position: relative; min-height: 100svh; display: grid; place-items: center; overflow: hidden; background: radial-gradient(ellipse at 50% 0%, #17231c 0, #101216 38%, #0c0e11 78%); }
.auth-glow { position: absolute; width: 300px; height: 300px; border-radius: 50%; filter: blur(100px); opacity: .13; pointer-events: none; }
.auth-glow-one { top: 9%; left: 12%; background: #4adb7f; }
.auth-glow-two { right: 10%; bottom: 4%; background: #619dbd; opacity: .1; }
.auth-card, .setup-card { position: relative; width: min(100% - 36px, 418px); padding: 33px; border: 1px solid rgba(255,255,255,.09); border-radius: 17px; background: rgba(19,22,26,.82); box-shadow: 0 24px 100px rgba(0,0,0,.38); backdrop-filter: blur(18px); }
.auth-brand { margin-bottom: 42px; }
.auth-card .eyebrow { margin-bottom: 11px; }
.auth-card h1, .setup-card h1 { font-size: 32px; }
.auth-subtitle { margin: 11px 0 24px; color: #9298a1; font-size: 13px; line-height: 1.65; }
.auth-form { display: flex; flex-direction: column; }
.auth-form label { margin: 14px 0 7px; color: #c4c8cd; font-size: 11px; font-weight: 550; }
.auth-form input { height: 41px; padding: 0 11px; outline: none; border: 1px solid rgba(255,255,255,.11); border-radius: 7px; background: #111317; color: #edf0f2; }
.auth-form input:focus { border-color: rgba(147,226,170,.47); }
.primary-button { min-height: 42px; display: flex; gap: 9px; margin-top: 20px; font-size: 12px; font-weight: 650; }
.button-arrow { transform: rotate(45deg); }
.auth-switch { margin: 20px 0 0; color: #858b94; font-size: 11px; text-align: center; }
.auth-switch button { padding: 0; border: 0; background: transparent; color: #a5edbd; font-weight: 600; }
.auth-footnote { display: flex; align-items: center; justify-content: center; gap: 5px; margin: 24px 0 0; color: #727982; font-size: 10px; }
.auth-footnote svg { color: #91daa8; }
.loading-screen { display: flex; gap: 10px; color: #9aa1a9; font-size: 12px; }
.spinner { animation: spin 1s linear infinite; }
@keyframes spin { to { transform: rotate(360deg); } }
.setup-card { width: min(100% - 36px, 520px); }
.setup-card .brand-mark { margin-bottom: 24px; }
.setup-card h1 { margin-bottom: 12px; }
.setup-card p, .setup-card li { color: #9da3ab; font-size: 13px; line-height: 1.7; }
.setup-card ol { display: grid; gap: 6px; padding-left: 21px; margin: 20px 0; }
.setup-card code { color: #b2edc2; font-family: Consolas, monospace; font-size: .92em; }
.setup-card a { color: #a5edbd; font-size: 12px; }

@media (max-width: 760px) {
  .sidebar { width: 220px; flex-basis: 220px; padding-inline: 11px; }
  .topbar { padding-inline: 19px; }
  .powered-by { display: none; }
  .conversation-scroll { padding-inline: 18px; }
  .composer-area { width: calc(100% - 32px); }
}
@media (max-width: 560px) {
  .workspace { flex-direction: column-reverse; }
  .sidebar { width: 100%; flex: 0 0 auto; padding: 10px 14px; border-top: 1px solid var(--line); border-right: 0; }
  .sidebar-brand, .sidebar-section-label, .conversation-list { display: none; }
  .new-chat-button { margin: 0; }
  .sidebar-account { position: absolute; z-index: 1; right: 12px; bottom: 10px; width: 43%; padding: 0; border: 0; }
  .account-copy span { display: none; }
  .chat-panel { min-height: calc(100svh - 52px); }
  .topbar { height: 50px; padding-inline: 15px; }
  .topbar-context { max-width: 100%; font-size: 9px; }
  .conversation-scroll { padding-inline: 17px; }
  .message-column { padding-top: 30px; }
  .message-column-empty { padding-top: 10px; }
  .welcome-block h1 { font-size: 33px; }
  .composer-area { width: calc(100% - 26px); padding-bottom: 10px; }
  .new-chat-button span { display: none; }
  .auth-card { padding: 27px 23px; }
}
'@

    Write-SlmnFullFile -Path $Path -RelativePath '.env.example' -Content @'
# Supabase project URL: Supabase dashboard → Project Settings → API → Project URL
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co

# Supabase publishable key (safe for browser use; database access is protected by RLS):
# Supabase dashboard → Project Settings → API Keys → Publishable key
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=sb_publishable_replace_me

# OpenAI secret key (server-only; never prefix this with NEXT_PUBLIC_):
# Create at https://platform.openai.com/api-keys
OPENAI_API_KEY=sk-proj-replace_me

# Optional model ID. Defaults to gpt-4.1-mini.
OPENAI_MODEL=gpt-4.1-mini
'@

    $gitignorePath = Join-Path $Path '.gitignore'
    if (-not (Test-Path -LiteralPath $gitignorePath -PathType Leaf)) {
        throw "Expected the Next.js scaffold to create .gitignore: $gitignorePath"
    }
    $gitignoreContents = [System.IO.File]::ReadAllText($gitignorePath)
    if ($gitignoreContents -notmatch '(?m)^!\.env\.example\s*$') {
        [System.IO.File]::AppendAllText(
            $gitignorePath,
            [Environment]::NewLine + '!.env.example' + [Environment]::NewLine,
            [System.Text.UTF8Encoding]::new($false)
        )
    }

    Write-SlmnFullFile -Path $Path -RelativePath 'database/schema.sql' -Content @'
create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null default 'New chat',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  role text not null check (role in ('user', 'assistant')),
  content text not null,
  created_at timestamptz not null default now()
);

create index if not exists conversations_user_updated_idx
  on public.conversations (user_id, updated_at desc);
create index if not exists messages_conversation_created_idx
  on public.messages (conversation_id, created_at);

alter table public.conversations enable row level security;
alter table public.messages enable row level security;

grant select, insert, update, delete on public.conversations to authenticated;
grant select, insert on public.messages to authenticated;

drop policy if exists "Users can read their own conversations" on public.conversations;
create policy "Users can read their own conversations"
  on public.conversations for select to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "Users can create their own conversations" on public.conversations;
create policy "Users can create their own conversations"
  on public.conversations for insert to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "Users can update their own conversations" on public.conversations;
create policy "Users can update their own conversations"
  on public.conversations for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "Users can delete their own conversations" on public.conversations;
create policy "Users can delete their own conversations"
  on public.conversations for delete to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "Users can read messages in their conversations" on public.messages;
create policy "Users can read messages in their conversations"
  on public.messages for select to authenticated
  using (exists (
    select 1 from public.conversations
    where conversations.id = messages.conversation_id
      and conversations.user_id = (select auth.uid())
  ));

drop policy if exists "Users can add messages to their conversations" on public.messages;
create policy "Users can add messages to their conversations"
  on public.messages for insert to authenticated
  with check (exists (
    select 1 from public.conversations
    where conversations.id = messages.conversation_id
      and conversations.user_id = (select auth.uid())
  ));

create or replace function public.touch_conversation_after_message()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.conversations
  set updated_at = now()
  where id = new.conversation_id;
  return new;
end;
$$;

drop trigger if exists touch_conversation_after_message on public.messages;
create trigger touch_conversation_after_message
  after insert on public.messages
  for each row execute function public.touch_conversation_after_message();
'@

    $readme = @'
# __PROJECT_NAME__ — SLMN Full

A polished, single-project full-stack starter: Next.js App Router, TypeScript, Tailwind CSS v4, Supabase Auth + Postgres, and a streaming OpenAI chat. The Orbit chat is a working, removable product demo—not a separate service.

## Getting started

### 1. Create the Supabase project and database

1. Create a project at [supabase.com/dashboard](https://supabase.com/dashboard).
2. Open **SQL Editor**, paste the contents of [`database/schema.sql`](./database/schema.sql), and run it. This creates the chat tables, indexes, ownership policies, and timestamp trigger.
3. Under **Authentication → Providers → Email**, enable email/password sign-in. For quick local testing, you can turn off email confirmation; otherwise, new users must confirm the link delivered to their email.
4. Under **Project Settings → API**, copy the **Project URL** and **Publishable key**. The app uses a publishable key and RLS; never put a service-role key in the browser.

### 2. Add environment variables

Copy `.env.example` to `.env.local` and fill in:

- `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` from Supabase **Project Settings → API**.
- `OPENAI_API_KEY` from [platform.openai.com/api-keys](https://platform.openai.com/api-keys). This is a server-only secret.
- `OPENAI_MODEL` is optional; it defaults to `gpt-4.1-mini`.

Restart the development server after changing environment values.

### 3. Run the app

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000), create an account, and start chatting. Production checks:

```bash
npm run lint
npm run build
```

## What is included

- `src/app/` — App Router shell, setup screen, and authenticated chat API route.
- `src/components/chat-workspace.tsx` — self-contained demo UI for email auth, saved chats, and streaming chat.
- `src/lib/supabase/` — browser and cookie-aware server clients.
- `database/schema.sql` — conversations/messages schema, indexes, RLS policies, and chat ordering trigger.
- `.env.example` — documented public and server-only configuration.
- `AGENTS.md` — architecture, product intent, safety constraints, and validation expectations for coding agents.

## Security and production notes

- The OpenAI key is only read by the server route; it is never sent to the browser.
- Supabase RLS restricts conversations and messages to their owner. Keep RLS enabled and do not ship a service-role key to client code.
- The API validates the signed-in user and conversation ownership, bounds each message, and sends only the latest 20 messages as model context.
- Add rate limiting, observability, and your own data-retention policy before exposing this demo publicly. Configure your production Supabase Auth redirect/site URLs before deployment.

## Removing the demo

The Orbit sample is intentionally easy to replace. Swap `src/components/chat-workspace.tsx` and the content in `src/app/page.tsx` for your product UI. Keep `src/app/api/chat/route.ts` and `src/lib/supabase/` only if you want the supplied AI and Supabase integrations; remove `database/schema.sql` if you do not need saved chats. Then remove unused packages from `package.json`.
'@
    Write-SlmnFullFile -Path $Path -RelativePath 'README.md' -Content ($readme.Replace('__PROJECT_NAME__', $Name))

    $agents = @'
# AGENTS.md

## Project intent

This project is a production-minded starting point for a small full-stack product. The included Orbit experience demonstrates email authentication, private database-backed conversations, and a streamed AI response. Replace the demo with the product being built; do not let the sample define product scope.

## How to work here

1. Read this file before changing code.
2. Inspect the current implementation and configuration before choosing a pattern.
3. Keep changes focused and preserve the server/client boundaries below.
4. Run `npm run lint` and `npm run build` for meaningful changes; manually test auth, chat persistence, and streaming when those flows change.
5. Report what changed, how it was verified, and any required external setup.

## Architecture and boundaries

- Next.js App Router with TypeScript. Prefer Server Components; add `"use client"` only for interactive/browser-dependent UI.
- Tailwind CSS v4 is configured through `src/app/globals.css`.
- Supabase Auth and Postgres are accessed through `@supabase/ssr` clients. Use the browser client for user-scoped interactive data and the cookie-aware server client in route handlers.
- `database/schema.sql` is the source of truth for saved conversation data and its Row Level Security policies. Do not bypass RLS or use a service-role key for ordinary requests.
- `/api/chat` validates the session and chat ownership, reads bounded history from Supabase, and streams model output from the server.
- `OPENAI_API_KEY` is secret and server-only. Only `NEXT_PUBLIC_*` values may be considered browser-visible; never place credentials in client components, logs, or committed files.
- Email/password is the demo auth flow. Storage is intentionally not configured because the demo does not use it.

## Product and data model

- A user can sign up, sign in, start a conversation, revisit saved conversations, and stream an assistant response.
- `conversations.user_id` identifies the owner. `messages` belong to one conversation and contain only `user` or `assistant` text.
- Every database read/write must remain scoped by Supabase Auth and the matching RLS rules.
- The Orbit sample is removable. Keep product-specific code out of shared starter setup; replace `src/components/chat-workspace.tsx` and `src/app/page.tsx` when beginning a real product.

## Technology choices

- Next.js App Router, React, TypeScript
- Tailwind CSS v4
- Supabase Auth, Postgres, and `@supabase/ssr`
- Vercel AI SDK (`ai`, `@ai-sdk/openai`) with a configurable OpenAI model
- `lucide-react` for demo icons

## Checks

- `npm run lint`
- `npm run build`
- Manual: create/sign in to an account; create a chat; send a prompt and confirm it streams; reload and confirm the conversation persists; verify a second account cannot read the first account's data.

## Non-goals and constraints

- No separate Express server, extra provider variants, or unused storage integration.
- Do not accept conversation history from the browser as trusted model context; load it from the database after verifying ownership.
- Do not add privileged database credentials to the frontend.
- Before public production use, add rate limiting, provider-cost controls, monitoring, and an explicit retention policy.
'@
    Write-SlmnFullFile -Path $Path -RelativePath 'AGENTS.md' -Content $agents

    foreach ($asset in @('public/next.svg', 'public/vercel.svg', 'public/file.svg', 'public/globe.svg', 'src/app/favicon.ico')) {
        $assetPath = Join-Path $Path $asset
        if (Test-Path -LiteralPath $assetPath -PathType Leaf) {
            Remove-Item -LiteralPath $assetPath -Force
        }
    }
}

function slmn-full {
    param(
        [Parameter(Mandatory)][string]$name,
        [Alias('Path')][string]$ProjectRoot
    )

    $projectName = ($name.Trim().ToLowerInvariant() -replace '[^a-z0-9._-]+', '-').Trim([char[]]'.-_')
    if ([string]::IsNullOrWhiteSpace($projectName)) {
        throw 'Project name must contain at least one letter or number.'
    }

    $projectsRoot = Get-SlmnProjectsPath -OverridePath $ProjectRoot
    $path = Join-Path $projectsRoot $projectName
    if (Test-Path -LiteralPath $path) {
        throw "Project already exists: $path"
    }

    Set-Location $projectsRoot
    if ($projectName -ne $name) {
        Write-Host "Using project folder name: $projectName" -ForegroundColor DarkGray
    }
    Write-SlmnStatus "Scaffolding the Next.js full-stack project '$projectName'..."
    & npx --yes create-next-app@latest $projectName --typescript --tailwind --eslint --app --src-dir --use-npm --import-alias '@/*' --yes
    if ($LASTEXITCODE -ne 0) {
        throw "Next.js setup failed for '$projectName'."
    }

    if (-not (Test-Path -LiteralPath (Join-Path $path 'src/app/layout.tsx')) -or
        -not (Test-Path -LiteralPath (Join-Path $path 'package.json'))) {
        throw "Next.js did not create the expected TypeScript project: $path"
    }

    Push-Location $path
    try {
        Invoke-Npm install ai @ai-sdk/openai @supabase/ssr @supabase/supabase-js lucide-react
        Write-SlmnFullProject -Path $path -Name $projectName
    } finally {
        Pop-Location
    }

    Write-Host ''
    Write-Host '  Next steps:' -ForegroundColor Green
    Write-Host '  1. Copy .env.example to .env.local and add your Supabase URL + publishable key.' -ForegroundColor White
    Write-Host '     Get them from Supabase Dashboard > Project Settings > API.' -ForegroundColor DarkGray
    Write-Host '  2. Run database/schema.sql in your Supabase project SQL Editor.' -ForegroundColor White
    Write-Host '  3. Add OPENAI_API_KEY from https://platform.openai.com/api-keys to .env.local.' -ForegroundColor White
    Write-Host '  4. Start the app with: npm run dev' -ForegroundColor White
    Write-Host '  See README.md for the full setup, email confirmation, and production notes.' -ForegroundColor DarkGray
    Write-Host ''

    Set-Location $path
    Open-ProjectEditor -Path $path -SkipAgentInstructions
    Start-SlmnDevServer -Path $path
}

# -----------------------------
# 11. STARTER MENU
# -----------------------------
function slmn-starter {
    param([Alias('Path')][string]$ProjectRoot)

    $initialCommand = $null
    while ($true) {
        $command = Select-StarterCommand -InitialCommand $initialCommand
        if ([string]::IsNullOrWhiteSpace($command)) {
            Write-Host 'Starter selection cancelled.' -ForegroundColor DarkGray
            return
        }

        if ($command -eq '__settings__') {
            Show-SlmnSettings
            $initialCommand = $null
            continue
        }

        Clear-Host
        Show-SlmnBanner
        Write-SlmnStatus "Selected $command"
        $name = Read-SlmnProjectName
        if ($null -eq $name) {
            Write-Host 'Returning to the starter selection...' -ForegroundColor DarkGray
            $initialCommand = $command
            continue
        }
        if ([string]::IsNullOrWhiteSpace($name)) {
            throw 'A project name is required.'
        }

        Write-SlmnStatus "Creating '$($name.Trim())'..."
        & $command $name.Trim() -Path $ProjectRoot
        return
    }
}

# -----------------------------
# 12. INTERACTIVE NEXT.JS
# -----------------------------
function next-app {
    param(
        [Parameter(Mandatory)][string]$name,
        [Alias('Path')][string]$ProjectRoot
    )

    $projectsRoot = Get-SlmnProjectsPath -OverridePath $ProjectRoot
    $path = Join-Path $projectsRoot $name
    if (Test-Path -LiteralPath $path) {
        throw "Project already exists: $path"
    }

    Set-Location $projectsRoot
    Write-SlmnStatus "Scaffolding the Next.js project '$name'..."
    npx create-next-app@latest $name
    if ($LASTEXITCODE -ne 0) {
        throw "Next.js setup failed for '$name'."
    }

    Complete-InteractiveProject -Path $path -Name $name -Stack Next
}

# <<< SLMN PROFILE SCRIPT END <<<

function next-ts-app {
    param(
        [Parameter(Mandatory)][string]$name,
        [Alias('Path')][string]$ProjectRoot
    )

    $projectsRoot = Get-SlmnProjectsPath -OverridePath $ProjectRoot
    $path = Join-Path $projectsRoot $name
    if (Test-Path -LiteralPath $path) {
        throw "Project already exists: $path"
    }

    Set-Location $projectsRoot
    Write-SlmnStatus "Scaffolding the Next.js + TypeScript project '$name'..."
    npx create-next-app@latest $name --typescript
    if ($LASTEXITCODE -ne 0) {
        throw "Next.js TypeScript setup failed for '$name'."
    }

    Complete-InteractiveProject -Path $path -Name $name -Stack Next
}
