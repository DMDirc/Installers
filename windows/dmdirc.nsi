SetCompressor /FINAL /SOLID lzma

!include "MUI2.nsh"
!include "MultiUser.nsh"
!include "WordFunc.nsh"
!include "LogicLib.nsh"
!include "WinVer.nsh"

!define SF_USELECTED  0
!define MUI_ABORTWARNING
!define MUI_STARTMENUPAGE_REGISTRY_ROOT SHCTX
!define MUI_STARTMENUPAGE_REGISTRY_KEY "SOFTWARE\DMDirc\DMDirc" 
!define MUI_STARTMENUPAGE_REGISTRY_VALUENAME "DMDirc"
!define MUI_FINISHPAGE_RUN "$INSTDIR\DMDirc.exe"
!define UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\DMDirc"
!define JAVAEXE "javaw.exe"
!define JRE_VERSION "6.0"
!define JRE_URL "www.dmdirc.com/getjava.php?os=windows"

Name "DMDirc"
OutFile "..\output\DMDirc-Setup.exe"

;Default installation folder
InstallDir "$PROGRAMFILES\DMDirc"

;Request application privileges for Windows Vista
RequestExecutionLevel admin

Var StartMenuFolder

!insertmacro VersionCompare
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "..\..\..\src\com\dmdirc\licences\DMDirc - MIT"
!insertmacro MUI_PAGE_STARTMENU Application $StartMenuFolder
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH


!insertmacro MUI_UNPAGE_WELCOME
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

!insertmacro MUI_LANGUAGE "English"


Section "DMDirc" SecDMDirc
  SectionIn RO
  SetOutPath "$INSTDIR"
  SetOverwrite ifnewer

  file "..\..\..\dist\DMDirc.jar"

  ;Store installation folder
  WriteRegStr HKLM "${UNINST_KEY}" "DisplayName" "DMDirc"
  WriteRegStr HKLM "${UNINST_KEY}" "UninstallString" "$\"$INSTDIR\uninstall.exe$\""
  WriteRegStr HKLM "${UNINST_KEY}" "QuietUninstallString" "$\"$INSTDIR\uninstall.exe$\""
  WriteRegStr HKLM "${UNINST_KEY}" "DisplayIcon" "$\"$INSTDIR\DMDirc.exe$\""

  ;Create uninstaller
  WriteUninstaller "$INSTDIR\Uninstall.exe"

  !insertmacro MUI_STARTMENU_WRITE_BEGIN Application
    CreateDirectory "$SMPROGRAMS\$StartMenuFolder"
    CreateShortCut "$SMPROGRAMS\$StartMenuFolder\DMDirc.lnk" "$INSTDIR\DMDirc.exe"
    CreateShortCut "$SMPROGRAMS\$StartMenuFolder\Uninstall.lnk" "$INSTDIR\Uninstall.exe"
  !insertmacro MUI_STARTMENU_WRITE_END

SectionEnd

Section "Install JRE" SecJRE
  StrCpy $2 "$TEMP\Java Runtime Environment.exe"
  nsisdl::download /TIMEOUT=30000 ${JRE_URL} $2
  Pop $R0 ;Get the return value
  StrCmp $R0 "success" +3
  MessageBox MB_ICONSTOP "Download failed: $R0"
  ExecWait '"$2"'
  DetailPrint "some program returned $0"
  Delete $2
SectionEnd

Section "Desktop" SecDesktop
    CreateShortCut "$DESKTOP\DMDirc.lnk" "$INSTDIR\DMDirc.exe"
SectionEnd

Section "Quick Launch" SecQuickLaunch
  CreateShortCut "$QUICKLAUNCH\DMDirc.lnk" "$INSTDIR\DMDirc.exe"
SectionEnd

Section "Register URL Protocol" SecProtocol
SectionEnd

LangString DESC_SecDMDirc ${LANG_ENGLISH} "Core client"
LangString DESC_SecDesktop ${LANG_ENGLISH} "Create desktop shortcut"
LangString DESC_SecQuickLaunch ${LANG_ENGLISH} "Create quick launch shortcuts"
LangString DESC_SecProtocol ${LANG_ENGLISH} "Register DMDirc as a protocol handler for IRC:// URLs"

!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  !insertmacro MUI_DESCRIPTION_TEXT ${SecDMDirc} $(DESC_SecDMDirc)
  !insertmacro MUI_DESCRIPTION_TEXT ${SecDesktop} $(DESC_SecDesktop)
  !insertmacro MUI_DESCRIPTION_TEXT ${SecQuickLaunch} $(DESC_SecQuickLaunch)
  !insertmacro MUI_DESCRIPTION_TEXT ${SecProtocol} $(DESC_SecProtocol)
!insertmacro MUI_FUNCTION_DESCRIPTION_END

Section "Uninstall"
  RMDir /r "$INSTDIR"

  !insertmacro MUI_STARTMENU_GETFOLDER Application $StartMenuFolder
  RMDir /r "$SMPROGRAMS\$StartMenuFolder"

  Delete "$DESKTOP\DMDirc.lnk"
  Delete "$QUICKLAUNCH\DMDirc.lnk"

  DeleteRegKey HKLM "${UNINST_KEY}"

SectionEnd

!macro SecUnSelect SecId
  Push $0
  IntOp $0 ${SF_USELECTED} | ${SF_RO}
  SectionSetFlags ${SecId} $0
  SectionSetText  ${SecId} ""
  Pop $0
!macroend
 
!define UnSelectSection '!insertmacro SecUnSelect'

Function .onInit
  ${If} ${IsWin7}
    ${UnSelectSection} ${SecQuickLaunch}
  ${EndIf}
  Call checkJREExists
  Pop $R0
  ${If} $R0 == ""
    ${UnSelectSection} ${SecJRE}
  ${EndIf}
FunctionEnd

;  returns the full path of a valid java.exe or a blank string
;  looks in:
;  1 - .\jre directory (JRE Installed with application)
;  2 - JAVA_HOME environment variable
;  3 - the registry
;  4 - hopes it is in current dir or PATH
Function checkJREExists
  Push $R0
  Push $R1
  Push $2

   ;checkLocal
    ClearErrors
    StrCpy $R0 "$EXEDIR\jre\bin\${JAVAEXE}"
    IfFileExists $R0 0 checkJavaHome
    Call CheckJREVersion
    IfErrors 0 JreFound

  checkJavaHome:
    ClearErrors
    ReadEnvStr $R0 "JAVA_HOME"
    StrCpy $R0 "$R0\bin\${JAVAEXE}"
    IfErrors CheckRegistry     
    IfFileExists $R0 0 CheckRegistry
    Call CheckJREVersion
    IfErrors 0 JreFound
 
  checkRegistry:
    ClearErrors
    ReadRegStr $R1 HKLM "SOFTWARE\JavaSoft\Java Runtime Environment" "CurrentVersion"
    ReadRegStr $R0 HKLM "SOFTWARE\JavaSoft\Java Runtime Environment\$R1" "JavaHome"
    StrCpy $R0 "$R0\bin\${JAVAEXE}"
    IfErrors NotFound
    IfFileExists $R0 0 NotFound
    Call CheckJREVersion
    IfErrors NotFound

  JreFound:
    Pop $2
    Pop $R1
    Exch $R0
 
  NotFound:
    StrCpy $R0 ""
    Exch $R0
FunctionEnd

; Pass the "javaw.exe" path by $R0
Function CheckJREVersion
  Push $R1
  ; Get the file version of javaw.exe
  ${GetFileVersion} $R0 $R1
  ${VersionCompare} ${JRE_VERSION} $R1 $R1
  ; Check whether $R1 != "1"
  ClearErrors
  StrCmp $R1 "1" 0 CheckDone
  SetErrors
  CheckDone:
    Pop $R1
FunctionEnd
