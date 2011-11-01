.sub '' :anon :load :init
    load_bytecode 'HLL.pbc'
    load_bytecode 'P6Regex.pbc'
.end

.include 'gen_grammar.pir'
.include 'gen_actions.pir'
.include 'gen_lst.pir'
.include 'gen_past2lst.pir'
.include 'gen_lst2lua.pir'
.loadlib 'io_ops'
#.include 'gen_nqpoptimizer.pir'

.sub 'main' :main
    .param pmc args

    # Do we have an argument saying we're compiling the setting or that we should
    # omit core library loading?
    $P0 = new ['Integer']
    .lex '$*COMPILING_NQP_SETTING', $P0
    $P1 = new ['Integer']
    .lex '$*NQP_NO_CORE_LIBS', $P1
    $S0 = args[2]
    if $S0 != '--setting' goto not_setting
    $P0 = 1
    $P1 = 1 # implicit with --setting, for now anyways.
  not_setting:
    if $S0 != '--no-core-libs' goto not_ncl
    $P1 = 1
  not_ncl:
    
    .local pmc g, a, opt, pastcomp, lstcomp
    g = get_hll_global ['JnthnNQP'], 'Grammar'
    a = get_hll_global ['JnthnNQP'], 'Actions'
#    opt = get_hll_global 'NQPOptimizer'
    pastcomp = get_hll_global 'PAST2LSTCompiler'
    lstcomp = get_hll_global 'LST2LuaCompiler'
    
    .local string filename, file
    .local pmc fh
    filename = args[1]
    fh = open filename, 'r'
    fh.'encoding'('utf8')
    file = fh.'readall'()
    fh.'close'()
    
    .local pmc match, ast, lst, compiled
    match = g.'parse'(file, 'actions'=>a)
    ast = match.'ast'()
#    opt.'optimize'(ast)
    lst = pastcomp.'compile'(ast)
    compiled = lstcomp.'compile'(lst)
    say compiled
.end
