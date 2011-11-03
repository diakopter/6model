@if exist x.exe del /Q x.exe
@if exist x.cs del /Q x.cs
@nmake /nologo P6Objects.dll >NUL
echo dofile('RakudoRuntime.lua');> x.lua
rem @type RakudoRuntime.lua > x.lua
rem @type NQPSetting.lua >> x.lua
rem @type P6Objects.lua >> x.lua
@parrot compile.pir %1 >> x.lua
@echo ---
@luajit x.lua
