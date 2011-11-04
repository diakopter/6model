@nmake /nologo >NUL
@echo dofile('RakudoRuntime.lua');> x.lua
@rem @type RakudoRuntime.lua > x.lua
@rem @type NQPSetting.lua >> x.lua
@rem @type P6Objects.lua >> x.lua
@parrot compile.pir %1 >> x.lua
@luajit LocalsOptimizer.lua x.lua > y.lua
@echo ---
@luajit y.lua
