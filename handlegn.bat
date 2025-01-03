@echo off
setlocal enabledelayedexpansion enableextensions
title Project Initialization Setup


REM =============================
REM Requirements Configuration
REM =============================
echo Checking and configuring requirements...
echo.

REM Check for Administrator privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This script requires Administrator privileges.
    echo Requesting administrative privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

REM Add the rest of your script below
echo Running with Administrator privileges...


REM =============================
REM Node.js Check and Install
REM =============================
echo Checking Node.js installation...
node -v
if errorlevel 1 (
    echo Node.js is not installed. Installing Node.js...
    REM Download Node.js installer (replace the URL with the latest version if needed)
    powershell -Command "Invoke-WebRequest -Uri https://nodejs.org/dist/v18.18.0/node-v18.18.0-x64.msi -OutFile nodejs_installer.msi"
    
    REM Install Node.js silently
    msiexec /i nodejs_installer.msi /quiet /norestart
    
    REM Clean up installer
    del nodejs_installer.msi

    echo Node.js has been installed.
)


@echo off
REM ==============================
REM Git Check
REM ==============================

echo Checking Git installation...

REM Check if Git is installed
git --version >nul 2>nul
if %errorlevel% neq 0 (
    echo Git is not installed. Attempting to install Git...

    REM Check if Chocolatey is installed
    choco -v >nul 2>nul
    if %errorlevel% neq 0 (
        echo Chocolatey is not installed. Installing Chocolatey...

        REM Install Chocolatey
        set "CHOCOLATEY_INSTALL=https://community.chocolatey.org/install.ps1"
        powershell -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('%CHOCOLATEY_INSTALL%'))"

        REM Check if Chocolatey was installed successfully
        choco -v >nul 2>nul
        if %errorlevel% neq 0 (
            echo Failed to install Chocolatey. Please install Chocolatey manually from https://chocolatey.org/install
            exit /b 1
        ) else (
            echo Chocolatey successfully installed!
        )
    )

    REM Install Git using Chocolatey
    echo Installing Git using Chocolatey...
    choco install git -y

    REM Verify Git installation again
    git --version >nul 2>nul
    if %errorlevel% neq 0 (
        echo Git installation failed. Please check your system.
        exit /b 1
    ) else (
        echo Git successfully installed!
    )
) else (
    git --version
)

REM =============================
REM GitHub CLI Check
REM =============================
echo Checking GitHub CLI installation...
gh --version 2>&1
if errorlevel 1 (
    echo GitHub CLI not found. Installing...
    choco install gh -y
    refreshenv
)

REM =============================
REM Git Configuration
REM =============================
echo Configuring Git...

REM Enable delayed variable expansion
setlocal enabledelayedexpansion

REM Check if Git username is set
for /f "delims=" %%i in ('git config --global user.name') do set "GIT_USERNAME=%%i"

if "%GIT_USERNAME%"=="" (
    REM If not set, prompt for username
    set /p "GIT_USERNAME=Enter your Git username: "
    
    REM Echo the Git username after input (delayed expansion)
    echo GitUser: !GIT_USERNAME!
    
    REM Check if GitHub username exists using delayed expansion for correct variable passing
    curl -s https://api.github.com/users/!GIT_USERNAME! | findstr /c:"\"login\": \"!GIT_USERNAME!\"" >nul
    if errorlevel 1 (
        echo GitHub username "!GIT_USERNAME!" does not exist. Please enter a valid GitHub username.
        exit /b
    ) else (
        git config --global user.name "!GIT_USERNAME!"
        echo Git username set to: !GIT_USERNAME!
    )
) else (
    REM If set, display the username
    echo Git username is: %GIT_USERNAME%
)

REM Check if Git email is set
for /f "delims=" %%i in ('git config --global user.email') do set "GIT_EMAIL=%%i"

if "%GIT_EMAIL%"=="" (
    REM If not set, prompt for email
    set /p "GIT_EMAIL=Enter your Git email: "
    
    REM Check if the email is associated with a GitHub account (basic check)
    curl -s "https://api.github.com/search/users?q=%GIT_EMAIL%+in:email" | findstr /c:"\"login\"" >nul
    if errorlevel 1 (
        echo GitHub account with the email "%GIT_EMAIL%" does not exist or is not associated with GitHub.
        exit /b
    ) else (
        git config --global user.email "%GIT_EMAIL%"
        echo Git email set to: %GIT_EMAIL%
    )
) else (
    REM If set, display the email
    echo Git email is: %GIT_EMAIL%
)

REM Final echo to confirm the configuration
echo Current Git username: !GIT_USERNAME! is connected.
REM End delayed expansion
endlocal

REM =============================
REM GitHub Authentication
REM =============================
echo Configuring GitHub CLI...

gh auth status >nul 2>&1
if errorlevel 1 (
    echo Logging into GitHub...
    gh auth login
)

REM =============================
REM Create Configuration File
REM =============================
echo Creating configuration file...

if not exist "config.ini" (
    echo Creating new configuration file...
    for /f "tokens=*" %%a in ('gh api user --jq ".login"') do set "GITHUB_USERNAME=%%a"
    
    echo [GitHub]> config.ini
    echo USERNAME=!GITHUB_USERNAME!>> config.ini
    echo.>> config.ini
    echo [Paths]>> config.ini
    echo PROJECT_BASE=%USERPROFILE%\Projectsbase>> config.ini
    echo TEMPLATE_PATH=%USERPROFILE%\ProjectTemplates>> config.ini
    echo.>> config.ini
    echo [Project]>> config.ini
    echo DEFAULT_DESCRIPTION=Created with Project Initializer>> config.ini
)


REM =============================
REM Create Template Directory
REM =============================
echo Setting up project templates...

set "TEMPLATE_DIR=%USERPROFILE%\ProjectTemplates"
if not exist "%TEMPLATE_DIR%" mkdir "%TEMPLATE_DIR%"

REM Define the path for the page.tsx template
set "PAGE_TEMPLATE=%TEMPLATE_DIR%\page.tsx"

REM Write the updated content to page.tsx
echo export default function Home() { > "%PAGE_TEMPLATE%"
echo   return ( >> "%PAGE_TEMPLATE%"
echo     ^<div className="flex h-screen w-full items-center justify-center bg-black flex-col"^> >> "%PAGE_TEMPLATE%"
echo       ^<svg >> "%PAGE_TEMPLATE%"
echo         xmlns="http://www.w3.org/2000/svg" >> "%PAGE_TEMPLATE%"
echo         width="200" >> "%PAGE_TEMPLATE%"
echo         height="128" >> "%PAGE_TEMPLATE%"
echo         viewBox="0 0 88 56" >> "%PAGE_TEMPLATE%"
echo         fill="none" >> "%PAGE_TEMPLATE%"
echo         role="img"^> >> "%PAGE_TEMPLATE%"
echo         ^<rect width="88" height="56" fill="" rx="8"/^> >> "%PAGE_TEMPLATE%"
echo         ^<path d="M28.4443 17.2266V35H24.4648V17.2266H28.4443Z" fill="#E5E5E5"/^> >> "%PAGE_TEMPLATE%"
echo         ^<path d="M39.0645 17.2266L32.1064 26.1133L28.0537 30.5078L27.3335 26.8091L30.0068 22.9761L34.1816 17.2266H39.0645ZM34.4502 35L29.543 26.8823L32.5703 24.5264L39.1621 35H34.4502Z" fill="#E5E5E5"/^> >> "%PAGE_TEMPLATE%"
echo         ^<rect x="34" y="34" width="21" height="3" rx="1.5" fill="#FFC107"/^> >> "%PAGE_TEMPLATE%"
echo         ^<path d="M46.0322 31.0571L49.9873 17.2266H54.4185L48.3271 35H45.4341L46.0322 31.0571ZM42.4312 17.2266L46.374 31.0571L46.9966 35H44.0669L38.0122 17.2266H42.4312Z" fill="#E5E5E5"/^> >> "%PAGE_TEMPLATE%"
echo         ^<path d="M63.5498 40.9238V44H54.0894V40.9238H63.5498ZM55.4443 26.2266V44H51.4648V26.2266H55.4443ZM62.3291 33.3799V36.3584H54.0894V33.3799H62.3291ZM63.562 26.2266V29.3149H54.0894V26.2266H63.562Z" fill="#FFC107"/^> >> "%PAGE_TEMPLATE%"
echo         ^<circle cx="29.5" cy="26.5" r="2.5" fill="#FFC107"/^> >> "%PAGE_TEMPLATE%"
echo       ^</svg^> >> "%PAGE_TEMPLATE%"
echo >> "%PAGE_TEMPLATE%"
echo       ^<div className="text-white bg-[#FFC107] bg-opacity-25 px-4 py-2 rounded-full border-[#FFC107] border-[2px]"^> >> "%PAGE_TEMPLATE%"
echo         ^<p className="font-semibold font-mono"^>Project created successfully^</p^> >> "%PAGE_TEMPLATE%"
echo       ^</div^> >> "%PAGE_TEMPLATE%"
echo     ^</div^> >> "%PAGE_TEMPLATE%"
echo   ); >> "%PAGE_TEMPLATE%"
echo } >> "%PAGE_TEMPLATE%"


REM Create globals.css template
set "CSS_TEMPLATE=%TEMPLATE_DIR%\globals.css"
echo @tailwind base;> "%CSS_TEMPLATE%"
echo @tailwind components;>> "%CSS_TEMPLATE%"
echo @tailwind utilities;>> "%CSS_TEMPLATE%"

REM Create layout.tsx template
set "LAYOUT_TEMPLATE=%TEMPLATE_DIR%\layout.tsx"
echo import type { Metadata } from 'next'> "%LAYOUT_TEMPLATE%"
echo import './globals.css'>> "%LAYOUT_TEMPLATE%"
echo.>> "%LAYOUT_TEMPLATE%"
echo export const metadata: Metadata = {>> "%LAYOUT_TEMPLATE%"
echo   title: 'Project Template',>> "%LAYOUT_TEMPLATE%"
echo   description: 'Created with Project Initializer',>> "%LAYOUT_TEMPLATE%"
echo }>> "%LAYOUT_TEMPLATE%"
echo.>> "%LAYOUT_TEMPLATE%"
echo export default function RootLayout({>> "%LAYOUT_TEMPLATE%"
echo   children,>> "%LAYOUT_TEMPLATE%"
echo }: {>> "%LAYOUT_TEMPLATE%"
echo   children: React.ReactNode>> "%LAYOUT_TEMPLATE%"
echo }) {>> "%LAYOUT_TEMPLATE%"
echo   return (>> "%LAYOUT_TEMPLATE%"
echo     ^<html lang="en"^>>> "%LAYOUT_TEMPLATE%"
echo       ^<body^>{children}^</body^>>> "%LAYOUT_TEMPLATE%"
echo     ^</html^>>> "%LAYOUT_TEMPLATE%"
echo   )>> "%LAYOUT_TEMPLATE%"
echo }>> "%LAYOUT_TEMPLATE%"


REM =============================
REM Verification
REM =============================
echo Verifying setup...

set "TOOLS=node git gh npm"
for %%t in (%TOOLS%) do (
    where %%t >nul 2>&1
    if errorlevel 1 (
        echo Error: %%t is not properly installed
        exit /b 1
    )
)


REM Verify template files
if not exist "%PAGE_TEMPLATE%" (
    echo Error: Failed to create page.tsx template
    exit /b 1
)
if not exist "%CSS_TEMPLATE%" (
    echo Error: Failed to create globals.css template
    exit /b 1
)
if not exist "%LAYOUT_TEMPLATE%" (
    echo Error: Failed to create layout.tsx template
    exit /b 1
)


echo.
echo =============================
echo Setup completed successfully!
echo =============================
echo.
echo The following tools have been installed and configured:
echo - Node.js: %NODE_VERSION%
echo - Git: %GIT_VERSION%
echo - GitHub CLI
echo - NPM packages
echo.
echo Configuration files have been created at:
echo - %CD%\config.ini
echo - %TEMPLATE_DIR%
echo   - page.tsx
echo   - globals.css
echo   - layout.tsx
echo.
echo You can now run the main project initialization script.
echo.
Rem lr



echo ================================
echo Project Name
echo ================================
echo Enter the name of the project
set /p "PROJECT_NAME=Project Name: "

REM ================================
REM Read Configuration File for PROJECT_BASE
REM ================================
for /f "tokens=2 delims==" %%i in ('findstr /b "PROJECT_BASE" config.ini') do set "PROJECT_BASE=%%i"

set "PROJECT_PATH=%PROJECT_BASE%\%PROJECT_NAME%"

if not exist "%PROJECT_PATH%" (
    echo Creating project folder: %PROJECT_PATH%
    mkdir "%PROJECT_PATH%"
) else (
    echo Project folder already exists: %PROJECT_PATH%
    echo try another name for the folder.
    exit /b
)


for /f "tokens=2 delims==" %%i in ('findstr /b "USERNAME" config.ini') do set "USERNAME=%%i"


cd %PROJECT_PATH%

mkdir my-app
cd my-app

echo Initializing Next.js app in %cd%
call npx create-next-app@latest . --use-npm
if errorlevel 1 (
    echo Failed to initialize the Next.js app. Exiting.
    exit /b
)

del /q %cd%\public\*.* 
if errorlevel 1 (
    echo Failed to delete files in %cd%\public
) else (
    echo Successfully deleted files in %cd%\public
)

del /q %cd%\src\app\favicon.ico
if errorlevel 1 (
    echo Failed to delete %cd%\src\app\favicon.ico
) else (
    echo Successfully deleted %cd%\src\app\favicon.ico
)

call :replaceFile "%TEMPLATE_DIR%\page.tsx" "%cd%\src\app\page.tsx"
call :replaceFile "%TEMPLATE_DIR%\layout.tsx" "%cd%\src\app\layout.tsx"
call :replaceFile "%TEMPLATE_DIR%\globals.css" "%cd%\src\app\globals.css"

color 0A
echo Page.tsx;Layout.tsx;Globals.css edited Success.
color 07

cd %PROJECT_PATH%
rmdir /s /q my-app\.git


Rem here was the code

SET DESCRIPTION=Created by KVE
call git init
IF %ERRORLEVEL% NEQ 0 (
    echo Git init failed.
    exit /b 1
) ELSE (
    echo Git init successful.
)

echo. > README.md
IF %ERRORLEVEL% NEQ 0 (
    echo Failed to create README.md.
    exit /b 1
) ELSE (
    echo README.md created successfully.
)

call git add .
IF %ERRORLEVEL% NEQ 0 (
    echo Failed to add files to git.
    exit /b 1
) ELSE (
    echo Files added successfully.
)

call git commit -m "initial commit-KVE"
IF %ERRORLEVEL% NEQ 0 (
    echo Git commit failed.
    exit /b 1
) ELSE (
    echo Git commit successful.
)

@echo off

REM ================================
REM Create GitHub repository
REM ================================
echo Creating GitHub repository...

gh repo create !USERNAME!/!PROJECT_NAME! --description "Created with KVE Project Initializer" --private
IF ERRORLEVEL 1 (
    echo Error: GitHub repository creation failed.
    exit /b 1
) ELSE (
    echo GitHub repository created successfully.
)

REM ================================
REM Git Push
REM ================================
echo Setting up remote repository...
git remote add origin https://github.com/!USERNAME!/!PROJECT_NAME!.git
IF ERRORLEVEL 1 (
    echo Error: Failed to add remote repository.
    exit /b 1
)

git push --set-upstream origin master
IF ERRORLEVEL 1 (
    echo Error: Git push failed.
    exit /b 1
)

echo Git push successful.
echo Check it out. Go to https://github.com/!USERNAME!/!PROJECT_NAME! to see.
echo ================================

cd my-app
echo Starting development server...
start code .
call npm run dev

timeout /t 15 /nobreak >nul

curl -f http://localhost:3000 >nul 2>&1
if %errorlevel% neq 0 (
    echo Warning: Server may not have started correctly
    echo Please check the console for errors
) else (
    echo Server is running
    start "" "http://localhost:3000"
)

echo Development environment setup complete


@echo off
:replaceFile
setlocal
set "sourceFile=%~1"
set "targetFile=%~2"

copy /y "%sourceFile%" "%targetFile%"
if %errorlevel% neq 0 (
    echo Possible error related to file changes.
) 

echo Successfully replaced "%targetFile%" with "%sourceFile%".
endlocal
exit /b
