; This is a file for creating an installer for Abiword Dictionaries using NSIS 
; by Alan Horkan <horkana@tcd.ie>
; modified by Michael D. Pritchett <mpritchett@attglobal.net>

; Do a Cyclic Redundancy Check to make sure the installer 
; was not corrupted by the download.  
CRCCheck on

; The name of the installer
Name "AbiWord Dictionary - Deutschmed"
Icon "setup.ico"
OutFile "AbiWord_Dictionary_Deutschmed.exe"

; License Information
LicenseText "This program is Licensed under the GNU General Public License (GPL)."
LicenseData "..\..\..\..\COPYING"

; The default installation directory
InstallDir $PROGRAMFILES\AbiSuite2

; Registry key to check for directory (so if you install again, it will overwrite the old one automatically)
InstallDirRegKey HKLM SOFTWARE\Abisuite\AbiWord\v2 "Install_Dir"

; The text to prompt the user to enter a directory
ComponentText "This will install Abiword's Deutschmed Dictionary on your computer."

; The text to prompt the user to enter a directory
DirText "Choose the AbiSuite directory where you previously installed Abiword:"

CheckBitmap modern.bmp

; The stuff that must be installed
; binary, license, and Deutschmed dictionary
Section "Abiword.exe (required)"

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; Set output path to the installation directory.
	SetOutPath $INSTDIR\dictionary
	File "..\..\..\..\..\abispell\le\deutschmed.hash"

	SetOutPath $INSTDIR
	File /oname=copying.txt "..\..\..\..\COPYING"
	File "..\..\..\..\user\wp\readme.txt"
  
SectionEnd

; eof
