@echo off


rem timeout /t 600 > nul


start /wait python "..\archive_06_playlist_to_excel.py"


start /wait python archive_07_sync_to_drive.py


start /wait python archive_08_remove_files_from_drive.py