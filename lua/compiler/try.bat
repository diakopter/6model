@rem nmake /nologo >NUL
@echo dofile('RakudoRuntime.lua');> x.lua
@parrot compile.pir %1 >> x.lua
@rem luajit LocalsOptimizer.lua x.lua > y.lua
@type x.lua > y.lua
@echo LastMain(); >> y.lua
@echo ---
@luajit y.lua
