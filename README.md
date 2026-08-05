<img width="1918" height="1034" alt="image" src="https://github.com/user-attachments/assets/54ddb4e6-c46d-4273-a1e0-d909b771f47a" />

# SLMN Frontend Starters

PowerShell commands for creating clean frontend projects on your Desktop. `slmn-app` is the flagship starter: a complete, removable React technology demo. The other commands are focused alternatives for smaller starting points.

## Quick Start

Open PowerShell in the folder containing `starters.ps1`, then run:

```powershell
. .\starters.ps1
slmn-starter
```

`slmn-starter` opens the menu. Use the Up and Down arrow keys to choose a starter, press Enter, type the project name, and press Enter again.

## What Is Included

| Command | Stack | Initial project |
| --- | --- | --- |
| `slmn-app "my-app"` | Vite, React JavaScript, Tailwind CSS v4, GSAP, Three.js, React Icons | **Flagship:** creates a removable SLMN technology demo with no setup prompts |
| `slmn-starter` | Starter menu | Choose any starter with Up/Down arrows, then enter a project name |
| `vanilla-project "my-site"` | HTML, CSS, JavaScript | A dark page with one centered heading and linked `js/script.js` |
| `tailwind-project "my-site"` | Vite, Tailwind CSS v4 | Dark static HTML with a centered heading and custom Tailwind screens |
| `gsap-project "my-site"` | HTML, CSS, JavaScript, GSAP CDN | One heading with a small entrance animation |
| `tailwind-gsap-project "my-site"` | Vite, Tailwind CSS v4, GSAP | Dark static HTML with one animated heading |
| `react-project "my-site"` | Vite, React | A dark page with a minimal `useState` counter |
| `react-tailwind-gsap-project "my-site"` | Vite, React, Tailwind CSS v4, GSAP | A dark animated React heading and `useState` counter |
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
git clone https://github.com/<your-account>/<your-repository>.git
cd <your-repository>
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

Keep the extracted or cloned folder in a location you will not move or delete. From that folder, run these commands once:

```powershell
New-Item -ItemType Directory -Path (Split-Path $PROFILE) -Force
New-Item -ItemType File -Path $PROFILE -Force
$startersPath = (Resolve-Path .\starters.ps1).Path
Add-Content -LiteralPath $PROFILE -Value ". '$startersPath'"
```

Close and reopen PowerShell, then verify the command is available:

```powershell
Get-Command slmn-starter
```

This saves the actual location of the extracted or cloned script instead of assuming `Desktop\STARTER`. If you later move the folder, run the four persistent-install commands again from its new location. To remove automatic loading later, open the profile with `notepad $PROFILE` and delete the line that starts with `. '`.

## Create A Project

After loading `starters.ps1`, run one command:

```powershell
slmn-starter
vanilla-project "my-site"
tailwind-project "tailwind-demo"
gsap-project "gsap-hero"
tailwind-gsap-project "animated-site"
react-project "portfolio"
react-tailwind-gsap-project "motion-app"
slmn-app "my-app"
vite-app "my-app"
next-app "my-next-app"
```

`slmn-starter` shows every starter, including `slmn-app`, in one menu. Use the Up and Down arrow keys to choose a starter, press Enter, type the project name, and press Enter again. Choosing `SLMN App` creates its React JavaScript project without further setup questions. Its project name is converted to a lowercase npm-safe folder name, so `APPP` becomes `appp`. Choosing Vite opens its normal framework and variant selector next.

Projects are created at `Desktop\<project-name>`. Vite-based starters scaffold, install npm packages, replace the default files, and then open the finished project in VS Code. They use Vite's non-interactive mode, so no development server is started while the project is being created.

For Tailwind, Tailwind + GSAP, React, and React + Tailwind + GSAP, start the development server from the opened project:

```powershell
npm run dev
```

The Vanilla starter can be opened directly in a browser or served with your preferred local server. The GSAP starter loads GSAP from a CDN, so its first animation requires an internet connection.

`vite-app` and `next-app` switch to your Desktop and start Vite's or Next.js's normal interactive command. Once the official CLI finishes, `vite-app` asks whether to add Tailwind CSS, GSAP, and Three.js; it configures Tailwind when selected. Create Next App already asks about Tailwind during its own setup, so `next-app` only asks whether to add GSAP and Three.js afterward. Each command installs only the features you select, opens the finished project in VS Code, and starts `npm run dev` in the current terminal. Git behavior follows the official CLI you choose.

Feature questions use uppercase `[Y/N]` prompts. Press `Y` or `N` once; no Enter key is needed.

For `vite-app`, choose the framework and variant in Vite's normal prompts. The launcher uses Vite's `--no-immediate` option, then installs your selected features and starts the server after setup. For `next-app`, answer Create Next App's normal prompts; its package installation completes before the two feature questions appear.

`slmn-app` is the primary starter. It converts the entered project name to a lowercase npm-safe folder name, then creates a React JavaScript Vite project without framework, variant, package-name, or Create Vite installation questions. It automatically installs Tailwind CSS, GSAP, Three.js, and React Icons, then replaces Vite's default React page with a dark SLMN technology preview: Tailwind controls the responsive layout, GSAP animates the header, and Three.js renders a mouse-controlled WebGL model. It then opens VS Code and starts the development server. `full-app` remains available as an alias.

## Share With Others

Share the whole `STARTER` folder, including `starters.ps1` and `README.md`. The recipient can place it anywhere, open PowerShell in that folder, and follow the **Install** section above.

For GitHub, create a repository, commit these two files, and share the repository URL. A recipient can then run:

```powershell
git clone https://github.com/<your-account>/<your-repository>.git
cd <your-repository>
. .\starters.ps1
```

They need Node.js, npm, and optionally the VS Code `code` command installed as described in **Requirements**.

The preview is split into removable files: `src/App.*` is a small composition root, `src/components/Hero.*` owns the header and GSAP animation, `src/components/TechPill.*` owns the technology links and brand icons, `src/components/three/ThreeScene.*` owns the pointer-controlled model, and `src/styles/demo.css` contains preview-specific styles. Vite, React, JavaScript, Tailwind CSS, GSAP, and Three.js cards link to their official sites or primary documentation in a new browser tab.

To replace the preview with your application:

1. In `src/App.*`, remove the `Hero` and `demo.css` imports.
2. Replace `<Hero />` inside `<main className="app-shell">` with your own components.
3. Delete `src/components/Hero.*`, `src/components/TechPill.*`, `src/components/three`, and `src/styles/demo.css`.
4. Keep `src/styles/app.css`; it provides the permanent application shell.
5. Run `npm uninstall gsap three react-icons` when you do not plan to use those preview-only packages.

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
- Vanilla and GSAP use only an HTML entry point, CSS, and linked JavaScript. Their JavaScript logs `Page loaded` in the browser console.
- Tailwind and Tailwind + GSAP keep their `<main>` and `<h1>` directly in `index.html`; `src/script.js` only loads CSS and, when applicable, runs GSAP.
- React uses only `src/main.jsx`, `src/App.jsx`, and `src/index.css` in addition to Vite and npm files. It starts with a small `useState` count button.
- React + Tailwind + GSAP combines the custom screens, title entrance animation, and the same small React counter.
- The full React demo keeps `App` intentionally small and places the Three.js preview in `src/components/three/ThreeScene.*`; moving the pointer over its canvas rotates the model.
- JavaScript and React entries log `Page loaded` in the browser console.

## Troubleshooting

**`code` is not recognized**

Install VS Code with its `Add to PATH` option enabled, then open a new PowerShell terminal. You can still open the generated project manually from its Desktop folder.

**`npm` is not recognized**

Install the current Node.js LTS release, then restart PowerShell.

**A project folder already exists**

Use another project name or remove the existing Desktop folder before creating it again.

**The starter command is not found**

Load the script again in the current terminal with `. .\starters.ps1`, or add it to your PowerShell profile as described above.
