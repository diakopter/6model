#!/bin/sh
make >/dev/null
echo 'dofile("RakudoRuntime.lua");' > x.lua
parrot compile.pir $1 >> x.lua
# luajit LocalsOptimizer.lua x.lua > y.lua
cat x.lua > y.lua
echo 'LastMain();' >> y.lua
echo ---
luajit y.lua
