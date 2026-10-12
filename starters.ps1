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

    if ($Setting -ine 'path') {
        throw 'Supported setting: path. Examples: slmn-config path "D:\Projects" or slmn-config path desktop'
    }
    if ([string]::IsNullOrWhiteSpace($Value)) {
        throw 'Provide a projects path. Example: slmn-config path "D:\Projects"'
    }

    $configuration.projectsPath = if ($Value -ieq 'desktop') { '%USERPROFILE%\Desktop' } else { $Value.Trim() }
    Get-SlmnProjectsPath -OverridePath $configuration.projectsPath | Out-Null
    $configuration | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath $configPath -Encoding utf8
    Write-Host "SLMN projects path: $(Get-SlmnProjectsPath)" -ForegroundColor Green
}

function Get-SlmnProfilePath {
    # $PROFILE identifies PowerShell's per-user profile scripts. All Hosts loads in PowerShell,
    # Windows Terminal, and VS Code, unlike a host-specific profile such as $PROFILE.CurrentUserCurrentHost.
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

function slmn-install {
    if ([string]::IsNullOrWhiteSpace($script:SlmnSourcePath) -or -not (Test-Path -LiteralPath $script:SlmnSourcePath)) {
        throw 'Run slmn-install from a loaded starters.ps1 file.'
    }

    $installDirectory = Get-SlmnInstallDirectory
    $installedScriptPath = Join-Path $installDirectory 'starters.ps1'
    $profilePath = Get-SlmnProfilePath
    New-Item -ItemType Directory -Path $installDirectory -Force | Out-Null
    $sourceScriptPath = (Resolve-Path -LiteralPath $script:SlmnSourcePath).Path
    $currentInstalledPath = (Resolve-Path -LiteralPath $installedScriptPath -ErrorAction SilentlyContinue).Path
    if ($sourceScriptPath -ne $currentInstalledPath) {
        Copy-Item -LiteralPath $script:SlmnSourcePath -Destination $installedScriptPath -Force
    }
    $sourceHotkeysPath = Join-Path (Split-Path -Parent $script:SlmnSourcePath) 'slmn-hotkeys.ahk'
    if (Test-Path -LiteralPath $sourceHotkeysPath) {
        $installedHotkeysPath = Join-Path $installDirectory 'slmn-hotkeys.ahk'
        if ((Resolve-Path -LiteralPath $sourceHotkeysPath).Path -ne (Resolve-Path -LiteralPath $installedHotkeysPath -ErrorAction SilentlyContinue).Path) {
            Copy-Item -LiteralPath $sourceHotkeysPath -Destination $installedHotkeysPath -Force
        }
    }
    Initialize-SlmnStorage | Out-Null

    New-Item -ItemType Directory -Path (Split-Path -Parent $profilePath) -Force | Out-Null
    if (-not (Test-Path -LiteralPath $profilePath)) {
        New-Item -ItemType File -Path $profilePath -Force | Out-Null
    }
    Remove-SlmnProfileEntry -ProfilePath $profilePath | Out-Null
    Add-Content -LiteralPath $profilePath -Value '. "$env:USERPROFILE\.slmn\starters.ps1"'

    Write-Host 'SLMN installed. Open a new PowerShell terminal to use the commands everywhere.' -ForegroundColor Green
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
    param([string]$SourcePath = $script:SlmnSourcePath)

    if ([string]::IsNullOrWhiteSpace($SourcePath) -or -not (Test-Path -LiteralPath $SourcePath)) {
        throw 'Provide a valid starters.ps1 file with: slmn-update -SourcePath "C:\path\to\starters.ps1"'
    }

    $installedScriptPath = Join-Path (Get-SlmnInstallDirectory) 'starters.ps1'
    if ((Resolve-Path -LiteralPath $SourcePath).Path -eq (Resolve-Path -LiteralPath $installedScriptPath -ErrorAction SilentlyContinue).Path) {
        Write-Host 'The installed SLMN script is already the loaded copy. Load a newer starters.ps1, then run slmn-update.' -ForegroundColor Yellow
        return
    }

    New-Item -ItemType Directory -Path (Get-SlmnInstallDirectory) -Force | Out-Null
    Copy-Item -LiteralPath $SourcePath -Destination $installedScriptPath -Force
    $sourceHotkeysPath = Join-Path (Split-Path -Parent $SourcePath) 'slmn-hotkeys.ahk'
    if (Test-Path -LiteralPath $sourceHotkeysPath) {
        Copy-Item -LiteralPath $sourceHotkeysPath -Destination (Join-Path (Get-SlmnInstallDirectory) 'slmn-hotkeys.ahk') -Force
    }
    Initialize-SlmnStorage | Out-Null
    Write-Host 'SLMN updated. Open a new PowerShell terminal to load the updated commands.' -ForegroundColor Green
}

function Get-SlmnHotkeysPath {
    return (Join-Path (Get-SlmnInstallDirectory) 'slmn-hotkeys.ahk')
}

function Get-SlmnHotkeysStartupShortcutPath {
    return (Join-Path ([Environment]::GetFolderPath('Startup')) 'SLMN Hotkeys.lnk')
}

function slmn-install-hotkeys {
    $sourceDirectory = Split-Path -Parent $script:SlmnSourcePath
    $sourcePath = Join-Path $sourceDirectory 'slmn-hotkeys.ahk'
    if (-not (Test-Path -LiteralPath $sourcePath)) {
        throw "slmn-hotkeys.ahk was not found next to starters.ps1: $sourcePath"
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

    $hotkeysPath = Get-SlmnHotkeysPath
    New-Item -ItemType Directory -Path (Get-SlmnInstallDirectory) -Force | Out-Null
    Copy-Item -LiteralPath $sourcePath -Destination $hotkeysPath -Force

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
    param([string]$Path)

    Write-SlmnSuccess "Project created: $Path"
    Write-ProjectAgentInstructions -Path $Path

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

function Select-StarterCommand {
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
        @{ Group = 'FRAMEWORKS'; Label = 'SLMN App (JavaScript)'; Shortcut = '8 / A'; Keys = @('8', 'a'); Badges = @(@{ Text = 'S'; Color = 'Cyan' }, @{ Text = 'JS'; Color = 'Yellow' }); Command = 'slmn-app' },
        @{ Group = 'FRAMEWORKS'; Label = 'Vite (choose framework and variant)'; Shortcut = '9 / VITE'; Keys = @('9', 'vite'); Badges = @(@{ Text = 'V'; Color = 'Magenta' }); Command = 'vite-app' },
        @{ Group = 'FRAMEWORKS'; Label = 'Next.js (TypeScript)'; Shortcut = 'NTS'; Keys = @('nts'); Badges = @(@{ Text = 'N'; Color = 'White' }, @{ Text = 'TS'; Color = 'Cyan' }); Command = 'next-ts-app' },
        @{ Group = 'FRAMEWORKS'; Label = 'Next.js'; Shortcut = '0 / NEXT'; Keys = @('0', 'next'); Badges = @(@{ Text = 'N'; Color = 'White' }, @{ Text = 'JS'; Color = 'Yellow' }); Command = 'next-app' }
    )
    $selectedIndex = 0
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
                Write-Host ("{0,2} [{1,-8}]" -f ($index + 1), $options[$index].Shortcut) -NoNewline -ForegroundColor DarkGray -BackgroundColor DarkBlue
                foreach ($badge in $options[$index].Badges) {
                    Write-Host " [$($badge.Text)]" -NoNewline -ForegroundColor $badge.Color -BackgroundColor DarkBlue
                }
                Write-Host "  $($options[$index].Label)" -ForegroundColor White -BackgroundColor DarkBlue
            } else {
                Write-Host ("    {0,2} [{1,-8}]" -f ($index + 1), $options[$index].Shortcut) -NoNewline -ForegroundColor DarkGray
                foreach ($badge in $options[$index].Badges) {
                    Write-Host " [$($badge.Text)]" -NoNewline -ForegroundColor $badge.Color
                }
                Write-Host "  $($options[$index].Label)" -ForegroundColor DarkGray
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
    $technologies = @('Next.js', 'React', $(if ($componentExtension -eq 'tsx') { 'TypeScript' } else { 'JavaScript' }))
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
    display: grid;
    width: 100%;
    min-height: 100svh;
    padding: 20px;
    color: #ffffff;
    text-align: left;
    background-color: #171717;
    background-image: linear-gradient(rgb(255 255 255 / 0.035) 1px, transparent 1px), linear-gradient(90deg, rgb(255 255 255 / 0.035) 1px, transparent 1px);
    background-size: 3rem 3rem;
    place-items: center;
}

.slmn-next-screen {
    display: grid;
    width: 100%;
    max-width: 72rem;
    min-height: min(30rem, calc(100svh - 40px));
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
# 11. STARTER MENU
# -----------------------------
function slmn-starter {
    param([Alias('Path')][string]$ProjectRoot)

    $command = Select-StarterCommand
    if ([string]::IsNullOrWhiteSpace($command)) {
        Write-Host 'Starter selection cancelled.' -ForegroundColor DarkGray
        return
    }

    Clear-Host
    Show-SlmnBanner
    Write-SlmnStatus "Selected $command"
    Write-Host '  Project name: ' -NoNewline -ForegroundColor Cyan
    $name = Read-Host
    if ([string]::IsNullOrWhiteSpace($name)) {
        throw 'A project name is required.'
    }

    Write-SlmnStatus "Creating '$($name.Trim())'..."
    & $command $name.Trim() -Path $ProjectRoot
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
