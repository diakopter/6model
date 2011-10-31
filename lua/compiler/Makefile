# This works provided you have a parrot-nqp and csc somewhere in your path.

CAT = perl -MExtUtils::Command -e cat
CP = perl -MExtUtils::Command -e cp
RM_RF = perl -MExtUtils::Command -e rm_f
RT_SRC = ../runtime/*.lua ../runtime/Metamodel/*.lua ../runtime/Metamodel/KnowHOW/*.lua  ../runtime/Metamodel/Representations/*.lua ../runtime/Runtime/*.lua ../runtime/Runtime/Exceptions/*.lua ../runtime/Runtime/MultiDispatch/*.lua ../runtime/Runtime/Ops/*.lua ../runtime/Runtime/Signatures/*.lua

all: compile.pir gen_actions.pir gen_grammar.pir gen_nqpoptimizer.pir gen_dnst.pir gen_past2dnst.pir gen_dnst2csharp.pir NQPSetting.dll P6Objects.dll

gen_actions.pir: Actions.pm
	parrot-nqp --target=pir Actions.pm > gen_actions.pir

gen_grammar.pir: Grammar.pm
	parrot-nqp --target=pir Grammar.pm > gen_grammar.pir

gen_nqpoptimizer.pir: NQPOptimizer.pm
	parrot-nqp --target=pir NQPOptimizer.pm > gen_nqpoptimizer.pir

gen_lst.pir: DNST.pm
	parrot-nqp --target=pir LST.pm > gen_lst.pir

gen_past2lst.pir: PAST2DNSTCompiler.pm
	parrot-nqp --target=pir PAST2LSTCompiler.pm > gen_past2lst.pir

gen_lst2lua.pir: LST2Lua.pm
	parrot-nqp --target=pir LST2Lua.pm > gen_lst2lua.pir

RakudoRuntime.lua: $(RT_SRC)
	$(CAT) $(RT_SRC) > RakudoRuntime.lua

NQPSetting.lua: ../../common/NQP/NQPSetting.pm RakudoRuntime.lua
	parrot compile.pir ../../common/NQP/NQPSetting.pm --setting > NQPSetting.lua

P6Objects.lua: compile.pir gen_actions.pir gen_grammar.pir gen_nqpoptimizer.pir gen_lst.pir gen_past2lst.pir gen_lst2lua.pir ../../common/NQP/P6Objects.pm NQPSetting.lua
	parrot compile.pir ../../common/NQP/P6Objects.pm --no-core-libs > P6Objects.lua

test: all
	prove -r --exec try ..\..\t\nqp

test-unixy: all
	prove -r --exec ./try.sh ../../t/nqp

clean:
	$(RM_RF) gen_*.pir *.lua
