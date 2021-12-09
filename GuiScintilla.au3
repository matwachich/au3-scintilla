#include-once
#include <WinAPI.au3>
#include <WindowsConstants.au3>

#include "ScintillaConstants.au3"

;~ On Windows, the top level window should forward any WM_SETTINGCHANGE, WM_SYSCOLORCHANGE, and WM_DPICHANGED messages to Scintilla as this allows Scintilla to respond to changes to mouse settings, monitor resolution, colour scheme and similar system properties.

Global $__gScintilla_hDLL = -1

Func _GUICtrlScintilla_Startup($sDllPath)
	$__gScintilla_hDLL = DllOpen($sDllPath)
	If $__gScintilla_hDLL = -1 Then
		MsgBox(16, @ScriptName, $sDllPath & " load failed!")
		Exit -1
	EndIf
	Return True
EndFunc

#Region Control creation/destruction ==============================================================

Const $GUI_SS_DEFAULT_SCINTILLA = BitOR($WS_CHILD,$WS_VISIBLE,$WS_TABSTOP,$WS_CLIPCHILDREN)

Func _GUICtrlScintilla_Create($hParent, $iCtrlID, $iX, $iY, $iWidth, $iHeight, $iStyle = Default, $iExStyle = Default)
	If $iStyle = Default Then $iStyle = BitOR($WS_CHILD,$WS_VISIBLE,$WS_TABSTOP,$WS_CLIPCHILDREN)
	If $iExStyle = Default Then $iExStyle = 0

	Local $hCtrl = _WinAPI_CreateWindowEx($iExStyle, "Scintilla", "", $iStyle, $iX, $iY, $iWidth, $iHeight, $hParent, $iCtrlID)
	If Not $hCtrl Then Return SetError(_WinAPI_GetLastError(), 0, 0)

	Return $hCtrl
EndFunc

Func _GUICtrlScintilla_Destroy($hCtrl)
	_WinAPI_DestroyWindow($hCtrl)
EndFunc

#EndRegion

#Region Colors ====================================================================================

Func _GUICtrlScintilla_Color($iR, $iG, $iB, $iAlpha = Default)
	If $iR < 0 Then $iR = 0
	If $iG < 0 Then $iG = 0
	If $iB < 0 Then $iB = 0
	If $iAlpha < 0 Then $iAlpha = 0

	If $iR > 255 Then $iR = 255
	If $iG > 255 Then $iG = 255
	If $iB > 255 Then $iB = 255
	If $iAlpha > 255 Then $iAlpha = 255

	If $iAlpha <> Default Then
		Return BitOR($iR, BitShift($iG, -8), BitShift($iB, -16), BitShift($iAlpha, -24))
	Else
		Return BitOR($iR, BitShift($iG, -8), BitShift($iB, -16))
	EndIf
EndFunc

Func __guiCtrlScintilla_colorConvert($iCol)
	Return BitOR( _ ; color format 0xAARRGGBB
		BitAND(BitShift($iCol, 16), 0xFF), _
		BitShift(BitAND(BitShift($iCol, 8), 0xFF), -8), _
		BitShift(BitAND($iCol, 0xFF), -16), _
		BitShift(BitAND(BitShift($iCol, 24), 0xFF), -24) _
	)
EndFunc

#EndRegion

#Region Text retreival and modification ===========================================================

;~ SCI_GETTEXT(position length, char *text) → position
Func _GUICtrlScintilla_GetText($hCtrl)
	Local $iLen = _SendMessage($hCtrl, $SCI_GETTEXT)
	If $iLen <= 0 Then Return ""

	Local $tBuf = DllStructCreate("byte[" & ($iLen + 1) & "]")
	_SendMessage($hCtrl, $SCI_GETTEXT, $iLen, $tBuf, 0, "wparam", "struct*")
	Return BinaryToString(DllStructGetData($tBuf, 1), 4)
EndFunc

;~ SCI_SETTEXT(<unused>, const char *text)
Func _GUICtrlScintilla_SetText($hCtrl, $sText)
	_SendMessage($hCtrl, $SCI_SETTEXT, 0, __guiScintilla_str2bin($sText), 0, "wparam", "struct*")
EndFunc

;~ SCI_SETSAVEPOINT
Func _GUICtrlScintilla_SetSavePoint($hCtrl)
	_SendMessage($hCtrl, $SCI_SETSAVEPOINT)
EndFunc

;~ SCI_GETLINE(line line, char *text) → position
Func _GUICtrlScintilla_GetLine($hCtrl, $iLine)
	Local $iLen = _SendMessage($hCtrl, $SCI_GETLINE, $iLine)
	If $iLen <= 0 Then Return ""

	Local $tBuf = DllStructCreate("byte[" & $iLen & "]")
	_SendMessage($hCtrl, $SCI_GETLINE, $iLine, $tBuf, 0, "wparam", "struct*")
	Return BinaryToString(DllStructGetData($tBuf, 1), 4)
EndFunc

;~ SCI_REPLACESEL(<unused>, const char *text)
Func _GUICtrlScintilla_ReplaceSel($hCtrl, $sText)
	_SendMessage($hCtrl, $SCI_REPLACESEL, 0, __guiScintilla_str2bin($sText), 0, "wparam", "struct*")
EndFunc

;~ SCI_SETREADONLY(bool readOnly)
Func _GUICtrlScintilla_SetReadOnly($hCtrl, $bReadOnly = True)
	_SendMessage($hCtrl, $SCI_SETREADONLY, $bReadOnly, 0, 0, "bool")
EndFunc

;~ SCI_GETREADONLY → bool
Func _GUICtrlScintilla_GetReadOnly($hCtrl)
	Return _SendMessage($hCtrl, $SCI_GETREADONLY, 0, 0, 0, "wparam", "lparam", "bool")
EndFunc

;~ SCI_GETTEXTRANGE(<unused>, Sci_TextRange *tr) → position
Func _GUICtrlScintilla_GetTextRange($hCtrl, $iMin = 0, $iMax = -1)
	If $iMax < 0 Then $iMax = _SendMessage($hCtrl, $SCI_GETLENGTH)
	If $iMax - $iMin <= 0 Then Return ""

	Local $tBuf = DllStructCreate("byte[" & ($iMax - $iMin + 1) & "]")
	Local $tTextRange = DllStructCreate($tagSCI_TEXTRANGE)
	$tTextRange.Min = $iMin
	$tTextRange.Max = $iMax
	$tTextRange.Text = DllStructGetPtr($tBuf)

	Local $iCopied = _SendMessage($hCtrl, $SCI_GETTEXTRANGE, 0, $tTextRange, 0, "wparam", "struct*")
	Return BinaryToString(DllStructGetData(DllStructCreate("byte[" & $iCopied & "]", $tTextRange.Text), 1), 4)
EndFunc

;~ SCI_ALLOCATE(position bytes)
Func _GUICtrlScintilla_Allocate($hCtrl, $iBytes)
	_SendMessage($hCtrl, $SCI_ALLOCATE, $iBytes)
EndFunc

;~ SCI_ALLOCATELINES(line lines)
Func _GUICtrlScintilla_AllocateLines($hCtrl, $iLines)
	_SendMessage($hCtrl, $SCI_ALLOCATELINES, $iLines)
EndFunc

;~ SCI_ADDTEXT(position length, const char *text)
Func _GUICtrlScintilla_AddText($hCtrl, $sText)
	Local $tBuf = __guiScintilla_str2bin($sText)
	Local $iLen = @extended
	_SendMessage($hCtrl, $SCI_ADDTEXT, $iLen, $tBuf, 0, "wparam", "struct*")
EndFunc

;~ SCI_ADDSTYLEDTEXT(position length, cell *c)

;~ SCI_APPENDTEXT(position length, const char *text)
Func _GUICtrlScintilla_AppendText($hCtrl, $sText)
	Local $tBuf = __guiScintilla_str2bin($sText)
	Local $iLen = @extended
	_SendMessage($hCtrl, $SCI_APPENDTEXT, $iLen, $tBuf, 0, "wparam", "struct*")
EndFunc

;~ SCI_INSERTTEXT(position pos, const char *text)
Func _GUICtrlScintilla_InsertText($hCtrl, $sText, $iPos = -1)
	Local $tBuf = __guiScintilla_str2bin($sText, True)
	_SendMessage($hCtrl, $SCI_INSERTTEXT, $iPos, $tBuf, 0, "wparam", "struct*")
EndFunc

;~ SCI_CHANGEINSERTION(position length, const char *text)
; This may only be called from a SC_MOD_INSERTCHECK notification handler and will change the text being inserted to that provided.
Func _GUICtrlScintilla_ChangeInsertion($hCtrl, $sText)
	Local $tBuf = __guiScintilla_str2bin($sText, True)
	Local $iLen = @extended
	_SendMessage($hCtrl, $SCI_CHANGEINSERTION, $iLen, $tBuf, 0, "wparam", "struct*")
EndFunc

;~ SCI_CLEARALL
Func _GUICtrlScintilla_ClearAll($hCtrl)
	_SendMessage($hCtrl, $SCI_CLEARALL)
EndFunc

;~ SCI_DELETERANGE(position start, position lengthDelete)
Func _GUICtrlScintilla_DeleteRange($hCtrl, $iStart, $iLength = -1)
	If $iLength < 0 Then $iLength = _SendMessage($hCtrl, $SCI_GETLENGTH) - $iStart
	_SendMessage($hCtrl, $SCI_DELETERANGE, $iStart, $iLength)
EndFunc

;~ SCI_CLEARDOCUMENTSTYLE
Func _GUICtrlScintilla_ClearDocumentStyle($hCtrl)
	_SendMessage($hCtrl, $SCI_CLEARDOCUMENTSTYLE)
EndFunc

;~ SCI_GETCHARAT(position pos) → int
Func _GUICtrlScintilla_GetCharAt($hCtrl, $iPos)
	Return _SendMessage($hCtrl, $SCI_GETCHARAT, $iPos)
EndFunc

;~ SCI_GETSTYLEAT(position pos) → int
Func _GUICtrlScintilla_GetStyleAt($hCtrl, $iPos)
	Return _SendMessage($hCtrl, $SCI_GETSTYLEAT, $iPos)
EndFunc

;~ SCI_GETSTYLEDTEXT(<unused>, Sci_TextRange *tr) → position

;~ SCI_RELEASEALLEXTENDEDSTYLES
Func _GUICtrlScintilla_ReleaseAllExtendedStyles($hCtrl)
	_SendMessage($hCtrl, $SCI_RELEASEALLEXTENDEDSTYLES)
EndFunc

;~ SCI_ALLOCATEEXTENDEDSTYLES(int numberStyles) → int
Func _GUICtrlScintilla_AllocateExtendedStyles($hCtrl, $iNumStyles)
	Return _SendMessage($hCtrl, $SCI_ALLOCATEEXTENDEDSTYLES, $iNumStyles)
EndFunc

;~ SCI_TARGETASUTF8(<unused>, char *s) → position

;~ SCI_ENCODEDFROMUTF8(const char *utf8, char *encoded) → position

;~ SCI_SETLENGTHFORENCODE(position bytes)

#EndRegion

#Region Searching =================================================================================

;~ SCI_SETTARGETSTART(position start)
;~ SCI_GETTARGETSTART → position
;~ SCI_SETTARGETSTARTVIRTUALSPACE(position space)
;~ SCI_GETTARGETSTARTVIRTUALSPACE → position
;~ SCI_SETTARGETEND(position end)
;~ SCI_GETTARGETEND → position
;~ SCI_SETTARGETENDVIRTUALSPACE(position space)
;~ SCI_GETTARGETENDVIRTUALSPACE → position
;~ SCI_SETTARGETRANGE(position start, position end)
;~ SCI_TARGETFROMSELECTION
;~ SCI_TARGETWHOLEDOCUMENT
;~ SCI_SETSEARCHFLAGS(int searchFlags)
;~ SCI_GETSEARCHFLAGS → int
;~ SCI_SEARCHINTARGET(position length, const char *text) → position
;~ SCI_GETTARGETTEXT(<unused>, char *text) → position
;~ SCI_REPLACETARGET(position length, const char *text) → position
;~ SCI_REPLACETARGETRE(position length, const char *text) → position
;~ SCI_GETTAG(int tagNumber, char *tagValue) → int

#EndRegion

#Region Overtype ==================================================================================

;~ SCI_SETOVERTYPE(bool overType)
;~ SCI_GETOVERTYPE → bool

#EndRegion

#Region Cut, copy and paste =======================================================================

;~ SCI_CUT
Func _GUICtrlScintilla_Cut($hCtrl)
	_SendMessage($hCtrl, $SCI_CUT)
EndFunc

;~ SCI_COPY
Func _GUICtrlScintilla_Copy($hCtrl)
	_SendMessage($hCtrl, $SCI_COPY)
EndFunc

;~ SCI_PASTE
Func _GUICtrlScintilla_Paste($hCtrl)
	_SendMessage($hCtrl, $SCI_PASTE)
EndFunc

;~ SCI_CLEAR
Func _GUICtrlScintilla_Clear($hCtrl)
	_SendMessage($hCtrl, $SCI_CLEAR)
EndFunc

;~ SCI_CANPASTE → bool
Func _GUICtrlScintilla_CanPaste($hCtrl)
	Return _SendMessage($hCtrl, $SCI_CANPASTE, 0, 0, 0, "wparam", "lparam", "bool")
EndFunc

;~ SCI_COPYRANGE(position start, position end)
Func _GUICtrlScintilla_CopyRange($hCtrl, $iStart = 0, $iEnd = -1)
	If $iEnd < 0 Then $iEnd = _SendMessage($hCtrl, $SCI_GETLENGTH)
	_SendMessage($hCtrl, $SCI_COPYRANGE, $iStart, $iEnd, 0, "wparam", "lparam")
EndFunc

;~ SCI_COPYTEXT(position length, const char *text)
Func _GUICtrlScintilla_CopyText($hCtrl, $sText)
	Local $tBuf = __guiScintilla_str2bin($sText)
	Local $iLen = @extended
	_SendMessage($hCtrl, $SCI_COPYTEXT, $iLen, $tBuf, 0, "wparam", "struct*")
EndFunc

;~ SCI_COPYALLOWLINE
Func _GUICtrlScintilla_CopyAllowLine($hCtrl)
	_SendMessage($hCtrl, $SCI_COPYALLOWLINE)
EndFunc

;~ SCI_SETPASTECONVERTENDINGS(bool convert)
Func _GUICtrlScintilla_SetPasteConvertEndings($hCtrl, $bConvert = True)
	_SendMessage($hCtrl, $SCI_SETPASTECONVERTENDINGS, $bConvert, 0, 0, "bool")
EndFunc

;~ SCI_GETPASTECONVERTENDINGS → bool
Func _GUICtrlScintilla_GetPasteConvertEndings($hCtrl)
	Return _SendMessage($hCtrl, $SCI_GETPASTECONVERTENDINGS, 0, 0, 0, "wparam", "lparam", "bool")
EndFunc

;~ SCI_REPLACERECTANGULAR(position length, const char *text)

#EndRegion

#Region Error handling ============================================================================

;~ SCI_SETSTATUS(int status)
Func _GUICtrlScintilla_SetStatus($hCtrl, $iStatus)
	_SendMessage($hCtrl, $SCI_SETSTATUS, $iStatus)
EndFunc

;~ SCI_GETSTATUS → int
Func _GUICtrlScintilla_GetStatus($hCtrl)
	Return _SendMessage($hCtrl, $SCI_GETSTATUS)
EndFunc

#EndRegion

#Region Undo and Redo =============================================================================

;~ SCI_UNDO
Func _GUICtrlScintilla_Undo($hCtrl)
	_SendMessage($hCtrl, $SCI_UNDO)
EndFunc

;~ SCI_CANUNDO → bool
Func _GUICtrlScintilla_CanUndo($hCtrl)
	Return _SendMessage($hCtrl, $SCI_CANUNDO, 0, 0, 0, "wparam", "lparam", "bool")
EndFunc

;~ SCI_EMPTYUNDOBUFFER
Func _GUICtrlScintilla_EmptyUndoBuffer($hCtrl)
	_SendMessage($hCtrl, $SCI_EMPTYUNDOBUFFER)
EndFunc

;~ SCI_REDO
Func _GUICtrlScintilla_Redo($hCtrl)
	_SendMessage($hCtrl, $SCI_REDO)
EndFunc

;~ SCI_CANREDO → bool
Func _GUICtrlScintilla_CanRedo($hCtrl)
	Return _SendMessage($hCtrl, $SCI_CANREDO, 0, 0, 0, "wparam", "lparam", "bool")
EndFunc

;~ SCI_SETUNDOCOLLECTION(bool collectUndo)
Func _GUICtrlScintilla_SetUndoCollection($hCtrl, $bCollectUndo)
	_SendMessage($hCtrl, $SCI_SETUNDOCOLLECTION, $bCollectUndo, 0, 0, "bool")
EndFunc

;~ SCI_GETUNDOCOLLECTION → bool
Func _GUICtrlScintilla_GetUndoCollection($hCtrl)
	Return _SendMessage($hCtrl, $SCI_GETUNDOCOLLECTION, 0, 0, 0, "wparam", "lparam", "bool")
EndFunc

;~ SCI_BEGINUNDOACTION
Func _GUICtrlScintilla_BeginUndoAction($hCtrl)
	_SendMessage($hCtrl, $SCI_BEGINUNDOACTION)
EndFunc

;~ SCI_ENDUNDOACTION
Func _GUICtrlScintilla_EndUndoAction($hCtrl)
	_SendMessage($hCtrl, $SCI_ENDUNDOACTION)
EndFunc

;~ SCI_ADDUNDOACTION(int token, int flags)
Func _GUICtrlScintilla_AddUndoAction($hCtrl, $iToken, $iFlags)
	_SendMessage($hCtrl, $SCI_ADDUNDOACTION, $iToken, $iFlags)
EndFunc

#EndRegion

#Region Selection and information =================================================================

;~ SCI_GETTEXTLENGTH → position
Func _GUICtrlScintilla_GetTextLength($hCtrl)
	Return _SendMessage($hCtrl, $SCI_GETTEXTLENGTH)
EndFunc

;~ SCI_GETLENGTH → position
Func _GUICtrlScintilla_GetLength($hCtrl)
	Return _SendMessage($hCtrl, $SCI_GETLENGTH)
EndFunc

;~ SCI_GETLINECOUNT → line
Func _GUICtrlScintilla_GetLineCount($hCtrl)
	Return _SendMessage($hCtrl, $SCI_GETLINECOUNT)
EndFunc

;~ SCI_LINESONSCREEN → line
Func _GUICtrlScintilla_LinesOnScreen($hCtrl)
	Return _SendMessage($hCtrl, $SCI_LINESONSCREEN)
EndFunc

;~ SCI_GETMODIFY → bool
Func _GUICtrlScintilla_GetModify($hCtrl)
	Return _SendMessage($hCtrl, $SCI_GETMODIFY, 0, 0, 0, "wparam", "lparam", "bool")
EndFunc

;~ SCI_SETSEL(position anchor, position caret)
Func _GUICtrlScintilla_SetSel($hCtrl, $iAnchor, $iCaret)
	_SendMessage($hCtrl, $SCI_SETSEL, $iAnchor, $iCaret)
EndFunc

;~ SCI_GOTOPOS(position caret)
Func _GUICtrlScintilla_GoToPos($hCtrl, $iCaret)
	_SendMessage($hCtrl, $SCI_GOTOPOS, $iCaret)
EndFunc

;~ SCI_GOTOLINE(line line)
Func _GUICtrlScintilla_GoToLine($hCtrl, $iLine)
	_SendMessage($hCtrl, $SCI_GOTOLINE, $iLine)
EndFunc

;~ SCI_SETCURRENTPOS(position caret)
Func _GUICtrlScintilla_SetCurrentPos($hCtrl, $iCaret)
	_SendMessage($hCtrl, $SCI_SETCURRENTPOS, $iCaret)
EndFunc

;~ SCI_GETCURRENTPOS → position
Func _GUICtrlScintilla_GetCurrentPos($hCtrl)
	Return _SendMessage($hCtrl, $SCI_GETCURRENTPOS)
EndFunc

;~ SCI_SETANCHOR(position anchor)
Func _GUICtrlScintilla_SetAnchor($hCtrl, $iAnchor)
	_SendMessage($hCtrl, $SCI_SETANCHOR, $iAnchor)
EndFunc

;~ SCI_GETANCHOR → position
Func _GUICtrlScintilla_GetAnchor($hCtrl)
	Return _SendMessage($hCtrl, $SCI_GETANCHOR)
EndFunc

;~ SCI_SETSELECTIONSTART(position anchor)
;~ SCI_SETSELECTIONEND(position caret)
Func _GUICtrlScintilla_SetSelection($hCtrl, $iStart = Default, $iEnd = Default)
	If $iStart <> Default Then _SendMessage($hCtrl, $SCI_SETSELECTIONSTART, $iStart)
	If $iEnd <> Default Then _SendMessage($hCtrl, $SCI_SETSELECTIONEND, $iEnd)
EndFunc

;~ SCI_GETSELECTIONSTART → position
;~ SCI_GETSELECTIONEND → position
Func _GUICtrlScintilla_GetSelection($hCtrl)
	Local $aRet[] = [_SendMessage($hCtrl, $SCI_GETSELECTIONSTART), _SendMessage($hCtrl, $SCI_GETSELECTIONEND)]
	Return $aRet
EndFunc

;~ SCI_SETEMPTYSELECTION(position caret)
Func _GUICtrlScintilla_SetEmptySelection($hCtrl, $iCaret)
	_SendMessage($hCtrl, $SCI_SETEMPTYSELECTION, $iCaret)
EndFunc

;~ SCI_SELECTALL
Func _GUICtrlScintilla_SelectAll($hCtrl)
	_SendMessage($hCtrl, $SCI_SELECTALL)
EndFunc

;~ SCI_LINEFROMPOSITION(position pos) → line
Func _GUICtrlScintilla_LineFromPosition($hCtrl, $iPos)
	Return _SendMessage($hCtrl, $SCI_LINEFROMPOSITION, $iPos)
EndFunc

;~ SCI_POSITIONFROMLINE(line line) → position
Func _GUICtrlScintilla_PositionFromLine($hCtrl, $iLine)
	Return _SendMessage($hCtrl, $SCI_POSITIONFROMLINE, $iLine)
EndFunc

;~ SCI_GETLINEENDPOSITION(line line) → position
;~ SCI_LINELENGTH(line line) → position
Func _GUICtrlScintilla_LineLength($hCtrl, $iLine, $bWithLineEndings = False)
	If $bWithLineEndings Then
		Return _SendMessage($hCtrl, $SCI_LINELENGTH, $iLine)
	Else
		Return _SendMessage($hCtrl, $SCI_GETLINEENDPOSITION, $iLine) - _SendMessage($hCtrl, $SCI_POSITIONFROMLINE, $iLine)
	EndIf
EndFunc

;~ SCI_GETCOLUMN(position pos) → position
Func _GUICtrlScintilla_GetColumn($hCtrl, $iPos)
	Return _SendMessage($hCtrl, $SCI_GETCOLUMN, $iPos)
EndFunc

;~ SCI_FINDCOLUMN(line line, position column) → position
Func _GUICtrlScintilla_FindColumn($hCtrl, $iLine, $iColumn)
	Return _SendMessage($hCtrl, $SCI_FINDCOLUMN, $iLine, $iColumn)
EndFunc

;~ SCI_POSITIONFROMPOINT(int x, int y) → position
;~ SCI_POSITIONFROMPOINTCLOSE(int x, int y) → position
Func _GUICtrlScintilla_PositionFromPoint($hCtrl, $iX, $iY, $bStrict = False)
	Return _SendMessage($hCtrl, $bStrict ? $SCI_POSITIONFROMPOINTCLOSE : $SCI_POSITIONFROMPOINT, $iX, $iY)
EndFunc

;~ SCI_CHARPOSITIONFROMPOINT(int x, int y) → position
;~ SCI_CHARPOSITIONFROMPOINTCLOSE(int x, int y) → position
Func _GUICtrlScintilla_CharPositionFromPoint($hCtrl, $iX, $iY, $bStrict = False)
	Return _SendMessage($hCtrl, $bStrict ? $SCI_CHARPOSITIONFROMPOINTCLOSE : $SCI_CHARPOSITIONFROMPOINT, $iX, $iY)
EndFunc

;~ SCI_POINTXFROMPOSITION(<unused>, position pos) → int
;~ SCI_POINTYFROMPOSITION(<unused>, position pos) → int
Func _GUICtrlScintilla_PointFromPosition($hCtrl, $iPos)
	Local $aRet[] = [ _
		_SendMessage($hCtrl, $SCI_POINTXFROMPOSITION, 0, $iPos), _
		_SendMessage($hCtrl, $SCI_POINTYFROMPOSITION, 0, $iPos) _
	]
	Return $aRet
EndFunc

;~ SCI_HIDESELECTION(bool hide)
Func _GUICtrlScintilla_HideSelection($hCtrl, $bHide = True)
	_SendMessage($hCtrl, $SCI_HIDESELECTION, $bHide, 0, 0, "bool")
EndFunc

;~ SCI_GETSELTEXT(<unused>, char *text) → position
Func _GUICtrlScintilla_GetSelText($hCtrl)
	Local $iLen = _SendMessage($hCtrl, $SCI_GETSELTEXT)
	If $iLen <= 0 Then Return ""

	Local $tBuf = DllStructCreate("byte[" & $iLen & "]")
	_SendMessage($hCtrl, $SCI_GETSELTEXT, 0, $tBuf, 0, "wparam", "struct*")
	Return __guiScintilla_bin2str($tBuf)
EndFunc

;~ SCI_GETCURLINE(position length, char *text) → position
Func _GUICtrlScintilla_GetCurLine($hCtrl, $iPos)
	Local $iLen = _SendMessage($hCtrl, $SCI_GETCURLINE)
	Local $tBuf = DllStructCreate("byte[" & $iLen & "]")
	_SendMessage($hCtrl, $SCI_GETCURLINE, $iPos, $tBuf, 0, "wparam", "struct*")
	Return __guiScintilla_bin2str($tBuf)
EndFunc

;~ SCI_SELECTIONISRECTANGLE → bool
Func _GUICtrlScintilla_SelectionIsRectangle($hCtrl)
	Return _SendMessage($hCtrl, $SCI_SELECTIONISRECTANGLE, 0, 0, 0, "wparam", "lparam", "bool")
EndFunc

;~ SCI_SETSELECTIONMODE(int selectionMode)
Func _GUICtrlScintilla_SetSelectionMode($hCtrl, $iSelectionMode = $SC_SEL_STREAM)
	_SendMessage($hCtrl, $SCI_SETSELECTIONMODE, $iSelectionMode)
EndFunc

;~ SCI_GETSELECTIONMODE → int
Func _GUICtrlScintilla_GetSelectionMode($hCtrl)
	Return _SendMessage($hCtrl, $SCI_GETSELECTIONMODE)
EndFunc

;~ SCI_GETMOVEEXTENDSSELECTION → bool
Func _GUICtrlScintilla_GetMoveExtendsSelection($hCtrl)
	Return _SendMessage($hCtrl, $SCI_GETMOVEEXTENDSSELECTION, 0, 0, 0, "wparam", "lparam", "bool")
EndFunc

;~ SCI_GETLINESELSTARTPOSITION(line line) → position
Func _GUICtrlScintilla_GetLineSelStartPosition($hCtrl, $iLine)
	Return _SendMessage($hCtrl, $SCI_GETLINESELSTARTPOSITION, $iLine)
EndFunc

;~ SCI_GETLINESELENDPOSITION(line line) → position
Func _GUICtrlScintilla_GetLineSelEndPosition($hCtrl, $iLine)
	Return _SendMessage($hCtrl, $SCI_GETLINESELENDPOSITION, $iLine)
EndFunc

;~ SCI_MOVECARETINSIDEVIEW
Func _GUICtrlScintilla_MoveCaretInsideView($hCtrl)
	_SendMessage($hCtrl, $SCI_MOVECARETINSIDEVIEW)
EndFunc

;~ SCI_POSITIONBEFORE(position pos) → position
Func _GUICtrlScintilla_PositionBefore($hCtrl, $iPos)
	Return _SendMessage($hCtrl, $SCI_POSITIONBEFORE, $iPos)
EndFunc

;~ SCI_POSITIONAFTER(position pos) → position
Func _GUICtrlScintilla_PositionAfter($hCtrl, $iPos)
	Return _SendMessage($hCtrl, $SCI_POSITIONAFTER, $iPos)
EndFunc

;~ SCI_TEXTWIDTH(int style, const char *text) → int
Func _GUICtrlScintilla_TextWidth($hCtrl, $iStyle, $sText)
	Local $tBuf = __guiScintilla_str2bin($sText)
	Return _SendMessage($hCtrl, $SCI_TEXTWIDTH, $iStyle, $tBuf, 0, "int_ptr", "struct*")
EndFunc

;~ SCI_TEXTHEIGHT(line line) → int
Func _GUICtrlScintilla_TextHeight($hCtrl, $iLine)
	Return _SendMessage($hCtrl, $SCI_TEXTHEIGHT, $iLine)
EndFunc

;~ SCI_CHOOSECARETX
;~ SCI_MOVESELECTEDLINESUP
;~ SCI_MOVESELECTEDLINESDOWN
;~ SCI_SETMOUSESELECTIONRECTANGULARSWITCH(bool mouseSelectionRectangularSwitch)
;~ SCI_GETMOUSESELECTIONRECTANGULARSWITCH → bool

#EndRegion

#Region By character or UTF-16 code unit ==========================================================

;~ SCI_POSITIONRELATIVE(position pos, position relative) → position
;~ SCI_POSITIONRELATIVECODEUNITS(position pos, position relative) → position
;~ SCI_COUNTCHARACTERS(position start, position end) → position
;~ SCI_COUNTCODEUNITS(position start, position end) → position
;~ SCI_GETLINECHARACTERINDEX → int
;~ SCI_ALLOCATELINECHARACTERINDEX(int lineCharacterIndex)
;~ SCI_RELEASELINECHARACTERINDEX(int lineCharacterIndex)
;~ SCI_LINEFROMINDEXPOSITION(position pos, int lineCharacterIndex) → line
;~ SCI_INDEXPOSITIONFROMLINE(line line, int lineCharacterIndex) → position

#EndRegion

#Region Multiple Selection and Virtual Space ======================================================
#EndRegion

#Region Scrolling and automatic scrolling =========================================================

;~ SCI_SETFIRSTVISIBLELINE(line displayLine)
Func _GUICtrlScintilla_SetFirstVisibleLine($hCtrl, $iDisplayLine)
	_SendMessage($hCtrl, $SCI_SETFIRSTVISIBLELINE, $iDisplayLine)
EndFunc

;~ SCI_GETFIRSTVISIBLELINE → line
Func _GUICtrlScintilla_GetFirstVisibleLine($hCtrl)
	Return _SendMessage($hCtrl, $SCI_GETFIRSTVISIBLELINE)
EndFunc

;~ SCI_SETXOFFSET(int xOffset)
Func _GUICtrlScintilla_SetXOffset($hCtrl, $iXOffset)
	_SendMessage($hCtrl, $SCI_SETXOFFSET, $iXOffset)
EndFunc

;~ SCI_GETXOFFSET → int
Func _GUICtrlScintilla_GetXOffset($hCtrl)
	Return _SendMessage($hCtrl, $SCI_GETXOFFSET)
EndFunc

;~ SCI_LINESCROLL(position columns, line lines)
Func _GUICtrlScintilla_LineScroll($hCtrl, $iColumns, $iLines)
	_SendMessage($hCtrl, $SCI_LINESCROLL, $iColumns, $iLines)
EndFunc

;~ SCI_SCROLLCARET
Func _GUICtrlScintilla_ScrollCaret($hCtrl)
	_SendMessage($hCtrl, $SCI_SCROLLCARET)
EndFunc

;~ SCI_SCROLLRANGE(position secondary, position primary)
Func _GUICtrlScintilla_ScrollRange($hCtrl, $iSecondary, $iPrimary)
	_SendMessage($hCtrl, $SCI_SCROLLRANGE, $iSecondary, $iPrimary)
EndFunc

;~ SCI_SETXCARETPOLICY(int caretPolicy, int caretSlop)
;~ SCI_SETYCARETPOLICY(int caretPolicy, int caretSlop)
Func _GUICtrlScintilla_SetCaretPolicy($hCtrl, $iXPolicy = Default, $iXSlop = Default, $iYPolicy = Default, $iYSlop = Default)
	If $iXPolicy <> Default And $iXSlop <> Default Then _SendMessage($hCtrl, $SCI_SETXCARETPOLICY, $iXPolicy, $iXSlop)
	If $iYPolicy <> Default And $iYSlop <> Default Then _SendMessage($hCtrl, $SCI_SETYCARETPOLICY, $iYPolicy, $iYSlop)
EndFunc

;~ SCI_SETVISIBLEPOLICY(int visiblePolicy, int visibleSlop)
Func _GUICtrlScintilla_SetVisiblePolicy($hCtrl, $iPolicy, $iSlop)
	_SendMessage($hCtrl, $SCI_SETVISIBLEPOLICY, $iPolicy, $iSlop)
EndFunc

;~ SCI_SETHSCROLLBAR(bool visible)
;~ SCI_SETVSCROLLBAR(bool visible)
Func _GUICtrlScintilla_SetScrollBars($hCtrl, $bHorizontalVisible = Default, $bVerticalVisible = Default)
	If $bHorizontalVisible <> Default Then _SendMessage($hCtrl, $SCI_SETHSCROLLBAR, $bHorizontalVisible, 0, 0, "bool")
	If $bVerticalVisible <> Default Then _SendMessage($hCtrl, $SCI_SETVSCROLLBAR, $bVerticalVisible, 0, 0, "bool")
EndFunc

;~ SCI_GETHSCROLLBAR → bool
;~ SCI_GETVSCROLLBAR → bool
Func _GUICtrlScintilla_GetScrollBars($hCtrl)
	Local $aRet[] = [ _
		_SendMessage($hCtrl, $SCI_GETHSCROLLBAR, 0, 0, 0, "wparam", "lparam", "bool"), _
		_SendMessage($hCtrl, $SCI_GETVSCROLLBAR, 0, 0, 0, "wparam", "lparam", "bool") _
	]
	Return $aRet
EndFunc

;~ SCI_SETSCROLLWIDTH(int pixelWidth)
Func _GUICtrlScintilla_SetScrollWidth($hCtrl, $iPixelWidth)
	_SendMessage($hCtrl, $SCI_SETSCROLLWIDTH, $iPixelWidth)
EndFunc

;~ SCI_GETSCROLLWIDTH → int
Func _GUICtrlScintilla_GetScrollWidth($hCtrl)
	Return _SendMessage($hCtrl, $SCI_GETSCROLLWIDTH)
EndFunc

;~ SCI_SETSCROLLWIDTHTRACKING(bool tracking)
Func _GUICtrlScintilla_SetScrollWidthTracking($hCtrl, $bTracking)
	_SendMessage($hCtrl, $SCI_SETSCROLLWIDTHTRACKING, $bTracking, 0, 0, "bool")
EndFunc

;~ SCI_GETSCROLLWIDTHTRACKING → bool
Func _GUICtrlScintilla_GetScrollWidthTracking($hCtrl)
	Return _SendMessage($hCtrl, $SCI_GETSCROLLWIDTHTRACKING, 0, 0, 0, "wparam", "lparam", "bool")
EndFunc

;~ SCI_SETENDATLASTLINE(bool endAtLastLine)
Func _GUICtrlScintilla_SetEndAtLastLine($hCtrl, $bEndAtLastLine = True)
	_SendMessage($hCtrl, $SCI_SETENDATLASTLINE, $bEndAtLastLine, 0, 0, "bool")
EndFunc

;~ SCI_GETENDATLASTLINE → bool
Func _GUICtrlScintilla_GetEndAtLastLine($hCtrl)
	Return _SendMessage($hCtrl, $SCI_GETENDATLASTLINE, 0, 0, 0, "wparam", "lparam", "bool")
EndFunc

#EndRegion

#Region White space ===============================================================================
#EndRegion

#Region Cursor ====================================================================================

;~ SCI_SETCURSOR(int cursorType)
Func _GUICtrlScintilla_SetCursor($hCtrl, $iCursorType = -1)
	_SendMessage($hCtrl, $SCI_SETCURSOR, $iCursorType)
EndFunc

;~ SCI_GETCURSOR → int
Func _GUICtrlScintilla_GetCursor($hCtrl)
	Return _SendMessage($hCtrl, $SCI_GETCURSOR)
EndFunc

#EndRegion

#Region Mouse capture =============================================================================

;~ SCI_SETMOUSEDOWNCAPTURES(bool captures)
;~ SCI_GETMOUSEDOWNCAPTURES → bool
;~ SCI_SETMOUSEWHEELCAPTURES(bool captures)
;~ SCI_GETMOUSEWHEELCAPTURES → bool

#EndRegion

#Region Line endings ==============================================================================

;~ SCI_SETEOLMODE(int eolMode)
;~ SCI_GETEOLMODE → int
;~ SCI_CONVERTEOLS(int eolMode)
;~ SCI_SETVIEWEOL(bool visible)
;~ SCI_GETVIEWEOL → bool
;~ SCI_GETLINEENDTYPESSUPPORTED → int
;~ SCI_SETLINEENDTYPESALLOWED(int lineEndBitSet)
;~ SCI_GETLINEENDTYPESALLOWED → int
;~ SCI_GETLINEENDTYPESACTIVE → int

#EndRegion

#Region Words =====================================================================================

;~ SCI_WORDENDPOSITION(position pos, bool onlyWordCharacters) → position
;~ SCI_WORDSTARTPOSITION(position pos, bool onlyWordCharacters) → position
Func _GUICtrlScintilla_WordPosition($hCtrl, $iPos, $bOnlyWordCharacters = True)
	Local $aRet[] = [ _
		_SendMessage($hCtrl, $SCI_WORDSTARTPOSITION, $iPos, $bOnlyWordCharacters, 0, "wparam", "bool"), _
		_SendMessage($hCtrl, $SCI_WORDENDPOSITION, $iPos, $bOnlyWordCharacters, 0, "wparam", "bool") _
	]
	Return $aRet
EndFunc

;~ SCI_ISRANGEWORD(position start, position end) → bool
Func _GUICtrlScintilla_IsRangeWord($hCtrl, $iStart, $iEnd)
	Return _SendMessage($hCtrl, $SCI_ISRANGEWORD, $iStart, $iEnd, 0, "wparam", "lparam", "bool")
EndFunc

;~ SCI_SETWORDCHARS(<unused>, const char *characters)
Func _GUICtrlScintilla_SetWordChars($hCtrl, $sCharacters)
	Local $tBuf = __guiScintilla_str2bin($sCharacters)
	_SendMessage($hCtrl, $SCI_SETWORDCHARS, 0, $tBuf, 0, "wparam", "struct*")
EndFunc

;~ SCI_GETWORDCHARS(<unused>, char *characters) → int
Func _GUICtrlScintilla_GetWordChars($hCtrl)
	Local $iLen = _SendMessage($hCtrl, $SCI_GETWORDCHARS)
	If $iLen <= 0 Then Return ""

	Local $tBuf = DllStructCreate("byte[" & $iLen & "]")
	_SendMessage($hCtrl, $SCI_GETWORDCHARS, 0, $tBuf, 0, "wparam", "struct*")
	Return __guiScintilla_bin2str($tBuf, False)
EndFunc

;~ SCI_SETWHITESPACECHARS(<unused>, const char *characters)
Func _GUICtrlScintilla_SetWhitespaceChars($hCtrl, $sCharacters)
	Local $tBuf = __guiScintilla_str2bin($sCharacters)
	_SendMessage($hCtrl, $SCI_SETWHITESPACECHARS, 0, $tBuf, 0, "wparam", "struct*")
EndFunc

;~ SCI_GETWHITESPACECHARS(<unused>, char *characters) → int
Func _GUICtrlScintilla_GetwhitespaceChars($hCtrl)
	Local $iLen = _SendMessage($hCtrl, $SCI_GETWORDCHARS)
	If $iLen <= 0 Then Return ""

	Local $tBuf = DllStructCreate("byte[" & $iLen & "]")
	_SendMessage($hCtrl, $SCI_GETWHITESPACECHARS, 0, $tBuf, 0, "wparam", "struct*")
	Return __guiScintilla_bin2str($tBuf, False)
EndFunc

;~ SCI_SETPUNCTUATIONCHARS(<unused>, const char *characters)
Func _GUICtrlScintilla_SetPunctuationChars($hCtrl, $sCharacters)
	Local $tBuf = __guiScintilla_str2bin($sCharacters)
	_SendMessage($hCtrl, $SCI_SETPUNCTUATIONCHARS, 0, $tBuf, 0, "wparam", "struct*")
EndFunc

;~ SCI_GETPUNCTUATIONCHARS(<unused>, char *characters) → int
Func _GUICtrlScintilla_GetPunctuationChars($hCtrl)
	Local $iLen = _SendMessage($hCtrl, $SCI_GETWORDCHARS)
	If $iLen <= 0 Then Return ""

	Local $tBuf = DllStructCreate("byte[" & $iLen & "]")
	_SendMessage($hCtrl, $SCI_GETPUNCTUATIONCHARS, 0, $tBuf, 0, "wparam", "struct*")
	Return __guiScintilla_bin2str($tBuf, False)
EndFunc

;~ SCI_SETCHARSDEFAULT
Func _GUICtrlScintilla_SetCharsDefault($hCtrl)
	_SendMessage($hCtrl, $SCI_SETCHARSDEFAULT)
EndFunc

;~ SCI_SETCHARACTERCATEGORYOPTIMIZATION(int countCharacters)
Func _GUICtrlScintilla_SetCharacterCategoryOptimization($hCtrl, $iCountCharacters)
	_SendMessage($hCtrl, $SCI_SETCHARACTERCATEGORYOPTIMIZATION, $iCountCharacters)
EndFunc

;~ SCI_GETCHARACTERCATEGORYOPTIMIZATION → int
Func _GUICtrlScintilla_GetCharacterCategoryOptimization($hCtrl)
	Return _SendMessage($hCtrl, $SCI_GETCHARACTERCATEGORYOPTIMIZATION)
EndFunc

#EndRegion

#Region Styling ===================================================================================

;~ SCI_GETENDSTYLED → position
Func _GUICtrlScintilla_GetEndStyled($hCtrl)
	Return _SendMessage($hCtrl, $SCI_GETENDSTYLED)
EndFunc

;~ SCI_STARTSTYLING(position start, int unused)
Func _GUICtrlScintilla_StartStyling($hCtrl, $iStart)
	_SendMessage($hCtrl, $SCI_STARTSTYLING, $iStart)
EndFunc

;~ SCI_SETSTYLING(position length, int style)
;~ SCI_SETSTYLINGEX(position length, const char *styles)
Func _GUICtrlScintilla_SetStyling($hCtrl, $vStyles, $iLength = 1)
	If IsArray($vStyles) Then
		Local $tStyles = DllStructCreate("byte[" & UBound($vStyles) & "]")
		DllStructSetData($tStyles, 1, $vStyles)
		_SendMessage($hCtrl, $SCI_SETSTYLINGEX, UBound($vStyles), $tStyles, 0, "wparam", "struct*")
	Else
		_SendMessage($hCtrl, $SCI_SETSTYLING, $iLength, $vStyles)
	EndIf
EndFunc

;~ SCI_SETIDLESTYLING(int idleStyling)
Func _GUICtrlScintilla_SetIdleStyling($hCtrl, $iIdleStyling = $SC_IDLESTYLING_NONE)
	_SendMessage($hCtrl, $SCI_SETIDLESTYLING, $iIdleStyling)
EndFunc

;~ SCI_GETIDLESTYLING → int
Func _GUICtrlScintilla_GetIdleStyling($hCtrl)
	Return _SendMessage($hCtrl, $SCI_GETIDLESTYLING)
EndFunc

;~ SCI_SETLINESTATE(line line, int state)
Func _GUICtrlScintilla_SetLineState($hCtrl, $iLine, $iState)
	_SendMessage($hCtrl, $SCI_SETLINESTATE, $iLine, $iState)
EndFunc

;~ SCI_GETLINESTATE(line line) → int
Func _GUICtrlScintilla_GetLineState($hCtrl, $iLine)
	Return _SendMessage($hCtrl, $SCI_GETLINESTATE, $iLine)
EndFunc

;~ SCI_GETMAXLINESTATE → int
Func _GUICtrlScintilla_GetMaxLineState($hCtrl)
	Return _SendMessage($hCtrl, $SCI_GETMAXLINESTATE)
EndFunc

#EndRegion

#Region Style definition ==========================================================================

;~ SCI_STYLERESETDEFAULT
Func _GUICtrlScintilla_StyleResetDefault($hCtrl)
	_SendMessage($hCtrl, $SCI_STYLERESETDEFAULT)
EndFunc

;~ SCI_STYLECLEARALL
Func _GUICtrlScintilla_StyleClearAll($hCtrl)
	_SendMessage($hCtrl, $SCI_STYLECLEARALL)
EndFunc

;~ SCI_STYLESETFONT(int style, const char *fontName)
Func _GUICtrlScintilla_StyleSetFont($hCtrl, $iStyle, $sFontName)
	_SendMessage($hCtrl, $SCI_STYLESETFONT, $iStyle, $sFontName, 0, "int_ptr", "str*")
EndFunc

;~ SCI_STYLEGETFONT(int style, char *fontName) → int
Func _GUICtrlScintilla_StyleGetFont($hCtrl, $iStyle)
	Local $iLen = _SendMessage($hCtrl, $SCI_STYLEGETFONT, $iStyle, 0)
	Local $tBuf = DllStructCreate("byte[" & $iLen & "]")
	_SendMessage($hCtrl, $SCI_STYLEGETFONT, $iStyle, $tBuf, 0, "int_ptr", "struct*")
	Return __guiScintilla_bin2str($tBuf, False)
EndFunc

;~ SCI_STYLESETSIZE(int style, int sizePoints)
;~ SCI_STYLESETSIZEFRACTIONAL(int style, int sizeHundredthPoints)
Func _GUICtrlScintilla_StyleSetSize($hCtrl, $iStyle, $iSize)
	If IsFloat($iSize) Then
		_SendMessage($hCtrl, $SCI_STYLESETSIZEFRACTIONAL, $iStyle, Int($iSize * $SC_FONT_SIZE_MULTIPLIER))
	Else
		_SendMessage($hCtrl, $SCI_STYLESETSIZE, $iStyle, $iSize)
	EndIf
EndFunc

;~ SCI_STYLEGETSIZE(int style) → int
;~ SCI_STYLEGETSIZEFRACTIONAL(int style) → int
Func _GUICtrlScintilla_StyleGetSize($hCtrl, $iStyle)
	Return _SendMessage($hCtrl, $SCI_STYLEGETSIZEFRACTIONAL, $iStyle, 0, 0, "int_ptr", "lparam", "int_ptr") / $SC_FONT_SIZE_MULTIPLIER
EndFunc

;~ SCI_STYLESETBOLD(int style, bool bold)
Func _GUICtrlScintilla_StyleSetBold($hCtrl, $iStyle, $bBold)
	_SendMessage($hCtrl, $SCI_STYLESETBOLD, $iStyle, $bBold)
EndFunc

;~ SCI_STYLEGETBOLD(int style) → bool
Func _GUICtrlScintilla_StyleGetBold($hCtrl, $iStyle)
	Return _SendMessage($hCtrl, $SCI_STYLEGETBOLD, $iStyle, 0, 0, "int_ptr", "lparam", "bool")
EndFunc

;~ SCI_STYLESETWEIGHT(int style, int weight)
Func _GUICtrlScintilla_StyleSetWeight($hCtrl, $iStyle, $iWeight)
	_SendMessage($hCtrl, $SCI_STYLESETWEIGHT, $iStyle, $iWeight)
EndFunc

;~ SCI_STYLEGETWEIGHT(int style) → int
Func _GUICtrlScintilla_StyleGetWeight($hCtrl, $iStyle)
	Return _SendMessage($hCtrl, $SCI_STYLEGETWEIGHT, $iStyle)
EndFunc

;~ SCI_STYLESETITALIC(int style, bool italic)
Func _GUICtrlScintilla_StyleSetItalic($hCtrl, $iStyle, $bItalic)
	_SendMessage($hCtrl, $SCI_STYLESETITALIC, $iStyle, $bItalic)
EndFunc

;~ SCI_STYLEGETITALIC(int style) → bool
Func _GUICtrlScintilla_StyleGetItalic($hCtrl, $iStyle)
	Return _SendMessage($hCtrl, $SCI_STYLEGETITALIC, $iStyle, 0, 0, "int_ptr", "lparam", "bool")
EndFunc

;~ SCI_STYLESETUNDERLINE(int style, bool underline)
Func _GUICtrlScintilla_StyleSetUnderline($hCtrl, $iStyle, $bUnderline)
	_SendMessage($hCtrl, $SCI_STYLESETUNDERLINE, $iStyle, $bUnderline)
EndFunc

;~ SCI_STYLEGETUNDERLINE(int style) → bool
Func _GUICtrlScintilla_StyleGetUnderline($hCtrl, $iStyle)
	Return _SendMessage($hCtrl, $SCI_STYLEGETUNDERLINE, $iStyle, 0, 0, "int_ptr", "lparam", "bool")
EndFunc

;~ SCI_STYLESETFORE(int style, colour fore)
Func _GUICtrlScintilla_StyleSetFore($hCtrl, $iStyle, $iFore0xRRGGBB)
	_SendMessage($hCtrl, $SCI_STYLESETFORE, $iStyle, __guiCtrlScintilla_colorConvert($iFore0xRRGGBB))
EndFunc

;~ SCI_STYLEGETFORE(int style) → colour
Func _GUICtrlScintilla_StyleGetFore($hCtrl, $iStyle)
	Return __guiCtrlScintilla_colorConvert(_SendMessage($hCtrl, $SCI_STYLEGETFORE, $iStyle))
EndFunc

;~ SCI_STYLESETBACK(int style, colour back)
Func _GUICtrlScintilla_StyleSetBack($hCtrl, $iStyle, $iBack0xRRGGBB)
	_SendMessage($hCtrl, $SCI_STYLESETBACK, $iStyle, __guiCtrlScintilla_colorConvert($iBack0xRRGGBB))
EndFunc

;~ SCI_STYLEGETBACK(int style) → colour
Func _GUICtrlScintilla_StyleGetBack($hCtrl, $iStyle)
	Return __guiCtrlScintilla_colorConvert(_SendMessage($hCtrl, $SCI_STYLEGETBACK, $iStyle))
EndFunc

;~ SCI_STYLESETEOLFILLED(int style, bool eolFilled)
Func _GUICtrlScintilla_StyleSetEOLFilled($hCtrl, $iStyle = $STYLE_DEFAULT, $bEOLFilled = True)
	_SendMessage($hCtrl, $SCI_STYLESETEOLFILLED, $iStyle, $bEOLFilled)
EndFunc

;~ SCI_STYLEGETEOLFILLED(int style) → bool
Func _GUICtrlScintilla_StyleGetEOLFilled($hCtrl, $iStyle = $STYLE_DEFAULT)
	Return _SendMessage($hCtrl, $SCI_STYLEGETEOLFILLED, $iStyle, 0, 0, "int_ptr", "lparam", "bool")
EndFunc

;~ SCI_STYLESETCHARACTERSET(int style, int characterSet)
Func _GUICtrlScintilla_StyleSetCharacterSet($hCtrl, $iStyle = $STYLE_DEFAULT, $iCharacterSet = $SC_CHARSET_DEFAULT)
	_SendMessage($hCtrl, $SCI_STYLESETCHARACTERSET, $iStyle, $iCharacterSet)
EndFunc

;~ SCI_STYLEGETCHARACTERSET(int style) → int
Func _GUICtrlScintilla_StyleGetCharacterSet($hCtrl, $iStyle = $STYLE_DEFAULT)
	Return _SendMessage($hCtrl, $SCI_STYLEGETCHARACTERSET, $iStyle)
EndFunc

;~ SCI_STYLESETCASE(int style, int caseVisible)
Func _GUICtrlScintilla_StyleSetCase($hCtrl, $iStyle = $STYLE_DEFAULT, $iCaseVisible = $SC_CASE_MIXED)
	_SendMessage($hCtrl, $SCI_STYLESETCASE, $iStyle, $iCaseVisible)
EndFunc

;~ SCI_STYLEGETCASE(int style) → int
Func _GUICtrlScintilla_StyleGetCase($hCtrl, $iStyle = $STYLE_DEFAULT)
	Return _SendMessage($hCtrl, $SCI_STYLEGETCASE, $iStyle)
EndFunc

;~ SCI_STYLESETVISIBLE(int style, bool visible)
Func _GUICtrlScintilla_StyleSetVisible($hCtrl, $iStyle = $STYLE_DEFAULT, $bVisible = True)
	_SendMessage($hCtrl, $SCI_STYLESETVISIBLE, $iStyle, $bVisible)
EndFunc

;~ SCI_STYLEGETVISIBLE(int style) → bool
Func _GUICtrlScintilla_StyleGetVisible($hCtrl, $iStyle = $STYLE_DEFAULT)
	Return _SendMessage($hCtrl, $SCI_STYLEGETVISIBLE, $iStyle, 0, 0, "int_ptr", "lparam", "bool")
EndFunc

;~ SCI_STYLESETCHANGEABLE(int style, bool changeable)
Func _GUICtrlScintilla_StyleSetChangeable($hCtrl, $iStyle = $STYLE_DEFAULT, $bChangeable = True)
	_SendMessage($hCtrl, $SCI_STYLESETCHANGEABLE, $iStyle, $bChangeable)
EndFunc

;~ SCI_STYLEGETCHANGEABLE(int style) → bool
Func _GUICtrlScintilla_StyleGetChangeable($hCtrl, $iStyle = $STYLE_DEFAULT)
	Return _SendMessage($hCtrl, $SCI_STYLEGETCHANGEABLE, $iStyle, 0, 0, "int_ptr", "lparam", "bool")
EndFunc

;~ SCI_STYLESETHOTSPOT(int style, bool hotspot)
Func _GUICtrlScintilla_StyleSetHotspot($hCtrl, $iStyle = $STYLE_DEFAULT, $bHotspot = False)
	_SendMessage($hCtrl, $SCI_STYLESETHOTSPOT, $iStyle, $bHotspot)
EndFunc

;~ SCI_STYLEGETHOTSPOT(int style) → bool
Func _GUICtrlScintilla_StyleGetHotspot($hCtrl, $iStyle = $STYLE_DEFAULT)
	Return _SendMessage($hCtrl, $SCI_STYLEGETHOTSPOT, $iStyle, 0, 0, "int_ptr", "lparam", "bool")
EndFunc

;~ SCI_STYLESETCHECKMONOSPACED(int style, bool checkMonospaced)
;~ SCI_STYLEGETCHECKMONOSPACED(int style) → bool
;~ SCI_SETFONTLOCALE(<unused>, const char *localeName)
;~ SCI_GETFONTLOCALE(<unused>, char *localeName) → int

; composite functions (a la AutoIt)

Func _GUICtrlScintilla_Au3_StyleSet($hCtrl, $iStyle = $STYLE_DEFAULT, $iSize = Default, $iWeight = Default, $iAttributes = Default, $sFontName = Default)
	If $iSize <> Default Then
		If IsFloat($iSize) Then
			_SendMessage($hCtrl, $SCI_STYLESETSIZEFRACTIONAL, $iStyle, Int($iSize * $SC_FONT_SIZE_MULTIPLIER))
		Else
			_SendMessage($hCtrl, $SCI_STYLESETSIZE, $iStyle, $iSize)
		EndIf
	EndIf
	If $iWeight <> Default Then
		_SendMessage($hCtrl, $SCI_STYLESETWEIGHT, $iStyle, $iWeight)
	EndIf
	If $iAttributes <> Default Then
		If $iAttributes = 0 Then
			_SendMessage($hCtrl, $SCI_STYLESETITALIC, $iStyle, False)
			_SendMessage($hCtrl, $SCI_STYLESETUNDERLINE, $iStyle, False)
		EndIf
		If BitAND($iAttributes, 2) Then _SendMessage($hCtrl, $SCI_STYLESETITALIC, $iStyle, True)
		If BitAND($iAttributes, 4) Then _SendMessage($hCtrl, $SCI_STYLESETUNDERLINE, $iStyle, True)
	EndIf
	If $sFontName <> Default Then
		_SendMessage($hCtrl, $SCI_STYLESETFONT, $iStyle, $sFontName, 0, "int_ptr", "str")
	EndIf
EndFunc

Func _GUICtrlScintilla_Au3_StyleGet($hCtrl, $iStyle = $STYLE_DEFAULT)
	Local $aRet[4]
	; size
	$aRet[0] = _SendMessage($hCtrl, $SCI_STYLEGETSIZEFRACTIONAL, $iStyle) / $SC_FONT_SIZE_MULTIPLIER

	; weight
	$aRet[1] = _SendMessage($hCtrl, $SCI_STYLEGETWEIGHT, $iStyle)

	; attributes
	$aRet[2] = 0
	If _SendMessage($hCtrl, $SCI_STYLEGETITALIC, $iStyle) Then $aRet[2] += 2
	If _SendMessage($hCtrl, $SCI_STYLEGETUNDERLINE, $iStyle) Then $aRet[2] += 4

	; font
	Local $iLen = _SendMessage($hCtrl, $SCI_STYLEGETFONT, $iStyle, 0)
	Local $tBuf = DllStructCreate("byte[" & $iLen & "]")
	_SendMessage($hCtrl, $SCI_STYLEGETFONT, $iStyle, $tBuf, 0, "int_ptr", "struct*")
	$aRet[3] = __guiScintilla_bin2str($tBuf, False)

	Return $aRet
EndFunc

#EndRegion

#Region Element colours ===========================================================================

;~ SCI_SETELEMENTCOLOUR(int element, colouralpha colourElement)
Func _GUICtrlScintilla_SetElementColour($hCtrl, $iElement, $iColour)
	_SendMessage($hCtrl, $SCI_SETELEMENTCOLOUR, $iElement, $iColour)
EndFunc

;~ SCI_GETELEMENTCOLOUR(int element) → colouralpha
Func _GUICtrlScintilla_GetElementColout($hCtrl, $iElement)
	Return _SendMessage($hCtrl, $SCI_GETELEMENTCOLOUR, $iElement)
EndFunc

;~ SCI_RESETELEMENTCOLOUR(int element)
Func _GUICtrlScintilla_ResetElementColour($hCtrl, $iElement)
	_SendMessage($hCtrl, $SCI_RESETELEMENTCOLOUR, $iElement)
EndFunc

;~ SCI_GETELEMENTISSET(int element) → bool
Func _GUICtrlScintilla_GetElementIsSet($hCtrl, $iElement)
	Return _SendMessage($hCtrl, $SCI_GETELEMENTISSET, $iElement, 0, 0, "int_ptr", "lparam", "bool")
EndFunc

;~ SCI_GETELEMENTALLOWSTRANSLUCENT(int element) → bool
Func _GUICtrlScintilla_GetElementAllowsTranslucent($hCtrl, $iElement)
	Return _SendMessage($hCtrl, $SCI_GETELEMENTALLOWSTRANSLUCENT, $iElement, 0, 0, "int_ptr", "lparam", "bool")
EndFunc

;~ SCI_GETELEMENTBASECOLOUR(int element) → colouralpha
Func _GUICtrlScintilla_GetElementBaseColour($hCtrl, $iElement)
	Return _SendMessage($hCtrl, $SCI_GETELEMENTBASECOLOUR, $iElement)
EndFunc

#EndRegion

#Region Selection, caret, and hotspot styles ======================================================

#EndRegion

#Region Character representations =================================================================

#EndRegion

#Region Margins ===================================================================================

;~ SCI_SETMARGINS(int margins)
Func _GUICtrlScintilla_SetMargins($hCtrl, $iMargins)
	_SendMessage($hCtrl, $SCI_SETMARGINS, $iMargins)
EndFunc

;~ SCI_GETMARGINS → int
Func _GUICtrlScintilla_GetMargins($hCtrl)
	Return _SendMessage($hCtrl, $SCI_GETMARGINS)
EndFunc

;~ SCI_SETMARGINTYPEN(int margin, int marginType)
Func _GUICtrlScintilla_SetMarginTypeN($hCtrl, $iMargin, $iMarginType)
	_SendMessage($hCtrl, $SCI_SETMARGINTYPEN, $iMargin, $iMarginType)
EndFunc

;~ SCI_GETMARGINTYPEN(int margin) → int
Func _GUICtrlScintilla_GetMarginTypeN($hCtrl, $iMargin)
	Return _SendMessage($hCtrl, $SCI_GETMARGINTYPEN, $iMargin)
EndFunc

;~ SCI_SETMARGINWIDTHN(int margin, int pixelWidth)
Func _GUICtrlScintilla_SetMarginWidthN($hCtrl, $iMargin, $iPixelWidth)
	_SendMessage($hCtrl, $SCI_SETMARGINWIDTHN, $iMargin, $iPixelWidth)
EndFunc

;~ SCI_GETMARGINWIDTHN(int margin) → int
Func _GUICtrlScintilla_GetMarginWidthN($hCtrl, $iMargin)
	Return _SendMessage($hCtrl, $SCI_GETMARGINWIDTHN, $iMargin)
EndFunc

;~ SCI_SETMARGINMASKN(int margin, int mask)
Func _GUICtrlScintilla_SetMarginMaskN($hCtrl, $iMargin, $iMask)
	_SendMessage($hCtrl, $SCI_SETMARGINMASKN, $iMargin, $iMask)
EndFunc

;~ SCI_GETMARGINMASKN(int margin) → int
Func _GUICtrlScintilla_GetMarginMaskN($hCtrl, $iMargin)
	Return _SendMessage($hCtrl, $SCI_GETMARGINMASKN, $iMargin)
EndFunc

;~ SCI_SETMARGINSENSITIVEN(int margin, bool sensitive)
Func _GUICtrlScintilla_SetMarginSensitiveN($hCtrl, $iMargin, $bSensitive)
	_SendMessage($hCtrl, $SCI_SETMARGINSENSITIVEN, $iMargin, $bSensitive, 0, "int_ptr", "bool")
EndFunc

;~ SCI_GETMARGINSENSITIVEN(int margin) → bool
Func _GUICtrlScintilla_GetMarginSensitiveN($hCtrl, $iMargin)
	Return _SendMessage($hCtrl, $SCI_GETMARGINSENSITIVEN, $iMargin, 0, 0, "int_ptr", "lparam", "bool")
EndFunc

;~ SCI_SETMARGINCURSORN(int margin, int cursor)
Func _GUICtrlScintilla_SetMarginCursorN($hCtrl, $iMargin, $iCursor)
	_SendMessage($hCtrl, $SCI_SETMARGINCURSORN, $iMargin, $iCursor)
EndFunc

;~ SCI_GETMARGINCURSORN(int margin) → int
Func _GUICtrlScintilla_GetMarginCursorN($hCtrl, $iMargin)
	Return _SendMessage($hCtrl, $SCI_GETMARGINCURSORN, $iMargin)
EndFunc

;~ SCI_SETMARGINBACKN(int margin, colour back)
Func _GUICtrlScintilla_SetMarginBackN($hCtrl, $iMargin, $iColor = Default)
	_SendMessage($hCtrl, $SCI_SETMARGINBACKN, $iMargin, $iColor)
EndFunc

;~ SCI_GETMARGINBACKN(int margin) → colour
Func _GUICtrlScintilla_GetMarginBackN($hCtrl, $iMargin)
	Return _SendMessage($hCtrl, $SCI_GETMARGINBACKN, $iMargin)
EndFunc

;~ SCI_SETMARGINLEFT(<unused>, int pixelWidth)
;~ SCI_SETMARGINRIGHT(<unused>, int pixelWidth)
Func _GUICtrlScintilla_SetMargin($hCtrl, $iPixelWidthLeft = Default, $iPixelWidthRight = Default)
	If $iPixelWidthLeft <> Default Then _SendMessage($hCtrl, $SCI_SETMARGINLEFT, 0, $iPixelWidthLeft)
	If $iPixelWidthRight <> Default Then _SendMessage($hCtrl, $SCI_SETMARGINRIGHT, 0, $iPixelWidthRight)
EndFunc

;~ SCI_GETMARGINLEFT → int
;~ SCI_GETMARGINRIGHT → int
Func _GUICtrlScintilla_GetMargin($hCtrl)
	Local $aRet[] = [_SendMessage($hCtrl, $SCI_GETMARGINLEFT), _SendMessage($hCtrl, $SCI_GETMARGINRIGHT)]
	Return $aRet
EndFunc

;~ SCI_SETFOLDMARGINCOLOUR(bool useSetting, colour back)
;~ SCI_SETFOLDMARGINHICOLOUR(bool useSetting, colour fore)
Func _GUICtrlScintilla_SetFoldMarginColors($hCtrl, $bUseSetting = True, $iColorBack = Default, $iColorFore = Default)
	If $iColorBack <> Default Then _SendMessage($hCtrl, $SCI_SETFOLDMARGINCOLOUR, $bUseSetting, __guiCtrlScintilla_colorConvert($iColorBack), 0, "bool")
	If $iColorFore <> Default Then _SendMessage($hCtrl, $SCI_SETFOLDMARGINHICOLOUR, $bUseSetting, __guiCtrlScintilla_colorConvert($iColorFore), 0, "bool")
EndFunc

;~ SCI_MARGINSETTEXT(line line, const char *text)
;~ SCI_MARGINGETTEXT(line line, char *text) → int
;~ SCI_MARGINSETSTYLE(line line, int style)
;~ SCI_MARGINGETSTYLE(line line) → int
;~ SCI_MARGINSETSTYLES(line line, const char *styles)
;~ SCI_MARGINGETSTYLES(line line, char *styles) → int
;~ SCI_MARGINTEXTCLEARALL
;~ SCI_MARGINSETSTYLEOFFSET(int style)
;~ SCI_MARGINGETSTYLEOFFSET → int
;~ SCI_SETMARGINOPTIONS(int marginOptions)
;~ SCI_GETMARGINOPTIONS → int

#EndRegion

#Region Annotations ===============================================================================

;~ SCI_ANNOTATIONSETTEXT(line line, const char *text)
;~ SCI_ANNOTATIONGETTEXT(line line, char *text) → int
;~ SCI_ANNOTATIONSETSTYLE(line line, int style)
;~ SCI_ANNOTATIONGETSTYLE(line line) → int
;~ SCI_ANNOTATIONSETSTYLES(line line, const char *styles)
;~ SCI_ANNOTATIONGETSTYLES(line line, char *styles) → int
;~ SCI_ANNOTATIONGETLINES(line line) → int
;~ SCI_ANNOTATIONCLEARALL
;~ SCI_ANNOTATIONSETVISIBLE(int visible)
;~ SCI_ANNOTATIONGETVISIBLE → int
;~ SCI_ANNOTATIONSETSTYLEOFFSET(int style)
;~ SCI_ANNOTATIONGETSTYLEOFFSET → int

#EndRegion

#Region End of Line Annotations ===================================================================

;~ SCI_EOLANNOTATIONSETTEXT(line line, const char *text)
;~ SCI_EOLANNOTATIONGETTEXT(line line, char *text) → int
;~ SCI_EOLANNOTATIONSETSTYLE(line line, int style)
;~ SCI_EOLANNOTATIONGETSTYLE(line line) → int
;~ SCI_EOLANNOTATIONCLEARALL
;~ SCI_EOLANNOTATIONSETVISIBLE(int visible)
;~ SCI_EOLANNOTATIONGETVISIBLE → int
;~ SCI_EOLANNOTATIONSETSTYLEOFFSET(int style)
;~ SCI_EOLANNOTATIONGETSTYLEOFFSET → int

#EndRegion

#Region Other settings ============================================================================

;~ SCI_SETBUFFEREDDRAW(bool buffered)
Func _GUICtrlScintilla_SetBufferedDraw($hCtrl, $bBuffered)
	_SendMessage($hCtrl, $SCI_SETBUFFEREDDRAW, $bBuffered, 0, 0, "bool")
EndFunc

;~ SCI_GETBUFFEREDDRAW → bool
Func _GUICtrlScintilla_GetBufferedDraw($hCtrl)
	Return _SendMessage($hCtrl, $SCI_GETBUFFEREDDRAW, 0, 0, 0, "wparam", "lparam", "bool")
EndFunc

;~ SCI_SETPHASESDRAW(int phases)
Func _GUICtrlScintilla_SetPhasesDraw($hCtrl, $iPhases)
	_SendMessage($hCtrl, $SCI_SETPHASESDRAW, $iPhases)
EndFunc

;~ SCI_GETPHASESDRAW → int
Func _GUICtrlScintilla_GetPhasesDraw($hCtrl)
	Return _SendMessage($hCtrl, $SCI_GETPHASESDRAW)
EndFunc

;~ SCI_SETTECHNOLOGY(int technology)
Func _GUICtrlScintilla_SetTechnology($hCtrl, $iTechnology = $SC_TECHNOLOGY_DEFAULT)
	_SendMessage($hCtrl, $SCI_SETTECHNOLOGY, $iTechnology)
EndFunc

;~ SCI_GETTECHNOLOGY → int
Func _GUICtrlScintilla_GetTechnology($hCtrl)
	Return _SendMessage($hCtrl, $SCI_GETTECHNOLOGY)
EndFunc

;~ SCI_SETFONTQUALITY(int fontQuality)
Func _GUICtrlScintilla_SetFontQuality($hCtrl, $iFontQuality = $SC_EFF_QUALITY_DEFAULT)
	_SendMessage($hCtrl, $SCI_SETFONTQUALITY, $iFontQuality)
EndFunc

;~ SCI_GETFONTQUALITY → int
Func _GUICtrlScintilla_GetFontQuality($hCtrl)
	Return _SendMessage($hCtrl, $SCI_GETFONTQUALITY)
EndFunc

;~ SCI_SETCODEPAGE(int codePage)
Func _GUICtrlScintilla_SetCodePage($hCtrl, $iCodePage = $SC_CP_UTF8)
	_SendMessage($hCtrl, $SCI_SETCODEPAGE, $iCodePage)
EndFunc

;~ SCI_GETCODEPAGE → int
Func _GUICtrlScintilla_GetCodePage($hCtrl)
	Return _SendMessage($hCtrl, $SCI_GETCODEPAGE)
EndFunc

;~ SCI_SETIMEINTERACTION(int imeInteraction)
;~ SCI_GETIMEINTERACTION → int

;~ SCI_SETBIDIRECTIONAL(int bidirectional) ; experimental and incomplete
;~ SCI_GETBIDIRECTIONAL → int

;~ SCI_GRABFOCUS
Func _GUICtrlScintilla_GrabFocus($hCtrl)
	_SendMessage($hCtrl, $SCI_GRABFOCUS)
EndFunc

;~ SCI_SETFOCUS(bool focus)
Func _GUICtrlScintilla_SetFocus($hCtrl, $bFocus)
	_SendMessage($hCtrl, $SCI_SETFOCUS, $bFocus, 0, 0, "bool")
EndFunc

;~ SCI_GETFOCUS → bool
Func _GUICtrlScintilla_GetFocus($hCtrl)
	Return _SendMessage($hCtrl, $SCI_GETFOCUS, 0, 0, 0, "wparam", "lparam", "bool")
EndFunc

;~ SCI_SUPPORTSFEATURE(int feature) → bool

#EndRegion

#Region Brace highlighting ========================================================================

;~ SCI_BRACEHIGHLIGHT(position posA, position posB)
;~ SCI_BRACEBADLIGHT(position pos)
;~ SCI_BRACEHIGHLIGHTINDICATOR(bool useSetting, int indicator)
;~ SCI_BRACEBADLIGHTINDICATOR(bool useSetting, int indicator)
;~ SCI_BRACEMATCH(position pos, int maxReStyle) → position
;~ SCI_BRACEMATCHNEXT(position pos, position startPos) → position

#EndRegion

#Region Tabs and Indentation Guides ===============================================================

;~ SCI_SETTABWIDTH(int tabWidth)
Func _GUICtrlScintilla_SetTabWidth($hCtrl, $iTabWidth)
	_SendMessage($hCtrl, $SCI_SETTABWIDTH, $iTabWidth)
EndFunc

;~ SCI_GETTABWIDTH → int
Func _GUICtrlScintilla_GetTabWidth($hCtrl)
	Return _SendMessage($hCtrl, $SCI_GETTABWIDTH)
EndFunc

;~ SCI_SETTABMINIMUMWIDTH(int pixels)
;~ SCI_GETTABMINIMUMWIDTH → int
;~ SCI_CLEARTABSTOPS(line line)
;~ SCI_ADDTABSTOP(line line, int x)
;~ SCI_GETNEXTTABSTOP(line line, int x) → int
;~ SCI_SETUSETABS(bool useTabs)
;~ SCI_GETUSETABS → bool
;~ SCI_SETINDENT(int indentSize)
;~ SCI_GETINDENT → int
;~ SCI_SETTABINDENTS(bool tabIndents)
;~ SCI_GETTABINDENTS → bool
;~ SCI_SETBACKSPACEUNINDENTS(bool bsUnIndents)
;~ SCI_GETBACKSPACEUNINDENTS → bool
;~ SCI_SETLINEINDENTATION(line line, int indentation)
;~ SCI_GETLINEINDENTATION(line line) → int
;~ SCI_GETLINEINDENTPOSITION(line line) → position
;~ SCI_SETINDENTATIONGUIDES(int indentView)
;~ SCI_GETINDENTATIONGUIDES → int
;~ SCI_SETHIGHLIGHTGUIDE(position column)
;~ SCI_GETHIGHLIGHTGUIDE → position

#EndRegion

#Region Markers ===================================================================================

;~ SCI_MARKERDEFINE(int markerNumber, int markerSymbol)
;~ SCI_MARKERDEFINEPIXMAP(int markerNumber, const char *pixmap)
;~ SCI_RGBAIMAGESETWIDTH(int width)
;~ SCI_RGBAIMAGESETHEIGHT(int height)
;~ SCI_RGBAIMAGESETSCALE(int scalePercent)
;~ SCI_MARKERDEFINERGBAIMAGE(int markerNumber, const char *pixels)
;~ SCI_MARKERSYMBOLDEFINED(int markerNumber) → int
;~ SCI_MARKERSETFORE(int markerNumber, colour fore)
;~ SCI_MARKERSETFORETRANSLUCENT(int markerNumber, colouralpha fore)
;~ SCI_MARKERSETBACK(int markerNumber, colour back)
;~ SCI_MARKERSETBACKTRANSLUCENT(int markerNumber, colouralpha back)
;~ SCI_MARKERSETBACKSELECTED(int markerNumber, colour back)
;~ SCI_MARKERSETBACKSELECTEDTRANSLUCENT(int markerNumber, colouralpha back)
;~ SCI_MARKERSETSTROKEWIDTH(int markerNumber, int hundredths)
;~ SCI_MARKERENABLEHIGHLIGHT(bool enabled)
;~ SCI_MARKERSETLAYER(int markerNumber, int layer)
;~ SCI_MARKERGETLAYER(int markerNumber) → int
;~ SCI_MARKERSETALPHA(int markerNumber, alpha alpha)
;~ SCI_MARKERADD(line line, int markerNumber) → int
;~ SCI_MARKERADDSET(line line, int markerSet)
;~ SCI_MARKERDELETE(line line, int markerNumber)
;~ SCI_MARKERDELETEALL(int markerNumber)
;~ SCI_MARKERGET(line line) → int
;~ SCI_MARKERNEXT(line lineStart, int markerMask) → line
;~ SCI_MARKERPREVIOUS(line lineStart, int markerMask) → line
;~ SCI_MARKERLINEFROMHANDLE(int markerHandle) → line
;~ SCI_MARKERDELETEHANDLE(int markerHandle)
;~ SCI_MARKERHANDLEFROMLINE(line line, int which) → int
;~ SCI_MARKERNUMBERFROMLINE(line line, int which) → int

#EndRegion

#Region Indicators ================================================================================

;~ SCI_INDICSETSTYLE(int indicator, int indicatorStyle)
;~ SCI_INDICGETSTYLE(int indicator) → int
;~ SCI_INDICSETFORE(int indicator, colour fore)
;~ SCI_INDICGETFORE(int indicator) → colour
;~ SCI_INDICSETSTROKEWIDTH(int indicator, int hundredths)
;~ SCI_INDICGETSTROKEWIDTH(int indicator) → int
;~ SCI_INDICSETALPHA(int indicator, alpha alpha)
;~ SCI_INDICGETALPHA(int indicator) → int
;~ SCI_INDICSETOUTLINEALPHA(int indicator, alpha alpha)
;~ SCI_INDICGETOUTLINEALPHA(int indicator) → int
;~ SCI_INDICSETUNDER(int indicator, bool under)
;~ SCI_INDICGETUNDER(int indicator) → bool
;~ SCI_INDICSETHOVERSTYLE(int indicator, int indicatorStyle)
;~ SCI_INDICGETHOVERSTYLE(int indicator) → int
;~ SCI_INDICSETHOVERFORE(int indicator, colour fore)
;~ SCI_INDICGETHOVERFORE(int indicator) → colour
;~ SCI_INDICSETFLAGS(int indicator, int flags)
;~ SCI_INDICGETFLAGS(int indicator) → int

;~ SCI_SETINDICATORCURRENT(int indicator)
;~ SCI_GETINDICATORCURRENT → int
;~ SCI_SETINDICATORVALUE(int value)
;~ SCI_GETINDICATORVALUE → int
;~ SCI_INDICATORFILLRANGE(position start, position lengthFill)
;~ SCI_INDICATORCLEARRANGE(position start, position lengthClear)
;~ SCI_INDICATORALLONFOR(position pos) → int
;~ SCI_INDICATORVALUEAT(int indicator, position pos) → int
;~ SCI_INDICATORSTART(int indicator, position pos) → position
;~ SCI_INDICATOREND(int indicator, position pos) → position
;~ SCI_FINDINDICATORSHOW(position start, position end)
;~ SCI_FINDINDICATORFLASH(position start, position end)
;~ SCI_FINDINDICATORHIDE

#EndRegion

#Region Autocompletion ============================================================================

;~ SCI_AUTOCSHOW(position lengthEntered, const char *itemList)
Func _GUICtrlScintilla_AutoCShow($hCtrl, $iLengthEntered, $sItemList)
	Local $tBuf = __guiScintilla_str2bin($sItemList)
	_SendMessage($hCtrl, $SCI_AUTOCSHOW, $iLengthEntered, $tBuf, 0, "wparam", "struct*")
EndFunc

;~ SCI_AUTOCCANCEL
Func _GUICtrlScintilla_AutoCCancel($hCtrl)
	_SendMessage($hCtrl, $SCI_AUTOCCANCEL)
EndFunc

;~ SCI_AUTOCACTIVE → bool
Func _GUICtrlScintilla_AutoCActive($hCtrl)
	Return _SendMessage($hCtrl, $SCI_AUTOCACTIVE, 0, 0, 0, "wparam", "lparam", "bool")
EndFunc

;~ SCI_AUTOCPOSSTART → position
Func _GUICtrlScintilla_AutoCPosStart($hCtrl)
	Return _SendMessage($hCtrl, $SCI_AUTOCPOSSTART)
EndFunc

;~ SCI_AUTOCCOMPLETE
Func _GUICtrlScintilla_AutoCComplete($hCtrl)
	_SendMessage($hCtrl, $SCI_AUTOCCOMPLETE)
EndFunc

;~ SCI_AUTOCSTOPS(<unused>, const char *characterSet)
Func _GUICtrlScintilla_AutoCStops($hCtrl, $sCharacterSet)
	Local $tBuf = __guiScintilla_str2bin($sCharacterSet)
	_SendMessage($hCtrl, $SCI_AUTOCSTOPS, 0, $tBuf, 0, "wparam", "struct*")
EndFunc

;~ SCI_AUTOCSETSEPARATOR(int separatorCharacter)
Func _GUICtrlScintilla_AutoCSetSeparator($hCtrl, $sSeparatorCharacter)
	_SendMessage($hCtrl, $SCI_AUTOCSETSEPARATOR, Asc(StringLeft($sSeparatorCharacter, 1)))
EndFunc

;~ SCI_AUTOCGETSEPARATOR → int
Func _GUICtrlScintilla_AutoCGetSeparator($hCtrl)
	Return Chr(_SendMessage($hCtrl, $SCI_AUTOCGETSEPARATOR))
EndFunc

;~ SCI_AUTOCSELECT(<unused>, const char *select)
Func _GUICtrlScintilla_AutoCSelect($hCtrl, $sSelect)
	Local $tBuf = __guiScintilla_str2bin($sSelect)
	_SendMessage($hCtrl, $SCI_AUTOCSELECT, 0, $tBuf, 0, "wparam", "struct*")
EndFunc

;~ SCI_AUTOCGETCURRENT → int
Func _GUICtrlScintilla_AutoCGetCurrent($hCtrl)
	Return _SendMessage($hCtrl, $SCI_AUTOCGETCURRENT)
EndFunc

;~ SCI_AUTOCGETCURRENTTEXT(<unused>, char *text) → int
Func _GUICtrlScintilla_AutoCGetCurrentText($hCtrl)
	Local $iLen = _SendMessage($hCtrl, $SCI_AUTOCGETCURRENTTEXT)
	If $iLen <= 0 Then Return ""

	Local $tBuf = DllStructCreate("byte[" & $iLen & "]")
	_SendMessage($hCtrl, $SCI_AUTOCGETCURRENTTEXT, 0, $tBuf, 0, "wparam", "struct*")
	Return __guiScintilla_bin2str($tBuf, False)
EndFunc

;~ SCI_AUTOCSETCANCELATSTART(bool cancel)
Func _GUICtrlScintilla_AutoCSetCancelAtStart($hCtrl, $bCancelAtStart = True)
	_SendMessage($hCtrl, $SCI_AUTOCSETCANCELATSTART, $bCancelAtStart, 0, 0, "bool")
EndFunc

;~ SCI_AUTOCGETCANCELATSTART → bool
Func _GUICtrlScintilla_AutoCGetCancelAtStart($hCtrl)
	Return _SendMessage($hCtrl, $SCI_AUTOCGETCANCELATSTART, 0, 0, 0, "wparam", "lparam", "bool")
EndFunc

;~ SCI_AUTOCSETFILLUPS(<unused>, const char *characterSet)
Func _GUICtrlScintilla_AutoCSetFillups($hCtrl, $sCharacterSet)
	Local $tBuf = __guiScintilla_str2bin($sCharacterSet)
	_SendMessage($hCtrl, $SCI_AUTOCSETFILLUPS, 0, $tBuf, 0, "wparam", "struct*")
EndFunc

;~ SCI_AUTOCSETCHOOSESINGLE(bool chooseSingle)
Func _GUICtrlScintilla_AutoCSetChooseSingle($hCtrl, $bChooseSingle = True)
	_SendMessage($hCtrl, $SCI_AUTOCSETCHOOSESINGLE, $bChooseSingle, 0, 0, "bool")
EndFunc

;~ SCI_AUTOCGETCHOOSESINGLE → bool
Func _GUICtrlScintilla_AutoCGetChooseSingle($hCtrl)
	Return _SendMessage($hCtrl, $SCI_AUTOCGETCHOOSESINGLE, 0, 0, 0, "wparam", "lparam", "bool")
EndFunc

;~ SCI_AUTOCSETIGNORECASE(bool ignoreCase)
Func _GUICtrlScintilla_AutoCSetIgnoreCase($hCtrl, $bIgnoreCase = True)
	_SendMessage($hCtrl, $SCI_AUTOCSETIGNORECASE, $bIgnoreCase, 0, 0, "bool")
EndFunc

;~ SCI_AUTOCGETIGNORECASE → bool
Func _GUICtrlScintilla_AutoCGetIgnoreCase($hCtrl)
	Return _SendMessage($hCtrl, $SCI_AUTOCGETIGNORECASE, 0, 0, 0, "wparam", "lparam", "bool")
EndFunc

;~ SCI_AUTOCSETCASEINSENSITIVEBEHAVIOUR(int behaviour)
Func _GUICtrlScintilla_AutoCSetCaseInsensitiveBehaviour($hCtrl, $iBehaviour = $SC_CASEINSENSITIVEBEHAVIOUR_RESPECTCASE)
	_SendMessage($hCtrl, $SCI_AUTOCSETCASEINSENSITIVEBEHAVIOUR, $iBehaviour)
EndFunc

;~ SCI_AUTOCGETCASEINSENSITIVEBEHAVIOUR → int
Func _GUICtrlScintilla_AutoCGetCaseInsensitiveBehaviour($hCtrl)
	Return _SendMessage($hCtrl, $SCI_AUTOCGETCASEINSENSITIVEBEHAVIOUR)
EndFunc

;~ SCI_AUTOCSETMULTI(int multi)
Func _GUICtrlScintilla_AutoCSetMulti($hCtrl, $iMulti = $SC_MULTIAUTOC_ONCE)
	_SendMessage($hCtrl, $SCI_AUTOCSETMULTI, $iMulti)
EndFunc

;~ SCI_AUTOCGETMULTI → int
Func _GUICtrlScintilla_AutoCGetMulti($hCtrl)
	Return _SendMessage($hCtrl, $SCI_AUTOCGETMULTI)
EndFunc

;~ SCI_AUTOCSETORDER(int order)
Func _GUICtrlScintilla_AutoCSetOrder($hCtrl, $iOrder = $SC_ORDER_PRESORTED)
	_SendMessage($hCtrl, $SCI_AUTOCSETORDER, $iOrder)
EndFunc

;~ SCI_AUTOCGETORDER → int
Func _GUICtrlScintilla_AutoCGetOrder($hCtrl)
	Return _SendMessage($hCtrl, $SCI_AUTOCGETORDER)
EndFunc

;~ SCI_AUTOCSETAUTOHIDE(bool autoHide)
Func _GUICtrlScintilla_AutoCSetAutoHide($hCtrl, $bAutoHide = True)
	_SendMessage($hCtrl, $SCI_AUTOCSETAUTOHIDE, $bAutoHide, 0, 0, "bool")
EndFunc

;~ SCI_AUTOCGETAUTOHIDE → bool
Func _GUICtrlScintilla_AutoCGetAutoHide($hCtrl)
	Return _SendMessage($hCtrl, $SCI_AUTOCGETAUTOHIDE, 0, 0, 0, "wparam", "lparam", "bool")
EndFunc

;~ SCI_AUTOCSETDROPRESTOFWORD(bool dropRestOfWord)
Func _GUICtrlScintilla_AutoCSetDropRestOfWord($hCtrl, $bDropRestOfWord = True)
	_SendMessage($hCtrl, $SCI_AUTOCSETDROPRESTOFWORD, $bDropRestOfWord, 0, 0, "bool")
EndFunc

;~ SCI_AUTOCGETDROPRESTOFWORD → bool
Func _GUICtrlScintilla_AutoCGetDropRestOfWord($hCtrl)
	Return _SendMessage($hCtrl, $SCI_AUTOCGETDROPRESTOFWORD, 0, 0, 0, "wparam", "lparam", "bool")
EndFunc

;~ SCI_AUTOCSETOPTIONS(int options)
Func _GUICtrlScintilla_AutoCSetOptions($hCtrl, $iOptions)
	_SendMessage($hCtrl, $SCI_AUTOCSETOPTIONS, $iOptions)
EndFunc

;~ SCI_AUTOCGETOPTIONS → int
Func _GUICtrlScintilla_AutoCGetOptions($hCtrl)
	Return _SendMessage($hCtrl, $SCI_AUTOCGETOPTIONS)
EndFunc

;~ SCI_REGISTERIMAGE(int type, const char *xpmData)
;~ SCI_REGISTERRGBAIMAGE(int type, const char *pixels)
;~ SCI_CLEARREGISTEREDIMAGES

;~ SCI_AUTOCSETTYPESEPARATOR(int separatorCharacter)
Func _GUICtrlScintilla_AutoCSetTypeSeparator($hCtrl, $sSeparatorCharacter)
	_SendMessage($hCtrl, $SCI_AUTOCSETTYPESEPARATOR, Asc(StringLeft($sSeparatorCharacter, 1)))
EndFunc

;~ SCI_AUTOCGETTYPESEPARATOR → int
Func _GUICtrlScintilla_AutoCTypeSeparator($hCtrl)
	Return Chr(_SendMessage($hCtrl, $SCI_AUTOCGETTYPESEPARATOR))
EndFunc

;~ SCI_AUTOCSETMAXHEIGHT(int rowCount)
Func _GUICtrlScintilla_AutoCSetMaxHeight($hCtrl, $iRowCount = 5)
	_SendMessage($hCtrl, $SCI_AUTOCSETMAXHEIGHT, $iRowCount)
EndFunc

;~ SCI_AUTOCGETMAXHEIGHT → int
Func _GUICtrlScintilla_AutoCGetMaxHeight($hCtrl)
	Return _SendMessage($hCtrl, $SCI_AUTOCGETMAXHEIGHT)
EndFunc

;~ SCI_AUTOCSETMAXWIDTH(int characterCount)
Func _GUICtrlScintilla_AutoCSetMaxWidth($hCtrl, $iCharacterCount = 0)
	_SendMessage($hCtrl, $SCI_AUTOCSETMAXWIDTH, $iCharacterCount)
EndFunc

;~ SCI_AUTOCGETMAXWIDTH → int
Func _GUICtrlScintilla_AutoCGetMaxWidth($hCtrl)
	Return _SendMessage($hCtrl, $SCI_AUTOCGETMAXWIDTH)
EndFunc

;~ SC_ELEMENT_LIST : colouralpha
;~ SC_ELEMENT_LIST_BACK : colouralpha
;~ SC_ELEMENT_LIST_SELECTED : colouralpha
;~ SC_ELEMENT_LIST_SELECTED_BACK : colouralpha

#EndRegion

#Region User lists ================================================================================

;~ SCI_USERLISTSHOW(int listType, const char *itemList)
Func _GUICtrlScintilla_UserListShow($hCtrl, $iListType, $sItemList)
	Local $tBuf = __guiScintilla_str2bin($sItemList)
	_SendMessage($hCtrl, $SCI_USERLISTSHOW, $iListType, $tBuf, 0, "int", "struct*")
EndFunc

#EndRegion

#Region Call tips =================================================================================

;~ SCI_CALLTIPSHOW(position pos, const char *definition)
;~ SCI_CALLTIPCANCEL
;~ SCI_CALLTIPACTIVE → bool
;~ SCI_CALLTIPPOSSTART → position
;~ SCI_CALLTIPSETPOSSTART(position posStart)
;~ SCI_CALLTIPSETHLT(position highlightStart, position highlightEnd)
;~ SCI_CALLTIPSETBACK(colour back)
;~ SCI_CALLTIPSETFORE(colour fore)
;~ SCI_CALLTIPSETFOREHLT(colour fore)
;~ SCI_CALLTIPUSESTYLE(int tabSize)
;~ SCI_CALLTIPSETPOSITION(bool above)

#EndRegion

#Region Keyboard commands =========================================================================

Func _GUICtrlScintilla_KeyboardCommand($hCtrl, $iCmd)
	_SendMessage($hCtrl, $iCmd)
EndFunc

#EndRegion

#Region Key bindings ==============================================================================

;~ SCI_ASSIGNCMDKEY(int keyDefinition, int sciCommand)
Func _GUICtrlScintilla_AssignCmdKey($hCtrl, $iCommand, $iKey, $iMod = 0)
	_SendMessage($hCtrl, $SCI_ASSIGNCMDKEY, BitOR($iKey, BitShift($iMod, -16)), $iCommand)
EndFunc

;~ SCI_CLEARCMDKEY(int keyDefinition)
Func _GUICtrlScintilla_ClearCmdKey($hCtrl, $iKey, $iMod = 0)
	_SendMessage($hCtrl, $SCI_CLEARCMDKEY, BitOR($iKey, BitShift($iMod, -16)))
EndFunc

;~ SCI_CLEARALLCMDKEYS
Func _GUICtrlScintilla_ClearAllCmdKeys($hCtrl)
	_SendMessage($hCtrl, $SCI_CLEARALLCMDKEYS)
EndFunc

;~ SCI_NULL

#EndRegion

#Region Popup edit menu ===========================================================================

;~ SCI_USEPOPUP(int popUpMode)
Func _GUICtrlScintilla_UsePopup($hCtrl, $iPopupMode = $SC_POPUP_NEVER)
	_SendMessage($hCtrl, $SCI_USEPOPUP, $iPopupMode)
EndFunc

#EndRegion

#Region Macro recording ===========================================================================

;~ SCI_STARTRECORD
;~ SCI_STOPRECORD

#EndRegion

#Region Printing ==================================================================================

;~ SCI_FORMATRANGE(bool draw, Sci_RangeToFormat *fr) → position
;~ SCI_SETPRINTMAGNIFICATION(int magnification)
;~ SCI_GETPRINTMAGNIFICATION → int
;~ SCI_SETPRINTCOLOURMODE(int mode)
;~ SCI_GETPRINTCOLOURMODE → int
;~ SCI_SETPRINTWRAPMODE(int wrapMode)
;~ SCI_GETPRINTWRAPMODE → int

#EndRegion

#Region Direct access =============================================================================

;~ SCI_GETDIRECTFUNCTION → pointer
;~ SCI_GETDIRECTSTATUSFUNCTION → pointer
;~ SCI_GETDIRECTPOINTER → pointer
;~ SCI_GETCHARACTERPOINTER → pointer
;~ SCI_GETRANGEPOINTER(position start, position lengthRange) → pointer
;~ SCI_GETGAPPOSITION → position

#EndRegion

#Region Multiple views ============================================================================

;~ SCI_GETDOCPOINTER → pointer
;~ SCI_SETDOCPOINTER(<unused>, pointer doc)
;~ SCI_CREATEDOCUMENT(position bytes, int documentOptions) → pointer
;~ SCI_ADDREFDOCUMENT(<unused>, pointer doc)
;~ SCI_RELEASEDOCUMENT(<unused>, pointer doc)
;~ SCI_GETDOCUMENTOPTIONS → int

#EndRegion

#Region Background loading and saving =============================================================

;~ SCI_CREATELOADER(position bytes, int documentOptions) → pointer

#EndRegion

#Region Folding ===================================================================================

;~ SCI_VISIBLEFROMDOCLINE(line docLine) → line
;~ SCI_DOCLINEFROMVISIBLE(line displayLine) → line
;~ SCI_SHOWLINES(line lineStart, line lineEnd)
;~ SCI_HIDELINES(line lineStart, line lineEnd)
;~ SC_ELEMENT_HIDDEN_LINE : colouralpha
;~ SCI_GETLINEVISIBLE(line line) → bool
;~ SCI_GETALLLINESVISIBLE → bool
;~ SCI_SETFOLDLEVEL(line line, int level)
;~ SCI_GETFOLDLEVEL(line line) → int
;~ SCI_SETAUTOMATICFOLD(int automaticFold)
;~ SCI_GETAUTOMATICFOLD → int
;~ SCI_SETFOLDFLAGS(int flags)
;~ SC_ELEMENT_FOLD_LINE : colouralpha
;~ SCI_GETLASTCHILD(line line, int level) → line
;~ SCI_GETFOLDPARENT(line line) → line
;~ SCI_SETFOLDEXPANDED(line line, bool expanded)
;~ SCI_GETFOLDEXPANDED(line line) → bool
;~ SCI_CONTRACTEDFOLDNEXT(line lineStart) → line
;~ SCI_TOGGLEFOLD(line line)
;~ SCI_TOGGLEFOLDSHOWTEXT(line line, const char *text)
;~ SCI_FOLDDISPLAYTEXTSETSTYLE(int style)
;~ SCI_FOLDDISPLAYTEXTGETSTYLE → int
;~ SCI_SETDEFAULTFOLDDISPLAYTEXT(<unused>, const char *text)
;~ SCI_GETDEFAULTFOLDDISPLAYTEXT(<unused>, char *text) → int
;~ SCI_FOLDLINE(line line, int action)
;~ SCI_FOLDCHILDREN(line line, int action)
;~ SCI_FOLDALL(int action)
;~ SCI_EXPANDCHILDREN(line line, int level)
;~ SCI_ENSUREVISIBLE(line line)
;~ SCI_ENSUREVISIBLEENFORCEPOLICY(line line)

#EndRegion

#Region Line wrapping =============================================================================

;~ SCI_SETWRAPMODE(int wrapMode)
Func _GUICtrlScintilla_SetWrapMode($hCtrl, $iWrapMode = $SC_WRAP_NONE)
	_SendMessage($hCtrl, $SCI_SETWRAPMODE, $iWrapMode)
EndFunc

;~ SCI_GETWRAPMODE → int
Func _GUICtrlScintilla_GetWrapMode($hCtrl)
	Return _SendMessage($hCtrl, $SCI_GETWRAPMODE, 0, 0, 0, "wparam", "lparam", "int")
EndFunc

;~ SCI_SETWRAPVISUALFLAGS(int wrapVisualFlags)
Func _GUICtrlScintilla_SetWrapVisualFlags($hCtrl, $iWrapVisualFlags = $SC_WRAPVISUALFLAG_NONE)
	_SendMessage($hCtrl, $SCI_SETWRAPVISUALFLAGS, $iWrapVisualFlags)
EndFunc

;~ SCI_GETWRAPVISUALFLAGS → int
Func _GUICtrlScintilla_GetWrapVisualFlags($hCtrl)
	Return _SendMessage($hCtrl, $SCI_GETWRAPVISUALFLAGS, 0, 0, 0, "wparam", "lparam", "int")
EndFunc

;~ SCI_SETWRAPVISUALFLAGSLOCATION(int wrapVisualFlagsLocation)
Func _GUICtrlScintilla_SetWrapVisualFlagsLocation($hCtrl, $iWrapVisualFlagsLocation = $SC_WRAPVISUALFLAGLOC_DEFAULT)
	_SendMessage($hCtrl, $SCI_SETWRAPVISUALFLAGSLOCATION, $iWrapVisualFlagsLocation)
EndFunc

;~ SCI_GETWRAPVISUALFLAGSLOCATION → int
Func _GUICtrlScintilla_GetWrapVisualFlagsLocation($hCtrl)
	Return _SendMessage($hCtrl, $SCI_GETWRAPVISUALFLAGSLOCATION, 0, 0, 0, "wparam", "lparam", "int")
EndFunc

;~ SCI_SETWRAPINDENTMODE(int wrapIndentMode)
Func _GUICtrlScintilla_SetWrapIndentMode($hCtrl, $iWrapIndentMode = $SC_WRAPINDENT_FIXED)
	_SendMessage($hCtrl, $SCI_SETWRAPINDENTMODE, $iWrapIndentMode)
EndFunc

;~ SCI_GETWRAPINDENTMODE → int
Func _GUICtrlScintilla_GetWrapIdentMode($hCtrl)
	Return _SendMessage($hCtrl, $SCI_GETWRAPINDENTMODE, 0, 0, 0, "wparam", "lparam", "int")
EndFunc

;~ SCI_SETWRAPSTARTINDENT(int indent)
Func _GUICtrlScintilla_SetWrapStartIndent($hCtrl, $iIdent)
	_SendMessage($hCtrl, $SCI_SETWRAPSTARTINDENT, $iIdent)
EndFunc

;~ SCI_GETWRAPSTARTINDENT → int
Func _GUICtrlScintilla_GetWrapStartIndent($hCtrl)
	Return _SendMessage($hCtrl, $SCI_GETWRAPSTARTINDENT, 0, 0, 0, "wparam", "lparam", "int")
EndFunc

;~ SCI_SETLAYOUTCACHE(int cacheMode)
Func _GUICtrlScintilla_SetLayoutCache($hCtrl, $iCacheMode)
	_SendMessage($hCtrl, $SCI_SETLAYOUTCACHE, $iCacheMode)
EndFunc

;~ SCI_GETLAYOUTCACHE → int
Func _GUICtrlScintilla_GetLayoutCache($hCtrl)
	Return _SendMessage($hCtrl, $SCI_GETLAYOUTCACHE, 0, 0, 0, "wparam", "lparam", "int")
EndFunc

;~ SCI_SETPOSITIONCACHE(int size)
Func _GUICtrlScintilla_SetPositionCache($hCtrl, $iSize)
	_SendMessage($hCtrl, $SCI_SETPOSITIONCACHE, $iSize)
EndFunc

;~ SCI_GETPOSITIONCACHE → int
Func _GUICtrlScintilla_GetPositionCache($hCtrl)
	Return _SendMessage($hCtrl, $SCI_GETPOSITIONCACHE, 0, 0, 0, "wparam", "lparam", "int")
EndFunc

;~ SCI_LINESSPLIT(int pixelWidth)
Func _GUICtrlScintilla_LinesSplit($hCtrl, $iPixelWidth = 0)
	_SendMessage($hCtrl, $SCI_LINESSPLIT, $iPixelWidth)
EndFunc

;~ SCI_LINESJOIN
Func _GUICtrlScintilla_LinesJoin($hCtrl)
	_SendMessage($hCtrl, $SCI_LINESJOIN)
EndFunc

;~ SCI_WRAPCOUNT(line docLine) → line
Func _GUICtrlScintilla_WrapCount($hCtrl, $iDocLine)
	Return _SendMessage($hCtrl, $SCI_WRAPCOUNT, $iDocLine)
EndFunc

#EndRegion

#Region Zooming ===================================================================================

;~ SCI_ZOOMIN
Func _GUICtrlScintilla_ZoomIn($hCtrl)
	_SendMessage($hCtrl, $SCI_ZOOMIN)
EndFunc

;~ SCI_ZOOMOUT
Func _GUICtrlScintilla_ZoomOut($hCtrl)
	_SendMessage($hCtrl, $SCI_ZOOMOUT)
EndFunc

;~ SCI_SETZOOM(int zoomInPoints)
Func _GUICtrlScintilla_SetZoom($hCtrl, $iZoomInPoints)
	_SendMessage($hCtrl, $SCI_SETZOOM, $iZoomInPoints, 0, 0, "int")
EndFunc

;~ SCI_GETZOOM → int
Func _GUICtrlScintilla_GetZoom($hCtrl)
	Return _SendMessage($hCtrl, $SCI_GETZOOM, 0, 0, 0, "wparam", "lparam", "int")
EndFunc

#EndRegion

#Region Long lines ================================================================================

;~ SCI_SETEDGEMODE(int edgeMode)
Func _GUICtrlScintilla_SetEdgeMode($hCtrl, $iEdgeMode = $EDGE_NONE)
	_SendMessage($hCtrl, $SCI_SETEDGEMODE, $iEdgeMode, 0, 0, "int")
EndFunc

;~ SCI_GETEDGEMODE → int
Func _GUICtrlScintilla_GetEdgeMode($hCtrl)
	Return _SendMessage($hCtrl, $SCI_GETEDGEMODE, 0, 0, 0, "wparam", "lparam", "int")
EndFunc

;~ SCI_SETEDGECOLUMN(position column)
Func _GUICtrlScintilla_SetEdgeColumn($hCtrl, $iEdgeMode = $EDGE_NONE)
	_SendMessage($hCtrl, $SCI_SETEDGECOLUMN, $iEdgeMode)
EndFunc

;~ SCI_GETEDGECOLUMN → position
Func _GUICtrlScintilla_GetEdgeColumn($hCtrl)
	Return _SendMessage($hCtrl, $SCI_GETEDGECOLUMN)
EndFunc

;~ SCI_SETEDGECOLOUR(colour edgeColour)
Func _GUICtrlScintilla_SetEdgeColour($hCtrl, $iEdgeColour)
	_SendMessage($hCtrl, $SCI_SETEDGECOLOUR, $iEdgeColour)
EndFunc

;~ SCI_GETEDGECOLOUR → colour
Func _GUICtrlScintilla_GetEdgeColour($hCtrl)
	Return _SendMessage($hCtrl, $SCI_GETEDGECOLOUR)
EndFunc


;~ SCI_MULTIEDGEADDLINE(position column, colour edgeColour)
Func _GUICtrlScintilla_MultiEdgeAddLine($hCtrl, $iColumn, $iEdgeColour)
	_SendMessage($hCtrl, $SCI_MULTIEDGEADDLINE, $iColumn, $iEdgeColour)
EndFunc

;~ SCI_MULTIEDGECLEARALL
Func _GUICtrlScintilla_MultiEdgeClearAll($hCtrl)
	_SendMessage($hCtrl, $SCI_MULTIEDGECLEARALL)
EndFunc

;~ SCI_GETMULTIEDGECOLUMN(int which) → position
Func _GUICtrlScintilla_GetMultiEdgeColumn($hCtrl, $iWhich)
	Return _SendMessage($hCtrl, $SCI_GETMULTIEDGECOLUMN, $iWhich, 0, 0, "int", "lparam", "int_ptr")
EndFunc

#EndRegion

#Region Accessibility =============================================================================

;~ SCI_SETACCESSIBILITY(int accessibility)
;~ SCI_GETACCESSIBILITY → int

#EndRegion

#Region Lexer =====================================================================================

;~ SCI_GETLEXER → int
;~ SCI_GETLEXERLANGUAGE(<unused>, char *language) → int
Func _GUICtrlScintilla_GetLexer($hCtrl)
	Local $iSize = _SendMessage($hCtrl, $SCI_GETLEXERLANGUAGE)
	Local $tBuf = DllStructCreate("char[" & ($iSize + 1) & "]")

	_SendMessage($hCtrl, $SCI_GETLEXERLANGUAGE, 0, $tBuf, 0, "wparam", "struct*")

	Return SetExtended(_SendMessage($hCtrl, $SCI_GETLEXER), DllStructGetData($tBuf, 1))
EndFunc

;~ SCI_SETILEXER(<unused>, pointer ilexer)
Func _GUICtrlScintilla_SetILexer($hCtrl, $pILexer)
	_SendMessage($hCtrl, $SCI_SETILEXER, 0, $pILexer)
EndFunc

;~ SCI_COLOURISE(position start, position end)
Func _GUICtrlScintilla_Colourise($hCtrl, $iStart = 0, $iEnd = -1)
	_SendMessage($hCtrl, $SCI_COLOURISE, $iStart, $iEnd)
EndFunc

;~ SCI_CHANGELEXERSTATE(position start, position end) → int

;~ SCI_PROPERTYNAMES(<unused>, char *names) → int
;~ SCI_PROPERTYTYPE(const char *name) → int
;~ SCI_DESCRIBEPROPERTY(const char *name, char *description) → int
Func _GUICtrlScintilla_Properties($hCtrl)
	Local $iSize = _SendMessage($hCtrl, $SCI_PROPERTYNAMES)
EndFunc

;~ SCI_SETPROPERTY(const char *key, const char *value)
;~ SCI_GETPROPERTY(const char *key, char *value) → int
;~ SCI_GETPROPERTYEXPANDED(const char *key, char *value) → int
;~ SCI_GETPROPERTYINT(const char *key, int defaultValue) → int
;~ SCI_DESCRIBEKEYWORDSETS(<unused>, char *descriptions) → int

;~ SCI_SETKEYWORDS(int keyWordSet, const char *keyWords)
Func _GUICtrlScintilla_SetKeywords($hCtrl, $iKeyWordSet, $sKeyWords)
	_SendMessage($hCtrl, $SCI_SETKEYWORDS, $iKeyWordSet, $sKeyWords, 0, "int_ptr", "str")
EndFunc

;~ SCI_GETSUBSTYLEBASES(<unused>, char *styles) → int
;~ SCI_DISTANCETOSECONDARYSTYLES → int
;~ SCI_ALLOCATESUBSTYLES(int styleBase, int numberStyles) → int
;~ SCI_FREESUBSTYLES
;~ SCI_GETSUBSTYLESSTART(int styleBase) → int
;~ SCI_GETSUBSTYLESLENGTH(int styleBase) → int
;~ SCI_GETSTYLEFROMSUBSTYLE(int subStyle) → int
;~ SCI_GETPRIMARYSTYLEFROMSTYLE(int style) → int
;~ SCI_SETIDENTIFIERS(int style, const char *identifiers)
;~ SCI_PRIVATELEXERCALL(int operation, pointer pointer) → pointer
;~ SCI_GETNAMEDSTYLES → int
;~ SCI_NAMEOFSTYLE(int style, char *name) → int
;~ SCI_TAGSOFSTYLE(int style, char *tags) → int
;~ SCI_DESCRIPTIONOFSTYLE(int style, char *description) → int

#EndRegion

#Region AutoIt internal helpers ===================================================================

Func __guiScintilla_str2bin($sText, $bZeroTerminate = True)
	If Not IsBinary($sText) Then $sText = StringToBinary($sText, 4)
	Local $iLen = BinaryLen($sText)
	Local $tBuf = DllStructCreate("byte[" & ($bZeroTerminate ? $iLen + 1 : $iLen) & "]")
	DllStructSetData($tBuf, 1, $sText)
	Return SetError(0, $iLen, $tBuf)
EndFunc

Func __guiScintilla_bin2str($tStruct, $bIsZeroTerminated = True)
	If $bIsZeroTerminated Then
		Return BinaryToString(DllStructGetData(DllStructCreate("byte[" & (DllStructGetSize($tStruct) - 1) & "]", DllStructGetPtr($tStruct)), 1), 4)
	Else
		Return BinaryToString(DllStructGetData($tStruct, 1), 4)
	EndIf
EndFunc

#EndRegion
