!ifndef VERSION
  !define VERSION "NONE"
!endif

!addplugindir "plugins"
!include "WordFunc.nsh"
!include "LogicLib.nsh"
!include "FileFunc.nsh"
!include "MUI2.nsh"
!include "UAC.nsh"

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
  IfFileExists $updateDir\.DMDircUpdater.exe update checkUpdateJar
  checkUpdateJar:
  IfFileExists $updateDir\.DMDirc.jar update checkUninstaller
  checkUninstaller:
  IfFileExists $updateDir\.Uninstaller.exe update checkLauncher
  checkLauncher:
  IfFileExists $updateDir\.DMDirc.exe update done
  update:
    !insertmacro UAC_AsUser_ExecShell "" "DMDircUpdater.exe" "" "" ""
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
  StrCmp ${VERSION} "" unversioned versioned
  unversioned:
    ExecWait '"$1\bin\javaw.exe" -ea -jar DMDirc.jar -l windows-NONE $R0' $0
  versioned:
    ExecWait '"$1\bin\javaw.exe" -ea -jar DMDirc.jar -l windows-${VERSION} $R0' $0
  strcmp $0 42 runclient exit
  warn:
    MessageBox MB_OK "Unable to find java, exiting."

  exit:

SectionEnd