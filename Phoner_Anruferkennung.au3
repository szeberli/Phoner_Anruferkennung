#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_icon=notifications.ico
#AutoIt3Wrapper_Res_Comment=Benachrichtigung wer anruft
#AutoIt3Wrapper_Res_Description=Benachrichtigung wer anruft
#AutoIt3Wrapper_Res_Fileversion=1.0.0.0
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=p
#AutoIt3Wrapper_Res_LegalCopyright=Simon Zeberli
#AutoIt3Wrapper_Res_Language=2055
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include <String.au3>
#include <_rss.au3>
#include <Notifications.au3>

Global $__notificationSound = ""
Opt("GUIOnEventMode", 1)


;~ MsgBox(0,"Parameters", $CmdLine[1])

;~ Command line Testen und einen Wert ausgeben
If $CmdLine[0] = 0 Then
   $TEL_NR = "0800800800" ;0800800800
Else
   $TEL_NR = $CmdLine[1]
EndIf


;~ $TEL_NR = "0716421602@fritz.box" ;Debug Funktion
$TEL_NR_RENDERED = StringReplace ($TEL_NR, '@fritz.box', "")



$FEED = _RSSGetInfo("https://tel.search.ch/api/?was=" & $TEL_NR_RENDERED , '<content type="text">', '</content>')
$FEED_RENDERD = StringReplace ($FEED[1], 't type="text">', "")
$FEED_RENDERD_finish = StringReplace ($FEED_RENDERD, '    ', "")


$FEED_RENDERD_finish = StringReplace($FEED_RENDERD_finish, 'ÃŸ', "ß")
$FEED_RENDERD_finish = StringReplace($FEED_RENDERD_finish, 'Ãœ', "Ü")
$FEED_RENDERD_finish = StringReplace($FEED_RENDERD_finish, 'Ã„', 'Ä')
$FEED_RENDERD_finish = StringReplace($FEED_RENDERD_finish, 'Ã–', 'Ö')
$FEED_RENDERD_finish = StringReplace($FEED_RENDERD_finish, 'Ã¼', "ü")
$FEED_RENDERD_finish = StringReplace($FEED_RENDERD_finish, 'Ã¤', "ä")
$FEED_RENDERD_finish = StringReplace($FEED_RENDERD_finish, 'Ã¶', "ö")

;~ MsgBox(0, "Test", $FEED_RENDERD_finish)


_Notifications_Startup()

; #6
_Notifications_SetDateFormat("DD.MM.YYYY")
_Notifications_SetTimeFormat(Default)
_Notifications_SetButtonText("Schliessen")
_Notifications_SetColor(0x0D0D0D)
_Notifications_SetBkColor(0xFFFFFF)
_Notifications_SetBorder(True)
_Notifications_SetTextAlign("left")
_Notifications_Create( $TEL_NR_RENDERED, $FEED_RENDERD_finish)




While Sleep(7000)
   Exit
WEnd
