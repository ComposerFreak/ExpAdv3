@echo off
echo WARNING: THIS SCRIPT WILL PUBLISH A NEW ADDON!
pause

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

	@echo on
	gmpublish.exe create -addon "%gma%" -icon "%adir%\icon.jpg"
	@echo off
	
	pause

	echo Deleting temporary gma file
	del "%gma%"

	pause

) else (

	echo Failed to create gma file, please check error log!
	pause

)

