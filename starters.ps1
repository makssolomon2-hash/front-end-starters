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
#   react-tailwind-gsap-project "motion-app"
#   vite-app "my-app"
#   next-app "my-next-app"
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

    $autoHotkey = Get-Command AutoHotkey.exe, AutoHotkey64.exe -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $autoHotkey) {
        throw 'AutoHotkey v2 was not found in PATH. Install it from https://www.autohotkey.com/ and run slmn-install-hotkeys again.'
    }

    $hotkeysPath = Get-SlmnHotkeysPath
    New-Item -ItemType Directory -Path (Get-SlmnInstallDirectory) -Force | Out-Null
    Copy-Item -LiteralPath $sourcePath -Destination $hotkeysPath -Force

    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut((Get-SlmnHotkeysStartupShortcutPath))
    $shortcut.TargetPath = $autoHotkey.Source
    $shortcut.Arguments = '"' + $hotkeysPath + '"'
    $shortcut.WorkingDirectory = Get-SlmnInstallDirectory
    $shortcut.Save()

    Start-Process -FilePath $autoHotkey.Source -ArgumentList ('"' + $hotkeysPath + '"')
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

function Set-StaticStarterScreen {
    param(
        [string]$Path,
        [string]$Name,
        [string[]]$Technologies,
        [switch]$UseVite,
        [switch]$UseGsap
    )

    $technologyPills = ($Technologies | ForEach-Object { "        <span class=`"slmn-tech-pill`">$_</span>" }) -join "`n"
    $scriptTag = if ($UseVite) { '<script type="module" src="/src/script.js"></script>' } else { '<script src="./js/script.js"></script>' }
    $gsapScript = if ($UseGsap -and -not $UseVite) { '    <script src="https://cdnjs.cloudflare.com/ajax/libs/gsap/3.12.5/gsap.min.js"></script>' } else { '' }
    $stylesheetHref = if ($UseVite) { '/src/style.css' } else { './css/style.css' }

    @"
<!doctype html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$Name</title>
    <link rel="stylesheet" href="$stylesheetHref">
</head>
<body>
    <main class="slmn-start">
        <section class="slmn-screen">
            <p class="slmn-kicker" data-slmn-reveal>SLMN Starter</p>
            <h1 data-slmn-reveal>Ready to build.</h1>
            <p class="slmn-project" data-slmn-reveal>$Name</p>
            <div class="slmn-tech-list" data-slmn-reveal>
$technologyPills
            </div>
        </section>
    </main>
$gsapScript
    $scriptTag
</body>
</html>
"@ | Set-Content -LiteralPath (Join-Path $Path 'index.html') -Encoding utf8

    @'
* {
    box-sizing: border-box;
}

:root {
    color: #ffffff;
    background: #171717;
    font-family: "Segoe UI", sans-serif;
}

body {
    min-width: 320px;
    min-height: 100vh;
    margin: 0;
}

.slmn-start {
    display: grid;
    min-height: 100vh;
    padding: 1.5rem;
    place-items: center;
    background-color: #171717;
    background-image: linear-gradient(rgb(255 255 255 / 0.035) 1px, transparent 1px), linear-gradient(90deg, rgb(255 255 255 / 0.035) 1px, transparent 1px);
    background-size: 3rem 3rem;
}

.slmn-screen {
    width: min(100%, 56rem);
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
    max-width: 42rem;
    margin: 0;
    font-size: clamp(2.5rem, 7vw, 4.75rem);
    font-weight: 600;
    line-height: 1.1;
}

.slmn-project {
    margin: 1.25rem 0 0;
    color: #d4d4d4;
    font-size: clamp(1rem, 3vw, 1.25rem);
}

.slmn-tech-list {
    display: flex;
    flex-wrap: wrap;
    gap: 0.625rem;
    margin-top: 2rem;
}

.slmn-tech-pill {
    padding: 0.625rem 0.875rem;
    color: #dbeafe;
    font-size: 0.875rem;
    font-weight: 600;
    background: rgb(96 165 250 / 0.14);
    border: 1px solid rgb(147 197 253 / 0.34);
}

@media (min-width: 48rem) {
    .slmn-start {
        padding: 2.5rem;
    }
}
'@ | ForEach-Object {
        $stylesheetPath = Join-Path $Path $(if ($UseVite) { 'src/style.css' } else { 'css/style.css' })
        New-Item -ItemType Directory -Path (Split-Path -Parent $stylesheetPath) -Force | Out-Null
        Set-Content -LiteralPath $stylesheetPath -Value $_ -Encoding utf8
    }

    $scriptPath = Join-Path $Path $(if ($UseVite) { 'src/script.js' } else { 'js/script.js' })
    New-Item -ItemType Directory -Path (Split-Path -Parent $scriptPath) -Force | Out-Null
    $script = if ($UseGsap -and $UseVite) {
@'
import './style.css'
import gsap from 'gsap'

gsap.from('[data-slmn-reveal]', {
    y: 18,
    opacity: 0,
    duration: 0.55,
    stagger: 0.1,
    ease: 'power2.out',
})
'@
    } elseif ($UseGsap) {
@'
gsap.from('[data-slmn-reveal]', {
    y: 18,
    opacity: 0,
    duration: 0.55,
    stagger: 0.1,
    ease: 'power2.out',
})
'@
    } elseif ($UseVite) {
        "import './style.css'`n"
    } else {
        "console.log('Page loaded')`n"
    }
    Set-Content -LiteralPath $scriptPath -Value $script -Encoding utf8
}

function Invoke-Npm {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)

    Write-Host "Running: npm $($Arguments -join ' ')" -ForegroundColor Cyan
    & npm @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "npm $($Arguments -join ' ') failed with exit code $LASTEXITCODE."
    }
}

function Invoke-NpmDevInstall {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Packages)

    Write-Host "Installing development packages: $($Packages -join ', ')" -ForegroundColor Cyan
    & npm install --save-dev @Packages
    if ($LASTEXITCODE -ne 0) {
        throw "npm install --save-dev $($Packages -join ' ') failed with exit code $LASTEXITCODE."
    }
}

function Open-ProjectEditor {
    param([string]$Path)

    Write-Host "Project created: $Path" -ForegroundColor Green
    if (-not (Get-SlmnConfiguration).openInVSCode) {
        Write-Host 'VS Code opening is disabled in SLMN configuration.' -ForegroundColor DarkGray
        return
    }

    if (Get-Command code -ErrorAction SilentlyContinue) {
        & code $Path
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "VS Code could not open: $Path"
        }
    } else {
        Write-Warning "VS Code CLI ('code') was not found. Open manually: $Path"
    }
}

function Start-SlmnDevServer {
    if ((Get-SlmnConfiguration).autoStartDev) {
        Invoke-Npm run dev
    } else {
        Write-Host 'Automatic dev-server start is disabled in SLMN configuration.' -ForegroundColor DarkGray
    }
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
        @{ Label = 'Vanilla'; Shortcut = '1 / V'; Keys = @('1', 'v'); Command = 'vanilla-project' },
        @{ Label = 'Tailwind CSS'; Shortcut = '2 / T'; Keys = @('2', 't'); Command = 'tailwind-project' },
        @{ Label = 'GSAP'; Shortcut = '3 / G'; Keys = @('3', 'g'); Command = 'gsap-project' },
        @{ Label = 'Tailwind CSS + GSAP'; Shortcut = '4 / TG'; Keys = @('4', 'tg'); Command = 'tailwind-gsap-project' },
        @{ Label = 'React'; Shortcut = '5 / R'; Keys = @('5', 'r'); Command = 'react-project' },
        @{ Label = 'React + Tailwind CSS'; Shortcut = '6 / RT'; Keys = @('6', 'rt'); Command = 'react-tailwind-project' },
        @{ Label = 'React + Tailwind CSS + GSAP'; Shortcut = '7 / RTG'; Keys = @('7', 'rtg'); Command = 'react-tailwind-gsap-project' },
        @{ Label = 'SLMN App (flagship)'; Shortcut = '8 / A'; Keys = @('8', 'a'); Command = 'slmn-app' },
        @{ Label = 'Vite (choose framework and variant)'; Shortcut = '9 / VITE'; Keys = @('9', 'vite'); Command = 'vite-app' },
        @{ Label = 'Next.js'; Shortcut = '0 / NEXT'; Keys = @('0', 'next'); Command = 'next-app' }
    )
    $selectedIndex = 0
    $shortcutBuffer = ''

    while ($true) {
        Clear-Host
        Write-Host 'SLMN Starter' -ForegroundColor Cyan
        Write-Host 'Use Up/Down arrows and Enter, or type a shortcut.' -ForegroundColor DarkGray
        Write-Host ''

        for ($index = 0; $index -lt $options.Count; $index++) {
            $prefix = if ($index -eq $selectedIndex) { '> ' } else { '  ' }
            $color = if ($index -eq $selectedIndex) { 'Blue' } else { 'White' }
            Write-Host ("{0}{1,-10} {2}" -f $prefix, "[$($options[$index].Shortcut)]", $options[$index].Label) -ForegroundColor $color
        }

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

    $heroRef = if ($isTypeScript) { 'useRef<HTMLElement>(null)' } else { 'useRef(null)' }
    $titleRef = if ($isTypeScript) { 'useRef<HTMLHeadingElement>(null)' } else { 'useRef(null)' }
    $techPillProps = if ($isTypeScript) { ': { name: string; detail: string; href: string; Icon: IconType }' } else { '' }
    $techPillTypeImport = if ($isTypeScript) { "import type { IconType } from 'react-icons'`n" } else { '' }
    $canvasRef = if ($isTypeScript) { 'useRef<HTMLCanvasElement>(null)' } else { 'useRef(null)' }
    $pointerEventType = if ($isTypeScript) { ': PointerEvent' } else { '' }

    @"
import Hero from './components/Hero.$componentExtension'
import './styles/app.css'
import './styles/demo.css'

export default function App() {
    return (
        <main className="app-shell">
            <Hero />
        </main>
    )
}
"@ | Set-Content -LiteralPath $appPath -Encoding utf8

    @"
import { useLayoutEffect, useRef } from 'react'
import gsap from 'gsap'
import { SiGreensock, SiJavascript, SiReact, SiTailwindcss, SiThreedotjs, SiVite } from 'react-icons/si'
import TechPill from './TechPill.$componentExtension'
import ThreeScene from './three/ThreeScene.$componentExtension'

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
        name: 'JavaScript',
        detail: 'Language',
        href: 'https://developer.mozilla.org/docs/Web/JavaScript',
        Icon: SiJavascript,
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
        <section className="demo-shell px-4 py-10 text-white tab:px-8">
            <header ref={heroRef} className="demo-grid mx-auto grid min-h-[calc(100vh-5rem)] max-w-6xl items-center gap-8 lap:grid-cols-[1fr_0.9fr]">
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
#root,
.app-shell {
    min-height: 100vh;
}
'@ | Set-Content -LiteralPath (Join-Path $stylesPath 'app.css') -Encoding utf8

@'
.demo-shell {
    min-height: 100vh;
    background-color: #171717;
    background-image: linear-gradient(rgb(255 255 255 / 0.035) 1px, transparent 1px), linear-gradient(90deg, rgb(255 255 255 / 0.035) 1px, transparent 1px);
    background-size: 3rem 3rem;
}

.demo-grid {
    position: relative;
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

    $technologies = @(
        @{ Name = 'Vite'; Detail = 'Build tooling'; Href = 'https://vite.dev/' },
        @{ Name = 'React'; Detail = 'UI library'; Href = 'https://react.dev/' },
        @{ Name = 'JavaScript'; Detail = 'Language'; Href = 'https://developer.mozilla.org/docs/Web/JavaScript' }
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
    $heroReference = if ($IncludeGsap) { "    const heroRef = useRef(null)`n    const titleRef = useRef(null)`n" } else { '' }
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

    @'
import Hero from './components/Hero.$componentExtension'
import './styles/app.css'
import './styles/demo.css'

export default function App() {
    return (
        <main className="app-shell">
            <Hero />
        </main>
    )
}
'@ | Set-Content -LiteralPath $appPath -Encoding utf8

    @"
$gsapImports
import TechPill from './TechPill.$componentExtension'

const technologies = [
$technologyItems]

export default function Hero() {
$heroReference$animation
    return (
        <section className="demo-shell">
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
#root,
.app-shell {
    min-height: 100vh;
}
'@ | Set-Content -LiteralPath (Join-Path $stylesPath 'app.css') -Encoding utf8

    @'
.demo-shell {
    box-sizing: border-box;
    min-height: 100vh;
    padding: 2.5rem 1rem;
    color: #fff;
    background-color: #171717;
    background-image: linear-gradient(rgb(255 255 255 / 0.035) 1px, transparent 1px), linear-gradient(90deg, rgb(255 255 255 / 0.035) 1px, transparent 1px);
    background-size: 3rem 3rem;
}

.demo-grid {
    display: grid;
    min-height: calc(100vh - 5rem);
    max-width: 72rem;
    margin: 0 auto;
    align-items: center;
}

.demo-copy {
    max-width: 40rem;
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
    font-size: clamp(2.5rem, 7vw, 4.5rem);
    font-weight: 600;
    line-height: 1.1;
}

.demo-description {
    max-width: 34rem;
    margin: 1.25rem 0 0;
    color: #d4d4d4;
    font-size: 1.125rem;
    line-height: 1.75;
}

.demo-tech-list {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(12rem, 1fr));
    gap: 0.75rem;
    margin-top: 2rem;
}

.demo-tech-pill {
    display: flex;
    gap: 0.75rem;
    align-items: flex-start;
    padding: 1rem;
    color: inherit;
    text-decoration: none;
    background: rgb(255 255 255 / 0.05);
    border: 1px solid rgb(255 255 255 / 0.1);
    transition: border-color 160ms ease, background-color 160ms ease, transform 160ms ease;
}

.demo-tech-pill:hover {
    background: rgb(255 255 255 / 0.09);
    border-color: rgb(147 197 253 / 0.65);
    transform: translateY(-2px);
}

.demo-tech-pill:focus-visible {
    outline: 2px solid #93c5fd;
    outline-offset: 3px;
}

.demo-tech-mark {
    display: grid;
    width: 1.5rem;
    height: 1.5rem;
    flex: 0 0 auto;
    place-items: center;
    color: #bfdbfe;
    font-size: 0.75rem;
    font-weight: 700;
    background: rgb(96 165 250 / 0.2);
}

.demo-tech-name,
.demo-tech-detail {
    display: block;
}

.demo-tech-name {
    color: #fff;
    font-weight: 600;
}

.demo-tech-detail {
    margin-top: 0.25rem;
    color: #a3a3a3;
    font-size: 0.875rem;
}

.demo-note {
    margin: 0.75rem 0 0;
    color: #a3a3a3;
    font-size: 0.875rem;
}

@media (min-width: 48rem) {
    .demo-shell {
        padding-right: 2rem;
        padding-left: 2rem;
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
    <script type="module" src="/src/main.jsx"></script>
</body>
</html>
"@ | Set-Content -LiteralPath (Join-Path $Path 'index.html') -Encoding utf8

    Remove-Item -LiteralPath (Join-Path $Path 'src/assets') -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath (Join-Path $Path 'public') -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath (Join-Path $Path 'src/App.css') -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath (Join-Path $Path 'eslint.config.js') -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath (Join-Path $Path 'README.md') -Force -ErrorAction SilentlyContinue
    Invoke-Npm pkg delete scripts.lint
    Invoke-Npm uninstall eslint @eslint/js eslint-plugin-react-hooks eslint-plugin-react-refresh globals
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
    $technologyPills = ($technologies | ForEach-Object { "                    <span className={styles.pill}>$_</span>" }) -join "`n"
    $gsapImport = if ($IncludeGsap) { "import { useLayoutEffect, useRef } from 'react'`nimport gsap from 'gsap'" } else { '' }
    $animation = if ($IncludeGsap) {
@'
    const screenRef = useRef(null)

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
'@
    } else { '' }
    $screenReference = if ($IncludeGsap) { ' ref={screenRef}' } else { '' }

    @"
'use client'

$gsapImport
import styles from '../app/slmn-start.module.css'

export default function SlmnStartScreen() {
$animation
    return (
        <main$screenReference className={styles.shell}>
            <section className={styles.content}>
                <p className={styles.kicker} data-slmn-reveal>SLMN Starter</p>
                <h1 data-slmn-reveal>Ready to build.</h1>
                <p className={styles.project} data-slmn-reveal>$Name</p>
                <div className={styles.pills} data-slmn-reveal>
$technologyPills
                </div>
            </section>
        </main>
    )
}
"@ | Set-Content -LiteralPath (Join-Path $componentsDirectory "SlmnStartScreen.$componentExtension") -Encoding utf8

    @"
import SlmnStartScreen from '../components/SlmnStartScreen'

export default function Home() {
    return <SlmnStartScreen />
}
"@ | Set-Content -LiteralPath $pagePath -Encoding utf8

    @'
.shell {
    display: grid;
    min-height: 100vh;
    padding: 1.5rem;
    color: #ffffff;
    background-color: #171717;
    background-image: linear-gradient(rgb(255 255 255 / 0.035) 1px, transparent 1px), linear-gradient(90deg, rgb(255 255 255 / 0.035) 1px, transparent 1px);
    background-size: 3rem 3rem;
    place-items: center;
}

.content {
    width: min(100%, 56rem);
}

.kicker {
    margin: 0 0 1rem;
    color: #93c5fd;
    font-size: 0.875rem;
    font-weight: 600;
    letter-spacing: 0.18em;
    text-transform: uppercase;
}

.content h1 {
    margin: 0;
    font-size: clamp(2.5rem, 7vw, 4.75rem);
    font-weight: 600;
    line-height: 1.1;
}

.project {
    margin: 1.25rem 0 0;
    color: #d4d4d4;
    font-size: clamp(1rem, 3vw, 1.25rem);
}

.pills {
    display: flex;
    flex-wrap: wrap;
    gap: 0.625rem;
    margin-top: 2rem;
}

.pill {
    padding: 0.625rem 0.875rem;
    color: #dbeafe;
    font-size: 0.875rem;
    font-weight: 600;
    background: rgb(96 165 250 / 0.14);
    border: 1px solid rgb(147 197 253 / 0.34);
}

@media (min-width: 48rem) {
    .shell {
        padding: 2.5rem;
    }
}
'@ | Set-Content -LiteralPath (Join-Path $appDirectory 'slmn-start.module.css') -Encoding utf8
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
    Start-SlmnDevServer
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
    Start-SlmnDevServer
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
    Start-SlmnDevServer
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
    Start-SlmnDevServer
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
    Start-SlmnDevServer
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
    Start-SlmnDevServer
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
    Clear-Host
    Write-Host "Selected: $command" -ForegroundColor Cyan
    $name = Read-Host 'Project name'
    if ([string]::IsNullOrWhiteSpace($name)) {
        throw 'A project name is required.'
    }

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
    npx create-next-app@latest $name
    if ($LASTEXITCODE -ne 0) {
        throw "Next.js setup failed for '$name'."
    }

    Complete-InteractiveProject -Path $path -Name $name -Stack Next
}
