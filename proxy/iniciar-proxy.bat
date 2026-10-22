@echo off
title Proxy HTTP CONNECT (porta 3128)
echo Iniciando proxy na porta 3128...
echo Feche esta janela para parar o proxy.
echo.
node "%~dp0proxy.js" 3128
pause
