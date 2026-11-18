@echo off
cd /d "F:\Xampp\htdocs\shahjalal_equity_hr"
for /f "delims=[] tokens=2" %%a in ('ping -4 -n 1 Munir-PC ^| findstr [') do set NetworkIP=%%a
php artisan serve --host 192.168.10.1 --port 8004
pause