@echo off
call pull.bat
choice /d y /t 3 > nul
call hugo
choice /d y /t 3 > nul
git config core.autocrlf true
git add .
git commit -m "build"
git push https://github.com/eyalmolad/gotask.net.git


