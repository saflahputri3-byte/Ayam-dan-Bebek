@echo off
title AGI Ayam & Bebek ERP
cd /d "%~dp0"
echo ===================================================
echo   AGI AYAM & BEBEK - SISTEM ERP TERINTEGRASI
echo ===================================================
echo.
echo Menjalankan aplikasi ERP Mode Presentasi...
echo.
echo Membuka di browser: http://localhost:5173/
start http://localhost:5173/
echo.
echo ===================================================
echo Server aktif di: http://localhost:5173/
echo (Biarkan jendela ini tetap terbuka selama aplikasi digunakan)
echo ===================================================
echo.
call npx.cmd vite preview --host 0.0.0.0 --port 5173
pause
