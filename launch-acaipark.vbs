Option Explicit

Dim shell, fso, projectRoot, launcher, exitCode
Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

projectRoot = fso.GetParentFolderName(WScript.ScriptFullName)
launcher = projectRoot & "\deploy\windows-cashier\start-cashier.ps1"

exitCode = shell.Run("powershell.exe -NoProfile -ExecutionPolicy Bypass -File """ & launcher & """ -ProjectRoot """ & projectRoot & """", 0, True)
If exitCode <> 0 Then
  shell.Popup "No se pudo iniciar ACAI PARK Cajero." & vbCrLf & vbCrLf & "Consulta el registro en:" & vbCrLf & projectRoot & "\logs\cashier-launcher.log", 0, "ACAI PARK Cajero", 16
End If
