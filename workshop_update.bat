@echo off

set adir=%cd%
echo Compiling addon from
echo %adir%

cd ..\
set gma=%cd%\__TEMP.gma

echo to the following gma file:
echo %gma%
pause

cd ..\..\bin\

@echo on
gmad create -folder "%adir%" -out "%gma%"
@echo off

if exist "%gma%" (
	echo Addon was packaged to gma file 
	echo publishing to workshop
) else (
	echo Failed to create gma file, please check error log!
	pause
	exit
)

@echo on
gmpublish update -addon "%gma%" -id "2001386268"
@echo off
pause


echo Deleting temporary gma file
del "%gma%"





