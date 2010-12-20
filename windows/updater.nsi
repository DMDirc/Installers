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
  System::Call 'kernel32::CreateMutexA(i 0, i 0, t "DMDirc") ?e'
  Strcpy $updateDir $APPDATA\DMDirc
  Pop $R0
  StrCmp $R0 0 +3 -3
  MessageBox MB_OK "The installer is already running."
  Abort

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
  IfFileExists .DMDirc.jar updateJar checkUpdateUpdater
    updateJar:
      delete "$EXEDIR\DMDirc.jar"
      rename "$updateDir\.DMDirc.jar" "$EXEDIR\DMDirc.jar"
      delete "$updateDir\.DMDirc.jar"
  checkUpdateUpdater:
  IfFileExists .DMDircUpdater.exe updateUpdater checkUpdateLauncher
    updateUpdater:
      delete "$EXEDIR\DMDircUpdater.exe"
      rename "$updateDir\.DMDircUpdater.exe" "$EXEDIR\DMDircUpdater.exe"
      delete "$updateDir\.DMDircUpdater.exe"
  checkUpdateLauncher:
  IfFileExists .DMDirc.exe updateLauncher checkUpdateUninstaller
    updateLauncher:
      delete "$EXEDIR\DMDirc.exe"
      rename "$updateDir\.DMDirc.exe" "$EXEDIR\DMDirc.exe"
      delete "$updateDir\.DMDirc.exe"
  checkUpdateUninstaller:
  IfFileExists .Uninstaller.exe updateUninstaller finish
    updateUninstaller:
      delete "$EXEDIR\Uninstaller.exe"
      rename "$updateDir\.Uninstaller.exe" "$EXEDIR\Uninstaller.exe"
      delete "$updateDir\.Uninstaller.exe"
  finish:
    Exec 'DMDirc.exe'
SectionEnd