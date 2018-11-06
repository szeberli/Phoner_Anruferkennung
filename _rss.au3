#include-once
#region _RSS
; RSS Reader
; Created By: Frostfel
#include <INet.au3>
#include <Array.au3>
; ============================================================================
; Function: _RSSGetInfo($RSS, $RSS_InfoS, $RSS_InfoE[, $RSS_Info_ = 1])
; Description: Gets RSS Info
; Parameter(s): $RSS =  RSS Feed Example: "http://feed.com/index.xml"
;               $RSS_InfoS = String to find for info start Example: <title>
;               $RSS_InfoE = String to find for info end Example: </title>
;               $RSS_Info_Start = [optional] <info>/</info> To start at
;                                   Some RSS feeds will have page titles
;                                   you dont want Defualt = 0
; Requirement(s): None
; Return Value(s): On Success - Returns RSS Info in Array Starting at 1
;                  On Failure - Returns 0
;                       @Error = 1 - Failed to get RSS Feed
; Author(s): Frostfel
; ============================================================================
Func _RSSGetInfo($RSS, $RSS_InfoS, $RSS_InfoE, $RSS_Info_Start = 0)
$RSSFile = _INetGetSource($RSS)

If @Error Then
    SetError(1)
    Return -1
EndIf

Dim $InfoSearchS = 1
Dim $Info[1000]
Dim $InfoNumA
$InfoNum = $RSS_Info_Start
    While $InfoSearchS <> 6
        $InfoNum += 1
        $InfoNumA += 1
        $InfoSearchS = StringInStr($RSSFile, $RSS_InfoS, 0, $InfoNum)
        $InfoSearchE = StringInStr($RSSFile, $RSS_InfoE, 0, $InfoNum)
        $InfoSearchS += 6
        $InfoSS = StringTrimLeft($RSSFile, $InfoSearchS)
        $InfoSearchE -= 1
        $InfoSE_Len = StringLen(StringTrimLeft($RSSFile, $InfoSearchE))
        $InfoSE = StringTrimRight($InfoSS, $InfoSE_Len)
        _ArrayInsert($Info, $InfoNumA, $InfoSE)
    WEnd
Return $Info
EndFunc
#endregion