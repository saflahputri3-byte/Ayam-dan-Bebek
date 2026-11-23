@echo off
set GIT="C:\Users\LENOVO-i5-8\AppData\Local\Microsoft\WinGet\Packages\Git.MinGit_Microsoft.Winget.Source_8wekyb3d8bbwe\cmd\git.exe"
cd /d D:\agy\AGI
%GIT% add -A
%GIT% commit -m "fix: settings error details, currency and timezone fallbacks, remove type email blocking"
for /f "tokens=*" %%t in ('gh auth token') do (
  %GIT% remote set-url origin https://x-access-token:%%t@github.com/saflahputri3-byte/Ayam-dan-Bebek.git
  %GIT% push origin main
  %GIT% remote set-url origin https://github.com/saflahputri3-byte/Ayam-dan-Bebek.git
)
