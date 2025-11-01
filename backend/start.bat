@echo off
cd /d %~dp0
call venv\Scripts\activate.bat
echo Backend starting on http://localhost:8000
python main.py

