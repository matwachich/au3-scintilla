#include-once

Global $__gLexilla_hDLL = -1

Func _Lexilla_Startup($sDllPath)
	$__gLexilla_hDLL = DllOpen($sDllPath)
	If $__gLexilla_hDLL = -1 Then
		MsgBox(16, @ScriptName, $sDllPath & " load failed!")
		Return False
	EndIf
	Return True
EndFunc

;~ ILexer5 * LEXILLA_CALL CreateLexer(const char *name);
Func _Lexilla_CreateLexer($sName)
	Return DllCall($__gLexilla_hDLL, "ptr", "CreateLexer", "str", $sName)[0]
EndFunc

;~ int LEXILLA_CALL GetLexerCount();
;~ void LEXILLA_CALL GetLexerName(unsigned int index, char *name, int buflength);
;~ LexerFactoryFunction LEXILLA_CALL GetLexerFactory(unsigned int index);
;~ DEPRECATE_DEFINITION const char *LEXILLA_CALL LexerNameFromID(int identifier);
;~ const char * LEXILLA_CALL GetLibraryPropertyNames();
;~ void LEXILLA_CALL SetLibraryProperty(const char *key, const char *value);
;~ const char *LEXILLA_CALL GetNameSpace();