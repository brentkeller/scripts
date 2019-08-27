@echo off

rem Azure Storage Emulator
start azemu

rem Open dev folder
rem start bsp

rem Try 'timeout X' or 'timeout /T X' if sleep doesn't seem to be working
sleep 5

rem Open console
start c

sleep 5

rem Open visual studio project
start C:\dev\buckscore\BuckScore.sln

sleep 15

rem Cosmos Emulator
start docemu

exit