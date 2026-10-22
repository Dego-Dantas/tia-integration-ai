@echo off
cd /d "%~dp0"

REM Se opencode.exe nao existir (ex: clone direto do git), baixa automaticamente pelo atualizador
if not exist "%~dp0opencode.exe" (
    echo [Primeiro uso] Baixando opencode.exe, Magic Context e TIA-PORTAL MCP...
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0update-all.ps1"
)

REM Configura proxy automaticamente caso o proxy do Host (192.168.79.1:3128) esteja acessivel
powershell -NoProfile -Command "try { $t = New-Object Net.Sockets.TcpClient; $ar = $t.BeginConnect('192.168.79.1', 3128, $null, $null); if ($ar.AsyncWaitHandle.WaitOne(300) -and $t.Connected) { $t.Close(); exit 0 } else { exit 1 } } catch { exit 1 }"
if %ERRORLEVEL% EQU 0 (
    set HTTP_PROXY=http://192.168.79.1:3128
    set HTTPS_PROXY=http://192.168.79.1:3128
    set NO_PROXY=localhost,127.0.0.1,192.168.79.1
)

set XDG_CONFIG_HOME=%~dp0config
set XDG_STATE_HOME=%~dp0state
set XDG_DATA_HOME=%~dp0data
set XDG_CACHE_HOME=%~dp0cache
set MAGIC_CONTEXT_STORAGE_DIR=%~dp0data\cortexkit-magic-context
set MAGIC_CONTEXT_LOG_PATH=%~dp0state\magic-context.log
set OPENCODE_DISABLE_AUTOCOMPACT=1
mkdir "%USERPROFILE%\.config\cortexkit" 2>nul
copy /Y "%~dp0config\cortexkit\magic-context.jsonc" "%USERPROFILE%\.config\cortexkit\magic-context.jsonc" >nul
opencode.exe
