@echo off
REM Wrapper para o MCP tiaolder (bulaofen0036)
REM Ajuste os caminhos abaixo para o seu ambiente
set /p TIA_VER=<"%~dp0tiaolder-version.txt"
"%~dp0..\tia-openness-mcp\TIA_MCP_Delivery_v2.2.4_20260615\tools\tiaportal-mcp\src\TiaMcpServer\bin-v20\Release\net48\TiaMcpServer.exe" --tia-major-version %TIA_VER% %*
