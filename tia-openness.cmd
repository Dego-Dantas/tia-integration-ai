@echo off
set /p TIA_VER=<"%~dp0tiaolder-version.txt"
if "%TIA_VER%"=="20" (
    set "BIN_PATH=%~dp0tia-openness-mcp\TIA_MCP_Delivery_v2.7.5_20261014\runtime\v20\TiaMcpServer.exe"
) else (
    set "BIN_PATH=%~dp0tia-openness-mcp\TIA_MCP_Delivery_v2.7.5_20261014\runtime\v21\TiaMcpServer.exe"
    set "TiaPortalLocation=C:\Program Files\Siemens\Automation\Portal V21\"
)
"%BIN_PATH%" --tia-major-version %TIA_VER% --profile full %*