# SLMN Next Design Preview

This folder contains a persistent Next.js app for previewing the `slmn-next` flagship design without creating a new starter project for every iteration.

## Run the preview

```powershell
Set-Location .\design-preview\next
npm run dev
```

The preview starts at `http://localhost:3000` and automatically tries the next available port (`3001`, `3002`, and so on) if needed.

## Refresh the preview from the starter template

From the repository root, load the starter functions and rewrite the preview's screen files:

```powershell
. .\starters.ps1
Write-SlmnNextProject -Path (Join-Path $PWD 'design-preview\next')
```

The PowerShell generator remains the source for files emitted by `slmn-next`. Keep design changes in `Write-SlmnNextProject` and refresh this preview after changing those template files. The preview has its own dependencies and lockfile; it does not create or modify projects in the configured SLMN projects folder.
