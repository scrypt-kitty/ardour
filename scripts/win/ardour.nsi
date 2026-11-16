; Installer for the native Windows (MSYS2/UCRT64) Ardour bundle.
; Built by: scripts/win/build-msys2.sh installer
; Required defines: VERSION, BUNDLE (dir produced by `package`), ICON, LICENSE, OUTFILE, NSISINC
Unicode true
!ifndef VERSION
  !error "pass -DVERSION=..."
!endif

!define PRODUCT   "Ardour"
!define MAJOR     "9"
!define UNINSTKEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT}${MAJOR}"
!define SWKEY     "Software\${PRODUCT}\v${MAJOR}"
!define ASSOC     ".ardour"

!addincludedir "${NSISINC}"
!include MUI2.nsh
!include LogicLib.nsh
!include FileFunc.nsh
!include FileAssociation.nsh

Name "${PRODUCT} ${VERSION}"
OutFile "${OUTFILE}"
InstallDir "$PROGRAMFILES64\${PRODUCT} ${MAJOR}"
InstallDirRegKey HKLM "${SWKEY}" "Install_Dir"
RequestExecutionLevel admin
SetCompressor /SOLID lzma
ShowInstDetails nevershow
BrandingText "${PRODUCT} ${VERSION} (native Windows build)"

!define MUI_ICON   "${ICON}"
!define MUI_UNICON "${ICON}"
!define MUI_ABORTWARNING
!insertmacro MUI_PAGE_LICENSE "${LICENSE}"
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!define MUI_FINISHPAGE_RUN "$INSTDIR\ardour.cmd"
!define MUI_FINISHPAGE_RUN_TEXT "Start ${PRODUCT} ${MAJOR}"
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "English"

; Upgrade in place: remove the previous install first so stale files from an
; older version can never be picked up (the launcher resolves its exe by name).
Function .onInit
  SetRegView 64
  ReadRegStr $R0 HKLM "${UNINSTKEY}" "UninstallString"
  ReadRegStr $R1 HKLM "${SWKEY}" "Install_Dir"
  StrCmp $R0 "" done
  StrCmp $R1 "" done
  ${IfNot} ${Silent}
    MessageBox MB_OKCANCEL|MB_ICONINFORMATION "${PRODUCT} is already installed in $R1.$\n$\nClick OK to replace it." IDOK +2
    Abort
  ${EndIf}
  ExecWait '$R0 /S _?=$R1'
  Delete "$R0"
  RMDir "$R1"
done:
FunctionEnd

Section "${PRODUCT} ${VERSION} (required)" SecMain
  SectionIn RO
  SetRegView 64
  SetOutPath "$INSTDIR"
  File "${ICON}"
  File "${BUNDLE}\ardour.cmd"
  File /r "${BUNDLE}\bin"
  File /r "${BUNDLE}\etc"
  File /r "${BUNDLE}\lib"
  File /r "${BUNDLE}\share"

  WriteRegStr   HKLM "${SWKEY}" "Install_Dir" "$INSTDIR"
  WriteRegStr   HKLM "${UNINSTKEY}" "DisplayName"     "${PRODUCT} ${VERSION}"
  WriteRegStr   HKLM "${UNINSTKEY}" "DisplayVersion"  "${VERSION}"
  WriteRegStr   HKLM "${UNINSTKEY}" "DisplayIcon"     "$INSTDIR\Ardour.ico"
  WriteRegStr   HKLM "${UNINSTKEY}" "Publisher"       "Ardour (native Windows build)"
  WriteRegStr   HKLM "${UNINSTKEY}" "InstallLocation" "$INSTDIR"
  WriteRegStr   HKLM "${UNINSTKEY}" "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegDWORD HKLM "${UNINSTKEY}" "NoModify" 1
  WriteRegDWORD HKLM "${UNINSTKEY}" "NoRepair" 1
  ${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
  IntFmt $0 "0x%08X" $0
  WriteRegDWORD HKLM "${UNINSTKEY}" "EstimatedSize" "$0"
  WriteUninstaller "$INSTDIR\uninstall.exe"
SectionEnd

Section "Start Menu shortcut" SecMenu
  SetShellVarContext all
  SetOutPath "$INSTDIR"
  CreateDirectory "$SMPROGRAMS\${PRODUCT} ${MAJOR}"
  ; SW_SHOWMINIMIZED keeps the launcher's console out of the way
  CreateShortCut "$SMPROGRAMS\${PRODUCT} ${MAJOR}\${PRODUCT} ${MAJOR}.lnk" "$INSTDIR\ardour.cmd" "" "$INSTDIR\Ardour.ico" 0 SW_SHOWMINIMIZED
  CreateShortCut "$SMPROGRAMS\${PRODUCT} ${MAJOR}\Uninstall.lnk" "$INSTDIR\uninstall.exe"
SectionEnd

Section "Desktop shortcut" SecDesktop
  SetShellVarContext all
  SetOutPath "$INSTDIR"
  CreateShortCut "$DESKTOP\${PRODUCT} ${MAJOR}.lnk" "$INSTDIR\ardour.cmd" "" "$INSTDIR\Ardour.ico" 0 SW_SHOWMINIMIZED
SectionEnd

Section "Associate ${ASSOC} session files" SecAssoc
  SetRegView 64
  ${registerExtension} "$INSTDIR\ardour.cmd" "${ASSOC}" "${PRODUCT} Session"
SectionEnd

!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  !insertmacro MUI_DESCRIPTION_TEXT ${SecMain}    "Ardour application, libraries and runtime."
  !insertmacro MUI_DESCRIPTION_TEXT ${SecMenu}    "Add ${PRODUCT} to the Start Menu."
  !insertmacro MUI_DESCRIPTION_TEXT ${SecDesktop} "Add a ${PRODUCT} shortcut to the desktop."
  !insertmacro MUI_DESCRIPTION_TEXT ${SecAssoc}   "Open ${ASSOC} session files with ${PRODUCT}."
!insertmacro MUI_FUNCTION_DESCRIPTION_END

Section "Uninstall"
  SetRegView 64
  SetShellVarContext all
  ${unregisterExtension} "${ASSOC}" "${PRODUCT} Session"
  ; remove only what we installed, never the whole $INSTDIR tree
  RMDir /r "$INSTDIR\bin"
  RMDir /r "$INSTDIR\etc"
  RMDir /r "$INSTDIR\lib"
  RMDir /r "$INSTDIR\share"
  Delete "$INSTDIR\ardour.cmd"
  Delete "$INSTDIR\Ardour.ico"
  Delete "$INSTDIR\uninstall.exe"
  RMDir "$INSTDIR"
  Delete "$SMPROGRAMS\${PRODUCT} ${MAJOR}\*.lnk"
  RMDir "$SMPROGRAMS\${PRODUCT} ${MAJOR}"
  Delete "$DESKTOP\${PRODUCT} ${MAJOR}.lnk"
  DeleteRegKey HKLM "${UNINSTKEY}"
  DeleteRegKey HKLM "${SWKEY}"
SectionEnd
