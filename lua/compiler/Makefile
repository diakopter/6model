# This works provided you have a parrot-nqp and luajit (or lua) somewhere in your path.

CAT = perl -MExtUtils::Command -e cat
CP = perl -MExtUtils::Command -e cp
RM_RF = perl -MExtUtils::Command -e rm_f
RT_SRC = ../runtime/*.lua ../runtime/Metamodel/*.lua ../runtime/Metamodel/KnowHOW/*.lua  ../runtime/Metamodel/Representations/*.lua ../runtime/Runtime/*.lua ../runtime/Runtime/Exceptions/*.lua ../runtime/Runtime/MultiDispatch/*.lua ../runtime/Runtime/Ops/*.lua ../runtime/Runtime/Signatures/*.lua
LUA = luajit

all: RakudoRuntime.lbc NQPSetting.lbc P6Objects.lbc

gen_actions.pir: Actions.pm
	parrot-nqp --target=pir Actions.pm > gen_actions.pir

gen_grammar.pir: Grammar.pm
	parrot-nqp --target=pir Grammar.pm > gen_grammar.pir

gen_nqpoptimizer.pir: NQPOptimizer.pm
	parrot-nqp --target=pir NQPOptimizer.pm > gen_nqpoptimizer.pir

gen_lst.pir: LST.pm
	parrot-nqp --target=pir LST.pm > gen_lst.pir

gen_past2lst.pir: PAST2LSTCompiler.pm
	parrot-nqp --target=pir PAST2LSTCompiler.pm > gen_past2lst.pir

gen_lst2lua.pir: LST2Lua.pm
	parrot-nqp --target=pir LST2Lua.pm > gen_lst2lua.pir

RakudoRuntime.lua: $(RT_SRC)
	$(CAT) $(RT_SRC) > RakudoRuntime.lua

RakudoRuntime.lbc:	RakudoRuntime.lua
	luajit -b RakudoRuntime.lua RakudoRuntime.lbc

NQPSetting.lua: LocalsOptimizer.lua NQPSetting_pre.lua
	$(CAT) NQPSetting_pre.lua > NQPSetting.lua
#	 luajit LocalsOptimizer.lua NQPSetting_pre.lua > NQPSetting.lua

NQPSetting_pre.lua: compile.pir gen_actions.pir gen_grammar.pir gen_nqpoptimizer.pir gen_lst.pir gen_past2lst.pir gen_lst2lua.pir ../../common/NQP/NQPSetting.pm
	parrot compile.pir ../../common/NQP/NQPSetting.pm --setting > NQPSetting_pre.lua

NQPSetting.lbc:	NQPSetting.lua
	luajit -b NQPSetting.lua NQPSetting.lbc

P6Objects.lua: LocalsOptimizer.lua P6Objects_pre.lua
	$(CAT) P6Objects_pre.lua > P6Objects.lua
#	luajit LocalsOptimizer.lua P6Objects_pre.lua > P6Objects.lua

P6Objects_pre.lua: compile.pir gen_actions.pir gen_grammar.pir gen_nqpoptimizer.pir gen_lst.pir gen_past2lst.pir gen_lst2lua.pir ../../common/NQP/P6Objects.pm
	parrot compile.pir ../../common/NQP/P6Objects.pm --no-core-libs > P6Objects_pre.lua

P6Objects.lbc:	P6Objects.lua
	luajit -b P6Objects.lua P6Objects.lbc

test: all
	prove -r --exec try ..\..\t\nqp

test-unixy: all
	prove -r --exec ./try.sh ../../t/nqp

clean:
	$(RM_RF) gen_*.pir RakudoRuntime.lua NQPSettin*.lua P6Object*.lua x.lua y.lua *.lbc
