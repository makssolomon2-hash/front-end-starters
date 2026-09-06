#Requires AutoHotkey v2.0
#SingleInstance Force

^!s:: {
    Run("powershell.exe -NoExit -Command `". '$env:USERPROFILE\.slmn\starters.ps1'; slmn-starter`"")
}

^!a:: {
    Run("powershell.exe -NoExit -Command `". '$env:USERPROFILE\.slmn\starters.ps1'; slmn-app (Read-Host 'Project name')`"")
}
