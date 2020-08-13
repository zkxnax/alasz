@echo off
pushd %~dp0
title ALAS run
set CMD=%SystemRoot%\system32\cmd.exe
:: -----------------------------------------------------------------------------
:check_Permissions
    echo Administrative permissions required. Detecting permissions...
    net session >nul 2>&1
    if %errorLevel% == 0 (
        echo Success: Administrative permissions confirmed.
        echo Press any to continue...
        pause >nul
        call :continue
    ) else (
        echo Failure: Current permissions inadequate.
    )
    pause >nul
:: -----------------------------------------------------------------------------
:continue
set ALAS_PATH=%~dp0
:: -----------------------------------------------------------------------------
set ADB=%ALAS_PATH%toolkit\Lib\site-packages\adbutils\binaries\adb.exe
set PYTHON=%ALAS_PATH%toolkit\python.exe
set GIT=%ALAS_PATH%toolkit\Git\cmd\git.exe
set LMESZINC=https://github.com/LmeSzinc/AzurLaneAutoScript.git
set WHOAMIKYO=https://github.com/whoamikyo/AzurLaneAutoScript.git
set ALAS_ENV=https://github.com/whoamikyo/alas-env.git
set ALAS_ENV_GITEE=https://gitee.com/lmeszinc/alas-env.git
set GITEE_URL=https://gitee.com/lmeszinc/AzurLaneAutoScript.git
set ADB_P=%ALAS_PATH%config\adb_port.ini
set CURL=%ALAS_PATH%toolkit\Git\mingw64\bin\curl.exe
set API_JSON=%ALAS_PATH%log\API_GIT.json
set config=%~dp0config\alas.ini
set configtemp=%~dp0config\alastemp.ini
set template=%~dp0config\template.ini
set git_log="%GIT% log --pretty=format:%%H%%n%%aI -1"
:: -----------------------------------------------------------------------------
set TOOLKIT_GIT=%~dp0toolkit\.git
if not exist %TOOLKIT_GIT% (
	echo You may need to update your dependencies
	echo Press any key to update
	pause > NUL
	call :toolkit_choose
) else (
	call :adb_kill
)
:: -----------------------------------------------------------------------------
:adb_kill
cls
call %ADB% kill-server > nul 2>&1
:: -----------------------------------------------------------------------------
set SCREENSHOT_FOLDER=%~dp0screenshots
if not exist %SCREENSHOT_FOLDER% (
	mkdir %SCREENSHOT_FOLDER%
)
:: -----------------------------------------------------------------------------
::if config\adb_port.ini dont exist, will be created
	if not exist %ADB_P% (
	cd . > %ADB_P%
		)
:: -----------------------------------------------------------------------------
:prompt
REM if adb_port is empty, prompt HOST:PORT
set "adb_empty=%~dp0config\adb_port.ini"
for %%A in (%adb_empty%) do if %%~zA==0 (
    echo Enter your HOST:PORT eg: 127.0.0.1:5555 for default bluestacks
	echo If you misstype, you can edit the file in config/adb_port.ini
    set /p adb_input=
	)
:: -----------------------------------------------------------------------------
REM if adb_input = 0 load from adb_port.ini
:adb_input
if [%adb_input%]==[] (
    call :CHECK_BST_BETA
	) else (
	REM write adb_input on adb_port.ini
	echo %adb_input% >> %ADB_P%
	call :FINDSTR
	)
:: -----------------------------------------------------------------------------
:: Will search for 127.0.0.1:62001 and replace for %ADB_PORT%
:FINDSTR
REM setlocal enableextensions disabledelayedexpansion
set "search=127.0.0.1:62001"
set "replace=%adb_input%"
set "string=%template%"

for /f "delims=" %%i in ('type "%string%" ^& break ^> "%string%" ') do (
    set "line=%%i"
    setlocal enabledelayedexpansion
    >>"%string%" echo(!line:%search%=%replace%!
    endlocal
	)
)
call :CHECK_BST_BETA
:: -----------------------------------------------------------------------------
:CHECK_BST_BETA
reg query HKEY_LOCAL_MACHINE\SOFTWARE\BlueStacks_bgp64_hyperv >nul
if %errorlevel% equ 0 (
	choice /t 10 /c yn /d n /m "Bluestacks Hyper-V BETA detected, would you like to use realtime_connection mode?"
	if errorlevel 2 call :load
	if errorlevel 1 call :realtime_connection
) else (
	call :load
)
:: -----------------------------------------------------------------------------
:realtime_connection
ECHO. Connecting with realtime mode ...
for /f "tokens=3" %%a in ('reg query HKEY_LOCAL_MACHINE\SOFTWARE\BlueStacks_bgp64_hyperv\Guests\Android\Config /v BstAdbPort') do (set /a port = %%a)
set "SERIAL_REALTIME=127.0.0.1:%port%"
echo connecting at %SERIAL_REALTIME%
call %ADB% connect %SERIAL_REALTIME%

set /a search=103
set "replace=serial = %SERIAL_REALTIME%"

(for /f "tokens=1*delims=:" %%a IN ('findstr /n "^" "%config%"') do (
    set "Line=%%b"
    IF %%a equ %search% set "Line=%replace%"
    setlocal enabledelayedexpansion
    ECHO(!Line!
    endlocal
))> %~dp0config\alastemp.ini
del %config%
MOVE %configtemp% %config%
)
call :init
:: -----------------------------------------------------------------------------
:: -----------------------------------------------------------------------------
:load
set "config=%~dp0config\alas.ini"
setlocal enabledelayedexpansion
for /f "delims=" %%i in (!config!) do (
    set line=%%i
    if "x!line:~0,9!"=="xserial = " (
        set serial=!line:~9!
    )
)
echo connecting at !serial!
call !ADB! connect !serial!
endlocal
REM Load adb_port.ini
REM
REM set /p ADB_PORT=<%ADB_P%
REM echo connecting at %ADB_PORT%
REM call %ADB% connect %ADB_PORT%
:: -----------------------------------------------------------------------------
:init
setlocal enabledelayedexpansion
for /f "delims=" %%a in (!config!) do (
    set line=%%a
    if "x!line:~0,15!"=="xgithub_token = " (
        set github_token=!line:~15!
		endlocal
    )
)
echo initializing uiautomator2
call %PYTHON% -m uiautomator2 init
REM timeout /t 1
:: uncomment the pause to catch errors
REM pause
:: timout
call :alas
:: -----------------------------------------------------------------------------
:alas
	cls
	echo.
	echo  :: Alas run
	echo.
	echo  Choose your option
    echo.
    echo	1. EN
	echo	2. CN
	echo	3. JP
	echo	4. UPDATER
	echo.
	echo  :: Type a 'number' and press ENTER
	echo  :: Type 'exit' to quit
	echo.
	set /P menu=
		if %menu%==1 call :en
		if %menu%==2 call :cn
		if %menu%==3 call :jp
		if %menu%==4 call :choose_update_mode
		if %menu%==exit call :EOF
		else (
		cls
	echo.
	echo  :: Incorrect Input Entered
	echo.
	echo     Please type a 'number' or 'exit'
	echo     Press any key to retry to the menu...
	echo.
		pause > NUL
		call :alas
		)
:: -----------------------------------------------------------------------------
:en
if exist .git\ (
%CURL% -s https://api.github.com/repos/lmeszinc/AzurLaneAutoScript/git/refs/heads/master?access_token=%github_token% > %~dp0log\API_GIT.json
setlocal enableDelayedExpansion
FOR /f "skip=5 tokens=2 delims=:," %%I IN (!API_JSON!) DO IF NOT DEFINED sha SET "sha=%%I"
set sha=%sha:"=%
set sha=%sha: =%
FOR /F "delims=" %%i IN ('%GIT% log -1 "--pretty=%%H"') DO set LAST_LOCAL_GIT=%%i
:: -----------------------------------------------------------------------------
REM echo !sha!
REM echo !LAST_LOCAL_GIT!
REM echo Parse Ok
REM pause
:: -----------------------------------------------------------------------------
if !LAST_LOCAL_GIT! EQU !sha! (
	echo your ALAS is updated
	timeout /t 2
	call :run_en
) else (
	start /wait popup.exe
	choice /t 10 /c yn /d n /m "There is an update for ALAS. Download now?"
	if errorlevel 2 call :run_en
	if errorlevel 1 call :choose_update_mode
)
endlocal
) else (
	call :run_en
)
:: -----------------------------------------------------------------------------
:run_en
	call %PYTHON% --version >nul
	if %errorlevel% == 0 (
	echo Python Found in %PYTHON% Proceeding..
	echo Opening alas_en.pyw in %ALAS_PATH%
	call %PYTHON% alas_en.pyw
	call :alas
	) else (
		echo :: it was not possible to open alas_en.pyw, make sure you have a folder toolkit
		echo :: inside AzurLaneAutoScript folder.
		echo Alas PATH: %ALAS_PATH%
		echo Python Path: %PYTHON%
		echo.
        pause > NUL
        call :alas
	)
:: -----------------------------------------------------------------------------
:cn
if exist .git\ (
%CURL% -s https://api.github.com/repos/lmeszinc/AzurLaneAutoScript/git/refs/heads/master?access_token=%github_token% > %~dp0log\API_GIT.json
setlocal enableDelayedExpansion
FOR /f "skip=5 tokens=2 delims=:," %%I IN (!API_JSON!) DO IF NOT DEFINED sha SET "sha=%%I"
set sha=%sha:"=%
set sha=%sha: =%
FOR /F "delims=" %%i IN ('%GIT% log -1 "--pretty=%%H"') DO set LAST_LOCAL_GIT=%%i
:: -----------------------------------------------------------------------------
REM echo !sha!
REM echo !LAST_LOCAL_GIT!
REM echo Parse Ok
REM pause
:: -----------------------------------------------------------------------------
if !LAST_LOCAL_GIT! EQU !sha! (
	echo your ALAS is updated
	timeout /t 2
	call :run_en
) else (
	start /wait popup.exe
	choice /t 10 /c yn /d n /m "There is an update for ALAS. Download now?"
	if errorlevel 2 call :run_cn
	if errorlevel 1 call :choose_update_mode
)
endlocal
) else (
	call :run_cn
)
:: -----------------------------------------------------------------------------
:run_cn
	call %PYTHON% --version >nul
	if %errorlevel% == 0 (
	echo Python Found in %PYTHON% Proceeding..
	echo Opening alas_en.pyw in %ALAS_PATH%
	call %PYTHON% alas_cn.pyw
	call :alas
	) else (
		echo :: it was not possible to open alas_cn.pyw, make sure you have a folder toolkit
		echo :: inside AzurLaneAutoScript folder.
		echo Alas PATH: %ALAS_PATH%
		echo Python Path: %PYTHON%
		echo.
        pause > NUL
        call :alas
	)
:: -----------------------------------------------------------------------------
:jp
if exist .git\ (
%CURL% -s https://api.github.com/repos/lmeszinc/AzurLaneAutoScript/git/refs/heads/master?access_token=%github_token% > %~dp0log\API_GIT.json
setlocal enableDelayedExpansion
FOR /f "skip=5 tokens=2 delims=:," %%I IN (!API_JSON!) DO IF NOT DEFINED sha SET "sha=%%I"
set sha=%sha:"=%
set sha=%sha: =%
FOR /F "delims=" %%i IN ('%GIT% log -1 "--pretty=%%H"') DO set LAST_LOCAL_GIT=%%i
:: -----------------------------------------------------------------------------
REM echo !sha!
REM echo !LAST_LOCAL_GIT!
REM echo Parse Ok
REM pause
:: -----------------------------------------------------------------------------
if !LAST_LOCAL_GIT! EQU !sha! (
	echo your ALAS is updated
	timeout /t 2
	call :run_en
) else (
	start /wait popup.exe
	choice /t 10 /c yn /d n /m "There is an update for ALAS. Download now?"
	if errorlevel 2 call :run_jp
	if errorlevel 1 call :choose_update_mode
)
endlocal
) else (
	call :run_jp
)
:: -----------------------------------------------------------------------------
:run_jp
	call %PYTHON% --version >nul
	if %errorlevel% == 0 (
	echo Python Found in %PYTHON% Proceeding..
	echo Opening alas_en.pyw in %ALAS_PATH%
	call %PYTHON% alas_jp.pyw
	call :alas
	) else (
		echo :: it was not possible to open alas_jp.pyw, make sure you have a folder toolkit
		echo :: inside AzurLaneAutoScript folder.
		echo Alas PATH: %ALAS_PATH%
		echo Python Path: %PYTHON%
		echo.
        pause > NUL
        call :alas
	)
:: -----------------------------------------------------------------------------
:updater_menu
	cls
	echo.
	echo	:: This update only will work if you downloaded ALAS on
	echo	:: Release tab and installed with Easy_Install-v2.bat
	echo.
	echo	::Overwrite local changes::
	echo.
	echo.
	echo	1) https://github.com/LmeSzinc/AzurLaneAutoScript (Main Repo, When in doubt, use it)
	echo	2) https://github.com/whoamikyo/AzurLaneAutoScript (Mirrored Fork)
	echo	3) https://github.com/whoamikyo/AzurLaneAutoScript (nightly build, dont use)
	echo	4) https://gitee.com/lmeszinc/AzurLaneAutoScript.git (Recommended for CN users)
	echo	5) https://github.com/LmeSzinc/AzurLaneAutoScript (Dev build, use only if you know what you are doing)
	echo	6) Toolkit tools updater
	echo	7) Back to main menu
	echo.
	echo	:: Type a 'number' and press ENTER
	echo	:: Type 'exit' to quit
	echo.
	set /P choice=
		if %choice%==1 call :LmeSzinc
		if %choice%==2 call :whoamikyo
		if %choice%==3 call :nightly
		if %choice%==4 call :gitee
		if %choice%==5 call :LmeSzincD
		if %choice%==6 call :toolkit_updater
		if %choice%==7 call :alas
		if %choice%==exit call :EOF
		else (
		cls
	echo.
	echo  :: Incorrect Input Entered
	echo.
	echo     Please type a 'number' or 'exit'
	echo     Press any key to return to the menu...
	echo.
		pause > NUL
		call :alas
		)
:: -----------------------------------------------------------------------------
:update_menu_local
	cls
	echo.
	echo	:: This update only will work if you downloaded ALAS on
	echo	:: Release tab and installed with Easy_Install-v2.bat
	echo.
	echo	::Keep local changes::
	echo.
	echo.
	echo	1) https://github.com/LmeSzinc/AzurLaneAutoScript (Main Repo, When in doubt, use it)
	echo	2) https://github.com/whoamikyo/AzurLaneAutoScript (Mirrored Fork)
	echo	3) https://github.com/whoamikyo/AzurLaneAutoScript (nightly build, dont use)
	echo	4) https://gitee.com/lmeszinc/AzurLaneAutoScript.git (Recommended for CN users)
	echo	5) Back to main menu
	echo.
	echo	:: Type a 'number' and press ENTER
	echo	:: Type 'exit' to quit
	echo.
	set /P choice=
		if %choice%==1 call :LmeSzinc_local
		if %choice%==2 call :whoamikyo_local
		if %choice%==3 call :nightly_local
		if %choice%==4 call :gitee_local
		if %choice%==5 call :alas
		if %choice%==exit call :EOF
		else (
		cls
	echo.
	echo  :: Incorrect Input Entered
	echo.
	echo     Please type a 'number' or 'exit'
	echo     Press any key to return to the menu...
	echo.
		pause > NUL
		call :alas
		)
:: -----------------------------------------------------------------------------
:LmeSzinc
	call %GIT% --version >nul
	if %errorlevel% == 0 (
	echo GIT Found in %GIT% Proceeding
	echo Updating from LmeSzinc repository..
	call %GIT% fetch origin master
	call %GIT% reset --hard origin/master
	call %GIT% pull --ff-only origin master
	echo DONE!
	echo Press any key to proceed
	pause > NUL
	call :updater_menu
	) else (
		echo  :: Git not detected, maybe there was an installation issue
		echo check if you have this directory:
		echo AzurLaneAutoScript\toolkit\Git\cmd
		echo.
        pause > NUL
        call :alas
	)
:: -----------------------------------------------------------------------------
:LmeSzincD
	call %GIT% --version >nul
	if %errorlevel% == 0 (
	echo GIT Found in %GIT% Proceeding
	echo Updating from LmeSzinc Dev branch..
	call %GIT% fetch origin dev
	call %GIT% reset --hard origin/dev
	call %GIT% pull --ff-only origin dev
	echo DONE!
	echo Press any key to proceed
	pause > NUL
	call :updater_menu
	) else (
		echo  :: Git not detected, maybe there was an installation issue
		echo check if you have this directory:
		echo AzurLaneAutoScript\toolkit\Git\cmd
		echo.
        pause > NUL
        call :alas
	)
:: -----------------------------------------------------------------------------
:whoamikyo
	call %GIT% --version >nul
	if %errorlevel% == 0 (
	echo GIT Found in %GIT% Proceeding
	echo Updating from whoamikyo repository..
	call %GIT% fetch whoamikyo master
	call %GIT% reset --hard whoamikyo/master
	call %GIT% pull --ff-only whoamikyo master
	echo DONE!
	echo Press any key to proceed
	pause > NUL
	call :updater_menu
	) else (
		echo  :: Git not detected, maybe there was an installation issue
		echo check if you have this directory:
		echo AzurLaneAutoScript\toolkit\Git\cmd
        pause > NUL
        call :alas
	)
:: -----------------------------------------------------------------------------
:nightly
	call %GIT% --version >nul
	if %errorlevel% == 0 (
	echo GIT Found in %GIT% Proceeding
	echo Updating from whoamikyo nightly repository..
	call %GIT% fetch whoamikyo nightly
	call %GIT% reset --hard whoamikyo/nightly
	call %GIT% pull --ff-only whoamikyo nightly
	echo Press any key to proceed
	pause > NUL
	call :alas
	) else (
		echo  :: Git not detected, maybe there was an installation issue
		echo check if you have this directory:
		echo AzurLaneAutoScript\toolkit\Git\cmd
		echo.
        pause > NUL
        call :alas
	)
:: -----------------------------------------------------------------------------
:gitee
	call %GIT% --version >nul
	if %errorlevel% == 0 (
	echo GIT Found in %GIT% Proceeding
	echo Updating from LmeSzinc repository..
	call %GIT% fetch lmeszincgitee master
	call %GIT% reset --hard lmeszincgitee/master
	call %GIT% pull --ff-only lmeszincgitee master
	echo DONE!
	echo Press any key to proceed
	pause > NUL
	call :updater_menu
	) else (
		echo  :: Git not detected, maybe there was an installation issue
		echo check if you have this directory:
		echo AzurLaneAutoScript\toolkit\Git\cmd
        pause > NUL
        call :alas
	)
:: -----------------------------------------------------------------------------
rem :check_connection
rem cls
rem 	echo.
rem 	echo  :: Checking For Internet Connection to Github...
rem 	echo.
rem 	timeout /t 2 /nobreak > NUL

rem 	ping -n 1 google.com -w 20000 >nul

rem 	if %errorlevel% == 0 (
rem 	echo You have a good connection with Github! Proceeding...
rem 	echo press any to proceed
rem 	pause > NUL
rem 	call updater_menu
rem 	) else (
rem 		echo  :: You don't have a good connection out of China
rem 		echo  :: It might be better to update using Gitee
rem 		echo  :: Redirecting...
rem 		echo.
rem         echo     Press any key to continue...
rem         pause > NUL
rem         call start_gitee
rem 	)
:: -----------------------------------------------------------------------------
rem Keep local changes
:: -----------------------------------------------------------------------------
:choose_update_mode
	cls
	echo.
	echo.
	echo	::Choose update method::
	echo.
	echo	1) Overwrite local changes (Will undo any local changes)
	echo	2) Keep local changes (Useful if you have customized a map)
	echo	3) Back to main menu
	echo.
	echo	:: Type a 'number' and press ENTER
	echo	:: Type 'exit' to quit
	echo.
	set /P choice=
		if %choice%==1 call :updater_menu
		if %choice%==2 call :update_menu_local
		if %choice%==3 call :alas
		if %choice%==exit call EOF
		else (
		cls
	echo.
	echo  :: Incorrect Input Entered
	echo.
	echo     Please type a 'number' or 'exit'
	echo     Press any key to return to the menu...
	echo.
		pause > NUL
		call :alas
		)
:: -----------------------------------------------------------------------------
:LmeSzinc_local
	call %GIT% --version >nul
	if %errorlevel% == 0 (
	echo GIT Found in %GIT% Proceeding
	echo Updating from LmeSzinc repository..
	call %GIT% stash
	call %GIT% pull origin master
	call %GIT% stash pop
	echo DONE!
	echo Press any key to proceed
	pause > NUL
	call :update_menu_local
	) else (
		echo  :: Git not detected, maybe there was an installation issue
		echo check if you have this directory:
		echo AzurLaneAutoScript\toolkit\Git\cmd
		echo.
        pause > NUL
        call :alas
	)
:: -----------------------------------------------------------------------------
:whoamikyo_local
	call %GIT% --version >nul
	if %errorlevel% == 0 (
	echo GIT Found in %GIT% Proceeding
	echo Updating from whoamikyo repository..
	call %GIT% stash
	call %GIT% pull whoamikyo master
	call %GIT% stash pop
	echo DONE!
	echo Press any key to proceed
	pause > NUL
	call :update_menu_local
	) else (
		echo  :: Git not detected, maybe there was an installation issue
		echo check if you have this directory:
		echo AzurLaneAutoScript\toolkit\Git\cmd
        pause > NUL
        call :alas
	)
:: -----------------------------------------------------------------------------
:nightly_local
	call %GIT% --version >nul
	if %errorlevel% == 0 (
	echo GIT Found in %GIT% Proceeding
	echo Updating from whoamikyo nightly repository..
	call %GIT% stash
	call %GIT% pull whoamikyo nightly
	call %GIT% stash pop
	echo Press any key to proceed
	pause > NUL
	call :update_menu_local
	) else (
		echo  :: Git not detected, maybe there was an installation issue
		echo check if you have this directory:
		echo AzurLaneAutoScript\toolkit\Git\cmd
		echo.
        pause > NUL
        call :alas
	)
:: -----------------------------------------------------------------------------
:gitee_local
	call %GIT% --version >nul
	if %errorlevel% == 0 (
	echo GIT Found in %GIT% Proceeding
	echo Updating from LmeSzinc repository..
	call %GIT% stash
	call %GIT% pull lmeszincgitee master
	call %GIT% stash pop
	echo DONE!
	echo Press any key to proceed
	pause > NUL
	call :update_menu_local
	) else (
		echo  :: Git not detected, maybe there was an installation issue
		echo check if you have this directory:
		echo AzurLaneAutoScript\toolkit\Git\cmd
        pause > NUL
        call :alas
	)
:: -----------------------------------------------------------------------------
:toolkit_choose
	cls
	echo.
	echo	:: This will add the toolkit repository for updating
	echo.
	echo	::Toolkit::
	echo.
	echo.
	echo	1) https://github.com/whoamikyo/alas-env.git (Default Github)
	echo	2) https://gitee.com/lmeszinc/alas-env.git (Recommended for CN users)
	echo	3) Back to main menu
	echo.
	echo	:: Type a 'number' and press ENTER
	echo	:: Type 'exit' to quit
	echo.
	set /P choice=
		if %choice%==1 call :toolkit_github
		if %choice%==2 call :toolkit_gitee
		if %choice%==3 call :alas
		if %choice%==exit call :EOF
		else (
		cls
	echo.
	echo  :: Incorrect Input Entered
	echo.
	echo     Please type a 'number' or 'exit'
	echo     Press any key to return to the menu...
	echo.
		pause > NUL
		call :alas
		)
:: -----------------------------------------------------------------------------
:toolkit_github
	call %GIT% --version >nul
	if %errorlevel% == 0 (
	echo GIT Found in %GIT% Proceeding
	echo Updating toolkit..
	call cd toolkit
	echo ## initializing toolkit..
	call %GIT% init
	call %GIT% config --global core.autocrlf false
	echo ## Adding files
	echo ## This process may take a while
	call %GIT% add -A
	echo ## adding origin..
	call %GIT% remote add origin %ALAS_ENV%
	echo Fething...
	call %GIT% fetch origin master
	call %GIT% reset --hard origin/master
	echo Pulling...
	call %GIT% pull --ff-only origin master
	call cd ..
	echo DONE!
	echo Press any key to proceed
	pause > NUL
	call :adb_kill
	) else (
		echo	:: Git not found, maybe there was an installation issue
		echo	:: check if you have this directory %GIT%
        pause > NUL
        call :adb_kill
	)
:: -----------------------------------------------------------------------------
:toolkit_gitee
	call %GIT% --version >nul
	if %errorlevel% == 0 (
	echo GIT Found in %GIT% Proceeding
	echo Updating toolkit..
	call cd toolkit
	echo ## initializing toolkit..
	call %GIT% init
	call %GIT% config --global core.autocrlf false
	echo ## Adding files
	echo ## This process may take a while
	call %GIT% add -A
	echo ## adding origin..
	call %GIT% remote add origin %ALAS_ENV_GITEE%
	echo Fething...
	call %GIT% fetch origin master
	call %GIT% reset --hard origin/master
	echo Pulling...
	call %GIT% pull --ff-only origin master
	call cd ..
	echo DONE!
	echo Press any key to proceed
	pause > NUL
	call :adb_kill
	) else (
		echo	:: Git not found, maybe there was an installation issue
		echo	:: check if you have this directory %GIT%
        pause > NUL
        call :adb_kill
	)
:: -----------------------------------------------------------------------------
:toolkit_updater
	call %GIT% --version >nul
	if %errorlevel% == 0 (
	echo GIT Found in %GIT% Proceeding
	echo Updating toolkit..
	call cd toolkit
	call %GIT% fetch origin master
	call %GIT% reset --hard origin/master
	echo Pulling...
	call %GIT% pull --ff-only origin master
	echo DONE!
	call cd ..
	echo Press any key to proceed
	pause > NUL
	call :updater_menu
	) else (
		echo  :: Git not detected, maybe there was an installation issue
		echo check if you have this directory:
		echo AzurLaneAutoScript\toolkit\Git\cmd
        pause > NUL
        call :alas
	)
:: -----------------------------------------------------------------------------
::Add paths
rem call :AddPath %ALAS_PATH%
rem call :AddPath %ADB%
rem call :AddPath %PYTHON%
rem call :AddPath %GIT%

rem :UpdateEnv
rem ECHO Making updated PATH go live . . .
rem REG delete HKCU\Environment /F /V TEMPVAR > nul 2>&1
rem setx TEMPVAR 1 > nul 2>&1
rem REG delete HKCU\Environment /F /V TEMPVAR > nul 2>&1
:: -----------------------------------------------------------------------------
rem :AddPath <pathToAdd>
rem ECHO %PATH% | FINDSTR /C:"%~1" > nul
rem IF ERRORLEVEL 1 (
rem 	 REG add "HKLM\SYSTEM\CurrentControlset\Control\Session Manager\Environment" /f /v PATH /t REG_SZ /d "%PATH%;%~1" >> add-paths-detail.log
rem 	IF ERRORLEVEL 0 (
rem 		ECHO Adding   %1 . . . Success! >> add-paths.log
rem 		set "PATH=%PATH%;%~1"
rem 		rem set UPDATE=1
rem 	) ELSE (
rem 		ECHO Adding   %1 . . . FAILED. Run this script with administrator privileges. >> add-paths.log
rem 	)
rem ) ELSE (
rem 	ECHO Skipping %1 - Already in PATH >> add-paths.log
rem 	)
:: -----------------------------------------------------------------------------
rem :AddPath <pathToAdd>
rem ECHO %PATH% | FINDSTR /C:"%~1" > nul
rem IF ERRORLEVEL 1 (
rem 	REG add "HKLM\SYSTEM\CurrentControlset\Control\Session Manager\Environment" /f /v PATH /t REG_SZ /d "%PATH%;%~1"  > nul 2>&1
rem 	IF ERRORLEVEL 0 (
rem 		ECHO Adding   %1 . . . Success!
rem 		set "PATH=%PATH%;%~1"
rem 		set UPDATE=1
rem 	) ELSE (
rem 		ECHO Adding   %1 . . . FAILED. Run this script with administrator privileges.
rem 	)
rem ) ELSE (
rem 	ECHO Skipping %1 - Already in PATH
rem 	)
:: -----------------------------------------------------------------------------
:EOF
exit
