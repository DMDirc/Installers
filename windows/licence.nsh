  !macro CUSTOM_PAGE_LICENCE
    Page custom CUSTOM_PAGE_LICENCE
  !macroend

Function CUSTOM_PAGE_LICENCE

  nsDialogs::create /NOUNLOAD 1018
  !insertmacro MUI_HEADER_TEXT "License agreement" "Please review the license terms before installing DMDirc."
  nsDialogs::CreateControl /NOUNLOAD ${__NSD_Text_CLASS} ${DEFAULT_STYLES}|${ES_READONLY}|${WS_TABSTOP}|${ES_MULTILINE}|${WS_VSCROLL} ${__NSD_Text_EXSTYLE} 0 0 -1 -1 ""
  Pop $0
  StrCpy $1 "Copyright (c) 2006-2015 DMDirc Developers$\r$\n$\r$\n"
  SendMessage $0 ${EM_REPLACESEL} "0" "STR:$1"
  StrCpy $1 "Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the $\"Software$\"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:$\r$\n$\r$\n"
  SendMessage $0 ${EM_REPLACESEL} "0" "STR:$1"
  StrCpy $1 "The above copyright notice and this permission notice shall be included in all copies or substantial, portions of the Software.$\r$\n$\r$\n"
  SendMessage $0 ${EM_REPLACESEL} "0" "STR:$1"
  StrCpy $1 "THE SOFTWARE IS PROVIDED $\"AS IS$\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE."
  SendMessage $0 ${EM_REPLACESEL} "0" "STR:$1"
  nsDialogs::Show

FunctionEnd