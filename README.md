<p align="center">
  <img 
    src="https://github.com/user-attachments/assets/54ddb4e6-c46d-4273-a1e0-d909b771f47a" 
    alt="SLMN React Starter" 
    style="max-width: 100%; height: auto; border-radius: 12px;" 
  />
</p>

# SLMN Frontend Starters

PowerShell commands for creating clean frontend projects on your Desktop. `slmn-app` is the flagship starter: a complete, removable React technology demo. The other commands are focused alternatives for smaller starting points.

## Quick Start

Open PowerShell in the folder containing `starters.ps1`, then run:

```powershell
. .\starters.ps1
slmn-starter
```

`slmn-starter` opens the menu. Use the Up and Down arrow keys and Enter, or type the displayed number/letter shortcut, then enter a project name.

## What Is Included

| Command | Stack | Initial project |
| --- | --- | --- |
| `slmn-app "my-app"` | Vite, React JavaScript, Tailwind CSS v4, GSAP, Three.js, React Icons | **Flagship:** creates a removable SLMN technology demo with no setup prompts |
| `slmn-starter` | Starter menu | Choose a starter with arrows/Enter or a displayed number/letter shortcut |
| `vanilla-project "my-site"` | HTML, CSS, JavaScript | A dark page with one centered heading and linked `js/script.js` |
| `tailwind-project "my-site"` | Vite, Tailwind CSS v4 | Dark static HTML with a centered heading and custom Tailwind screens |
| `gsap-project "my-site"` | HTML, CSS, JavaScript, GSAP CDN | One heading with a small entrance animation |
| `tailwind-gsap-project "my-site"` | Vite, Tailwind CSS v4, GSAP | Dark static HTML with one animated heading |
| `react-project "my-site"` | Vite, React | Removable React technology preview linking to Vite, React, and JavaScript |
| `react-tailwind-project "my-site"` | Vite, React, Tailwind CSS v4 | Removable React preview linking to Vite, React, JavaScript, and Tailwind CSS |
| `react-tailwind-gsap-project "my-site"` | Vite, React, Tailwind CSS v4, GSAP | Removable React preview with GSAP entrance motion and stack-specific links |
| `react-tailwind-gsap-three-project "my-site"` | Vite, React, Tailwind CSS v4, GSAP, Three.js, React Icons | Full removable React technology demo with the interactive Three.js model (available as a direct command) |
| `vite-app "my-app"` | Vite | Official Vite prompts, then optional Tailwind CSS, GSAP, and Three.js |
| `full-app "my-demo"` | Alias for `slmn-app` | Backwards-compatible name for the flagship starter |
| `next-app "my-next-app"` | Next.js | Official Create Next App prompts, then optional GSAP and Three.js |

Vite-generated projects are cleaned before VS Code opens. They do not keep the default counter, starter icons, `public` folder, `src/assets`, generated README, or the default React lint setup.

## Requirements

- Windows with PowerShell
- Node.js LTS and npm for the Vite-based starters
- VS Code with the `code` command available in `PATH`

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

The leading `.` is important: it dot-sources the script, making the starter commands available in the current terminal. A ZIP downloaded from the internet can be blocked by Windows; unblock it first when needed:

```powershell
Unblock-File .\starters.ps1
```

If PowerShell blocks local scripts for the current terminal only, run this first:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
. .\starters.ps1
```

### Install For Every New Terminal

From the folder containing `starters.ps1`, load the script once, then install it:

```powershell
. .\starters.ps1
slmn-install
```

`slmn-install` copies the tool to `~\.slmn\starters.ps1`, creates `~\.slmn\config.json`, creates the **Current User, All Hosts** PowerShell profile when needed, and keeps one clean load line in that profile:

```powershell
. "$env:USERPROFILE\.slmn\starters.ps1"
```

The All Hosts profile is preferred over the host-specific `$PROFILE` because it loads in normal PowerShell, Windows Terminal, and VS Code terminals. Close and reopen PowerShell, then verify it:

```powershell
Get-Command slmn-starter
```

To update after pulling or downloading a newer copy, load that newer `starters.ps1` and run `slmn-update`. To stop automatic loading while keeping your configuration and installed files, run `slmn-uninstall`.

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

Set `openInVSCode` or `autoStartDev` to `false` in the config file when you prefer to open projects or start development servers manually.

## Global Hotkeys

Install [AutoHotkey v2](https://www.autohotkey.com/) and ensure `AutoHotkey.exe` is available in `PATH`, then run:

```powershell
slmn-install-hotkeys
```

This installs `~\.slmn\slmn-hotkeys.ahk`, starts it immediately, and adds it to your Windows Startup folder. `Ctrl + Alt + S` opens `slmn-starter`; `Ctrl + Alt + A` prompts for a project name and creates the flagship `slmn-app`. Remove the startup registration and script with `slmn-uninstall-hotkeys`.

## Create A Project

After loading `starters.ps1`, run one command:

```powershell
slmn-starter
vanilla-project "my-site"
tailwind-project "tailwind-demo"
gsap-project "gsap-hero"
tailwind-gsap-project "animated-site"
react-project "portfolio"
react-tailwind-project "tailwind-app"
react-tailwind-gsap-project "motion-app"
react-tailwind-gsap-three-project "three-app"
slmn-app "my-app"
vite-app "my-app"
next-app "my-next-app"
```

`slmn-starter` shows the primary starters in one menu. Use the Up and Down arrow keys and Enter, or type a shortcut: `1`/`v`, `2`/`t`, `3`/`g`, `4`/`tg`, `5`/`r`, `6`/`rt`, `7`/`rtg`, `8`/`a`, `9`/`vite`, or `0`/`next`. Choosing `SLMN App` creates its React JavaScript project without further setup questions. Its project name is converted to a lowercase npm-safe folder name, so `APPP` becomes `appp`. Choosing Vite opens its normal framework and variant selector next.

Projects are created at the configured `projectsPath` (Desktop by default), or at a command's temporary `-Path` override. Vite-based starters scaffold, install npm packages, replace the default files, and then open the finished project in VS Code. Every React starter starts `npm run dev` automatically after the project is ready unless `autoStartDev` is disabled.

The Vanilla starter can be opened directly in a browser or served with your preferred local server. The GSAP starter loads GSAP from a CDN, so its first animation requires an internet connection.

`vite-app` and `next-app` switch to your Desktop and start Vite's or Next.js's normal interactive command. Once the official CLI finishes, `vite-app` asks whether to add Tailwind CSS, GSAP, and Three.js; it configures Tailwind when selected. Create Next App already asks about Tailwind during its own setup, so `next-app` only asks whether to add GSAP and Three.js afterward. Each command installs only the features you select, opens the finished project in VS Code, and starts `npm run dev` in the current terminal. Git behavior follows the official CLI you choose.

Feature questions use uppercase `[Y/N]` prompts. Press `Y` or `N` once; no Enter key is needed.

For `vite-app`, choose the framework and variant in Vite's normal prompts. The launcher uses Vite's `--no-immediate` option, then installs your selected features and starts the server after setup. For `next-app`, answer Create Next App's normal prompts; its package installation completes before the two feature questions appear.

`slmn-app` is the primary starter. It converts the entered project name to a lowercase npm-safe folder name, then creates a React JavaScript Vite project without framework, variant, package-name, or Create Vite installation questions. It automatically installs Tailwind CSS, GSAP, Three.js, and React Icons, then replaces Vite's default React page with a dark SLMN technology preview: Tailwind controls the responsive layout, GSAP animates the header, and Three.js renders a mouse-controlled WebGL model. It then opens VS Code and starts the development server. `full-app` remains available as an alias.

## Share With Others

Share the whole `STARTER` folder, including `starters.ps1` and `README.md`. The recipient can place it anywhere, open PowerShell in that folder, and follow the **Install** section above.

For GitHub, create a repository, commit these two files, and share the repository URL. A recipient can then run:

```powershell
git clone https://github.com/makssolomon2-hash/front-end-starters.git
cd front-end-starters
. .\starters.ps1
```

They need Node.js, npm, and optionally the VS Code `code` command installed as described in **Requirements**.

Every starter opens on the same charcoal SLMN start screen with pills for only the tools included in that starter. Vanilla and GSAP screens are self-contained in `index.html`, `css/style.css`, and `js/script.js`; Tailwind and Tailwind + GSAP screens use `index.html`, `src/style.css`, and `src/script.js`. Delete or replace those files to remove the static screen. Interactive Vite React and vanilla templates receive these same file layouts after their dependency choices are complete. React previews are split into removable files: `src/App.*` is a small composition root, `src/components/Hero.*` owns the header and optional GSAP animation, `src/components/TechPill.*` owns the stack-specific technology links, and `src/styles/demo.css` contains preview-specific styles. The React + Tailwind + GSAP + Three.js starter and `slmn-app` additionally include `src/components/three/ThreeScene.*`. Cards link only to tools installed by that starter and open their official sites or primary documentation in a new browser tab.

The App Router version of the Next.js starter keeps its removable screen in `app/page.*` (or `src/app/page.*`), `components/SlmnStartScreen.*` (or `src/components/SlmnStartScreen.*`), and `app/slmn-start.module.css` (or `src/app/slmn-start.module.css`). Delete or replace those three files to remove it. Vite templates using a different framework remain on that framework's official initial screen so the starter does not overwrite its framework-specific entry code.

To replace the preview with your application:

1. In `src/App.*`, remove the `Hero` and `demo.css` imports.
2. Replace `<Hero />` inside `<main className="app-shell">` with your own components.
3. Delete `src/components/Hero.jsx`, `src/components/TechPill.jsx`, and `src/styles/demo.css`. Delete `src/components/three` for the Three.js starter as well.
4. Keep `src/styles/app.css`; it provides the permanent application shell.
5. Run `npm uninstall gsap`, `npm uninstall three react-icons`, or both when you do not plan to use those preview-only packages.

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

- Every starter begins with a modern charcoal `#171717` background and white text. There is no light/dark toggle.
- Vanilla and GSAP use only an HTML entry point, CSS, and linked JavaScript. Their start screens live in `index.html`, `css/style.css`, and `js/script.js`.
- Tailwind and Tailwind + GSAP keep their start screens in `index.html`, `src/style.css`, and `src/script.js`; GSAP animates only the GSAP-enabled variant.
- Every React starter uses a small `App.jsx` composition root and places its removable preview in `src/components/Hero.jsx`, `src/components/TechPill.jsx`, and `src/styles/demo.css`. Each preview lists links only for tools installed by that starter.
- React + Tailwind + GSAP + Three.js uses the richer `ThreeScene` component from the flagship demo.
- The full React demo keeps `App` intentionally small and places the Three.js preview in `src/components/three/ThreeScene.*`; moving the pointer over its canvas rotates the model.
- JavaScript and React entries log `Page loaded` in the browser console.

## Troubleshooting

**`code` is not recognized**

Install VS Code with its `Add to PATH` option enabled, then open a new PowerShell terminal. You can still open the generated project manually from its Desktop folder.

**`npm` is not recognized**

Install the current Node.js LTS release, then restart PowerShell.

**A project folder already exists**

Use another project name or remove the existing folder under your configured projects path before creating it again.

**The starter command is not found**

Load the script again in the current terminal with `. .\starters.ps1`, or run `slmn-install` as described above.
