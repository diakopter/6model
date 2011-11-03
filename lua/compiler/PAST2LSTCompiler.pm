# This is the beginnings of a PAST to Dotnet Syntax Tree translator. It'll
# no doubt evolve somewhat over time, and get filled out as we support more
# and more of PAST.
class PAST2LSTCompiler;

# Set up a hash of operator signatures. Only needed for those that do not
# return and take just RakudoObject instances. First type is return type,
# following ones are argument types.
our %nqp_op_sigs;
INIT {
    %nqp_op_sigs                  := pir::new__pS('Hash');
    %nqp_op_sigs<equal_nums>      := ('int', 'num', 'num');
    %nqp_op_sigs<equal_ints>      := ('int', 'int', 'int');
    %nqp_op_sigs<equal_strs>      := ('int', 'str', 'str');
    %nqp_op_sigs<logical_not_int> := ('int', 'int');
    %nqp_op_sigs<add_int>         := ('int', 'int', 'int');
    %nqp_op_sigs<sub_int>         := ('int', 'int', 'int');
    %nqp_op_sigs<mul_int>         := ('int', 'int', 'int');
    %nqp_op_sigs<div_int>         := ('int', 'int', 'int');
    %nqp_op_sigs<mod_int>         := ('int', 'int', 'int');
}

# Entry point for the compiler.
method compile(PAST::Node $node) {
    # This tracks the unique IDs we generate in this compilation unit.
    my $*CUR_ID := 0;

    # The nested blocks, flattened out.
    my @*INNER_BLOCKS;

    # Any loadinits we'll need to run, and if we're in one.
    my $*IN_LOADINIT;
    my @*LOADINITS;
    my @*SIGINITS;

    # We'll build a static block info array too; this helps us do so.
    my $*OUTER_SBI := 0;
    my $*SBI_POS := 1;
    my $*SBI_SETUP := LST::Stmts.new();

    # We'll do similar for values - essentially, this builds a constants
    # table so we don't have to build them again and again.
    my @*CONSTANTS;

    # Also need to track the PAST blocks we're in.
    my @*PAST_BLOCKS;

    # Current namespace path.
    my @*CURRENT_NS;

    # The current type context, e.g. what result type the thing further
    # up in the tree is expecting.
    my $*TYPE_CONTEXT := 'obj';

    # Compile the node; ensure it is an immediate block.
    $node.blocktype('immediate');
    my $main_block_call := lst_for($node);

    # Build a class node and add the inner code blocks.
    my $class := LST::Class.new(
        :name($*COMPILING_NQP_SETTING ?? 'NQPSetting' !! unique_name_for_module())
    );
    
    $class.push(LST::Attribute.new( :name('StaticBlockInfo'), :type('RakudoCodeRef.Instance[]') ));
    $class.push(LST::Attribute.new( :name('ConstantsTable'), :type('RakudoObject[]') ));
    
    for @*INNER_BLOCKS {
        $class.push($_);
    }

    # If we're compiling the setting, we'll hack the TryFinally node of the
    # outermost block to *not* restore the caller context, so then we can
    # steal it and use it as the outer for our other stuff.
    if $*COMPILING_NQP_SETTING {
        my $outermost := @*INNER_BLOCKS[0];
        for @($outermost) {
            if $_ ~~ LST::TryFinally {
                $_.pop();
                $_.push(LST::Stmts.new());
            }
        }
    }

    # Also need to include setup of static block info.
    $class.push(make_blocks_init_method('blocks_init'));
    $class.push(make_constants_init_method('constants_init'));

    # Calls to loadinits.
    my $loadinit_calls := LST::Stmts.new();
    for @*LOADINITS {
        $loadinit_calls.push($_);
    }
    for @*SIGINITS {
        $loadinit_calls.push($_);
    }

    # Finally, startup handling code.
    if $*COMPILING_NQP_SETTING {
        $class.push(LST::Method.new(
            :name('LoadSetting'),
            :return_type('Context'),
            LST::Local.new( :name('TC'), :isdecl(1), :type('ThreadContext'),
                LST::MethodCall.new(
                    :on('Init'), :name('Initialize'),
                    :type('ThreadContext'),
                    LST::Null.new()
                )
            ),
            LST::Call.new( :name('blocks_init'), :void(1), TC() ),

            # We fudge in a fake NQPStr, for the :repr('P6Str'). Bit hacky,
            # but best I can think of for now. :-)
            LST::MethodCall.new(
                :on('StaticBlockInfo[1].StaticLexPad'), :name('SetByName'), :void(1), :type('RakudoObject'),
                LST::Literal.new( :value('NQPStr'), :escape(1) ),
                'REPRRegistry.get_REPR_by_name("P6str"):type_object_for(nil, nil)'
            ),

            # We do the loadinit calls before building the constants, as we
            # may build some constants with types we're yet to define.
            $loadinit_calls,
            LST::Call.new( :name('constants_init'), :void(1), TC() ),
            $main_block_call,
            "TC.CurrentContext"
        ));
    }
    else {
        # Commonalities for no matter how we start running (be it from the
        # command line or loaded as a library).
        my @params;
        @params.push('TC');
        $class.push(LST::Method.new(
            :name('Initialize'),
            :params(@params),
            :return_type('void'),
            LST::Call.new( :name('blocks_init'), :void(1), TC() ),
            LST::Call.new( :name('constants_init'), :void(1), TC() ),
            $loadinit_calls
        ));

        # Code for when it's the entry point (e.g. a Main method).
        $class.push(LST::Method.new(
            :name('Main'),
            :return_type('void'),
            LST::Local.new( :name('TC'), :isdecl(1), :type('ThreadContext'),
                LST::MethodCall.new(
                    :on('Init'), :name('Initialize'), :type('ThreadContext'),
                    LST::Literal.new( :value('NQPSetting'), :escape(1) )
                )
            ),
            LST::Call.new( :name('Initialize'), :void(1), TC() ),
            $main_block_call
        ));

        # Code for when it's being loaded as a library.
        $class.push(LST::Method.new(
            :name('Load'),
            :params('TC', 'Setting'),
            :return_type('RakudoObject'),
            LST::Call.new( :name('Initialize'), :void(1), TC() ),
            $main_block_call
        ));
    }

    # Package up in a compilation unit with the required "using"s.
    return LST::CompilationUnit.new(
        LST::Using.new( :namespace('System') ),
        LST::Using.new( :namespace('System.Collections.Generic') ),
        LST::Using.new( :namespace('Rakudo.Metamodel') ),
        LST::Using.new( :namespace('Rakudo.Metamodel.Representations') ),
        LST::Using.new( :namespace('Rakudo.Runtime') ),
        LST::Using.new( :namespace('Rakudo.Runtime.Exceptions') ),
        $class
    );
}

# Creates a not-really-that-unique-yet name for the module (good enough if
# we compile one per second, which given we're cross-compiling, is enough
# for now.)
sub unique_name_for_module() {
    'NQPOutput_' ~ pir::set__IN(pir::time__N())
}

# This makes the block static info initialization sub. One day, this
# can likely go away and we freeze a bunch of this info. But for now,
# this will do.
sub make_blocks_init_method($name) {
    my @params;
    @params.push('TC');
    return LST::Method.new(
        :name($name),
        :params(@params),
        :return_type('void'),
        
        # Create array for storing these.
        LST::Bind.new(
            loc('StaticBlockInfo', 'RakudoCodeRef.Instance[]'),
            '{}'
        ),

        # Fake up outermost one for now.
        LST::Bind.new(
            'StaticBlockInfo[0]',
            LST::MethodCall.new(
                :on('CodeObjectUtility'), :name('BuildStaticBlockInfo'),
                :type('RakudoCodeRef.Instance'),
                LST::Null.new(), LST::Null.new(),
                LST::ArrayLiteral.new( :type('String') )
            )
        ),
        LST::Bind.new(
            'StaticBlockInfo[0].CurrentContext',
            'TC.Domain.Setting'
        ),

        # The others.
        $*SBI_SETUP
    );
}

# Sets up the constants table initialization method.
sub make_constants_init_method($name) {
    # Build init method.
    my @params;
    @params.push('TC');
    my $result := LST::Method.new(
        :name($name),
        :params(@params),
        :return_type('void'),

        # Fake up a context with the outer being the main block.
        LST::Local.new(
            :name('C'), :isdecl(1), :type('Context'),
            LST::New.new(
                :type('Context'),
                LST::MethodCall.new(
                    :on('CodeObjectUtility'), :name('BuildStaticBlockInfo'),
                    :type('RakudoCodeRef.Instance'),
                    LST::Null.new(),
                    'StaticBlockInfo[1]',
                    LST::ArrayLiteral.new( :type('string') )
                ),
                'TC.CurrentContext',
                LST::Null.new()
            )
        ),
        
        # Create array for storing these.
        LST::Bind.new(
            loc('ConstantsTable', 'RakudoObject[]'),
            'List.new(' ~ +@*CONSTANTS ~ ')'
        )
    );

    # Add all constants into table.
    my $i := 0;
    while $i < +@*CONSTANTS {
        $result.push(LST::Bind.new(
            "ConstantsTable[$i]",
            @*CONSTANTS[$i]
        ));
        $i := $i + 1;
    }

    return $result;
}

# Quick hack so we can get unique (for this compilation) IDs.
sub get_unique_id($prefix) {
    $*CUR_ID := $*CUR_ID + 1;
    if ($prefix ne 'block') {
        if ($prefix eq 'list_') { $*CUR_ID := $*CUR_ID + 1; } #workaround strange bug
        return 'locals[' ~ $*CUR_ID ~ ']';
    }
    return $prefix ~ '_' ~ $*CUR_ID;
}

# Compiles a block.
our multi sub lst_for(PAST::Block $block) {
    # Unshift this PAST::Block onto the block list.
    @*PAST_BLOCKS.unshift($block);
    
    # We'll collect all the parameter nodes and lexical declarations.
    my @*PARAMS;
    my @*LEXICALS;
    my @*HANDLERS;

    # Update namespace.
    my $prev_ns := @*CURRENT_NS;
    if pir::isa($block.namespace(), 'ResizablePMCArray') {
        @*CURRENT_NS := $block.namespace();
    }
    elsif ~$block.namespace() ne '' {
        @*CURRENT_NS := pir::new('ResizablePMCArray');
        @*CURRENT_NS.push(~$block.namespace());
    }
    
    # Fresh bind context.
    my $*BIND_CONTEXT := 0;

    # Setup static block info.
    my $outer_sbi := $*OUTER_SBI;
    my $our_sbi := $*SBI_POS;
    my $our_sbi_setup := LST::MethodCall.new(
        :on('CodeObjectUtility'),
        :name('BuildStaticBlockInfo'),
        :type('RakudoCodeRef.Instance')
    );
    $*SBI_POS := $*SBI_POS + 1;
    $*SBI_SETUP.push(LST::Bind.new(
        "StaticBlockInfo[$our_sbi]",
        $our_sbi_setup
    ));

    # Label the PAST block with its SBI.
    $block<SBI> := "StaticBlockInfo[$our_sbi]";

    # Make start of block.
    my $result := LST::Method.new(
        :name(get_unique_id('block')),
        :params('TC', 'Block', 'Capture'),
        :return_type('RakudoObject')
    );
    
    # Emit all the statements.
    my @inner_blocks;
    my $stmts := LST::Stmts.new();
    for @($block) {
        my $*OUTER_SBI := $our_sbi;
        my @*INNER_BLOCKS;
        $stmts.push(lst_for($_));
        for @*INNER_BLOCKS {
            @inner_blocks.push($_);
        }
    }

    # Handle loadinit. 
    if +@($block.loadinit) {
        my $*OUTER_SBI := $our_sbi;
        my @*INNER_BLOCKS;

        # We'll fake this as an inner block to compile.
        my $*IN_LOADINIT := 1;
        @*LOADINITS.push(lst_for(PAST::Block.new(
            :blocktype('immediate'), $block.loadinit
        )));

        # Add blocks from this compilation (probably just one,
        # but handle nested blocks from the loadinit).
        for @*INNER_BLOCKS {
            @inner_blocks.push($_);
        }
    }

    # If we have a return handler, add it.
    if $block.control eq 'return_pir' {
        my $*OUTER_SBI := $our_sbi;
        my @*INNER_BLOCKS;
        my %handler;
        %handler<type> := 57;
        %handler<code> := lst_for(PAST::Block.new(PAST::Stmts.new(
            PAST::Var.new( :name('$!'), :scope('parameter') ),
            emit_op('leave_block',
                LST::Literal.new( :value('TC.CurrentContext.Outer.StaticCodeObject') ),
                lst_for(PAST::Var.new( :name('$!'), :scope('lexical') ))
            )
        )));
        $stmts.unshift(%handler<code>); # To get the right lexical context.
        for @*INNER_BLOCKS {
            @inner_blocks.push($_);
        }
        @*HANDLERS.push(%handler);
    }

    # Add signature generation/setup. We need to do this in the
    # correct lexical scope. Also this is handy place to set up
    # the handlers; keep a placeholder for that.
    my $handlers_setup_placeholder := LST::Stmts.new();
    my $sig_setup_block := get_unique_id('block');
    my @params;
    @params.push('TC');
    @inner_blocks.push(LST::Method.new(
        :return_type('void'),
        :name($sig_setup_block),
        :params(@params),
        LST::Local.new(
            :type('Context'), :name('C'), :isdecl(1),
            LST::New.new(
                :type('Context'),
                LST::MethodCall.new(
                    :on('CodeObjectUtility'), :name('BuildStaticBlockInfo'),
                    :type('RakudoCodeRef.Instance'),
                    LST::Null.new(),
                    "StaticBlockInfo[$our_sbi]",
                    LST::ArrayLiteral.new( :type('string') ),
                ),
                'TC.CurrentContext',
                LST::Null.new()
            )
        ),
        LST::Bind.new( 'TC.CurrentContext', loc('C', 'Context') ),
        LST::Bind.new(
            "StaticBlockInfo[$our_sbi].Sig",
            compile_signature(@*PARAMS)
        ),
        $handlers_setup_placeholder,
        LST::Bind.new( 'TC.CurrentContext', 'C.Caller' )
    ));
    @*SIGINITS.push(LST::Call.new( :name($sig_setup_block), :void(1), TC() ));

    # Before start of statements, we want to bind the signature.
    $stmts.unshift(LST::MethodCall.new(
        :on('SignatureBinder'), :name('Bind'), :void(1),
        TC(), loc('C', 'Context'), loc('Capture')
    ));

    # Wrap in block prelude/postlude.
    $result.push(LST::Local.new(
        :name('C'), :isdecl(1), :type('Context'),
        LST::New.new( :type('Context'), "Block", "TC.CurrentContext", loc("Capture") )
    ));
    $result.push(LST::Bind.new( 'TC.CurrentContext', loc('C', 'Context') ));
    $result.push(LST::TryFinally.new(
        LST::TryCatch.new(
            :exception_type('LeaveStackUnwinderException'),
            :exception_var('exc'),
            $stmts,
            LST::Stmts.new(
                LST::If.new(
                    LST::Literal.new(
                        :value("(exc.TargetBlock ~= Block and 1 or 0)")
                    ),
                    LST::Throw.new()
                ),
                "exc.PayLoad"
            )
        ),
        LST::Bind.new( 'TC.CurrentContext', 'C.Caller' )
    ));
    
    # Add nested inner blocks after it (.Net does not support
    # nested blocks).
    @*INNER_BLOCKS.push($result);
    for @inner_blocks {
        @*INNER_BLOCKS.push($_);
    }

    # Set up body, static outer and lexicals in the code setup block call.
    $our_sbi_setup.push(LST::Local.new(
            :name($result.name)
    ));
    $our_sbi_setup.push("StaticBlockInfo[$outer_sbi]");
    my $lex_setup := LST::ArrayLiteral.new( :type('string') );
    for @*LEXICALS {
        $lex_setup.push(LST::Literal.new( :value($_), :escape(1) ));
    }
    $our_sbi_setup.push($lex_setup);
    $our_sbi_setup.push(LST::Literal.new(
            :value('"' ~ $result.name ~ '"')
    ));
    # Add handlers.
    if +@*HANDLERS {
        my $handler_node := LST::ArrayLiteral.new( :type('Exceptions.Handler') );
        for @*HANDLERS {
            $handler_node.push(LST::New.new(
                :type('Exceptions.Handler'),
                LST::Literal.new( :value($_<type>) ),
                $_<code>
            ));
        }
        $handlers_setup_placeholder.push(LST::Bind.new(
            "StaticBlockInfo[$our_sbi].Handlers",
            $handler_node
        ));
    }

    # Clear up this PAST::Block from the blocks list and restore outer NS.
    @*PAST_BLOCKS.shift;
    @*CURRENT_NS := $prev_ns;

    # For immediate evaluate to a call; for declaration, evaluate to the
    # low level code object.
    if $block.blocktype eq 'immediate' {
        return LST::MethodCall.new(
            :name('STable:Invoke'), :type('RakudoObject'),
            "StaticBlockInfo[$our_sbi]",
            TC(),
            "StaticBlockInfo[$our_sbi]",
            LST::MethodCall.new(
                :on('CaptureHelper'),
                :name('FormWith'),
                :type('RakudoObject')
            )
        );
    }
    else {
        return emit_op(
            ($block.closure ?? 'new_closure' !! 'capture_outer'),
            LST::Local.new( :name("StaticBlockInfo[$our_sbi]") )
        );
    }
}

# Compiles a bunch of parameter nodes down to a signature.
sub compile_signature(@params) {
    # Go through each of the parameters and compile them.
    my $params := LST::ArrayLiteral.new( :type('Parameter') );
    for @params {
        my $param := LST::New.new( :type('Parameter') );

        # Type.
        if $_.multitype {
            $param.push(lst_for($_.multitype));
        }
        else {
            $param.push(LST::Null.new());
        }

        # Variable name to bind into.
        my $lexpad_position := +@*LEXICALS;
        @*LEXICALS.push($_.name);
        $param.push(LST::Literal.new( :value($_.name), :escape(1) ));
        $param.push(LST::Literal.new( :value($lexpad_position) ));

        # Named param or not?
        $param.push((!$_.slurpy && $_.named) ??
            LST::Literal.new( :value(pir::substr($_.name, 1)), :escape(1) ) !!
            LST::Null.new());

        # Flags.
        $param.push(
            $_.viviself && $_.named ?? 'bit.bor(Parameter.OPTIONAL_FLAG, Parameter.NAMED_FLAG)' !!
            $_.viviself             ?? 'Parameter.OPTIONAL_FLAG'                        !!
            $_.slurpy && $_.named   ?? 'Parameter.NAMED_SLURPY_FLAG'                    !!
            $_.slurpy               ?? 'Parameter.POS_SLURPY_FLAG'                      !!
            $_.named                ?? 'Parameter.NAMED_FLAG'                           !!
            'Parameter.POS_FLAG');

        # Definedness constraint.
        $param.push($_<definedness> eq 'D' ?? 'DefinednessConstraint.DefinedOnly' !!
                    $_<definedness> eq 'U' ?? 'DefinednessConstraint.UndefinedOnly' !!
                    'DefinednessConstraint.None');
        
        # viviself.
        $param.push($_.viviself ~~ PAST::Node
            ?? lst_for(PAST::Block.new(:closure(1), $_.viviself))
            !! LST::Null.new());

        $params.push($param);
    }

    # Build up a signature object.
    return LST::New.new( :type('Signature'), $params );
}

# Compiles a statements node - really just all the stuff in it.
our multi sub lst_for(PAST::Stmts $stmts) {
    my $result := LST::Stmts.new();
    for @($stmts) {
        $result.push(lst_for($_));
    }
    return $result;
}

# Compiles the various forms of PAST::Op.
our multi sub lst_for(PAST::Op $op) {
    if $op.pasttype eq 'callmethod' {
        # We want to emit code for the args, but also need the
        # invocant to hand specially.
        my @args := @($op);
        if +@args == 0 { pir::die("callmethod node must have at least an invocant"); }
        
        # Invocant.
        my $inv := LST::Local.new(
            :name(get_unique_id('inv')), :isdecl(1), :type('RakudoObject'),
            lst_for(@args.shift)
        );

        # Method name, for indirectly named dotty calls
        my $name := $op.name ~~ PAST::Node
          ?? unbox('str', PAST::Op.new(
                 :pasttype('callmethod'), :name('Str'),
                 lst_for($op.name)
             ))
          !! LST::Literal.new( :value($op.name), :escape(1) );
        
        # Method lookup.
        my $callee := LST::Local.new(
            :name(get_unique_id('callee')), :isdecl(1), :type('RakudoObject'),
            LST::MethodCall.new(
                :on($inv.name), :name('STable:FindMethod'), :type('RakudoObject'),
                TC(),
                $inv.name,
                $name,
                'Hints.NO_HINT'
            )
        );

        # Emit the call.
        return LST::Stmts.new(
            $inv,
            LST::MethodCall.new(
                :name('STable:Invoke'), :type('RakudoObject'),
                $callee,
                TC(),
                $callee.name,
                form_capture(@args, $inv)
            )
        );
    }

    elsif $op.pasttype eq 'call' || $op.pasttype eq '' {
        my @args := @($op);
        my $callee;

        # See if we've a name or have to use the first arg as the callee.
        if $op.name ne "" {
            $callee := emit_lexical_lookup($op.name);
        }
        else {
            unless +@args {
                pir::die("PAST::Op call nodes with no name must have at least one child");
            }
            $callee := lst_for(@args.shift);
        }
        $callee := LST::Local.new( :name(get_unique_id('callee')), :isdecl(1), :type('RakudoObject'), $callee );

        # Emit call.
        return LST::MethodCall.new(
            :name('STable:Invoke'), :type('RakudoObject'),
            $callee,
            TC(),
            $callee.name,
            form_capture(@args)
        );
    }

    elsif $op.pasttype eq 'bind' {
        my $*BIND_CONTEXT := 1;
        my $*BIND_VALUE;
        {
            my $*BIND_CONTEXT := 0;
            $*BIND_VALUE := lst_for((@($op))[1]);
        }
        return lst_for((@($op))[0]);
    }

    elsif $op.pasttype eq 'nqpop' {
        # Just a call on the Ops class. Always pass thread context
        # as the first parameter.
        my @args := @($op);
        return emit_op($op.name, |@args);
    }

    elsif $op.pasttype eq 'if' {
        my $cond_evaluated := LST::Local.new( :name(get_unique_id('if_cond')) );
        return LST::Stmts.new(
            LST::Local.new(
                :name($cond_evaluated.name), :isdecl(1), :type('RakudoObject'),
                lst_for(PAST::Op.new(
                    :pasttype('callmethod'), :name('Bool'),
                    (@($op))[0]
                ))
            ),
            LST::If.new(
                unbox('int', $cond_evaluated),
                lst_for((@($op))[1]),
                (+@($op) == 3 ?? lst_for((@($op))[2]) !! $cond_evaluated)
            )
        );
    }

    elsif $op.pasttype eq 'unless' {
        my $cond_evaluated := get_unique_id('unless_cond');
        my $temp;
        return LST::Stmts.new(
            ($temp := LST::Local.new(
                :name(get_unique_id('unless_result')), :isdecl(1), :type('RakudoObject'), val(0)
            )),
            LST::Local.new(
                :name($cond_evaluated), :isdecl(1), :type('RakudoObject'),
                lst_for(PAST::Op.new(
                    :pasttype('call'), :name('&prefix:<!>'),
                    LST::Bind.new(lit($temp.name), lst_for((@($op))[0]))
                ))
            ),
            LST::If.new(
                LST::MethodCall.new(
                    :on('Ops'), :name('unbox_int'), :type('int'),
                    TC(), $cond_evaluated
                ),
                LST::Bind.new(lit($temp.name), lst_for((@($op))[1])),
                LST::Bind.new(lit($temp.name), lst_for($cond_evaluated)),
            ),
            lit($temp.name)
        );
    }

    elsif $op.pasttype eq 'while' || $op.pasttype eq 'until' {
        my $cond_result := LST::Local.new( :name(get_unique_id('cond')) );
        
        # Compile the condition.
        my $cop := $op.pasttype eq 'until'
          ?? PAST::Op.new(
                :pasttype('call'), :name('&prefix:<!>'),
                (@($op))[0]
            )
          !! PAST::Op.new(
                :pasttype('callmethod'), :name('Bool'),
                (@($op))[0]
            );
        my $cond := LST::Local.new(
            :name($cond_result.name), :isdecl(1), :type('RakudoObject'),
            lst_for($cop)
        );

        # Compile the body.
        my $body := lst_for((@($op))[1]);

        # Build up result.
        return LST::While.new(
            :repeat(0),
            $cond,
            unbox('int', $cond_result),
            $body
        );
    }

    elsif $op.pasttype eq 'repeat_while' || $op.pasttype eq 'repeat_until' {
        my $cond_result := LST::Local.new( :name(get_unique_id('cond')) );
        
        # Compile the condition.
        my $cop := $op.pasttype eq 'repeat_until'
          ?? PAST::Op.new(
                :pasttype('call'), :name('&prefix:<!>'),
                (@($op))[0]
            )
          !! PAST::Op.new(
                :pasttype('callmethod'), :name('Bool'),
                (@($op))[0]
            );
        my $cond := LST::Local.new(
            :name($cond_result.name), :isdecl(1), :type('RakudoObject'),
            lst_for($cop)
        );

        # Compile the body.
        my $body := lst_for((@($op))[1]);

        # Build up result.
        return LST::While.new(
            :repeat(1),
            $cond,
            unbox('int', $cond_result),
            $body
        );
    }

    elsif $op.pasttype eq 'list' {
        my $tmp_name := get_unique_id('list_');
        my $result := LST::Stmts.new(
            LST::Local.new(
                :name($tmp_name), :isdecl(1), :type('RakudoObject'),
                lst_for(PAST::Op.new(
                    :pasttype('callmethod'), :name('new'),
                    PAST::Var.new( :name('NQPArray'), :scope('lexical') )
                ))
            )
        );
        my $i := 0;
        for @($op) {
            $result.push(LST::MethodCall.new(
                :on('Ops'), :name('lllist_bind_at_pos'), :void(1), :type('RakudoObject'),
                TC(),
                $tmp_name,
                lst_for(PAST::Val.new( :value($i) )),
                lst_for($_)
            ));
            $i := $i + 1;
        }
        $result.push($tmp_name);
        return $result;
    }

    elsif $op.pasttype eq 'return' {
        return emit_op('throw_lexical', (@($op))[0], PAST::Val.new( :value(57) ));
    }

    elsif $op.pasttype eq 'def_or' {
        # Evaluate and store the first item.
        my $first_name := get_unique_id('def_or_first_');
        my $first := LST::Local.new(
            :name($first_name), :isdecl(1), :type('RakudoObject'),
            lst_for((@($op))[0])
        );

        # Compile it as an if node that checks definedness.
        my $first_var := LST::Local.new( :name($first_name) );
        return LST::Stmts.new(
            $first,
            lst_for(PAST::Op.new( :pasttype('if'),
                PAST::Op.new( :pasttype('callmethod'), :name('defined'), $first_var ),
                $first_var,
                (@($op))[1]
            ))
        );
    }

    else {
        pir::die("Don't know how to compile pasttype " ~ $op.pasttype);
    }
}

# How is capture formed?
sub form_capture(@args, $inv?) {
    # Create the various parts we might put into the capture.
    my $capture := LST::MethodCall.new(
        :on('CaptureHelper'), :name('FormWith'), :type('RakudoObject')
    );
    my $pos_part := LST::ArrayLiteral.new( :type('RakudoObject') );
    my $named_part := LST::DictionaryLiteral.new(
        :key_type('string'), :value_type('RakudoObject') );
    my $flatten_flags := LST::ArrayLiteral.new( :type('int') );
    my $has_flats := 0;
    
    # If it's a method call, we'll have an invocant to emit.
    if $inv ~~ LST::Node {
        $pos_part.push($inv.name);
    }

    # Go over the args.
    for @args {
        if $_ ~~ PAST::Node && $_.named {
            if $_.flat {
                $pos_part.push(lst_for($_));
                $flatten_flags.push('CaptureHelper.FLATTEN_NAMED');
                $has_flats := 1;
            }
            else {
                $named_part.push(LST::Literal.new( :value($_.named), :escape(1) ));
                $named_part.push(lst_for($_));
            }
        }
        elsif $_ ~~ PAST::Node && $_.flat {
            $pos_part.push(lst_for($_));
            $flatten_flags.push('CaptureHelper.FLATTEN_POS');
            $has_flats := 1;
        }
        else {
            $pos_part.push(lst_for($_));
            $flatten_flags.push('CaptureHelper.FLATTEN_NONE');
        }
    }

    # Push the various parts as needed.
    $capture.push($pos_part);
    if +@($named_part) || $has_flats { $capture.push($named_part); }
    if $has_flats { $capture.push($flatten_flags); }

    $capture;
}

# Emits a value.
our multi sub lst_for(PAST::Val $val) {
    # If it's a block reference, hand back the SBI.
    if $val.value ~~ PAST::Block {
        unless $val.value<SBI> {
            pir::die("Can't use PAST::Val for a block reference for an as-yet uncompiled block");
        }
        return LST::Literal.new( :value($val.value<SBI>) );
    }

    # Work out type to box to.
    my $primitive;
    if pir::isa($val.value, 'Integer') {
        $primitive := 'int';
    }
    elsif pir::isa($val.value, 'String') {
        $primitive := 'str';
    }
    elsif pir::isa($val.value, 'Float') {
        $primitive := 'num';
    }
    else {
        pir::die("Can not detect type of value")
    }

    # If we have a non-object type context, can hand back a literal value.
    if $*TYPE_CONTEXT ne 'obj' {
        return LST::Literal.new(
            :value($val.value),
            :type(vm_type_for($primitive)),
            :escape($primitive eq 'str')
        );
    }
    
    # Otherwise, need to box it. Add to constants table if possible.
    my $make_const := box($primitive, LST::Literal.new(
        :value($val.value), :escape($primitive eq 'str') ));
    if $*IN_LOADINIT || $*COMPILING_NQP_SETTING {
        return $make_const;
    }
    else {
        my $const_id := +@*CONSTANTS;
        @*CONSTANTS.push($make_const);
        return LST::Literal.new( :value("ConstantsTable[$const_id]") );
    }
}

# Emits code for a variable node.
our multi sub lst_for(PAST::Var $var) {
    # See if we have a scope provided. If not, work one out.
    my $scope := $var.scope;
    unless $scope {
        for @*PAST_BLOCKS {
            my %sym_info := $_.symbol($var.name);
            if %sym_info<scope> {
                $scope := %sym_info<scope>;
                last;
            }
        }
        unless $scope {
            pir::die('Symbol ' ~ $var.name ~ ' not pre-declared');
        }
    }

    # Now go by scope.
    if $scope eq 'parameter' {
        # Parameters we'll deal with later by building up a signature.
        @*PARAMS.push($var);
        return LST::Stmts.new();
    }
    elsif $scope eq 'lexical' {
        if $var.isdecl {
            return declare_lexical($var);
        }
        else {
            return emit_lexical_lookup($var.name);
        }
    }
    elsif $scope eq 'outer' {
        if $var.isdecl {
            pir::die("Cannot use isdecl when scope is 'outer'.");
        }
        else {
            return emit_outer_lexical_lookup($var.name);
        }
    }
    elsif $scope eq 'contextual' {
        if $var.isdecl {
            return declare_lexical($var);
        }
        else {
            return emit_dynamic_lookup($var.name);
        }
    }
    elsif $scope eq 'package' {
        # Get all parts of the name.
        my @parts;
        @parts.push('GLOBAL');
        if pir::isa($var.namespace, 'ResizablePMCArray') {
            for $var.namespace { @parts.push($_); }
        }
        elsif +@*CURRENT_NS {
            for @*CURRENT_NS {
                @parts.push($_)
            }
        }
        @parts.push($var.name);

        # First, we need to look up the first part.
        my $lookup;
        {
            my $*BIND_CONTEXT := 0;
            $lookup := emit_lexical_lookup(@parts.shift);
        }

        # Also need to treat last part specially.
        my $target := @parts.pop;

        # Now chase down the rest.
        for @parts {
            $lookup := lst_for(PAST::Op.new(
                :pasttype('callmethod'), :name('get_namespace'),
                $lookup,
                PAST::Val.new( :value(~$_) )
            ));
        }

        # Binding, if needed.
        if $*BIND_CONTEXT {
            my $*BIND_CONTEXT := 0;
            $lookup := lst_for(PAST::Op.new(
                :pasttype('callmethod'), :name('bind_key'),
                $lookup,
                PAST::Val.new( :value(~$target) ),
                $*BIND_VALUE
            ));
        }
        else {
            $lookup := lst_for(PAST::Op.new(
                :pasttype('callmethod'), :name('at_key'),
                $lookup,
                PAST::Val.new( :value(~$target) )
            ));
        }

        return $lookup;
    }
    elsif $scope eq 'register' {
        if $var.isdecl {
            my $result := LST::Local.new( :name($var.name), :isdecl(1), :type('RakudoObject') );
            if $*BIND_CONTEXT {
                $result.push($*BIND_VALUE);
            }
            elsif $var.viviself {
                $result.push(lst_for($var.viviself));
            }
            else {
                $result.push(LST::Null.new());
            }
            return $result;
        }
        elsif $*BIND_CONTEXT {
            return LST::Bind.new( LST::Local.new( :name($var.name) ), $*BIND_VALUE );
        }
        else {
            return LST::Local.new( :name($var.name) );
        }
    }
    elsif $scope eq 'attribute' {
        # Need to get hold of $?CLASS (always lookup) and self.
        my $class;
        my $self;
        {
            my $*BIND_CONTEXT := 0;
            $class := emit_lexical_lookup('$?CLASS');
            $self := emit_lexical_lookup('self');
        }

        # Emit attribute lookup/bind.
        my $lookup := emit_op(($*BIND_CONTEXT ?? 'bind_attr' !! 'get_attr'),
            $self,
            $class,
            LST::Literal.new( :value($var.name), :escape(1) )
        );
        if $*BIND_CONTEXT {
            $lookup.push($*BIND_VALUE);
        }
        elsif pir::defined($var.viviself) {
            # May need to auto-vivify.
            my $viv_name := get_unique_id('viv_attr_');
            my $temp := LST::Local.new( :name($viv_name), :isdecl(1), :type('RakudoObject'), $lookup );
            $lookup := LST::Stmts.new(
                $temp,
                LST::If.new( :bool(1),
                    eq(LST::Local.new( :name($viv_name) ), LST::Null.new()),
                    lst_for($var.viviself),
                    LST::Local.new( :name($viv_name) )
                )
            );
        }
        return $lookup;
    }
    elsif $scope eq 'keyed_int' {
        # XXX viviself, vivibase.
        if $*BIND_CONTEXT {
            # Get thing to do lookup in without bind context applied - we simply
            # want to look it up.
            my $*BIND_CONTEXT := 0;
            return lst_for(PAST::Op.new(
                :pasttype('callmethod'), :name('bind_pos'),
                @($var)[0], @($var)[1], $*BIND_VALUE
            ));
        }
        else {
            return lst_for(PAST::Op.new(
                :pasttype('callmethod'), :name('at_pos'),
                @($var)[0], @($var)[1]
            ));
        }
    }
    elsif $scope eq 'keyed' {
        # XXX viviself, vivibase.
        if $*BIND_CONTEXT {
            # Get thing to do lookup in without bind context applied - we simply
            # want to look it up.
            my $*BIND_CONTEXT := 0;
            return lst_for(PAST::Op.new(
                :pasttype('callmethod'), :name('bind_key'),
                @($var)[0], @($var)[1], $*BIND_VALUE
            ));
        }
        else {
            return lst_for(PAST::Op.new(
                :pasttype('callmethod'), :name('at_key'),
                @($var)[0], @($var)[1]
            ));
        }
    }
    else {
        pir::die("Don't know how to compile variable scope " ~ $var.scope);
    }
}

# Declares a lexical variable, and also handles viviself.
sub declare_lexical($var) {
    # Add to lexpad.
    @*LEXICALS.push($var.name);

    # Run viviself if there is one and bind it.
    if pir::defined($var.viviself) {
        my $*BIND_CONTEXT := 1;
        my $*BIND_VALUE;
        {
            my $*BIND_CONTEXT := 0;
            $*BIND_VALUE := lst_for($var.viviself);
        }
        return emit_lexical_lookup($var.name);
    }
    else {
        return emit_lexical_lookup($var.name);
    }
}

# Catch-all for values and error detection.
our multi sub lst_for($any) {
    if $any ~~ LST::Node {
        # LST of something already in LST is itself.
        return $any;
    }
    elsif pir::isa($any, 'String') || pir::isa($any, 'Integer') || pir::isa($any, 'Float') {
        # Literals - wrap up in a value node and compile that.
        return lst_for(PAST::Val.new( :value($any) ));
    }
    else {
        pir::die("Don't know how to compile a " ~ pir::typeof__SP($any) ~ "(" ~ $any ~ ")");
    }
}

# Non-regex nodes reached inside a regex
our multi sub lst_regex($r) {
    lst_for($r)
}

# Regex nodes reached from non-regex nodes
our multi sub lst_for(PAST::Regex $r, :$rtype) {
    my $rb; # regex block
    my $pasttype := $r.pasttype;
    #pir::die("Don't know how to compile toplevel regex pasttype $pasttype.") if $pasttype ne 'concat';
    my $stmts := PAST::Stmts.new;
    
    # create a name-based jump table for this CLR routine
    my $*re_jt := LST::JumpTable.new();
    
    $stmts.push(LST::Bind.new($*re_jt.register, lit('0')));
    
    # cursor register
    my $re_cur_tmp := LST::Local.new(
        :name(get_unique_id('re_cur')), :isdecl(1), :type('RakudoObject'),
        lst_for(PAST::Var.new( :name('self'), :scope('lexical')))
    );
    my $*re_cur := LST::Local.new( :name($re_cur_tmp.name) );
    my $*re_cur_name := $re_cur_tmp.name;
    $stmts.push($re_cur_tmp);
    
    # cursor self register
    my $re_cur_self_tmp := LST::Local.new(
        :name(get_unique_id('re_cur_self')), :isdecl(1), :type('RakudoObject'),
        lit($*re_cur_name)
    );
    my $*re_cur_self := LST::Local.new( :name($re_cur_self_tmp.name) );
    my $*re_cur_self_name := $re_cur_self_tmp.name;
    $stmts.push($re_cur_self_tmp);
    
    my $re_prefix := get_unique_id('rx');
    
    my $re_fail_label := $re_prefix ~ '_fail';
    my $*re_fail := LST::Goto.new(:label($re_fail_label));
    my $re_restart_label := $re_prefix ~ '_restart';
    my $re_restart := LST::Goto.new(:label($re_restart_label));
    my $re_done_label := $re_prefix ~ '_done';
    my $re_done := LST::Goto.new(:label($re_done_label));
    my $re_start_label := $re_prefix ~ '_start';
    my $re_start := LST::Goto.new(:label($re_start_label));
    
    my $*I10 := temp_int(:name("I10"));
    my $*P10 := temp_int(:name("P10"));
    $stmts.push($*I10);
    $stmts.push($*P10);
    my $*I10_lit := lit($*I10.name);
    my $*P10_lit := lit($*P10.name);
    
    my $regex_name := my $*REGEXNAME := @*PAST_BLOCKS[0].name;
    
    # If capnames is available, it's a hash where each key is the
    # name of a potential subcapture and the value is greater than 1
    # if it's to be an array.  This builds a list of arrayed subcaptures
    # for use by "!cursor_caparray" below.
    
    my @capnames := $r.capnames;
    my @caparray := ();
    for @capnames {
        @caparray.push($_) if @capnames[$_] > 1
    }
    
    # current position register
    my $re_pos := temp_int(:name("pos"), unbox('int', PAST::Op.new(
        :pasttype('callmethod'), :name('pos'),
        $*re_cur
    )));
    $stmts.push($re_pos);
    my $*re_pos := $re_pos.name;
    my $*re_pos_lit := lit($re_pos.name);
    
    # end of string register
    my $re_eos := temp_int(:name("eos"), unbox('int', PAST::Op.new(
        :pasttype('callmethod'), :name('eos'),
        $*re_cur
    )));
    $stmts.push($re_eos);
    my $*re_eos := $re_eos.name;
    my $*re_eos_lit := lit($re_eos.name);
    
    # offset register
    my $re_off := temp_int(:name("off"), unbox('int', PAST::Op.new(
        :pasttype('callmethod'), :name('off'),
        $*re_cur
    )));
    $stmts.push($re_off);
    my $*re_off := $re_off.name;
    my $*re_off_lit := lit($re_off.name);
    
    # rep register
    my $re_rep := temp_int();
    $stmts.push($re_rep);
    my $*re_rep := $re_rep.name;
    my $*re_rep_lit := lit($re_rep.name);
    
    # target (string) register
    my $re_tgt := temp_str(unbox('str', PAST::Op.new(
        :pasttype('callmethod'), :name('target'),
        $*re_cur
    )), :name("tgt"));
    $stmts.push($re_tgt);
    my $*re_tgt := $re_tgt.name;
    my $*re_tgt_lit := lit($re_tgt.name);
    
    if ($regex_name) {
        # XXX token peek
    }
    
    $stmts.push(returns_array(
        lst_for(PAST::Op.new( :pasttype('callmethod'),
            :name('cursor_start'), $*re_cur_self)),
        $*re_cur, 'RakudoObject',
        $*re_pos_lit, 'int',
        $*re_tgt_lit, 'string',
        $*I10_lit, 'int'
    ));
    
    $stmts.push(
        lst_for(PAST::Op.new( :pasttype('callmethod'),
            :name('cursor_caparray'), $*re_cur, lst_for(val(0)), |@caparray)))
                if +@caparray;
    
    unless pir::defined($rtype) {
        $stmts.push(declare_lexical(PAST::Var.new( :name('$¢'), :scope('lexical') )));
        $stmts.push(lst_for(LST::Bind.new(
            emit_lexical_lookup( '$¢'),
            $*re_cur
        )));
        $stmts.push(declare_lexical(PAST::Var.new( :name('$/'), :scope('lexical') )));
        $stmts.push(lst_for(LST::Bind.new(
            emit_lexical_lookup( '$/'),
            $*re_cur
        )));
    }
    
    $stmts.push(if_then(gt($*re_pos_lit, $*re_pos_lit), $re_done));
    
    $stmts.push(LST::Label.new(:name($re_start_label)));
    #$stmts.push(emit_say(lits("re startlabel at position ")));
    #$stmts.push(emit_say($*re_pos_lit));
    $stmts.push(if_then(eq($*I10_lit, lit("1")), $re_restart));
    
    $stmts.push(lst_for(PAST::Op.new(
        :pasttype('callmethod'), :name('cursor_debug'),
        $*re_cur, "START"
    )));
    
    for @($r) {
        #$stmts.push(emit_say(lits("gh " ~ $_.pasttype)));
        $stmts.push(lst_regex($_));
    }
    
    $stmts.push(LST::Label.new(:name($re_restart_label)));
    #$stmts.push(emit_say(lits("re restartlabel at position ")));
    #$stmts.push(emit_say($*re_pos_lit));
    
    $stmts.push(lst_for(PAST::Op.new(
        :pasttype('callmethod'), :name('cursor_debug'),
        $*re_cur, "NEXT"
    )));
    
    $stmts.push(LST::Label.new(:name($re_fail_label)));
    #$stmts.push(emit_say(lits("re faillabel at position ")));
    #$stmts.push(emit_say($*re_pos_lit));
    # self.'!cursorop'(ops, '!mark_fail', 4, rep, pos, '$I10', '$P10', 0)
    $stmts.push(returns_array(lst_for(PAST::Op.new(
        :pasttype('callmethod'), :name('mark_fail'), $*re_cur, val(0))),
        $*re_rep_lit, 'int',
        $*re_pos_lit, 'int',
        $*I10_lit, 'int',
        #$*P10_lit, 'RakudoObject'  # XXX 
    ));
    # ops.'push_pirop'('lt', pos, CURSOR_FAIL, donelabel)
    $stmts.push(if_then(lt($*re_pos_lit, lit('-1')), $re_done));
    # ops.'push_pirop'('eq', pos, CURSOR_FAIL, faillabel)
    $stmts.push(if_then(eq($*re_pos_lit, lit('-1')), $*re_fail));
    # ops.'push_pirop'('jump', '$I10')
    $stmts.push($*re_jt.jump($*I10_lit));
    
    $stmts.push($*re_jt);

    $stmts.push(LST::Label.new(:name($re_done_label)));
    #$stmts.push(emit_say(lits("re donelabel at position ")));
    #$stmts.push(emit_say($*re_pos_lit));
    
    $stmts.push(lst_for(PAST::Op.new(
        :pasttype('callmethod'), :name('cursor_fail'),
        $*re_cur, val(0)
    )));
    
    $stmts.push(lst_for(PAST::Op.new(
        :pasttype('callmethod'), :name('cursor_debug'),
        $*re_cur, "FAIL"
    )));
    
    $stmts.push(LST::Return.new($*re_cur));

    lst_for($stmts);
}

# Regex nodes reached inside a regex
our multi sub lst_regex(PAST::Regex $r) {
    my $pasttype := $r.pasttype;
    my $stmts := PAST::Stmts.new;
    if $pasttype eq 'concat' {
        # Handle a concatenation of regexes.
        for @($r) {
            $stmts.push(lst_regex($_));
        }
    }
    elsif $pasttype eq 'scan' {
        #$stmts.push(emit_say(lits("scan at position ")));
        #$stmts.push(emit_say($*re_pos_lit));
        # Code for initial regex scan.
        my $s0 := get_unique_id('rxscan');
        my $looplabel := $*re_jt.mark($s0 ~ '_loop');
        my $scanlabel := LST::Label.new(:name($s0 ~ '_scan'));
        my $donelabel := LST::Label.new(:name($s0 ~ '_done'));
        
        #$stmts.push(emit_say(lits("scan from returned ")));
        #$stmts.push(emit_say(
        #unbox('int', lst_for(PAST::Op.new(
        #        :pasttype('callmethod'), :name('special'), $*re_cur_self
        #    )))));
        
        $stmts.push(if_then(ne(unbox('int', lst_for(PAST::Op.new(
                :pasttype('callmethod'), :name('special'), $*re_cur_self
            ))), lit("-1")), LST::Goto.new(:label($donelabel.name))));
        $stmts.push(LST::Goto.new(:label($scanlabel.name)));
        $stmts.push($looplabel);
        #$stmts.push(emit_say(lits("scan looplabel at position ")));
        #$stmts.push(emit_say($*re_pos_lit));
        # self.'!cursorop'(ops, 'from', 1, '$P10')
        # ops.'push_pirop'('inc', '$P10')
        # ops.'push_pirop'('set', pos, '$P10')
        $stmts.push(LST::Bind.new($*re_pos_lit, plus(unbox('int', lst_for(PAST::Op.new(
            :pasttype('callmethod'), :name('from'),
            $*re_cur
        ))), lit("1"))));
        $stmts.push(lst_for(PAST::Op.new(
            :pasttype('callmethod'), :name('from'),
            $*re_cur, box('int', $*re_pos_lit)
        )));
        $stmts.push(if_then(ge($*re_pos_lit, $*re_eos_lit), LST::Goto.new(:label($donelabel.name))));
        $stmts.push($scanlabel);
        #$stmts.push(emit_say(lits("scan scanlabel at position ")));
        #$stmts.push(emit_say($*re_pos_lit));
        $stmts.push(lst_for(PAST::Op.new(
            :pasttype('callmethod'), :name('mark_push'),
            $*re_cur, val(0),
            box('int', $*re_pos_lit), box('int', lit($*re_jt.get_index($s0 ~ '_loop')))
        )));
        $stmts.push($donelabel);
        #$stmts.push(emit_say(lits("scan donelabel at position ")));
        #$stmts.push(emit_say($*re_pos_lit));
    }
    elsif $pasttype eq 'literal' {
        # Code for literal strings
        #$stmts.push(emit_say(lits("literal " ~ (@($r))[0] ~ " at position ")));
        #$stmts.push(emit_say($*re_pos_lit));
        $stmts.push(if_then(
            log_and(lt($*re_pos_lit, $*re_eos_lit), eq(emit_call($*re_tgt, 'IndexOf', 'int', lits((@($r))[0]), $*re_pos_lit), $*re_pos_lit)),
            LST::Bind.new($*re_pos_lit, plus($*re_pos_lit, lit(pir::length((@($r))[0])))),
            $*re_fail
        ));
        #$stmts.push(emit_say(lits("literal succeeded at position ")));
        #$stmts.push(emit_say($*re_pos_lit));
    }
    elsif $pasttype eq 'pass' {
        # Code for success
        #$stmts.push(emit_say(lits("pass at position ")));
        #$stmts.push(emit_say($*re_pos_lit));
        $stmts.push(LST::Label.new(:name(get_unique_id("rx_pass"))));
        
        $stmts.push(lst_for(PAST::Op.new(
            :pasttype('callmethod'), :name('cursor_pass'),
            $*re_cur, box('int', $*re_pos_lit), "" # XXX TODO regexname
        )));
        
        $stmts.push(lst_for(PAST::Op.new(
            :pasttype('callmethod'), :name('cursor_debug'),
            $*re_cur, "PASS"
        )));
        
        $stmts.push(lst_for(PAST::Op.new(
            :pasttype('callmethod'), :name('cursor_backtrack'),
            $*re_cur,
        )));
        
        $stmts.push(LST::Return.new($*re_cur));
    }
    elsif $pasttype eq 'anchor' {
        my $subtype := $r.subtype;
        my $lbl := get_unique_id('rxanchor');
        my $donelabel := LST::Label.new(:name($lbl));
        my $donegoto := LST::Goto.new(:label($lbl));
        if $subtype eq 'bos' {
            $stmts.push(if_then(
                ne($*re_pos_lit, lit("0")),
                $*re_fail
            ));
        } elsif $subtype eq 'eos' {
            $stmts.push(if_then(
                ne($*re_pos_lit, $*re_eos_lit),
                $*re_fail
            ));
        } elsif $subtype eq 'bol' {
            $stmts.push(if_then(
                emit_op('is_cclass_str_index', 'Newline',
                    $*re_tgt_lit, $*re_pos_lit),
                $donegoto
            ));
            $stmts.push(if_then(
                ne($*re_pos_lit, $*re_eos_lit),
                $*re_fail
            ));
            #$stmts.push(if_then(
            #    eq(lit('0'), $*re_pos_lit),
            #    $donegoto
            #));
            # XXX TODO add the rest here
            $stmts.push($donelabel);
        } else {
            pir::die("Don't know how to compile regex anchor $subtype.");
        }
    }
    elsif $pasttype eq 'alt' {
        my $total := +@($r);
        if $total > 0 {
            my $name := get_unique_id('alt') ~ '_';
            my $acount := 0;
            my $alabel := LST::Label.new(:name($name ~ $acount));
            my $endlabel := LST::Label.new(:name($name ~ 'end'));
            my $alst;
            $stmts.push($alabel);
            for @($r) {
                $alst := lst_regex($_);
                if ($acount := $acount + 1) <= $total {
                    $alabel := $*re_jt.mark($name ~ $acount);
                    $stmts.push(lst_for(PAST::Op.new(
                        :pasttype('callmethod'), :name('mark_push'),
                        $*re_cur, val(0),
                        box('int', $*re_pos_lit),
                        box('int', lit($*re_jt.get_index($name ~ $acount)))
                    )));
                }
                $stmts.push($alst);
                $stmts.push($alabel);
            }
            $stmts.push($endlabel);
        }
    }
    elsif $pasttype eq 'quant' {
        my $backtrack := $r.backtrack || 'g';
        my $sep := $r.sep;
        my $min := $r.min;
        my $max := $r.max;
        pir::defined($max) || ($max := -1);
        # # XXX TODO optimizations
        #my $cpast;
        #if +@($r) != 1 {
        #    $cpast := (@($r))[0];
        #    if self.can($cpast.pasttype ~ '_q') {
        #        my $p0 := self
        #    }
        #}
        my $qname := get_unique_id('rxquant' ~ $backtrack);
        my $q1label := $*re_jt.mark($qname ~ 'loop');
        my $q2label := $*re_jt.mark($qname ~ 'done');
        my $q1idx := box('int', lit($*re_jt.get_index($q1label.name)));
        my $q2idx := box('int', lit($*re_jt.get_index($q2label.name)));
        my $q1goto := LST::Goto.new(:label($q1label.name));
        my $q2goto := LST::Goto.new(:label($q2label.name));
        my $clst := lst_regex(PAST::Regex.new(:pasttype('concat'), |@($r)));
        my $seplst;
        my $seppast := $r.sep;
        $seplst := lst_regex($seppast) if $seppast;
        my $seplabel;
        
        #my $s0 := $max;
        my $needrep := $min > 1 || $max > 1 || $max == -1;
        #$s0 := '*' if $max < 0;
        my $btreg;
        
        if $backtrack ne 'f' { # greedy
            my $needmark := $needrep;
            my $peekcut := 'mark_peek';
            if $backtrack eq 'r' {
                $needmark := 1;
                $peekcut := 'mark_commit';
            }
            if $min == 0 || $needmark {
                $stmts.push(lst_for(PAST::Op.new(
                    :pasttype('callmethod'), :name('mark_push'),
                    $*re_cur, val(0), val($min == 0 ?? 0 !! -1),
                    $q2idx
                )));
            }
            $stmts.push($q1label);
            $stmts.push($clst);
            if $needmark {
                $stmts.push(lst_for(PAST::Op.new(
                    :pasttype('callmethod'), :name($peekcut),
                    $*re_cur, val(1), box('int', $*re_rep_lit),
                    $q2idx
                )));
                if $needrep {
                    $stmts.push(LST::Bind.new($*re_rep_lit,
                        plus($*re_rep_lit, lit('1'))));
                }
            }
            $stmts.push(if_then(ge($*re_rep_lit, lit($max)), $q2goto)) if $max > 1;
            if $max != 1 {
                $stmts.push(lst_for(PAST::Op.new(
                    :pasttype('callmethod'), :name('mark_push'),
                    $*re_cur, box('int', $*re_rep_lit), box('int', $*re_pos_lit),
                    $q2idx
                )));
                $stmts.push($seplst) if pir::defined($seplst);
                $stmts.push($q1goto);
            }
            $stmts.push($q2label);
            $stmts.push(if_then(lt($*re_rep_lit, lit($min)), $*re_fail)) if $min > 1;
        } else {
            my $ireg := temp_int(:name($qname ~ '_frugal'));
            $stmts.push($ireg);
            if $min == 0 {
                $stmts.push(lst_for(PAST::Op.new(
                    :pasttype('callmethod'), :name('mark_push'),
                    $*re_cur, val(0), box('int', $*re_pos_lit),
                    $q1idx
                )));
                $stmts.push($q2goto);
            } else {
                $stmts.push(LST::Bind.new($*re_rep_lit, lit('0'))) if $needrep;
                if pir::defined($seplst) {
                    $seplabel := LST::Label.new(:name(get_unique_id($qname ~ '_frugal_sep')));
                    $stmts.push(LST::Goto.new(:label($seplabel)));
                }
            }
            $stmts.push($q1label);
            if pir::defined($seplst) {
                $stmts.push($seplst);
                $stmts.push($seplabel);
            }
            if $needrep {
                $stmts.push(LST::Bind.new(lit($ireg.name), $*re_rep_lit));
                if $max > 1 {
                    $stmts.push(if_then(
                        ge($*re_rep_lit, lit($max)),
                        $*re_fail
                    ));
                }
            }
            $stmts.push($clst);
            $stmts.push(LST::Bind.new($*re_rep_lit, plus(lit($ireg.name),
                lit('1')))) if $needrep;
            $stmts.push(if_then(lt($*re_rep_lit, lit($min)), $q1goto)) if $max > 1;
            if $max != 1 {
                $stmts.push(lst_for(PAST::Op.new(
                    :pasttype('callmethod'), :name('mark_push'),
                    $*re_cur, box('int', $*re_rep_lit), box('int', $*re_pos_lit),
                    $q1idx
                )));
            }
            $stmts.push($q2label);
        }
    } elsif $pasttype eq 'subrule' {
        my $name := $r.name;
        my $clst := lst_for((@($r))[0]);
        my $posargs := lst_for((@($r))[1]);
        
        #my $sublst := $posargs.shift;
        
        my $negate := $r.negate;
        
        my $subtype := $r.subtype;
        my $backtrack := $r.backtrack;
        
        $stmts.push(cursorop('pos', box('int', $*re_pos_lit)));
        
        $stmts.push($clst);
        
        my $call := lst_for(PAST::Op.new(
            :pasttype('callmethod'), :name('Bool'),
            cursorop($name, $posargs)
        ));
        
        # the logic here *appears* inverted because of the if_then.
        $call := lst_for(PAST::Op.new(
            :pasttype('call'), :name('&prefix:<!>'),
            $call
        )) unless $negate;
        
        $stmts.push(if_then(:bool(0),
            unbox('int', $call),
            $*re_fail
        ));
        
        if $subtype eq 'zerowidth' {
            
        } else {
            
        }
    }
    else {
        pir::die("Don't know how to compile regex pasttype $pasttype.");
    }
    lst_for($stmts)
}

# Emits a cursor operation
sub cursorop($name, *@args) {
    lst_for(PAST::Op.new(
        :pasttype('callmethod'), :name($name),
        $*re_cur, |@args
    ))
}

# Emits a lookup of a lexical.
sub emit_lexical_lookup($name) {
    my $lookup := emit_op(($*BIND_CONTEXT ?? 'bind_lex' !! 'get_lex'),
        LST::Literal.new( :value($name), :escape(1) )
    );
    if $*BIND_CONTEXT {
        $lookup.push($*BIND_VALUE);
    }
    $lookup
}

# Emits a lookup of a lexical in a scope outside the present one.
sub emit_outer_lexical_lookup($name) {
    if $*BIND_CONTEXT {
        pir::die("Cannot bind to something using scope 'outer'.");
    }
    my $lookup := emit_op('get_lex_skip_current',
        LST::Literal.new( :value($name), :escape(1) )
    );
    $lookup
}

# Emits a lookup of a dynamic var.
sub emit_dynamic_lookup($name) {
    my $lookup := emit_op(($*BIND_CONTEXT ?? 'bind_dynamic' !! 'get_dynamic'),
        LST::Literal.new( :value($name), :escape(1) )
    );
    if $*BIND_CONTEXT {
        $lookup.push($*BIND_VALUE);
    }
    $lookup
}

# Emits the printing of something 
# XXX Debugging and C# only, silly.
sub emit_say($arg) {
    LST::Stmts.new(LST::MethodCall.new(
        :on('Console'), :name('WriteLine'),
        :void(1),
        lst_for($arg)
    ), lst_for(PAST::Val.new( :value("") )))
}

sub temp_int($arg?, :$name) {
    LST::Local.new(
        :name(get_unique_id('int_' ~ ($name || ''))), :isdecl(1), :type('int'),
        pir::defined($arg) ?? lst_for($arg) !! lit(0)
    )
}

sub temp_str($arg?, :$name) {
    LST::Local.new(
        :name(get_unique_id('string_' ~ ($name || ''))), :isdecl(1), :type('string'),
        pir::defined($arg) ?? lst_for($arg) !! lits("")
    )
}

# Emits a boxing operation to an int/num/str.
sub box($type, $arg) {
    LST::MethodCall.new(
        :on('Ops'), :name("box_$type"), :type('RakudoObject'),
        TC(), lst_for($arg)
    )
}

# Emits the unboxing of a str/num/int.
sub unbox($type, $arg) {
    LST::MethodCall.new(
        :on('Ops'), :name("unbox_$type"),
        :type(vm_type_for($type)),
        TC(), lst_for($arg)
    )
}

# Maps a hand-wavey type (one of the three we box/unbox with) to a CLR type.
sub vm_type_for($type) {
    $type eq 'num' ?? 'double' !!
    $type eq 'str' ?? 'string' !!
    $type eq 'int' ?? 'int'    !!
    $type eq 'obj' ?? 'RakudoObject' !!
                      pir::die("Don't know VM type for $type")
}

sub plus($l, $r, $type?) {
    LST::Add.new(lst_for($l), lst_for($r), pir::defined($type) ?? $type !! 'int')
}

sub minus($l, $r, $type?) {
    LST::Subtract.new(lst_for($l), lst_for($r), pir::defined($type) ?? $type !! 'int')
}

sub bitwise_or($l, $r, $type?) {
    LST::BOR.new(lst_for($l), lst_for($r), pir::defined($type) ?? $type !! 'int')
}

sub bitwise_and($l, $r, $type?) {
    LST::BAND.new(lst_for($l), lst_for($r), pir::defined($type) ?? $type !! 'int')
}

sub bitwise_xor($l, $r, $type?) {
    LST::BXOR.new(lst_for($l), lst_for($r), pir::defined($type) ?? $type !! 'int')
}

sub gt($l, $r) {
    LST::GT.new(lst_for($l), lst_for($r), 'bool')
}

sub lt($l, $r) {
    LST::LT.new(lst_for($l), lst_for($r), 'bool')
}

sub ge($l, $r) {
    LST::GE.new(lst_for($l), lst_for($r), 'bool')
}

sub le($l, $r) {
    LST::LE.new(lst_for($l), lst_for($r), 'bool')
}

sub eq($l, $r) {
    LST::EQ.new(lst_for($l), lst_for($r), 'bool')
}

sub ne($l, $r) {
    LST::NE.new(lst_for($l), lst_for($r), 'bool')
}

sub not($operand) {
    LST::NOT.new(lst_for($operand), 'bool')
}

# short-circuiting logical AND
sub log_and($l, $r) {
    my $temp;
    LST::Stmts.new(
    ($temp := LST::Local.new(
        :name(get_unique_id('log_and')), :isdecl(1), :type('bool'), lit('false')
    )),
    if_then(LST::Local.new(
        :name(get_unique_id('left_bool')), :isdecl(1), :type('bool'), lst_for($l)
    ), if_then(LST::Local.new(
        :name(get_unique_id('right_bool')), :isdecl(1), :type('bool'), lst_for($r)
    ), LST::Bind.new(
    ### XXX The next line works only with the C# backend (so far)
    ###   b/c the Bind causes the Temp to be redeclared without the lit(___.name)
    lit($temp.name)
    , lit('true')))));
}

# short-circuiting logical OR
sub log_or($l, $r) {
    my $temp;
    LST::Stmts.new(
    ($temp := LST::Local.new(
        :name(get_unique_id('log_or')), :isdecl(1), :type('bool'), lit('false')
    )),
    if_then(LST::Local.new(
        :name(get_unique_id('left_bool')), :isdecl(1), :type('bool'), lst_for($l)
    ),
    LST::Bind.new(lit($temp.name), lit('true')),
    if_then(LST::Local.new(
        :name(get_unique_id('right_bool')), :isdecl(1), :type('bool'), lst_for($r)
    ),
    LST::Bind.new(lit($temp.name), lit('true')),
    )));
}

sub log_xor($l, $r) {
    LST::XOR.new(lst_for($l), lst_for($r), 'bool')
}

sub if_then($cond, $pred, $oth?, :$bool?) {
    pir::defined($oth)
        ?? LST::If.new($cond, $pred, $oth, :bool(pir::defined($bool) ?? $bool !! 1), :result(0))
        !! LST::If.new($cond, $pred, :bool(pir::defined($bool) ?? $bool !! 1), :result(0))
}

sub lits($str) {
    LST::Literal.new( :value($str), :escape(1))
}

sub lit($str) {
    $str ~~ LST::Literal
        ?? $str
        !! LST::Literal.new( :value($str), :escape(0))
}

sub val($val) {
    $val ~~ LST::Node
        ?? $val
        !! lst_for(PAST::Val.new( :value($val) ))
}

sub emit_op($name, *@args) {
    # See if we have any info on this op's siggy.
    my $sig := %nqp_op_sigs{$name};
    my $type := 'obj';
    if pir::defined($sig) {
        $type := $sig[0];
    }
    
    # Compile the args.
    my @lst_args;
    my $i := 1;
    for @args {
        # Set the type context that is desired.
        my $*TYPE_CONTEXT := pir::defined($sig) ?? $sig[$i] !! 'obj';
        my $arg_lst := lst_for($_);
        
        # We may need to auto-unbox it if we don't have the desired type
        # of thing.
        if $*TYPE_CONTEXT ne 'obj' {
            unless ($arg_lst ~~ LST::MethodCall || $arg_lst ~~ LST::Call || $arg_lst ~~ LST::Literal)
              && $arg_lst.type eq vm_type_for($*TYPE_CONTEXT) {
                $arg_lst := unbox($*TYPE_CONTEXT, $arg_lst);
            }
        }

        @lst_args.push($arg_lst);
    }

    # Build op call.
    #pir::say("name is $name; type is $type; lst_arg count is " ~ +@lst_args);
    my $call := LST::MethodCall.new(
        :on('Ops'), :name($name),
        :type(vm_type_for($type)),
        TC(), |@lst_args
    );

    # We may need to auto-box it.
    $type ne $*TYPE_CONTEXT && $*TYPE_CONTEXT eq 'obj' ??
        box($type, $call) !!
        $call
}

sub emit_call($on, $name, $type, *@args) {
    my @lst_args;
    for @args {
        @lst_args.push(lst_for($_))
    }
    LST::MethodCall.new(
        :on($on), :name($name),
        :type($type),
        |@lst_args
    )
}

sub returns_array($expr, *@result_slots) {
    my $tmp;
    my $stmts := LST::Stmts.new(
        $tmp := LST::Local.new(
            :type('RakudoObject'),
            :name(get_unique_id('array_result')),
            :isdecl(1),
            $expr
        )
    );
    my $i := 0;
    while $i < +@result_slots {
        $stmts.push(LST::Bind.new(
            @result_slots[$i],
            @result_slots[$i + 1] eq 'int'
            ?? unbox('int', emit_op('lllist_get_at_pos',
                LST::Local.new(:name($tmp.name)),
                lit(~($i / 2))))
            !! 
            @result_slots[$i + 1] eq 'string'
            ?? unbox('str', emit_op('lllist_get_at_pos',
                LST::Local.new(:name($tmp.name)),
                lit(~($i / 2))))
            !! emit_op('lllist_get_at_pos',
                LST::Local.new(:name($tmp.name)),
                lit(~($i / 2)))
        ));
        $i := $i + 2;
    };
    $stmts
}

# Returns a LST::Local for looking up the variable name with the
# given type. Default type is RakudoObject.
sub loc($name, $type = 'RakudoObject') {
    LST::Local.new( :name($name), :type($type) )
}

# Returns a LST::Local referencing the current thread context.
sub TC() {
    loc('TC', 'ThreadContext')
}
