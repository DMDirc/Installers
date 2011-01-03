SetCompressor /FINAL /SOLID lzma

!ifndef VERSION
  !define VERSION "NONE"
!endif

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
!define MUI_ICON "files\icon.ico"
!define MUI_UNICON "files\icon.ico"
!define UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\DMDirc"
!define JRE_VERSION "1.6"
!define JRE_URL "www.dmdirc.com/getjava.php?os=windows"

!include "JREDyna.nsh"

Name "DMDirc"
BrandingText " "
Icon "files\icon.ico"
UninstallIcon "files\icon.ico"
OutFile "..\output\DMDirc-${VERSION}-Setup.exe"

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
!insertmacro CUSTOM_PAGE_JREINFO
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
  SetOverwrite on

  call DownloadAndInstallJREIfNecessary

  File /nonfatal /r "files\*.*"

  ;Store installation folder
  WriteRegStr HKLM "${UNINST_KEY}" "DisplayName" "DMDirc"
  WriteRegStr HKLM "${UNINST_KEY}" "UninstallString" "$\"$INSTDIR\uninstall.exe$\""
  WriteRegStr HKLM "${UNINST_KEY}" "QuietUninstallString" "$\"$INSTDIR\uninstall.exe$\""
  WriteRegStr HKLM "${UNINST_KEY}" "DisplayIcon" "$\"$INSTDIR\DMDirc.exe$\""
  WriteRegStr HKLM "${UNINST_KEY}" "Publisher" "DMDirc.com"
  WriteRegStr HKLM "${UNINST_KEY}" "URLInfoAbout" "http://www.DMDirc.com/"
  WriteRegStr HKLM "${UNINST_KEY}" "URLUpdateInfo" "http://www.DMDirc.com/"
  WriteRegDWORD HKLM "${UNINST_KEY}" "NoModify" 1
  WriteRegDWORD HKLM "${UNINST_KEY}" "NoRepair" 1
  WriteRegStr HKLM "${UNINST_KEY}" "Comments" "DMDirc - The intelligent IRC client"
  WriteRegStr HKLM "${UNINST_KEY}" "InstallLocation" "$\"$INSTDIR$\""
  WriteRegStr HKLM "${UNINST_KEY}" "StartMenuPath" "$\"$StartMenuFolder$\""

  ;Create uninstaller
  WriteUninstaller "$INSTDIR\Uninstall.exe"

  !insertmacro MUI_STARTMENU_WRITE_BEGIN Application
    CreateDirectory "$SMPROGRAMS\$StartMenuFolder"
    CreateShortCut "$SMPROGRAMS\$StartMenuFolder\DMDirc.lnk" "$INSTDIR\DMDirc.exe"
    CreateShortCut "$SMPROGRAMS\$StartMenuFolder\Uninstall.lnk" "$INSTDIR\Uninstall.exe"
  !insertmacro MUI_STARTMENU_WRITE_END

SectionEnd

Section "Desktop" SecDesktop
    CreateShortCut "$DESKTOP\DMDirc.lnk" "$INSTDIR\DMDirc.exe"
SectionEnd

Section "Quick Launch" SecQuickLaunch
  CreateShortCut "$QUICKLAUNCH\DMDirc.lnk" "$INSTDIR\DMDirc.exe"
SectionEnd

Section "Register URL Protocol" SecProtocol
  WriteRegStr HKCR "irc" "" "URL:IRC Protocol"
  WriteRegStr HKCR "irc" "URL Protocol" ""
  WriteRegBin HKCR "irc" "EditFlags" 02000000
  WriteRegStr HKCR "irc\DefaultIcon" "" "$\"$INSTDIR\icon.ico$\""
  WriteRegStr HKCR "irc\Shell\open\command" "" "$\"$INSTDIR\DMDirc.exe$\" -e -c %1"
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
  DeleteRegKey HKCR "irc"
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
FunctionEnd

Function un.onInit
  checkRunning:
    ClearErrors
    FileOpen $R0 "$INSTDIR\DMDirc.exe" a
    ${If} ${Errors}
      MessageBox MB_YESNO|MB_ICONEXCLAMATION \
      "DMDirc is open, uninstallation cannot continue. Try again?" \
      IDYES checkRunning IDNO abort
    ${ELSE}
      GoTo continue
    ${EndIf}
    FileClose $R0
  abort:
    Abort
  continue:
FunctionEnd