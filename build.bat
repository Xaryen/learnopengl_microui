@echo off

if not exist build mkdir build

xcopy /y /e /i shaders build\shaders >nul
if %ERRORLEVEL% neq 0 exit /b 1


odin run . -debug -keep-executable  -out:build\learnopengl.exe -show-timings -vet-shadowing

