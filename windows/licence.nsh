  !macro CUSTOM_PAGE_LICENCE
    Page custom CUSTOM_PAGE_LICENCE
  !macroend

Function CUSTOM_PAGE_LICENCE

  nsDialogs::create /NOUNLOAD 1018
  !insertmacro MUI_HEADER_TEXT "License agreement" "Please review the license terms before installing DMDirc."
  nsDialogs::CreateControl /NOUNLOAD ${__NSD_Text_CLASS} ${DEFAULT_STYLES}|${ES_READONLY}|${WS_TABSTOP}|${ES_MULTILINE}|${WS_VSCROLL} ${__NSD_Text_EXSTYLE} 0 0 -1 -1 ""
  Pop $0
  StrCpy $1 "Copyright (c) 2006-2011 Chris Smith, Shane Mc Cormack, Gregory Holmes$\r$\n$\r$\n"
  SendMessage $0 ${EM_REPLACESEL} "0" "STR:$1"
  StrCpy $1 "Permission is hereby granted, free of charge, to any person obtaining a copy of "
  SendMessage $0 ${EM_REPLACESEL} "0" "STR:$1"
  StrCpy $1 "this software and associated documentation files (the $\"Software$\"), to deal in "
  SendMessage $0 ${EM_REPLACESEL} "0" "STR:$1"
  StrCpy $1 "the Software without restriction, including without limitation the rights to "
  SendMessage $0 ${EM_REPLACESEL} "0" "STR:$1"
  StrCpy $1 "use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies "
  SendMessage $0 ${EM_REPLACESEL} "0" "STR:$1"
  StrCpy $1 "of the Software, and to permit persons to whom the Software is furnished to do "
  SendMessage $0 ${EM_REPLACESEL} "0" "STR:$1"
  StrCpy $1 "so, subject to the following conditions:$\r$\n$\r$\nThe above copyright notice "
  SendMessage $0 ${EM_REPLACESEL} "0" "STR:$1"
  StrCpy $1 "and this permission notice shall be included in all copies or substantial "
  SendMessage $0 ${EM_REPLACESEL} "0" "STR:$1"
  StrCpy $1 "portions of the Software.$\r$\n$\r$\n"
  SendMessage $0 ${EM_REPLACESEL} "0" "STR:$1"
  StrCpy $1 "THE SOFTWARE IS PROVIDED $\"AS IS$\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR "
  SendMessage $0 ${EM_REPLACESEL} "0" "STR:$1"
  StrCpy $1 "IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, "
  SendMessage $0 ${EM_REPLACESEL} "0" "STR:$1"
  StrCpy $1 "FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE "
  SendMessage $0 ${EM_REPLACESEL} "0" "STR:$1"
  StrCpy $1 "AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER "
  SendMessage $0 ${EM_REPLACESEL} "0" "STR:$1"
  StrCpy $1 "LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, "
  SendMessage $0 ${EM_REPLACESEL} "0" "STR:$1"
  StrCpy $1 "OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE "
  SendMessage $0 ${EM_REPLACESEL} "0" "STR:$1"
  StrCpy $1 "SOFTWARE."
  SendMessage $0 ${EM_REPLACESEL} "0" "STR:$1"
  nsDialogs::Show

FunctionEnd