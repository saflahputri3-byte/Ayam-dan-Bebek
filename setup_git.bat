@echo off
set GIT="C:\Users\LENOVO-i5-8\AppData\Local\Microsoft\WinGet\Packages\Git.MinGit_Microsoft.Winget.Source_8wekyb3d8bbwe\cmd\git.exe"
cd /d D:\agy\AGI
%GIT% init -b main
%GIT% config user.name "saflahputri3-byte"
%GIT% config user.email "saflahputri3@gmail.com"
%GIT% add .
%GIT% commit -m "Initial commit AGI Ayam Bebek ERP"
%GIT% remote add origin https://github.com/saflahputri3-byte/Ayam-dan-Bebek.git
%GIT% remote -v
%GIT% status
