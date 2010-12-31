!ifndef VERSION
  !define VERSION "NONE"
!endif

!include "WordFunc.nsh"
!include "LogicLib.nsh"
!include "FileFunc.nsh"

RequestExecutionLevel admin
Name "Launcher"
OutFile "files\DMDircUpdater.exe"
RequestExecutionLevel user
Icon "files\icon.ico"
UninstallIcon "files\icon.ico"

var updateDir

Function .onInit
  setSilent silent
  Strcpy $updateDir $APPDATA\DMDirc

  ${GetParameters} $R0
  ${GetOptions} $R0 "-d=" $R1
  StrCmp $R1 "" dir
  strcpy $updateDir $R1
  dir:
  ${GetParameters} $R0
  ${GetOptions} $R0 "--directory=" $R1
  StrCmp $R1 "" continue
  strcpy $updateDir $R1
  continue:
FunctionEnd

Section ""
  SetAutoClose true
  IfFileExists $updateDir\.DMDirc.exe updateLauncher finish
    updateLauncher:
      delete "$EXEDIR\DMDirc.exe"
      rename "$updateDir\.DMDirc.exe" "$EXEDIR\DMDirc.exe"
      delete "$updateDir\.DMDirc.exe"
  finish:
    Exec 'DMDirc.exe'
SectionEnd