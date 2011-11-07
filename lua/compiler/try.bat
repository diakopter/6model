@nmake /nologo >NUL
@echo dofile('RakudoRuntime.lua');> x.lua
@parrot compile.pir %1 >> x.lua
@luajit LocalsOptimizer.lua x.lua > y.lua
@rem type x.lua > y.lua
@echo LastMain(); >> y.lua
@echo ---
@luajit y.lua
