#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.8.1
 Author:         myName

 Script Function:
	Template AutoIt script.

#ce ----------------------------------------------------------------------------

; Script Start - Add your code below here
#include <File.au3>

Global $export_name = "Phoner_Anruferkennung"

FileRecycle("Output\*.*")
Sleep (200)
FileRecycle ( @ScriptDir & "Output" )

ShellExecute (@ScriptDir & "\Utilities\Wrapper\AutoIt3Wrapper.exe", " /in " & Chr(34) & $export_name & ".au3" & Chr(34) & " /out " & Chr(34) & "Output/" & $export_name & ".exe" & Chr(34))
	While Sleep(300)
		If WinExists("(2.0.3.0) Processing :") Then
			Sleep (300)
		Else
			ExitLoop
		EndIf
	WEnd
	While Sleep(300)
		If WinExists("(2.0.3.0) Processing :") Then
			Sleep (300)
		Else
			ExitLoop
		EndIf
	WEnd