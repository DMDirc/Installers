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
  System::Call 'kernel32::CreateMutexA(i 0, i 0, t "DMDirc") ?e'
  Strcpy $updateDir $APPDATA\DMDirc
  Pop $R0
  StrCmp $R0 0 +3
  MessageBox MB_OK "DMDirc is already running."
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

Function checkForUpdates
  ClearErrors
  IfFileExists .DMDirc.jar update checkUpdater
  checkUpdater:
  IfFileExists .DMDircUpdater.exe update checkLauncher
  checkLauncher:
  IfFileExists .DMDirc.exe update done
  update:
    Exec 'DMDircUpdater.exe'
    Quit
  done:
FunctionEnd

Section "launch"
  Call checkForUpdates
  SetAutoClose true
  runclient:
  push $0
  push $1
  push $2
  
  
  Push "${JRE_VERSION}"
  Call DetectJRE
  Pop $0
  Pop $1
  StrCmp $0 "OK" continue warn
  continue:
  ExecWait '"$1" -jar DMDirc.jar' $0
  strcmp $0 42 runclient exit
  warn:
    MessageBox MB_OK "Unable to find java, exiting."

  exit:
SectionEnd