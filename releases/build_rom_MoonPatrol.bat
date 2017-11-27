@echo off

set    zip=mpatrol.zip
set ifiles=mpa-1.3m+mpa-2.3l+mpa-3.3k+mpa-4.3j+mpe-5.3e+mpe-4.3f+mpb-2.3m+mpb-1.3n+mpe-3.3h+mpe-2.3k+mpe-1.3l+mp-s1.1a
set  ofile=a.moonpt.rom

rem =====================================
setlocal ENABLEDELAYEDEXPANSION

set pwd=%~dp0
echo.
echo.

if EXIST %zip% (

	!pwd!7za x -otmp %zip%
	if !ERRORLEVEL! EQU 0 ( 
		cd tmp

		copy /b/y %ifiles% !pwd!%ofile%
		if !ERRORLEVEL! EQU 0 ( 
			echo.
			echo ** done **
			echo.
			echo Copy "%ofile%" into root of SD card
		)
		cd !pwd!
		rmdir /s /q tmp
	)

) else (

	echo Error: Cannot find "%zip%" file
	echo.
	echo Put "%zip%", "7za.exe" and "%~nx0" into the same directory
)

echo.
echo.
pause
