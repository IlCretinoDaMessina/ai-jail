@echo off
cd /d "D:\.coding\.ai-jail" || (
    echo Failed to open ai-jail project directory.
    pause
    exit /b 1
)
opencode -m openai/gpt-5.6-sol
if errorlevel 1 pause
