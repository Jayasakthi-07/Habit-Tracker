; Inno Setup script for Aura Habits — Premium Windows Habit Tracker
; Build the app first:  flutter build windows --release --no-tree-shake-icons
; Then compile this script with Inno Setup 6 (https://jrsoftware.org/isinfo.php).

#define MyAppName "Aura Habits"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Aura Habits"
#define MyAppExeName "AuraHabits.exe"
; Path to the Flutter release output, relative to this .iss file.
#define ReleaseDir "..\build\windows\x64\runner\Release"

[Setup]
AppId={{8F1C9E22-7B4A-4E3D-9C1A-AURA00HABITS01}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=Output
OutputBaseFilename=AuraHabits-Setup
SetupIconFile=..\windows\runner\resources\app_icon.ico
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayIcon={app}\{#MyAppExeName}
; Per-user install — no admin rights / UAC prompt required (least privilege).
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
; Embed version metadata into the setup executable.
VersionInfoVersion={#MyAppVersion}
VersionInfoCompany={#MyAppPublisher}
VersionInfoProductName={#MyAppName}
VersionInfoDescription={#MyAppName} Setup
; Gracefully close a running instance when installing/updating.
CloseApplications=yes
RestartApplications=no
; ---- Code signing (optional) ----
; Off by default so the installer compiles with no certificate. To produce a
; SIGNED installer + uninstaller, first define a sign tool, then compile with
; the SIGN symbol, e.g.:
;
;   "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" ^
;     /DSIGN ^
;     /Saurasign="signtool sign /fd sha256 /f C:\path\cert.pfx /p PASSWORD /tr http://timestamp.digicert.com /td sha256 $f" ^
;     installer\AuraHabits.iss
;
; (Sign the app exe itself with the same signtool command BEFORE running the
;  Flutter build's output through here, so the bundled AuraHabits.exe is signed too.)
#ifdef SIGN
SignTool=aurasign
SignedUninstaller=yes
#endif

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "startupicon"; Description: "Start {#MyAppName} when Windows starts"; GroupDescription: "Startup:"; Flags: unchecked

[Files]
; Bundle the entire Flutter release folder (exe + DLLs + data/).
Source: "{#ReleaseDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon
Name: "{userstartup}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: startupicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
