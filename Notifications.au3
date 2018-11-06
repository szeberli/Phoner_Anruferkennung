#include-once

#include <GUIConstants.au3>
#include <Process.au3>

; #INDEX# =======================================================================================================================
; Title .........: Notifications
; Version .......: 1.2
; AutoIt Version : 3.3.14.2
; Language ......: English
; Description ...: UDF for usage of desktop notifications.
; Author(s) .....: S3cret (S3cret91)
; Dll ...........: ntdll.dll
; ===============================================================================================================================

; #VARIABLES# ===================================================================================================================
Global $__notificationStartup = False
Global $__notificationOnEvent = False
Global $__desktopHeight = 0
Global Const $__notificationWidth = 300
Global Const $__notificationHeight = 165
Global Const $__notificationLeft = @DesktopWidth - $__notificationWidth - 10


Global $__notificationList[0][9]
;      $__notificationList[i][0] = notification window handle
;      $__notificationList[i][1] = notification window state (True: notification visible, False: invisible)
;      $__notificationList[i][2] = notification window x coord
;      $__notificationList[i][3] = notification window y coord
;      $__notificationList[i][4] = notification button handle
;      $__notificationList[i][5] = notification closing button handle
;      $__notificationList[i][6] = notification call function
;      $__notificationList[i][7] = notification close on click
;      $__notificationList[i][8] = notification transparency


Global Const $__notificationAnimationTimeDefault = 150
Global Const $__notificationBkColorDefault = Default
Global Const $__notificationBorderDefault = False
Global Const $__notificationColorDefault = 0xFFFFFF
Global Const $__notificationDateFormatDefault = "DD.MM."
Global Const $__notificationClosingButtonTextDefault = "Close"
Global Const $__notificationSoundDefault = @WindowsDir & "\Media\Windows Background.wav"
Global Const $__notificationTextAlignDefault = $SS_CENTER
Global Const $__notificationTimeFormatDefault = "HH:MM"
Global Const $__notificationTransparencyDefault = Default

Global $__notificationAnimationTime = $__notificationAnimationTimeDefault
Global $__notificationBkColor = $__notificationBkColorDefault
Global $__notificationBorder = $__notificationBorderDefault
Global $__notificationClosingButtonText = $__notificationClosingButtonTextDefault
Global $__notificationDateFormat = $__notificationDateFormatDefault
Global $__notificationSound = $__notificationSoundDefault
Global $__notificationTextAlign = $__notificationTextAlignDefault
Global $__notificationColor = $__notificationColorDefault
Global $__notificationTimeFormat = $__notificationTimeFormatDefault
Global $__notificationTransparency = $__notificationTransparencyDefault

Global $__ntDLL
Global Const $__dllTimeStruct = DllStructCreate("int64 time;")
Global Const $__dllTimeStructPointer = DllStructGetPtr($__dllTimeStruct)
; ===============================================================================================================================

; #CURRENT# =====================================================================================================================
; _Notifications_CheckGUIMsg
; _Notifications_CloseAll
; _Notifications_Create
; _Notifications_SetAnimationTime
; _Notifications_SetBorder
; _Notifications_SetButtonText
; _Notifications_SetBkColor
; _Notifications_SetColor
; _Notifications_SetDateFormat
; _Notifications_SetSound
; _Notifications_SetTextAlign
; _Notifications_SetTimeFormat
; _Notifications_SetTransparency
; _Notifications_Shutdown
; _Notifications_Startup
; ===============================================================================================================================

; #INTERNAL_USE_ONLY# ===========================================================================================================
; _Notifications_Close
; _Notifications_CloseOnEvent
; _Notifications_GetTaskbarColor
; _Notifications_GetTaskbarTransparency
; _Notifications_GetTopPos
; _Notifications_Move
; _Notifications_StartupIsComplete
; ===============================================================================================================================



; FUNCTION ======================================================================================================================
; Name ..........: _Notifications_CheckGUIMsg
; Description ...: Checks if one button in one of the notification windows was clicked to close the notification
; Syntax ........: _Notifications_CheckGUIMsg ( $__GUIMsg )
; Parameters ....: $__GUIMsg     - Return value of the GUIGetMsg function
; Return values .: none
; Author ........: S3cret (S3cret91)
; Modified ......:
; Remarks .......: Do not use this function when GUIOnEventMode is activated.
; ===============================================================================================================================
Func _Notifications_CheckGUIMsg($__GUIMsg)

	If _Notifications_StartupIsComplete() = False Then Return

	Local $__notificationCount = UBound($__notificationList)
	Local $__deleteNotification = False
	Local $__callFunction = ""

	;check all notifications buttons for the gui message...
	For $__i = 0 To $__notificationCount - 1

		;until invisible notifications are reached. Stop here so save execution time
		If $__notificationList[$__i][1] = False Then ExitLoop


		;notification was clicked
		If $__GUIMsg = $__notificationList[$__i][4] Then

			If $__notificationList[$__i][6] <> "" Then $__callFunction = $__notificationList[$__i][6]

			If $__notificationList[$__i][7] = True Then $__deleteNotification = True

			ExitLoop


			;close button on notification was clicked
		ElseIf $__GUIMsg = $__notificationList[$__i][5] Then

			$__deleteNotification = True
			ExitLoop

		EndIf

	Next

	If $__deleteNotification = True Then _Notifications_Close($__i)

	If $__callFunction <> "" Then Call($__callFunction)

EndFunc   ;==>_Notifications_CheckGUIMsg


; FUNCTION ======================================================================================================================
; Name ..........: _Notifications_CloseAll
; Description ...: Closes all open notifications
; Syntax ........: _Notifications_CloseAll ()
; Return values .: none
; Author ........: S3cret (S3cret91)
; Modified ......:
; ===============================================================================================================================
Func _Notifications_CloseAll()

	If _Notifications_StartupIsComplete() = False Then Return

	For $__i = 0 To UBound($__notificationList) - 1

		GUIDelete($__notificationList[$__i][0])

	Next

	ReDim $__notificationList[0][UBound($__notificationList, 2)]

EndFunc   ;==>_Notifications_CloseAll


; FUNCTION ======================================================================================================================
; Name ..........: _Notifications_Create
; Description ...: Creates a notification with a given title and message
; Syntax ........: _Notifications_Create ( $__title, $__body )
; Parameters ....: $__title                - Title of the notification
;                  $__body                 - Message of the notification. Can be two lines seperated by @CRLF-Flag
;                  $__callFunction         - Function to call when the title or message part of the notification was clicked
;                  $__closeOnClick         - True:  close the notification when the title or message part was clicked
;                                            False: do not close the notification
; Return values .: none
; Author ........: S3cret (S3cret91)
; Modified ......:
; Remarks .......: $__closeOnClick only closes the notification when a callFunction was set
; ===============================================================================================================================
Func _Notifications_Create($__title, $__message, $__callFunction = "", $__closeOnClick = True)

	If _Notifications_StartupIsComplete() = False Then Return



	;Local $__bkColor = $__notificationBkColor
	;If $__bkColor = Default Then $__bkColor = _Notifications_GetTaskbarColor()
	Local $__bkColor = $__notificationBkColor = Default ? _Notifications_GetTaskbarColor() : $__notificationBkColor

	;Local $__transparency = $__notificationTransparency
	;If $__transparency = Default Then $__transparency = _Notifications_GetTaskbarTransparency()
	Local $__transparency = $__notificationTransparency = Default ? _Notifications_GetTaskbarTransparency() : $__notificationTransparency



	;date & time
	Local $__date, $__time
	$__date = StringReplace($__notificationDateFormat, "DD", @MDAY)
	$__date = StringReplace($__date, "MM", @MON)
	$__date = StringReplace($__date, "YYYY", @YEAR)
	$__time = StringReplace($__notificationTimeFormat, "HH", @HOUR)
	$__time = StringReplace($__time, "MM", @MIN)
	$__time = StringReplace($__time, "SS", @SEC)


	;add an entry to the notification array
	Local $__notificationCount = UBound($__notificationList)
	ReDim $__notificationList[$__notificationCount + 1][UBound($__notificationList, 2)]

	;new notifications top position
	Local $__notificationWindowTopPos = _Notifications_GetTopPos()

	$__notificationList[$__notificationCount][1] = False
	$__notificationList[$__notificationCount][2] = $__notificationLeft
	$__notificationList[$__notificationCount][3] = $__notificationWindowTopPos
	$__notificationList[$__notificationCount][6] = $__callFunction

	If $__callFunction = "" Then $__closeOnClick = False
	$__notificationList[$__notificationCount][7] = $__closeOnClick

	$__notificationList[$__notificationCount][8] = $__transparency


	Local $__closingButtonTop = 125

	;create the GUI and set transparency
	$__notificationList[$__notificationCount][0] = GUICreate($__title, $__notificationWidth, $__notificationHeight, _
			$__notificationLeft, $__notificationWindowTopPos, $WS_POPUP, BitOR($WS_EX_TOOLWINDOW, $WS_EX_TOPMOST))

	GUISetBkColor($__bkColor, $__notificationList[$__notificationCount][0])
	WinSetTrans($__notificationList[$__notificationCount][0], "", $__transparency)


	If $__notificationBorder = True Then ; border created by colored labels with 1 pixel height or width
		GUICtrlCreateLabel("", 0, 0, 1, $__notificationHeight) ;left border
		GUICtrlSetBkColor(-1, $__notificationColor)
		GUICtrlCreateLabel("", 0, 0, $__notificationWidth, 1) ;top border
		GUICtrlSetBkColor(-1, $__notificationColor)
		GUICtrlCreateLabel("", $__notificationWidth - 1, 0, 1, $__notificationHeight) ;right border
		GUICtrlSetBkColor(-1, $__notificationColor)
		GUICtrlCreateLabel("", 0, $__notificationHeight - 1, $__notificationWidth, 1) ;bottom border
		GUICtrlSetBkColor(-1, $__notificationColor)
	EndIf


	;clickable label for the function to call when notification is clicked
	$__notificationList[$__notificationCount][4] = GUICtrlCreateLabel("", 0, 0, $__notificationWidth, $__closingButtonTop - 2)
	GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)

	;title label
	GUICtrlCreateLabel($__title, 10, 10, $__notificationWidth - 20, 30, $__notificationTextAlign)
	GUICtrlSetColor(-1, $__notificationColor)
	GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
	GUICtrlSetFont(-1, 13, 500)

	;message label
	GUICtrlCreateLabel($__message, 10, 30, $__notificationWidth - 20, 65, $__notificationTextAlign)
	GUICtrlSetColor(-1, $__notificationColor)
	GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
	GUICtrlSetFont(-1, 11, 400)


	;creating a line to seperate the message of the notification from the closing button
	If $__notificationBorder = True Then
		GUICtrlCreateLabel("", 10, $__closingButtonTop, $__notificationWidth - 50, 1)
	Else
		GUICtrlCreateLabel("", 0, $__closingButtonTop, $__notificationWidth, 1)
	EndIf
	GUICtrlSetBkColor(-1, $__notificationColor)


	;bottom of the notification (closing button, date and time label)
	$__notificationList[$__notificationCount][5] = GUICtrlCreateLabel($__notificationClosingButtonText, 0, $__closingButtonTop, _
			$__notificationWidth, $__notificationHeight - $__closingButtonTop, BitOR($SS_CENTER, $SS_CENTERIMAGE))
	GUICtrlSetColor(-1, $__notificationColor)
	GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
	GUICtrlSetFont(-1, 11, 600)


	;date label
	GUICtrlCreateLabel($__date, 10, $__closingButtonTop, $__notificationWidth - 20, _
			$__notificationHeight - $__closingButtonTop, $SS_CENTERIMAGE)

	GUICtrlSetColor(-1, $__notificationColor)
	GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
	GUICtrlSetFont(-1, 11, 400)


	;time label
	GUICtrlCreateLabel($__time, 10, $__closingButtonTop, $__notificationWidth - 20, _
			$__notificationHeight - $__closingButtonTop, BitOR($SS_RIGHT, $SS_CENTERIMAGE))

	GUICtrlSetColor(-1, $__notificationColor)
	GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
	GUICtrlSetFont(-1, 11, 400)


	;if notification is in desktop area, show it
	If $__notificationWindowTopPos >= 0 Then

		GUISetState(@SW_SHOWNA, $__notificationList[$__notificationCount][0])
		$__notificationList[$__notificationCount][1] = True

	EndIf


	If $__notificationSound <> "" Then SoundPlay($__notificationSound)


	;if GUIOnEventMode is activated, set the function to be called when button is clicked
	If $__notificationOnEvent Then

		;Yes, it is right that the closing function for OnEvent is called for the usual notification click, because all the
		;function does it to get the clicked control ID and pass it to another function which checks which control was clicked
		If $__callFunction <> "" Then _
				GUICtrlSetOnEvent($__notificationList[$__notificationCount][4], "_Notifications_CloseOnEvent")

		;closing button
		GUICtrlSetOnEvent($__notificationList[$__notificationCount][5], "_Notifications_CloseOnEvent")

	EndIf


EndFunc   ;==>_Notifications_Create


; FUNCTION ======================================================================================================================
; Name ..........: _Notifications_SetAnimationTime
; Description ...: Sets the time for the animation, in which notifications are moved when another one was closed, in ms
; Syntax ........: _Notifications_SetAnimationTime ( $__animationTime )
; Parameters ....: $__animationTime        - Time in ms for the animation to take (Value can go from 0 = instant to 2000)
; Return values .: Success                 - True
;                  Failure (no valid time) - False
; Author ........: S3cret (S3cret91)
; Modified ......:
; Remarks .......: Despite other Set-Functions, this one doesn't only affect new notifications, but also existing ones.
;                  Please also note that when setting a very low animation time it can be that the computation time for the
;                  process can be larger than the animation time you set. In this case the Animation time will be the computation
;                  time.
; ===============================================================================================================================
Func _Notifications_SetAnimationTime($__animationTime)

	If $__animationTime = Default Then

		$__notificationAnimationTime = $__notificationAnimationTimeDefault
		Return True

	EndIf

	If StringRegExp($__animationTime, "^\d{1,4}$") = 0 Then Return False
	If $__animationTime > 2000 Then Return False

	$__notificationAnimationTime = $__animationTime
	Return True

EndFunc   ;==>_Notifications_SetAnimationTime


; FUNCTION ======================================================================================================================
; Name ..........: _Notifications_SetBorder
; Description ...: Sets if there is a border around new notifications
; Syntax ........: _Notifications_SetBorder ( $__showBorder )
; Parameters ....: $__showBorder        - True:  show border around notification
;                                         False: show no border
; Return values .: Success              - True
;                  Failure (no boolean) - False
; Author ........: S3cret (S3cret91)
; Modified ......:
; ===============================================================================================================================
Func _Notifications_SetBorder($__showBorder)

	If $__showBorder = Default Then

		$__notificationBorder = $__notificationBorderDefault
		Return True

	EndIf

	If IsBool($__showBorder) = 0 Then Return False

	$__notificationBorder = $__showBorder
	Return True

EndFunc   ;==>_Notifications_SetBorder


; FUNCTION ======================================================================================================================
; Name ..........: _Notifications_SetButtonText
; Description ...: Sets the text for the notifications closing button
; Syntax ........: _Notifications_SetButtonText ( $__buttonText )
; Parameters ....: $__buttonText        - Text for the notifications closing button
; Return values .: True
; Author ........: S3cret (S3cret91)
; Modified ......:
; ===============================================================================================================================
Func _Notifications_SetButtonText($__buttonText)

	If $__buttonText = Default Then

		$__notificationClosingButtonText = $__notificationClosingButtonTextDefault
		Return True

	EndIf

	$__notificationClosingButtonText = $__buttonText
	Return True

EndFunc   ;==>_Notifications_SetButtonText


; FUNCTION ======================================================================================================================
; Name ..........: _Notifications_SetBkColor
; Description ...: Sets the background color of new notifications
; Syntax ........: _Notifications_SetBkColor ( $__bkcolor )
; Parameters ....: $__bkcolor        - Color for the background
; Return values .: True
; Author ........: S3cret (S3cret91)
; Modified ......:
; ===============================================================================================================================
Func _Notifications_SetBkColor($__bkColor)

	If $__bkColor = Default Then

		$__notificationBkColor = $__notificationBkColorDefault
		Return True

	EndIf

	$__notificationBkColor = $__bkColor
	Return True

EndFunc   ;==>_Notifications_SetBkColor


; FUNCTION ======================================================================================================================
; Name ..........: _Notifications_SetColor
; Description ...: Sets the textcolor of new notifications
; Syntax ........: _Notifications_SetColor ( $__textColor )
; Parameters ....: $__textColor      - Color of the text
; Return values .: True
; Author ........: S3cret (S3cret91)
; Modified ......:
; ===============================================================================================================================
Func _Notifications_SetColor($__textColor)

	If $__textColor = Default Then

		$__notificationColor = $__notificationColorDefault
		Return True

	EndIf

	$__notificationColor = $__textColor
	Return True

EndFunc   ;==>_Notifications_SetColor


; FUNCTION ======================================================================================================================
; Name ..........: _Notifications_SetDateFormat
; Description ...: Sets the date format of new notifications
; Syntax ........: _Notifications_SetDateFormat ( $__dateFormat )
; Parameters ....: $__dateFormat        - Format of how to show the date. It is possible to show the year (YYYY), month (MM) and
;                                         day (DD).  A dateformat can look like this: DD.MM.YYYY
; Return values .: True
; Author ........: S3cret (S3cret91)
; Modified ......:
; Remarks .......: Give an empty string to show no date
; ===============================================================================================================================
Func _Notifications_SetDateFormat($__dateFormat)

	If $__dateFormat = Default Then

		$__notificationDateFormat = $__notificationDateFormatDefault
		Return True

	EndIf

	$__notificationDateFormat = $__dateFormat
	Return True

EndFunc   ;==>_Notifications_SetDateFormat


;set notification sound; "" = no sound; only mp3 or wav
; FUNCTION ======================================================================================================================
; Name ..........: _Notifications_SetSound
; Description ...: Sets the sound of new notifications
; Syntax ........: _Notifications_SetSound ( $__sound )
; Parameters ....: $__sound        - Name of the sound to be played for new notifications (mp3 or wav)
;                                    Give empty string for no sound
; Return values .: Success                                       - True
;                  Failure (wrong filetype, file does not exist) - False
; Author ........: S3cret (S3cret91)
; Modified ......:
; Remarks .......: Give an empty string to show no date
; ===============================================================================================================================
Func _Notifications_SetSound($__sound)

	If $__sound = Default Then

		$__notificationSound = $__notificationSoundDefault
		Return True

	EndIf

	If $__sound = "" Then

		$__notificationSound = ""
		Return True

	EndIf

	If Not FileExists($__sound) Then Return False

	If StringRegExp($__sound, "\.(wav|mp3)$") = 0 Then Return False

	$__notificationSound = $__sound
	Return True

EndFunc   ;==>_Notifications_SetSound


; FUNCTION ======================================================================================================================
; Name ..........: _Notifications_SetTextAlign
; Description ...: Sets the alignment of the text of new notifications
; Syntax ........: _Notifications_SetTextAlign ( $__textAlign )
; Parameters ....: $__textAlign                 - 'center' to display text in center
;                                                 'left'   to display text in center
;                                                 'right'  to display text in center
; Return values .: Success                      - True
;                  Failure (wrong $__textAlign) - False
; Author ........: S3cret (S3cret91)
; Modified ......:
; ===============================================================================================================================
Func _Notifications_SetTextAlign($__textAlign)

	If IsBool($__textAlign) Then Return False

	If $__textAlign = Default Then
		$__notificationTextAlign = $__notificationTextAlignDefault
		Return True

	EndIf


	Switch $__textAlign
		Case "left"
			$__notificationTextAlign = $SS_LEFT
		Case "center"
			$__notificationTextAlign = $SS_CENTER
		Case "right"
			$__notificationTextAlign = $SS_RIGHT
		Case Else
			Return False
	EndSwitch

	Return True

EndFunc   ;==>_Notifications_SetTextAlign


; FUNCTION ======================================================================================================================
; Name ..........: _Notifications_SetTimeFormat
; Description ...: Sets the time format of new notifications
; Syntax ........: _Notifications_SetTimeFormat ( $__timeFormat )
; Parameters ....: $__timeFormat        - Format of how to show the time. It is possible to display the hours (HH), minutes (MM)
;                                         and seconds (SS).  A timeformat can look like this: HH:MM:SS
; Return values .: True
; Author ........: S3cret (S3cret91)
; Modified ......:
; Remarks .......: Give an empty string to show no time
; ===============================================================================================================================
Func _Notifications_SetTimeFormat($__timeFormat)

	If $__timeFormat = Default Then

		$__notificationTimeFormat = $__notificationTimeFormatDefault
		Return True

	EndIf

	$__notificationTimeFormat = $__timeFormat
	Return True

EndFunc   ;==>_Notifications_SetTimeFormat


; FUNCTION ======================================================================================================================
; Name ..........: _Notifications_SetTransparency
; Description ...: Sets the transparency of new notification windows
; Syntax ........: _Notifications_SetTransparency ( $__transparency )
; Parameters ....: $__transparency                - Level of the transparency where 0 is transparent and 255 is solid
; Return values .: Success                        - True
;                  Failure (invalid transparency) - False
; Author ........: S3cret (S3cret91)
; Modified ......:
; ===============================================================================================================================
Func _Notifications_SetTransparency($__transparency)

	If $__transparency = Default Then

		$__notificationTransparency = $__notificationTransparencyDefault
		Return True

	EndIf

	If StringRegExp($__transparency, "^\d{1,3}$") = 0 Then Return False
	If $__transparency > 255 Then Return False

	$__notificationTransparency = $__transparency

	Return True
EndFunc   ;==>_Notifications_SetTransparency


; FUNCTION ======================================================================================================================
; Name ..........: _Notifications_Shutdown
; Description ...: Closes all open notifications and cleans up resources. To use notifications again, Startup has to be called
; Syntax ........: _Notifications_Shutdown ()
; Return values .: none
; Author ........: S3cret (S3cret91)
; Remarks .......: Does not have to be called manually, because the Startup function registers the shutdown function on on
;                  AutoIt Exit. But can be called manually when notifications are not needed anymore.
;                  Closes all notifications if there are still some open.
; ===============================================================================================================================
Func _Notifications_Shutdown()

	If _Notifications_StartupIsComplete() = False Then Return

	For $__i = 0 To UBound($__notificationList) - 1

		GUIDelete($__notificationList[$__i][0])

	Next

	ReDim $__notificationList[0][UBound($__notificationList, 2)]

	DllClose($__ntDLL)
	$__notificationStartup = False

EndFunc   ;==>_Notifications_Shutdown


; FUNCTION ======================================================================================================================
; Name ..........: _Notifications_Startup
; Description ...: Startup function for the UDF
; Syntax ........: _Notifications_Startup ()
; Return values .: Success   - True
;                  Failure   - False:
;							   @error = 1: startup was already called
;							   @error = 2: could not get taskbar Position
;							   @error = 3: calculated desktop height is invalid
;							   @error = 4: 'ntdll.dll' could not be opened
; Author ........: S3cret (S3cret91)
; Modified ......:
; Remarks .......: Has to be called after including the UDF and before using its functions.
; ===============================================================================================================================
Func _Notifications_Startup()

	;check if startup was already called
	If _Notifications_StartupIsComplete() = True Then Return SetError(1, 0, False)


	;get taskbar height
	Local $__taskbarPos = ControlGetPos("[CLASS:Shell_TrayWnd]", "", "[CLASS:MSTaskListWClass; INSTANCE:1]")
	If Not IsArray($__taskbarPos) Then Return SetError(2, 0, False)

	$__desktopHeight = @DesktopHeight - $__taskbarPos[3]
	If $__desktopHeight <= 0 Then Return SetError(3, 0, False)


	;Open the dll that is used for _Notifications_Sleep
	$__ntDLL = DllOpen("ntdll.dll")
	If $__ntDLL = -1 Then Return SetError(4, 0, False)

	;register the shutdown function to be called when autoit exits so that resources are released (dll...)
	OnAutoItExitRegister("_Notifications_Shutdown")


	;check if GUIOnEventMode is activated
	Local $__isEventModeActivated = Opt("GUIOnEventMode", 1)
	If $__isEventModeActivated <> 1 Then Opt("GUIOnEventMode", $__isEventModeActivated)
	If $__isEventModeActivated Then $__notificationOnEvent = True


	;startup complete
	$__notificationStartup = True

	Return True

EndFunc   ;==>_Notifications_Startup


; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _Notifications_Close
; Description ...: Closes a notification
; Syntax ........: _Notifications_Close ()
; Parameters ....: $__index     - Index of the notification to close
; Return values .: none
; Author ........: S3cret (S3cret91), (Andreas Karlsson (monoceres): Microsleep)
; Modified ......:
; Link ..........: https://www.autoitscript.com/forum/topic/77905-sleep-down-to-100-nano-seconds/
; Remarks........: This function is used internally by other functions in this UDF and is not supposed to be called by user
; ===============================================================================================================================
Func _Notifications_Close($__index)

	Local $__notificationCount = UBound($__notificationList)

	Local $__processPriority = _ProcessGetPriority(@AutoItPID)
	If $__processPriority = -1 Then $__processPriority = 2 ;normal priority

	;Set high process priority for smooth window movement
	If $__processPriority < 4 Then ProcessSetPriority(@AutoItPID, 4)


	;fade out time for the closing notitifaction
	Local $__fadeOutTime = $__notificationAnimationTime < $__notificationAnimationTimeDefault ? _
			$__notificationAnimationTime : $__notificationAnimationTimeDefault

	;Fade out time per step (fade out in 10 transparency steps)
	Local $__fadeOutTimePerStep = $__fadeOutTime / ($__notificationList[$__index][8] / 10)

	Local $__timer, $__timeFadeStep

	;ony use fade out when there is an animation time set, if 0 then it is instant
	If $__notificationAnimationTime > 0 Then

		;slowly increase transparency
		For $__transparency = $__notificationList[$__index][8] - 10 To 0 Step -10

			;as mentioned, there is a time for moving all notifications for 1 pixel, e.g. 2.5 ms. Moving one window may take
			;significantly shorter, while several notifications still need less time, but more more than just one. To compensate,
			;the time for moving the window will be recorded...
			$__timer = TimerInit()

			WinSetTrans($__notificationList[$__index][0], "", $__transparency)

			$__timeFadeStep = TimerDiff($__timer)

			;.. pause the script in case setting new transparency took less time than set
			If $__timeFadeStep < $__fadeOutTimePerStep Then

				DllStructSetData($__dllTimeStruct, "time", -10000 * ($__fadeOutTimePerStep - $__timeFadeStep))
				DllCall($__ntDLL, "dword", "ZwDelayExecution", "int", 0, "ptr", $__dllTimeStructPointer)

			EndIf

		Next

	EndIf


	GUIDelete($__notificationList[$__index][0])

	;restructure notification array: move all entries one index below and ReDim the array to its new size
	For $__rows = $__index To $__notificationCount - 2
		For $__columns = 0 To UBound($__notificationList, 2) - 1

			$__notificationList[$__rows][$__columns] = $__notificationList[$__rows + 1][$__columns]

		Next
	Next

	ReDim $__notificationList[$__notificationCount - 1][UBound($__notificationList, 2)]


	;lets do some cool windows moving now
	_Notifications_Move($__index)

	;restore original process priority
	ProcessSetPriority(@AutoItPID, $__processPriority)

EndFunc   ;==>_Notifications_Close


; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _Notifications_CloseOnEvent
; Description ...: Closes a notification when its button was clicked in GUIOnEventMode
; Syntax ........: _Notifications_CloseOnEvent ()
; Return values .: none
; Author ........: S3cret (S3cret91)
; Modified ......:
; Remarks .......: This function is used internally by other functions in this UDF and is not supposed to be called by user
; ===============================================================================================================================
Func _Notifications_CloseOnEvent()

	If _Notifications_StartupIsComplete() = False Then Return

	Local $__isEventModeActivated = Opt("GUIOnEventMode", 1)
	If $__isEventModeActivated <> 1 Then Opt("GUIOnEventMode", $__isEventModeActivated)

	If $__isEventModeActivated = 1 And $__notificationOnEvent = True Then _
			_Notifications_CheckGUIMsg(@GUI_CtrlId)

EndFunc   ;==>_Notifications_CloseOnEvent


; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _Notifications_GetTaskbarColor
; Description ...: Returns the color of the taskbar.
; Syntax ........: _Notifications_GetTaskbarColor ()
; Return values .: Windows 7 and earlier - black (0x000000)
;                  Windows 8 and 8.1     - color of the active's window border
;                  Windows 10            - color of the taskbar
; Author ........: nend
; Modified ......: S3cret (S3cret91)
; Remarks .......: This function is used internally by other functions in this UDF and is not supposed to be called by user
; Link ..........: https://www.autoitscript.com/forum/topic/182192-get-windows-810-taskbar-color/
; ===============================================================================================================================
Func _Notifications_GetTaskbarColor()

	If @OSVersion = "Win_8" Or @OSVersion = "Win_81" Then

		If RegRead("HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\DWM", "EnableWindowColorization") Then _
				Return "0x" & Hex(RegRead("HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\DWM", "ColorizationColor"), 6)

	ElseIf @OSVersion = "WIN_10" Then

		Local $__userOwnColorSettings = _
				RegRead("HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize", "ColorPrevalence")

		Local $__taskbarIsTransparent = _
				RegRead("HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize", "EnableTransparency")

		Local $__colorAccentPalette = _
				RegRead("HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Accent", "AccentPalette")

		If $__userOwnColorSettings Then

			If $__taskbarIsTransparent Then Return "0x" & StringLeft(StringRight($__colorAccentPalette, 16), 6)

			Return "0x" & StringLeft(StringRight($__colorAccentPalette, 24), 6)

		Else

			If $__taskbarIsTransparent Then Return 0x000000

			Return "0x101010"

		EndIf

	EndIf

	Return 0x000000

EndFunc   ;==>_Notifications_GetTaskbarColor


; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _Notifications_GetTaskbarTransparency
; Description ...: Returns the transparency of the taskbar.
; Syntax ........: _Notifications_GetTaskbarTransparency ()
; Return values .: Windows 7 and earlier - 217 (slight transparency)
;                  Windows 8, 8.1        - 255 (solid) if Window colorization is enabled, 217 else
;                  Windows 10            - 217 if taskbar is transparent, 255 it not
; Author ........: S3cret (S3cret91), thanks to nend for the RegRead
; Modified ......:
; Remarks .......: This function is used internally by other functions in this UDF and is not supposed to be called by user
; Link ..........: https://www.autoitscript.com/forum/topic/182192-get-windows-810-taskbar-color/
; ===============================================================================================================================
Func _Notifications_GetTaskbarTransparency()

	If @OSVersion = "Win_10" Then

		Local $__taskbarIsTransparent = _
				RegRead("HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize", "EnableTransparency")

		If Not $__taskbarIsTransparent Then Return 255

	ElseIf @OSVersion = "Win_8" Or @OSVersion = "Win_81" Then

		If RegRead("HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\DWM", "EnableWindowColorization") Then Return 255

	EndIf

	Return 217

EndFunc   ;==>_Notifications_GetTaskbarTransparency


; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _Notifications_GetTopPos
; Description ...: Returns the top position of a notification window by its id. The notification with this id can be non existent
; Syntax ........: _Notifications_GetTopPos ( [$__notificationID = -1] )
; Parameters ....: $__notificationID     - ID of a notification to get its top pos
; Return values .: Top pos of a notification with specified id
; Author ........: S3cret (S3cret91)
; Modified ......:
; Remarks .......: This function is used internally by other functions in this UDF and is not supposed to be called by user
; ===============================================================================================================================
Func _Notifications_GetTopPos($__notificationID = -1)

	If _Notifications_StartupIsComplete() = False Then Return

	If $__notificationID = -1 Then $__notificationID = UBound($__notificationList)

	Local $__topPos = 0

	For $__i = 1 To $__notificationID

		$__topPos += 200 + $__notificationHeight

	Next

	Return $__desktopHeight - $__topPos

EndFunc   ;==>_Notifications_GetTopPos


; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _Notifications_Move
; Description ...: Moves all existent notifications to their position based on their notification ID. Usually this function is
;                  called after a notification was deleted and others have to "move up"
; Syntax ........: _Notifications_Move ( $__index )
; Parameters ....: $__index     - Index number of the first notification to move
; Return values .: none
; Author ........: S3cret (S3cret91), (Andreas Karlsson (monoceres): Microsleep)
; Modified ......:
; Link ..........: https://www.autoitscript.com/forum/topic/77905-sleep-down-to-100-nano-seconds/
; Remarks .......: This function is used internally by other functions in this UDF and is should not be called by user
; ===============================================================================================================================
Func _Notifications_Move($__index)

	If _Notifications_StartupIsComplete() = False Then Return

	;Number of notifications to move
	Local $__notificationsToMove = UBound($__notificationList) - $__index

	If $__notificationsToMove < 1 Then Return


	Local $__movingDistance = _Notifications_GetTopPos($__index + 1) - $__notificationList[$__index][3] ;in pixels
	Local $__lastNotificationToMove = 0 ;set the last notification to move

	;find the last notification to move: it is the first hidden in the list or if there are only visible notifications,
	;it is the last one in the list
	For $__i = $__index To UBound($__notificationList) - 1

		;first invisible notification
		If $__notificationList[$__i][1] = False Then

			$__lastNotificationToMove = $__i
			GUISetState(@SW_SHOWNA, $__notificationList[$__lastNotificationToMove][0]) ;show notification
			$__notificationList[$__lastNotificationToMove][1] = True
			ExitLoop

		EndIf

	Next

	If $__lastNotificationToMove = 0 Then $__lastNotificationToMove = UBound($__notificationList) - 1



	;Move notifications simultiniously, therefore a timer is used to set a time to move the notifications 1 pixel further.
	;This guarantees the same moving speed no matter how many notifications are moved (in case animation time > computing time)
	Local $__timePerPixelMove = $__notificationAnimationTime / $__movingDistance

	Local $__timer, $__timeWinMoveStep

	;ony use animation when there is a time set, if 0 then it is instant
	If $__notificationAnimationTime > 0 Then

		;cover the moving distance
		For $__y = 1 To $__movingDistance


			;as mentioned, there is a time for moving all notifications for 1 pixel, e.g. 2.5 ms. Moving one window may take
			;significantly shorter, while several notifications still need less time, but more more than just one. To compensate,
			;the time for moving the window will be recorded...
			$__timer = TimerInit()


			;for each pixel move every notification by 1 pixel down
			For $__i = $__index To $__lastNotificationToMove

				$__notificationList[$__i][3] = $__notificationList[$__i][3] + 1
				WinMove($__notificationList[$__i][0], "", $__notificationList[$__i][2], $__notificationList[$__i][3])

			Next

			$__timeWinMoveStep = TimerDiff($__timer)

			;.. and for the time difference between the timePerPixel and the time of moving the windows the script will pause
			If $__timeWinMoveStep < $__timePerPixelMove Then

				DllStructSetData($__dllTimeStruct, "time", -10000 * ($__timePerPixelMove - $__timeWinMoveStep))
				DllCall($__ntDLL, "dword", "ZwDelayExecution", "int", 0, "ptr", $__dllTimeStructPointer)

			EndIf

		Next

	EndIf


	Local $__firstNotificationToMoveImmidiately = $__lastNotificationToMove + 1
	If $__notificationAnimationTime = 0 Then $__firstNotificationToMoveImmidiately = $__index

	;Move invisible notifications immidiately (and if time = 0, also visible notifications)
	For $__i = $__firstNotificationToMoveImmidiately To UBound($__notificationList) - 1

		$__notificationList[$__i][3] = $__notificationList[$__i][3] + $__movingDistance
		WinMove($__notificationList[$__i][0], "", $__notificationList[$__i][2], $__notificationList[$__i][3])

	Next


EndFunc   ;==>_Notifications_Move


; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: _Notifications_StartupIsComplete
; Description ...: Checks if the startup function was called
; Syntax ........: _Notifications_StartupIsComplete ()
; Return values .: True  - startup function was called
;                  False - startup function was not called
; Author ........: S3cret (S3cret91)
; Modified ......:
; Remarks .......: This function is used internally by other functions in this UDF and is not supposed to be called by user
; ===============================================================================================================================
Func _Notifications_StartupIsComplete()

	Return $__notificationStartup

EndFunc   ;==>_Notifications_StartupIsComplete
