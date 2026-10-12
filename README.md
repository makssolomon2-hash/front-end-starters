<p align="center">
  <img 
    src="https://github.com/user-attachments/assets/54ddb4e6-c46d-4273-a1e0-d909b771f47a" 
    alt="SLMN React Starter" 
    style="max-width: 100%; height: auto; border-radius: 12px;" 
  />
</p>

# SLMN Frontend Starters

PowerShell commands for creating clean frontend projects in your configured projects folder. Non-React starters provide a clean, connected root page plus a removable full-screen SLMN demo with linked technology cards and a pointer-reactive blue `S` signal. React and Next.js starters open with the removable screen. The layout uses a centered content frame with responsive outer padding. `slmn-app` remains the flagship React, GSAP, and Three.js version with the interactive 3D model.

## Current Release

- A self-contained full-screen charcoal demo across Vanilla, Tailwind, GSAP, compatible interactive Vite templates, React, and Next.js App Router projects.
- Linked cards list only the project's installed technologies.
- A responsive, pointer-reactive blue `S` panel replaces the flagship Three.js scene in starters that do not include Three.js.
- Native CSS provides entrance motion by default. GSAP starters use GSAP for that reveal instead.
- The full demo remains isolated in clearly named files so it can be removed without untangling application code.
- Project destination, editor opening, and automatic dev-server startup are controlled through `~\.slmn\config.json`.


## Easiest Way to Install

Open Windows Terminal, then press `Win + X` and select `I` or `A`. Run:

```powershell
notepad $PROFILE
```

Paste the complete contents of `starters.ps1` into the profile file, then save it.

Restart Windows Terminal, then run:

```powershell
slmn-starter
```

Choose a starter from the menu.

## Quick Start

Open PowerShell in the folder containing `starters.ps1`, then run:

```powershell
. .\starters.ps1
slmn-starter
```

`slmn-starter` opens the colorized menu. Use the Up and Down arrow keys and Enter, or type the displayed shortcut, then enter a project name. Press Esc to cancel.

## What Is Included

| Command | Stack | Initial project |
| --- | --- | --- |
| `slmn-app "my-app"` | Vite, React JavaScript, Tailwind CSS v4, GSAP, Three.js, React Icons | **Flagship:** creates a removable SLMN technology demo with no setup prompts |
| `slmn-starter` | Starter menu | Choose a starter with arrows/Enter or a displayed shortcut |
| `vanilla-project "my-site"` | HTML, CSS, JavaScript | Full-screen native HTML/CSS/JS screen with a pointer-reactive visual |
| `tailwind-project "my-site"` | Vite, Tailwind CSS v4 | Full-screen Vite screen with Tailwind ready for application code |
| `gsap-project "my-site"` | HTML, CSS, JavaScript, GSAP CDN | Full-screen screen with a GSAP reveal and pointer-reactive visual |
| `tailwind-gsap-project "my-site"` | Vite, Tailwind CSS v4, GSAP | Full-screen Tailwind screen with GSAP reveal motion |
| `react-project "my-site"` | Vite, React | Removable React screen with linked stack cards and `StarterVisual` |
| `react-ts-project "my-site"` | Vite, React, TypeScript | Type-safe React screen with a clean TSX entry and TSX demo components |
| `react-tailwind-project "my-site"` | Vite, React, Tailwind CSS v4 | React screen with Tailwind and a removable pointer-reactive visual |
| `react-tailwind-ts-project "my-site"` | Vite, React, TypeScript, Tailwind CSS v4 | Type-safe React + Tailwind screen with TSX demo components |
| `react-tailwind-gsap-project "my-site"` | Vite, React, Tailwind CSS v4, GSAP | React screen with GSAP reveal motion and stack-specific links |
| `react-tailwind-gsap-ts-project "my-site"` | Vite, React, TypeScript, Tailwind CSS v4, GSAP | Type-safe React + Tailwind + GSAP screen |
| `react-tailwind-gsap-three-project "my-site"` | Vite, React, Tailwind CSS v4, GSAP, Three.js, React Icons | Full removable React technology demo with the interactive Three.js model |
| `react-tailwind-gsap-three-ts-project "my-site"` | Vite, React, TypeScript, Tailwind CSS v4, GSAP, Three.js, React Icons | TypeScript version of the full removable technology demo |
| `slmn-ts-app "my-app"` | Vite, React TypeScript, Tailwind CSS v4, GSAP, Three.js, React Icons | TypeScript flagship demo; project name is normalized for npm |
| `vite-app "my-app"` | Vite | Official Vite prompts, optional libraries, then a matching screen for React and vanilla templates |
| `full-app "my-demo"` | Alias for `slmn-app` | Backwards-compatible name for the flagship starter |
| `next-app "my-next-app"` | Next.js | Official Create Next App prompts, optional GSAP/Three.js, then a matching App Router screen |
| `next-ts-app "my-next-app"` | Next.js, TypeScript | Create Next App with TypeScript explicitly selected, then optional libraries and a matching App Router screen |

Vite-generated projects are cleaned before VS Code opens. They do not keep the default counter, starter icons, `public` folder, `src/assets`, generated README, or the default React lint setup. TypeScript Vite starters retain Vite's `tsconfig.json` files and use typed TSX demo components.

## Requirements

- Windows with PowerShell
- Node.js LTS and npm for the Vite-based starters
- VS Code with the `code` command available in `PATH`
- AutoHotkey v2 only when using global hotkeys

Git is not required. The Vanilla and GSAP starters do not require npm.

Check the required commands:

```powershell
node --version
npm --version
code --version
```

## Install

### Use Once

Get the folder in either of these ways:

- **ZIP:** Download the repository ZIP from GitHub and use **Extract All**. Open the extracted `STARTER` folder in File Explorer, right-click empty space, and choose **Open in Terminal**.
- **Git:** Clone the repository, then enter its folder:

```powershell
git clone https://github.com/makssolomon2-hash/front-end-starters.git
cd front-end-starters
```

Confirm that PowerShell is in the folder containing `starters.ps1`:

```powershell
Get-Location
Test-Path .\starters.ps1
```

The last command must return `True`. Then load the functions into the current PowerShell session:

```powershell
. .\starters.ps1
```

The leading `.` is important: it dot-sources the script, making the starter commands available in the current terminal. See **Installation Recovery** when Windows blocks a downloaded script or your shell blocks local scripts.

### Fastest Manual Install: `$PROFILE`

From the repository folder, paste this complete block into PowerShell once. It creates your **Current User, All Hosts** profile when needed and adds the current checkout as a single loader line:

```powershell
$profilePath = $PROFILE.CurrentUserAllHosts
New-Item -ItemType Directory -Path (Split-Path -Parent $profilePath) -Force | Out-Null
New-Item -ItemType File -Path $profilePath -Force | Out-Null
$startersPath = (Resolve-Path .\starters.ps1).Path
$loader = ". `"$startersPath`""
if (-not (Select-String -LiteralPath $profilePath -SimpleMatch $loader -Quiet)) {
  Add-Content -LiteralPath $profilePath -Value $loader
}
```

Close and reopen PowerShell, then verify the command is available:

```powershell
Get-Command slmn-starter
```

`$PROFILE` points to PowerShell profile scripts. This uses the All Hosts profile because it loads in normal PowerShell, Windows Terminal, and VS Code terminals. Keep this repository in a location you will not move; after pulling updates, opening a new terminal loads the updated script automatically.

The profile contains only the loader line, not a copied `starters.ps1`. Keeping the script in the repository makes updates and hotkey installation work normally.

### Managed Install: `~\.slmn`

When you want a self-contained installation that continues to work after you move or remove the checkout, run:

```powershell
. .\starters.ps1
slmn-install
```

`slmn-install` copies the tool to `~\.slmn\starters.ps1`, creates `~\.slmn\config.json`, and replaces any existing SLMN loader with this one clean All Hosts profile line:

```powershell
. "$env:USERPROFILE\.slmn\starters.ps1"
```

To update the managed copy after getting a newer repository version, load that newer `starters.ps1` and run `slmn-update`. Updates affect projects created after the update; a project already generated keeps its own files and does not change automatically. To remove the managed profile loader while retaining `~\.slmn` and its configuration, run `slmn-uninstall`.

### Installation Recovery

If a downloaded ZIP is blocked by Windows, run `Unblock-File .\starters.ps1` before the install command. If your current shell blocks local scripts, use this session-only setting, then load the script again:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
. .\starters.ps1
```

## Configuration

SLMN stores its user configuration in `~\.slmn\config.json`. The default is:

```json
{
  "projectsPath": "%USERPROFILE%\\Desktop",
  "defaultStarter": "slmn-app",
  "openInVSCode": true,
  "autoStartDev": true
}
```

View the active configuration:

```powershell
slmn-config
```

Set the permanent projects directory, or restore Desktop:

```powershell
slmn-config path "D:\Projects"
slmn-config path desktop
```

Every starter also accepts `-Path` as a one-time override. It creates the destination directory when it does not already exist:

```powershell
slmn-app "my-app" -Path "D:\Experiments"
react-project "portfolio" -Path "D:\Clients"
slmn-starter -Path "D:\Scratch"
```

Set `openInVSCode` or `autoStartDev` to `false` in the config file when you prefer to open projects, start previews, or run development servers manually. When enabled, starters open VS Code first, then wait for the local preview and open it in your default browser.

## Global Hotkeys

SLMN hotkeys work anywhere in Windows through an AutoHotkey v2 script. They open a new PowerShell window and load the managed SLMN copy at `~\.slmn\starters.ps1`; they do not depend on the folder currently open in File Explorer or VS Code.

### Install Hotkeys

1. Install the managed SLMN copy. This is required even when you use the manual `$PROFILE` installation, because the hotkey script loads `~\.slmn\starters.ps1`:

```powershell
. .\starters.ps1
slmn-install
```

2. Install [AutoHotkey v2](https://www.autohotkey.com/). Winget is the simplest option:

```powershell
winget install --id AutoHotkey.AutoHotkey --exact --source winget
```

3. Close and reopen PowerShell, then enable the SLMN bindings:

```powershell
slmn-install-hotkeys
```

`slmn-install-hotkeys` copies the AutoHotkey script to `~\.slmn\slmn-hotkeys.ahk`, starts it immediately, and creates `SLMN Hotkeys.lnk` in your Windows Startup folder. The hotkeys therefore return automatically after you sign in.

### Hotkey Reference

| Shortcut | What happens |
| --- | --- |
| `Ctrl + Alt + S` | Opens a new PowerShell window with the interactive `slmn-starter` menu. Use arrow keys and Enter, or type one of the displayed shortcuts, including `RTS`, `RTTS`, `RTGTS`, `3DTS`, `ATS`, and `NTS`. Then enter the project name. |
| `Ctrl + Alt + A` | Opens a new PowerShell window, asks for a project name, then runs the flagship `slmn-app` starter. |

Both shortcuts create projects in the configured `projectsPath`, not the terminal's current folder. Set that destination with `slmn-config path "D:\Projects"` or use `slmn-config path desktop` to restore the Desktop default.

### Verify And Refresh

After installation, press `Ctrl + Alt + S`. A PowerShell window headed `SLMN Starter` confirms that the bindings are active. You can also check that AutoHotkey is running:

```powershell
Get-Process AutoHotkey64, AutoHotkey -ErrorAction SilentlyContinue
```

After pulling a newer version of this repository, refresh the managed SLMN copy before using the hotkeys:

```powershell
. .\starters.ps1
slmn-update
slmn-install-hotkeys
```

The final command restarts the binding with the current `slmn-hotkeys.ahk` file. New hotkey-created projects then use the updated generator; projects created earlier keep the files they already have.

### Hotkey Troubleshooting

**`AutoHotkey v2 was not found`**

Install AutoHotkey v2 with the Winget command above, then close and reopen PowerShell before running `slmn-install-hotkeys`. The SLMN installer detects both `PATH` installs and AutoHotkey's standard `C:\Program Files\AutoHotkey\v2` location.

**A hotkey opens PowerShell, but `slmn-starter` is not recognized**

Run the managed install from the repository folder, then reinstall the hotkeys:

```powershell
. .\starters.ps1
slmn-install
slmn-install-hotkeys
```

**The shortcut creates an older-looking project**

Refresh the installed copy and create a new project with a new name. Starters generate files once; they do not restyle an existing project:

```powershell
. .\starters.ps1
slmn-update
slmn-install-hotkeys
```

**The shortcut does nothing**

Another application may reserve the key combination, or the AutoHotkey process may have stopped. First reinstall the bindings:

```powershell
slmn-uninstall-hotkeys
slmn-install-hotkeys
```

If you are using an elevated application, Windows may block a non-elevated AutoHotkey process from receiving its input. Test the shortcut from a normal desktop application or terminal.

### Remove Hotkeys

To stop the currently running AutoHotkey process, delete the Startup shortcut, and remove the installed hotkey script:

```powershell
slmn-uninstall-hotkeys
```

## Create A Project

After loading `starters.ps1`, run one command:

```powershell
slmn-starter
vanilla-project "my-site"
tailwind-project "tailwind-demo"
gsap-project "gsap-hero"
tailwind-gsap-project "animated-site"
react-project "portfolio"
react-ts-project "typed-portfolio"
react-tailwind-project "tailwind-app"
react-tailwind-ts-project "typed-tailwind-app"
react-tailwind-gsap-project "motion-app"
react-tailwind-gsap-ts-project "typed-motion-app"
react-tailwind-gsap-three-project "three-app"
react-tailwind-gsap-three-ts-project "typed-three-app"
slmn-app "my-app"
slmn-ts-app "my-ts-app"
vite-app "my-app"
next-app "my-next-app"
next-ts-app "my-next-ts-app"
```

`slmn-starter` presents grouped JavaScript and TypeScript options in an animated terminal menu with colored tool badges: JavaScript yellow, TypeScript cyan/blue, React blue, Next.js white, Tailwind cyan, and GSAP green. A rotating spinner appears while the preview becomes ready. Use the Up and Down arrow keys and Enter, or type the displayed shortcut; Esc cancels. Choosing `SLMN App` or its TypeScript counterpart creates the full project without further setup questions. Their project names are converted to lowercase npm-safe folder names, so `APPP` becomes `appp`. Choosing Vite opens its normal framework and variant selector next.

Projects are created at the configured `projectsPath` (Desktop by default), or at a command's temporary `-Path` override. Starters open the finished project in VS Code, start their preview, wait for localhost to respond, and then open the app in your default browser. Framework dev servers keep running in the PowerShell session; `autoStartDev` controls both automatic server startup and browser preview.

Vanilla HTML and GSAP starters are served from a temporary localhost server using Node's built-in HTTP module; this adds no packages or files to the generated project. If Node.js is unavailable, the static page opens directly from disk. The GSAP starter loads GSAP from a CDN, so its first animation requires an internet connection.

`vite-app`, `next-app`, and `next-ts-app` use the configured projects folder and start Vite's or Next.js's normal interactive command. `next-ts-app` explicitly selects the official TypeScript option. Once the official CLI finishes, `vite-app` asks whether to add Tailwind CSS, GSAP, and Three.js; it configures Tailwind when selected. Create Next App already asks about Tailwind during its own setup, so the Next commands only ask whether to add GSAP and Three.js afterward. Each command installs only the features you select, opens the finished project in VS Code, waits until the server responds, and opens the preview in a browser unless `autoStartDev` is disabled. Git behavior follows the official CLI you choose.

Feature questions use uppercase `[Y/N]` prompts. Press `Y` or `N` once; no Enter key is needed.

For `vite-app`, choose the framework and variant in Vite's normal prompts. The launcher uses Vite's `--no-immediate` option, then installs your selected features and starts the server after setup. For `next-app` and `next-ts-app`, answer Create Next App's normal prompts; its package installation completes before the two feature questions appear.

`slmn-app` is the JavaScript flagship and `slmn-ts-app` is its TypeScript counterpart. Both convert the entered project name to a lowercase npm-safe folder name, create the corresponding official Vite React template without framework, variant, package-name, or Create Vite installation questions, and install Tailwind CSS, GSAP, Three.js, and React Icons. The TypeScript version also installs `@types/three`. Each replaces Vite's default React page with a dark full-screen SLMN demo: linked technology cards on the left and a mouse-controlled WebGL model on the right. They then open VS Code, wait for the development server, and open the ready app in a browser when `autoStartDev` is enabled. `full-app` remains an alias for `slmn-app`.

## Share With Others

Share the whole `front-end-starters` folder, including `starters.ps1`, `slmn-hotkeys.ahk`, and `README.md`. The recipient can place it anywhere, open PowerShell in that folder, and follow the **Install** section above.

For GitHub, create a repository, commit these two files, and share the repository URL. A recipient can then run:

```powershell
git clone https://github.com/makssolomon2-hash/front-end-starters.git
cd front-end-starters
. .\starters.ps1
```

They need Node.js, npm, and optionally the VS Code `code` command installed as described in **Requirements**.

## Start Screens and Removal

Every compatible screen uses the same charcoal full-screen composition: project copy and technology links alongside a blue `S` signal display. The display follows pointer movement with native browser events; it is not a Three.js scene. GSAP-enabled starters use GSAP for the entrance reveal, while the rest use CSS-only motion. The flagship and full Three.js starter use their WebGL visual instead.

Each technology card links to its official documentation and is rendered only when that technology belongs to the project.

**Vanilla, GSAP, Tailwind, and Tailwind + GSAP:** the permanent root files are `index.html`, a connected root stylesheet, and a connected root script. The complete optional demo is isolated in `slmn-start`: open `slmn-start/index.html` to view it, or delete that one folder to remove it. Your root entry remains a clean, working starter immediately.

**React, React + Tailwind, and React + Tailwind + GSAP:** replace `src/App.*`, then delete `src/components/Hero.*`, `src/components/TechPill.*`, `src/components/StarterVisual.*`, and `src/styles/demo.css`. `src/styles/app.css` only supplies the root minimum height and can be kept or deleted with the screen.

**`slmn-app` and React + Tailwind + GSAP + Three.js:** replace `src/App.*`, then delete `src/components/Hero.*`, `src/components/TechPill.*`, `src/components/three/ThreeScene.*`, `src/styles/app.css`, and `src/styles/demo.css`. Uninstall `gsap`, `three`, and `react-icons` when those libraries are no longer needed.

**Next.js App Router:** replace `app/page.*` or `src/app/page.*`, then delete `components/SlmnStartScreen.*` or `src/components/SlmnStartScreen.*` and `app/slmn-start.css` or `src/app/slmn-start.css`.

Interactive Vite applies the matching screen to vanilla, React, and React TypeScript templates once setup is complete. Other Vite frameworks keep their official starter page so framework-specific entry code is not overwritten.

## Responsive Screens

Tailwind's initial breakpoint names and values stay available. The starters add these extra screen names; they do not replace Tailwind's defaults:

| Screen | Width | Example |
| --- | --- | --- |
| `tab` | `48rem` / 768px | `tab:text-4xl` |
| `lap` | `64rem` / 1024px | `lap:grid-cols-2` |
| `fhd` | `120rem` / 1920px | `fhd:px-12` |
| `2k` | `160rem` / 2560px | `2k:text-7xl` |
| `4k` | `240rem` / 3840px | `4k:max-w-screen-2xl` |

Vanilla, GSAP, and React generate matching mobile-first CSS media queries at the same widths. Native CSS has no named breakpoint syntax, so the generated stylesheet labels each `@media` block with its corresponding screen name.

## Generated File Shape

The goal is a clean place to begin, not a sample app:

- Non-React root entries are clean, connected project foundations. Their optional charcoal `#171717` full-height SLMN demo is self-contained in the root `slmn-start` directory, with linked technology cards and a pointer-reactive blue `S` visual. Deleting that directory cannot break the root page.
- Vanilla and GSAP root assets are `index.html`, `css/style.css`, and `js/script.js`. Tailwind, Tailwind + GSAP, and compatible interactive Vite vanilla assets are `index.html`, `src/style.css`, and `src/script.js`. Every non-React demo has its own `slmn-start/index.html`, `slmn-start/style.css`, and `slmn-start/main.js`.
- React screens use `src/App.*` as a small composition root and keep the full demo in `src/components/Hero.*`, `src/components/TechPill.*`, `src/components/StarterVisual.*`, and `src/styles/demo.css`.
- GSAP controls the screen entrance only in starters that install it; all other screen motion is native CSS and browser events.
- React + Tailwind + GSAP + Three.js and `slmn-app` use the richer `src/components/three/ThreeScene.*` WebGL visual instead of `StarterVisual`.
- Next.js App Router screens use `app/page.*` or `src/app/page.*`, the matching `components/SlmnStartScreen.*`, and `slmn-start.css` inside the App Router directory.

## Troubleshooting

**`code` is not recognized**

Install VS Code with its `Add to PATH` option enabled, then open a new PowerShell terminal. You can still open the generated project manually from its Desktop folder.

**`npm` is not recognized**

Install the current Node.js LTS release, then restart PowerShell.

**A project folder already exists**

Use another project name or remove the existing folder under your configured projects path before creating it again.

**The starter command is not found**

Load the script again in the current terminal with `. .\starters.ps1`, or run `slmn-install` as described above.
