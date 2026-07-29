# Minimal Frontend Starters

PowerShell commands for creating clean frontend projects on your Desktop. The template starters open their completed project in VS Code; the interactive Vite and Next.js commands hand control to their official setup prompts.

## What Is Included

| Command | Stack | Initial project |
| --- | --- | --- |
| `vanilla-project "my-site"` | HTML, CSS, JavaScript | A dark page with one centered heading and linked `js/main.js` |
| `tailwind-project "my-site"` | Vite, Tailwind CSS v4 | Dark static HTML with a centered heading and custom Tailwind screens |
| `gsap-project "my-site"` | HTML, CSS, JavaScript, GSAP CDN | One heading with a small entrance animation |
| `tailwind-gsap-project "my-site"` | Vite, Tailwind CSS v4, GSAP | Dark static HTML with one animated heading |
| `react-project "my-site"` | Vite, React | A dark page with a minimal `useState` counter |
| `react-tailwind-gsap-project "my-site"` | Vite, React, Tailwind CSS v4, GSAP | A dark animated React heading and `useState` counter |
| `vite-app "my-app"` | Vite | Official Vite prompts, then optional Tailwind CSS, GSAP, and Three.js |
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

From this folder, load the functions into the current PowerShell session:

```powershell
. .\starters.ps1
```

The leading `.` is important: it dot-sources the script, making the starter commands available in the current terminal.

If PowerShell blocks local scripts for the current terminal only, run this first:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
. .\starters.ps1
```

To make the commands available in every new PowerShell session, add this line to your PowerShell profile once:

```powershell
. "$HOME\Desktop\STARTER\starters.ps1"
```

Create the profile first when it does not exist:

```powershell
New-Item -ItemType Directory -Path (Split-Path $PROFILE) -Force
New-Item -ItemType File -Path $PROFILE -Force
```

## Create A Project

After loading `starters.ps1`, run one command:

```powershell
vanilla-project "my-site"
tailwind-project "tailwind-demo"
gsap-project "gsap-hero"
tailwind-gsap-project "animated-site"
react-project "portfolio"
react-tailwind-gsap-project "motion-app"
vite-app "my-app"
next-app "my-next-app"
```

Projects are created at `Desktop\<project-name>`. Vite-based starters scaffold, install npm packages, replace the default files, and then open the finished project in VS Code. They use Vite's non-interactive mode, so no development server is started while the project is being created.

For Tailwind, Tailwind + GSAP, React, and React + Tailwind + GSAP, start the development server from the opened project:

```powershell
npm run dev
```

The Vanilla starter can be opened directly in a browser or served with your preferred local server. The GSAP starter loads GSAP from a CDN, so its first animation requires an internet connection.

`vite-app` and `next-app` switch to your Desktop and start Vite's or Next.js's normal interactive command. Once the official CLI finishes, `vite-app` asks whether to add Tailwind CSS, GSAP, and Three.js; it configures Tailwind when selected. Create Next App already asks about Tailwind during its own setup, so `next-app` only asks whether to add GSAP and Three.js afterward. Each command installs only the features you select, opens the finished project in VS Code, and starts `npm run dev` in the current terminal. Git behavior follows the official CLI you choose.

Feature questions use standard prompts: enter `Y` for Yes or `N` for No. Press Enter for No.

For `vite-app`, choose the framework and variant in Vite's normal prompts. The launcher uses Vite's `--no-immediate` option, then installs your selected features and starts the server after setup. For `next-app`, answer Create Next App's normal prompts; its package installation completes before the two feature questions appear.

## Responsive Screens

Tailwind starters replace Tailwind's default screens with these project-specific names:

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
- Tailwind and Tailwind + GSAP keep their `<main>` and `<h1>` directly in `index.html`; `src/main.js` only loads CSS and, when applicable, runs GSAP.
- React uses only `src/main.jsx`, `src/App.jsx`, and `src/index.css` in addition to Vite and npm files. It starts with a small `useState` count button.
- React + Tailwind + GSAP combines the custom screens, title entrance animation, and the same small React counter.
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