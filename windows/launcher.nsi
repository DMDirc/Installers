!ifndef VERSION
  !define VERSION "NONE"
!endif

!include "WordFunc.nsh"
!include "LogicLib.nsh"
!include "FileFunc.nsh"
!include "MUI2.nsh"

!define JRE_VERSION "1.6"
!define JRE_URL "www.dmdirc.com/getjava.php?os=windows"

!include "JREDyna.nsh"

Name "Launcher"
OutFile "files\DMDirc.exe"
RequestExecutionLevel user
Icon "files\icon.ico"
UninstallIcon "files\icon.ico"

var updateDir

Function .onInit
  setSilent silent
  Strcpy $updateDir $APPDATA\DMDirc

  ${GetParameters} $R0
  ${GetOptions} $R0 "-d " $R1
  StrCmp $R1 "" dir
  strcpy $updateDir $R1
  dir:
  ${GetParameters} $R0
  ${GetOptions} $R0 "--directory " $R1
  StrCmp $R1 "" continue
  strcpy $updateDir $R1
  continue:
FunctionEnd

Function checkForUpdates
  IfFileExists .DMDircUpdater.exe updateJar continue
    updateJar:
      delete "$EXEDIR\DMDircUpdater.exe.jar"
      rename "$updateDir\.DMDircUpdater.exe" "$EXEDIR\DMDircUpdater.exe"
      delete "$updateDir\.DMDircUpdater.exe"
  continue:
  IfFileExists .DMDirc.jar update checkUpdater
  checkUpdater:
  IfFileExists .DMDircUpdater.exe update checkLauncher
  checkLauncher:
  IfFileExists .DMDirc.exe update checkUninstaller
  checkUninstaller:
  IfFileExists .Uninstaller.exe update done
  update:
    Exec 'DMDircUpdater.exe'
    Quit
  done:
FunctionEnd

Section "launch"
  runclient:
  Call checkForUpdates
  SetAutoClose true
  push $0
  push $1
  push $2
  
  
  Push "${JRE_VERSION}"
  Call DetectJRE
  Pop $0
  Pop $1
  StrCmp $0 "OK" continue warn
  continue:
  ExecWait '"$1\bin\javaw.exe" -ea -jar DMDirc.jar -l windows-${VERSION} $R0' $0
  strcmp $0 42 runclient exit
  warn:
    MessageBox MB_OK "Unable to find java, exiting."

  exit:
SectionEnd