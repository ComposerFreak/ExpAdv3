@echo off

cd ..\
set gma=%cd%\__TEMP.gma

echo to the following gma file:
echo %gma%
pause

cd ..\..\bin\

@echo on
gmpublish update -addon "%gma%" -id "2001386268"
@echo off
pause






