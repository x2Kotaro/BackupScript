' Launches the Dex_Mcp watchdog loop with no console window.
' Put a shortcut to THIS file in shell:startup so the bridge survives reboots.
Set fso = CreateObject("Scripting.FileSystemObject")
Set sh = CreateObject("WScript.Shell")
here = fso.GetParentFolderName(WScript.ScriptFullName)
sh.CurrentDirectory = here
sh.Run """" & here & "\daemon-loop.cmd""", 0, False
