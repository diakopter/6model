class JnthnNQP::Actions is HLL::Actions;

our @BLOCK;

INIT {
    our @BLOCK := Q:PIR { %r = new ['ResizablePMCArray'] };
}

sub xblock_immediate($xblock) {
    $xblock[1] := block_immediate($xblock[1]);
    $xblock;
}

sub block_immediate($block) {
    $block.blocktype('immediate');
    unless $block.symtable() || $block.handlers() {
        my $stmts := PAST::Stmts.new( :node($block) );
        for $block.list { $stmts.push($_); }
        $block := $stmts;
    }
    $block;
}

sub vivitype($sigil) {
    if $sigil eq '%' {
        PAST::Op.new(
            :pasttype('callmethod'), :name('new'),
            PAST::Var.new( :name('NQPHash'), :scope('lexical') )
        )
    }
    elsif $sigil eq '@' {
        PAST::Op.new(
            :pasttype('callmethod'), :name('new'),
            PAST::Var.new( :name('NQPArray'), :scope('lexical') )
        )
    }
    else {
        PAST::Var.new( :name('Any'), :scope('lexical') )
    }
}


method TOP($/) { make $<comp_unit>.ast; }

method deflongname($/) {
    make $<colonpair>
         ?? ~$<identifier> ~ ':' ~ $<colonpair>[0].ast.named 
                ~ '<' ~ colonpair_str($<colonpair>[0].ast) ~ '>'
         !! ~$/;
    # make $<sym> ?? ~$<identifier> ~ ':sym<' ~ ~$<sym>[0] ~ '>' !! ~$/;
}

sub colonpair_str($ast) {
    PAST::Op.ACCEPTS($ast)
    ?? pir::join(' ', $ast.list)
    !! $ast.value;
}

method comp_unit($/) {
    # Make the main unit.
    my $mainline := $<statementlist>.ast;
    my $unit     := @BLOCK.shift;
    $unit.push($mainline);
    $unit.node($/);

    # The first thing we ever want to do is load the core libraries
    # (unless passed the flag to tell us not to, which probably means
    # we're actually compiling those libraries.)
    unless $*NQP_NO_CORE_LIBS {
        $unit.unshift(PAST::Block.new(
            :blocktype('declaration'),
            :loadinit(PAST::Stmts.new(
                PAST::Op.new( :pasttype('nqpop'), :name('load_module'), 'P6Objects' )
            ))
        ));
    }

    make $unit;
}

method statementlist($/) {
    my $past := PAST::Stmts.new( :node($/) );
    if $<statement> {
        for $<statement> {
            my $ast := $_.ast;
            $ast := $ast<sink> if pir::defined($ast<sink>);
            if $ast<bareblock> { $ast := block_immediate($ast); }
            $past.push( $ast );
        }
    }
    make $past;
}

method statement($/, $key?) {
    my $past;
    if $<EXPR> {
        my $mc := $<statement_mod_cond>[0];
        my $ml := $<statement_mod_loop>[0];
        $past := $<EXPR>.ast;
        if $mc {
            $past := PAST::Op.new($mc<cond>.ast, $past, :pasttype(~$mc<sym>), :node($/) );
        }
        if $ml {
            if ~$ml<sym> eq 'for' {
                $past := PAST::Block.new( :blocktype('immediate'),
                    PAST::Var.new( :name('$_'), :scope('parameter'), :isdecl(1) ),
                    $past);
                $past.symbol('$_', :scope('lexical') );
                $past.arity(1);
                $past := PAST::Op.new($ml<cond>.ast, $past, :pasttype(~$ml<sym>), :node($/) );
            }
            else {
                $past := PAST::Op.new($ml<cond>.ast, $past, :pasttype(~$ml<sym>), :node($/) );
            }
        }
    }
    elsif $<statement_control> { $past := $<statement_control>.ast; }
    else { $past := 0; }
    make $past;
}

method xblock($/) {
    make PAST::Op.new( $<EXPR>.ast, $<pblock>.ast, :pasttype('if'), :node($/) );
}

method pblock($/) {
    make $<blockoid>.ast;
}

method block($/) {
    make $<blockoid>.ast;
}

method blockoid($/) {
    my $past := $<statementlist>.ast;
    my $BLOCK := @BLOCK.shift;
    $BLOCK.push($past);
    $BLOCK.node($/);
    $BLOCK.closure(1);
    make $BLOCK;
}

method newpad($/) {
    our @BLOCK;
    @BLOCK.unshift( PAST::Block.new( PAST::Stmts.new() ) );
}

## Statement control

method statement_control:sym<if>($/) {
    my $count := +$<xblock> - 1;
    my $past := xblock_immediate( $<xblock>[$count].ast );
    if $<else> {
        $past.push( block_immediate( $<else>[0].ast ) );
    }
    # build if/then/elsif structure
    while $count > 0 {
        $count--;
        my $else := $past;
        $past := xblock_immediate( $<xblock>[$count].ast );
        $past.push($else);
    }
    make $past;
}

method statement_control:sym<unless>($/) {
    my $past := xblock_immediate( $<xblock>.ast );
    $past.pasttype('unless');
    make $past;
}

method statement_control:sym<while>($/) {
    my $past := xblock_immediate( $<xblock>.ast );
    $past.pasttype(~$<sym>);
    make $past;
}

method statement_control:sym<repeat>($/) {
    my $pasttype := 'repeat_' ~ ~$<wu>;
    my $past;
    if $<xblock> {
        $past := xblock_immediate( $<xblock>.ast );
        $past.pasttype($pasttype);
    }
    else {
        $past := PAST::Op.new( $<EXPR>.ast, block_immediate( $<pblock>.ast ),
                               :pasttype($pasttype), :node($/) );
    }
    make $past;
}

method statement_control:sym<for>($/) {
    my $xb := $<xblock>.ast;
    my $expr  := $xb[0];
    my $block := $xb[1];
    unless $block.arity {
        $block[0].push( PAST::Var.new( :name('$_'), :scope('parameter') ) );
        $block.symbol('$_', :scope('lexical') );
        $block.arity(1);
    }
    $block.blocktype('declaration');
    make PAST::Op.new(
        :pasttype('callmethod'), :name('eager'),
        PAST::Op.new(
            :pasttype('callmethod'), :name('map'),
            $expr,
            $block
        )
    );
}

method statement_control:sym<return>($/) {
    make PAST::Op.new( $<EXPR>.ast, :pasttype('return'), :node($/) );
}

method statement_control:sym<CATCH>($/) {
    my $block := $<block>.ast;
    push_block_handler($/, $block);
    @BLOCK[0].handlers()[0].handle_types_except('CONTROL');
    make PAST::Stmts.new(:node($/));
}

method statement_control:sym<CONTROL>($/) {
    my $block := $<block>.ast;
    push_block_handler($/, $block);
    @BLOCK[0].handlers()[0].handle_types('CONTROL');
    make PAST::Stmts.new(:node($/));
}

sub push_block_handler($/, $block) {
    unless @BLOCK[0].handlers() {
        @BLOCK[0].handlers([]);
    }
    unless $block.arity {
        $block.unshift(
            PAST::Op.new( :pasttype('bind'),
                PAST::Var.new( :scope('lexical'), :name('$!'), :isdecl(1) ),
                PAST::Var.new( :scope('lexical'), :name('$_')),
            ),
        );
        $block.unshift( PAST::Var.new( :name('$_'), :scope('parameter') ) );
        $block.symbol('$_', :scope('lexical') );
        $block.symbol('$!', :scope('lexical') );
        $block.arity(1);
    }
    $block.blocktype('declaration');
    @BLOCK[0].handlers.unshift(
        PAST::Control.new(
            :node($/),
            PAST::Stmts.new(
                PAST::Op.new( :pasttype('call'),
                    $block,
                    PAST::Var.new( :scope('register'), :name('exception')),
                ),
                PAST::Op.new( :pasttype('bind'),
                    PAST::Var.new( :scope('keyed'),
                        PAST::Var.new( :scope('register'), :name('exception')),
                        'handled'
                    ),
                    1
                )
            ),
        )
    );
}

method statement_prefix:sym<INIT>($/) {
    @BLOCK[0].loadinit.push($<blorst>.ast);
    make PAST::Stmts.new(:node($/));
}

method statement_prefix:sym<try>($/) {
    my $past := $<blorst>.ast;
    if $past.WHAT ne 'PAST::Block()' {
        $past := PAST::Block.new($past, :blocktype('immediate'), :node($/));
    }
    unless $past.handlers() {
        $past.handlers([PAST::Control.new(
                :handle_types_except('CONTROL'),
                PAST::Stmts.new(
                    PAST::Op.new( :pasttype('bind'),
                        PAST::Var.new( :scope('keyed'),
                            PAST::Var.new( :scope('register'), :name('exception')),
                            'handled'
                        ),
                        1
                    )
                )
            )]
        );
    }
    make $past;
}

method blorst($/) {
    make $<block>
         ?? block_immediate($<block>.ast)
         !! $<statement>.ast;
}

# Statement modifiers

method statement_mod_cond:sym<if>($/)     { make $<cond>.ast; }
method statement_mod_cond:sym<unless>($/) { make $<cond>.ast; }

method statement_mod_loop:sym<while>($/)  { make $<cond>.ast; }
method statement_mod_loop:sym<until>($/)  { make $<cond>.ast; }

## Terms

method term:sym<fatarrow>($/)           { make $<fatarrow>.ast; }
method term:sym<colonpair>($/)          { make $<colonpair>.ast; }
method term:sym<variable>($/)           { make $<variable>.ast; }
method term:sym<package_declarator>($/) { make $<package_declarator>.ast; }
method term:sym<scope_declarator>($/)   { make $<scope_declarator>.ast; }
method term:sym<routine_declarator>($/) { make $<routine_declarator>.ast; }
method term:sym<regex_declarator>($/)   { make $<regex_declarator>.ast; }
method term:sym<statement_prefix>($/)   { make $<statement_prefix>.ast; }
method term:sym<lambda>($/)             { make $<pblock>.ast; }

method fatarrow($/) {
    my $past := $<val>.ast;
    $past.named( $<key>.Str );
    make $past;
}

method colonpair($/) {
    my $past := $<circumfix>
                ?? $<circumfix>[0].ast
                !! PAST::Val.new( :value( !$<not> ) );
    $past.named( ~$<identifier> );
    make $past;
}

method variable($/) {
    my $past;
    if $<postcircumfix> {
        $past := $<postcircumfix>.ast;
        $past.unshift( PAST::Var.new( :name('$/') ) );
    }
    else {
        my @name := HLL::Compiler.parse_name(~$/);
        $past := PAST::Var.new( :name(~@name.pop) );
        if (@name) {
            if @name[0] eq 'GLOBAL' { @name.shift; }
            $past.namespace(@name);
            $past.scope('package');
            $past.viviself( vivitype( $<sigil> ) );
            $past.lvalue(1);
        }
        if $<sigil> eq '::' {
            $past.isdecl(1);
            $past.name(~$<desigilname>);
            @BLOCK[0].symbol($past.name(), :scope('lexical'));
        }
        elsif $<twigil>[0] eq '*' {
            $past.scope('contextual');
            $past.viviself( 
                PAST::Var.new( 
                    :scope('package'), :namespace(''), 
                    :name( ~$<sigil> ~ $<desigilname> ),
                    :viviself( 
                        PAST::Op.new( 'Contextual ' ~ ~$/ ~ ' not found',
                                      :pirop('die') )
                    )
                )
            );
        }
        elsif $<twigil>[0] eq '!' || $<twigil>[0] eq '.' {
            $past.push(PAST::Var.new( :name('self') ));
            $past.scope('attribute');
            $past.viviself( vivitype( $<sigil> ) );
            if ($<twigil>[0] eq '.') {
                $past.name(pir::substr($past.name, 0, 1) ~ '!' ~ pir::substr($past.name, 2));
            }
        }
    }
    make $past;
}

method package_declarator:sym<module>($/)  { make $<package_def>.ast; }
method package_declarator:sym<knowhow>($/) { make package($/); }
method package_declarator:sym<grammar>($/) { make package($/); }
method package_declarator:sym<class>($/)   { make package($/); }
method package_declarator:sym<role>($/)    { make package($/); }

sub package($/) {
    # Sort out name.
    my $long_name := ~$<package_def><name>;
    my @ns := pir::clone__PP($<package_def><name><identifier>);
    my $name := @ns.pop;
    
    # Prefix the class initialization with initial setup. Also install it
    # in the symbol table right away, and also into $?CLASS.
    $*PACKAGE-SETUP.unshift(PAST::Stmts.new(
        PAST::Op.new( :pasttype('bind'),
            PAST::Var.new( :name('type_obj'), :scope('register'), :isdecl(1) ),
            PAST::Op.new(
                :pasttype('callmethod'), :name('new_type'),
                PAST::Var.new( :name(%*HOW{~$<sym>}), :scope('lexical') ),
                PAST::Val.new( :value($long_name), :named('name') )
            )
        ),
        PAST::Op.new( :pasttype('bind'),
            PAST::Var.new( :name($name), :scope($*SCOPE eq 'my' ?? 'lexical' !! 'package'), :namespace(@ns) ),
            PAST::Var.new( :name('type_obj'), :scope('register') )
        ),
        PAST::Op.new( :pasttype('bind'),
            PAST::Var.new( :name('$?CLASS') ),
            PAST::Var.new( :name('type_obj'), :scope('register') )
        )
    ));
    if $<package_def><repr> {
        my $repr_name := $<package_def><repr>[0].ast;
        $repr_name.named('repr');
        $*PACKAGE-SETUP[0][0][1].push($repr_name);
    }

    # Parent class, if any. (XXX need to handle package vs lexical scope
    # properly).
    if $<package_def><parent> {
        my @parent_ns := pir::clone__PP($<package_def><parent>[0]<identifier>);
        my $parent_name := @parent_ns.pop;
        $*PACKAGE-SETUP.push(PAST::Op.new(
            :pasttype('callmethod'), :name('add_parent'),
            PAST::Op.new(
                :pasttype('nqpop'), :name('get_how'),
                PAST::Var.new( :name('type_obj'), :scope('register') )
            ),
            PAST::Var.new( :name('type_obj'), :scope('register') ),
            PAST::Var.new( :name($parent_name), :namespace(@parent_ns), :scope('package') )
        ));
    }

    # Postfix it with a call to compose.
    $*PACKAGE-SETUP.push(PAST::Op.new(
        :pasttype('callmethod'), :name('compose'),
        PAST::Op.new(
            :pasttype('nqpop'), :name('get_how'),
            PAST::Var.new( :name('type_obj'), :scope('register') )
        ),
        PAST::Var.new( :name('type_obj'), :scope('register') )
    ));

    # Set up lexical for lexical packages; otherwise, just record that it
    # lives in the package.
    if $*SCOPE eq 'my' {
        @BLOCK[0][0].unshift(PAST::Var.new( :name($name), :scope('lexical'), :isdecl(1) ));
        @BLOCK[0].symbol($name, :scope('lexical'));
    }
    else {
        @BLOCK[0].symbol($name, :scope('package'));
    }

    # Evaluate anything else in the package in-line; also give it a $?CLASS
    # lexical.
    my $past := $<package_def>.ast;
    $past.unshift(PAST::Var.new( :name('$?CLASS'), :scope('lexical'), :isdecl(1) ));
    $past.symbol('$?CLASS', :scope('lexical'));

    # Attach the class code to run at loadinit time.
    $past.loadinit.push(PAST::Block.new( :blocktype('immediate'), $*PACKAGE-SETUP ));

    return $past;
}

method package_def($/) {
    my $past := $<block> ?? $<block>.ast !! $<comp_unit>.ast;
    $past.namespace( $<name><identifier> );
    $past.blocktype('immediate');
    make $past;
}

method scope_declarator:sym<my>($/)  { make $<scoped>.ast; }
method scope_declarator:sym<our>($/) { make $<scoped>.ast; }
method scope_declarator:sym<has>($/) { make $<scoped>.ast; }

method scoped($/) {
    make $<declarator>       ?? $<declarator>.ast       !!
         $<multi_declarator> ?? $<multi_declarator>.ast !!
                                $<package_declarator>.ast;
}

method declarator($/) {
    make $<routine_declarator>
         ?? $<routine_declarator>.ast
         !! $<variable_declarator>.ast;
}

method multi_declarator:sym<multi>($/) { make $<declarator> ?? $<declarator>.ast !! $<routine_def>.ast }
method multi_declarator:sym<proto>($/) { make $<declarator> ?? $<declarator>.ast !! $<routine_def>.ast }
method multi_declarator:sym<null>($/)  { make $<declarator>.ast }


method variable_declarator($/) {
    my $past := $<variable>.ast;
    my $sigil := $<variable><sigil>;
    my $name := $past.name;
    my $BLOCK := @BLOCK[0];
    if $BLOCK.symbol($name) {
        $/.CURSOR.panic("Redeclaration of symbol ", $name);
    }
    if $*SCOPE eq 'has' {
        if $<variable><twigil>[0] eq '.' {
            $name := pir::substr($name, 0, 1) ~ '!' ~ pir::substr($name, 2);
        }
        # Create and add a meta-attribute.
        my $meta-attr-type := %*HOW-METAATTR{$*PKGDECL} || $*DEFAULT-METAATTR;
        $*PACKAGE-SETUP.push(PAST::Op.new(
            :pasttype('callmethod'), :name('add_attribute'),
            PAST::Op.new(
                :pasttype('nqpop'), :name('get_how'),
                PAST::Var.new( :name('type_obj'), :scope('register') )
            ),
            PAST::Var.new( :name('type_obj'), :scope('register') ),
            PAST::Op.new(
                :pasttype('callmethod'), :name('new'),
                PAST::Var.new( :name($meta-attr-type), :scope('lexical') ),
                PAST::Val.new( :value($name), :named('name') ),
                PAST::Val.new( :value($<variable><twigil>[0] eq '.'
                    ?? 1 !! 0), :named('has_accessor') ),
                PAST::Val.new( :value($<declarator_is_rw>
                    ?? 1 !! 0), :named('has_mutator') )
            )
        ));
        $past := PAST::Stmts.new();
    }
    else {
        my $scope := $*SCOPE eq 'our' ?? 'package' !! 'lexical';
        my $decl := PAST::Var.new( :name($name), :scope($scope), :isdecl(1),
                                   :lvalue(1), :viviself( vivitype($sigil) ),
                                   :node($/) );
        $BLOCK.symbol($name, :scope($scope) );
        $BLOCK[0].push($decl);
    }
    make $past;
}

method routine_declarator:sym<sub>($/) { make $<routine_def>.ast; }
method routine_declarator:sym<method>($/) { make $<method_def>.ast; }

method routine_def($/) {
    # If it's just got * as a body, make a multi-dispatch enterer.
    # Otherwise, need to build a sub.
    my $past;
    if $<onlystar> {
        $past := only_star_block();
    }
    else {
        $past := $<blockoid>.ast;
        $past.blocktype('declaration');
        $past.control('return_pir');
    }

    if $<deflongname> {
        my $name := ~$<sigil>[0] ~ $<deflongname>[0].ast;
        $past.name($name);
        if $*SCOPE eq '' || $*SCOPE eq 'my' || $*SCOPE eq 'our' {
            if $*MULTINESS eq 'multi' {
                # Does the current block have a candidate holder in place?
                if $*SCOPE eq 'our' { pir::die('our-scoped multis not yet implemented') }
                my $cholder;
                my %sym := @BLOCK[0].symbol($name);
                if %sym<cholder> {
                    $cholder := %sym<cholder>;
                }
                
                # Otherwise, no candidate holder, so add one.
                else {
                    # Check we have a proto in scope.
                    if %sym<proto> {
                        # WTF, a proto is in this scope, but didn't set up a
                        # candidate holder?!
                        $/.CURSOR.panic('Internal Error: Current scope has a proto, but no candidate list holder was set up. (This should never happen.)');
                    }
                    my $found_proto;
                    for @BLOCK {
                        my %sym := $_.symbol($name);
                        if %sym<proto> || %sym<cholder> {
                            $found_proto := 1;
                        }
                        elsif %sym {
                            $/.CURSOR.panic("Cannot declare a multi when an only is already in scope.");
                        }
                    }

                    # If we didn't find a proto, error for now.
                    unless $found_proto {
                        $/.CURSOR.panic("Sorry, no proto sub in scope, and auto-generation of protos is not yet implemented.");
                    }

                    # Set up dispatch routine in this scope.
                    $cholder := PAST::Op.new( :pasttype('list') );
                    my $dispatch_setup := PAST::Op.new(
                        :pasttype('nqpop'), :name('create_dispatch_and_add_candidates'),
                        PAST::Var.new( :name($name), :scope('outer') ),
                        $cholder
                    );
                    @BLOCK[0][0].push(PAST::Var.new( :name($name), :isdecl(1),
                                      :viviself($dispatch_setup), :scope('lexical') ) );
                    @BLOCK[0].symbol($name, :scope('lexical'), :cholder($cholder) );
                }

                # Add this candidate to the holder.
                $cholder.push($past);
            }
            elsif $*MULTINESS eq 'proto' {
                # Create a candidate list holder for the dispatchees
                # this proto will work over, and install them along
                # with the proto.
                if $*SCOPE eq 'our' { pir::die('our-scoped protos not yet implemented') }
                my $cholder := PAST::Op.new( :pasttype('list') );
                @BLOCK[0][0].push(PAST::Var.new( :name($name), :isdecl(1),
                                      :viviself($past), :scope('lexical') ) );
                @BLOCK[0][0].push(PAST::Op.new(
                    :pasttype('nqpop'), :name('set_dispatchees'),
                    PAST::Var.new( :name($name) ),
                    $cholder
                ));
                @BLOCK[0].symbol($name, :scope('lexical'), :proto(1), :cholder($cholder) );
            }
            else {
                @BLOCK[0][0].push(PAST::Var.new( :name($name), :isdecl(1),
                                      :viviself($past), :scope('lexical') ) );
                @BLOCK[0].symbol($name, :scope('lexical') );
                if $*SCOPE eq 'our' {
                    # Need to install it at loadinit time but also re-bind
                    # it per invocation.
                    @BLOCK[0][0].push(PAST::Op.new(
                        :pasttype('bind'),
                        PAST::Var.new( :name($name), :scope('package') ),
                        PAST::Var.new( :name($name), :scope('lexical') )
                    ));
                    @BLOCK[0].loadinit.push(PAST::Op.new(
                        :pasttype('bind'),
                        PAST::Var.new( :name($name), :scope('package') ),
                        PAST::Val.new( :value($past) )
                    ));
                }
            }
            $past := PAST::Var.new( :name($name) );
        }
        else {
            $/.CURSOR.panic("$*SCOPE scoped routines are not supported yet");
        }
    }
    make $past;
}


method method_def($/) {
    # If it's just got * as a body, make a multi-dispatch enterer.
    # Otherwise, build method block PAST.
    my $past;
    if $<onlystar> {
        $past := only_star_block();
    }
    else {
        $past := $<blockoid>.ast;
        $past.blocktype('declaration');
        $past.control('return_pir');
    }

    # Always need an invocant.
    unless $past<signature_has_invocant> {
        $past[0].unshift(PAST::Var.new(
            :name('self'), :scope('parameter'),
            :multitype(PAST::Var.new( :name('$?CLASS') ))
        ));
    }
    $past.symbol('self', :scope('lexical') );
    
    # Provided it's named, install it in the methods table.
    if $<deflongname> {
        # Set name.
        my $name := ~$<deflongname>[0].ast;
        $past.name($name);

        # If it's a proto, we'll mark it as such by giving it an empty candidate
        # list.
        my $to_add := $*MULTINESS ne 'proto' ??
            PAST::Val.new( :value($past) )   !!
            PAST::Op.new(
                :pasttype('nqpop'), :name('set_dispatchees'),
                PAST::Val.new( :value($past) ),
                PAST::Op.new( :pasttype('list') )
            );
        $*PACKAGE-SETUP.push(PAST::Op.new(
            :pasttype('callmethod'), :name($*MULTINESS eq 'multi' ?? 'add_multi_method' !! 'add_method'),
            PAST::Op.new(
                :pasttype('nqpop'), :name('get_how'),
                PAST::Var.new( :name('type_obj'), :scope('register') )
            ),
            PAST::Var.new( :name('type_obj'), :scope('register') ),
            PAST::Val.new( :value($name) ),
            $to_add
        ));
    }
    
    make $past;
}

sub only_star_block() {
    my $past := @BLOCK.shift;
    $past.closure(1);
    $past.push(PAST::Op.new(
        :pasttype('nqpop'), :name('multi_dispatch_over_lexical_candidates')
    ));
    $past
}

method signature($/) {
    my $BLOCKINIT := @BLOCK[0][0];
    if $<invocant> {
        my $inv := $<invocant>[0].ast;
        $BLOCKINIT.push($inv);
        $BLOCKINIT.push(PAST::Var.new(
            :name('self'), :scope('lexical'), :isdecl(1),
            :viviself(PAST::Var.new( :scope('lexical'), :name($inv.name) ))
        ));
        @BLOCK[0]<signature_has_invocant> := 1
    }
    for $<parameter> { $BLOCKINIT.push($_.ast); }
}

method parameter($/) {
    my $quant := $<quant>;
    my $past;
    if $<named_param> {
        $past := $<named_param>.ast;
        if $quant ne '!' {
            $past.viviself( vivitype($<named_param><param_var><sigil>) );
        }
    }
    else {
        $past := $<param_var>.ast;
        if $quant eq '*' {
            $past.slurpy(1);
            $past.named( $<param_var><sigil> eq '%' );
        }
        elsif $quant eq '?' {
            $past.viviself( vivitype($<param_var><sigil>) );
        }
    }
    if $<default_value> {
        if $quant eq '*' {
            $/.CURSOR.panic("Can't put default on slurpy parameter");
        }
        if $quant eq '!' {
            $/.CURSOR.panic("Can't put default on required parameter");
        }
        $past.viviself( $<default_value>[0]<EXPR>.ast );
    }
    unless $past.viviself { @BLOCK[0].arity( +@BLOCK[0].arity + 1 ); }

    # We're hijacking multi-type a bit here comapred to what Parrot NQP
    # uses it for.
    if $<typename> {
        $past.multitype($<typename>[0].ast);
    }

    # Set definedness flag (XXX perhaps want a better way to do this).
    if $<definedness> {
        $past<definedness> := ~$<definedness>[0];
    }

    make $past;
}

method typename($/) {
    if is_lexical(~$/) {
        make PAST::Var.new(
            :name(~$/),
            :scope('lexical')
        );
    }
    else {
        my @name := HLL::Compiler.parse_name(~$/);
        make PAST::Var.new(
            :name(@name.pop),
            :namespace(@name),
            :scope('package')
        );
    }
}

# Check if something is a lexical or not.
sub is_lexical($name) {
    # XXX Big hack for now, until we can really look at the contents
    # of the setting.
    my %setting_names;
    %setting_names<KnowHOW>          := 1;
    %setting_names<KnowHOWAttribute> := 1;
    %setting_names<NQPStr>           := 1;
    %setting_names<NQPInt>           := 1;
    %setting_names<NQPNum>           := 1;
    %setting_names<NQPList>          := 1;
    %setting_names<NQPArray>         := 1;
    %setting_names<NQPHash>          := 1;
    %setting_names<NQPStash>         := 1;
    %setting_names<NQPCapture>       := 1;
    %setting_names<Any>              := 1;
    if %setting_names{$name} {
        return 1;
    }
    for @BLOCK {
        my %sym := $_.symbol($name);
        if %sym {
            if %sym<scope> eq 'lexical' {
                return 1;
            }
        }
    }
    return 0;
}

method param_var($/) {
    my $name := ~$/;
    my $past :=  PAST::Var.new( :name($name), :scope('parameter'),
                                :isdecl(1), :node($/) );
    @BLOCK[0].symbol($name, :scope('lexical') );
    make $past;
}

method named_param($/) {
    my $past := $<param_var>.ast;
    $past.named( ~$<param_var><name> );
    make $past;
}

method regex_declarator($/, $key?) {
    my @MODIFIERS := Q:PIR {
        %r = get_hll_global ['Regex';'P6Regex';'Actions'], '@MODIFIERS'
    };
    my $name := ~$<deflongname>.ast;
    my $past;
    if $<proto> {
        $past :=
            PAST::Stmts.new(
                PAST::Block.new( :name($name),
                    PAST::Op.new(
                        PAST::Var.new( :name('self'), :scope('register') ),
                        $name,
                        :name('!protoregex'),
                        :pasttype('callmethod')
                    ),
                    :blocktype('method'),
                    :lexical(0),
                    :node($/)
                ),
                PAST::Block.new( :name('!PREFIX__' ~ $name),
                    PAST::Op.new(
                        PAST::Var.new( :name('self'), :scope('register') ),
                        $name,
                        :name('!PREFIX__!protoregex'),
                        :pasttype('callmethod')
                    ),
                    :blocktype('method'),
                    :lexical(0),
                    :node($/)
                )
            );
    }
    elsif $key eq 'open' {
        my %h;
        if $<sym> eq 'token' { %h<r> := 1; }
        if $<sym> eq 'rule'  { %h<r> := 1;  %h<s> := 1; }
        @MODIFIERS.unshift(%h);
        Q:PIR {
            $P0 = find_lex '$name'
            set_hll_global ['Regex';'P6Regex';'Actions'], '$REGEXNAME', $P0
        };
        @BLOCK[0].symbol('$¢', :scope('lexical'));
        @BLOCK[0].symbol('$/', :scope('lexical'));
        return 0;
    }
    else {
        my $regex := buildsub($<p6regex>.ast, @BLOCK.shift);
        $regex.name($name);
        $past := 
            PAST::Op.new(
                :pasttype<callmethod>, :name<new>,
                PAST::Var.new( :name('Method'), :namespace(['Regex']), :scope<package> ),
                $regex
            );
        # In sink context, we don't need the Regex::Regex object.
        $past<sink> := $regex;
        @MODIFIERS.shift;
    }
    make $past;
}


method dotty($/) {
    my $past := $<args> ?? $<args>[0].ast !! PAST::Op.new( :node($/) );
    if $<quote> {
        $past.name($<quote>.ast);
        $past.pasttype('callmethod');
    }
    elsif $<longname> eq 'HOW' {
        $past.name('get_how');
        $past.pasttype('nqpop');
    }
    elsif $<longname> eq 'WHAT' {
        $past.name('get_what');
        $past.pasttype('nqpop');
    }
    else {
        $past.name(~$<longname>);
        $past.pasttype('callmethod');
    }
    make $past;
}

## Terms

method term:sym<self>($/) {
    make PAST::Var.new( :name('self') );
}

method term:sym<identifier>($/) {
    my $past := $<args>.ast;
    $past.name(~$<deflongname>);
    make $past;
}

method term:sym<name>($/) {
    my $var;
    if is_lexical(~$<name>) {
        $var := PAST::Var.new( :name(~$<name>), :scope('lexical') );
    }
    else {
        my @ns := pir::clone__PP($<name><identifier>);
        my $name := @ns.pop;
        @ns.shift if @ns && @ns[0] eq 'GLOBAL';
        $var := PAST::Var.new( :name(~$name), :namespace(@ns), :scope('package') );
    }
    my $past := $var;
    if $<args> {
        $past := $<args>[0].ast;
        $past.unshift($var);
    }
    make $past;
}

method term:sym<nqp::op>($/) {
    my $past := $<args> ?? $<args>[0].ast !! PAST::Op.new( :node($/) );
    my $op_name := ~$<op>;
    $past.name($op_name);
    $past.pasttype('nqpop');
    make $past;
}

method term:sym<onlystar>($/) {
    make PAST::Op.new(
        :pasttype('nqpop'), :name('multi_dispatch_over_lexical_candidates')
    );
}

method args($/) { make $<arglist>.ast; }

method arglist($/) {
    my $past := PAST::Op.new( :pasttype('call'), :node($/) );
    if $<EXPR> {
        my $expr := $<EXPR>.ast;
        if $expr.name eq '&infix:<,>' && !$expr.named {
            for $expr.list { $past.push($_); }
        }
        else { $past.push($expr); }
    }
    my $i := 0;
    my $n := +$past.list;
    while $i < $n {
        if $past[$i].name eq '&prefix:<|>' {
            $past[$i] := $past[$i][0];
            $past[$i].flat(1);
            if $past[$i].isa(PAST::Var)
                && pir::substr($past[$i].name, 0, 1) eq '%' {
                    $past[$i].named(1);
            }
        }
        $i++;
    }
    make $past;
}


method term:sym<value>($/) { make $<value>.ast; }

method term:sym<multi_declarator>($/) { make $<multi_declarator>.ast; }

method circumfix:sym<( )>($/) {
    make $<EXPR>
         ?? $<EXPR>[0].ast
         !! PAST::Op.new( :pasttype('list'), :node($/) );
}

method circumfix:sym<[ ]>($/) {
    my $past;
    if $<EXPR> {
        $past := $<EXPR>[0].ast;
        if $past.name ne '&infix:<,>' {
            $past := PAST::Op.new( $past, :pasttype('list') );
        }
    }
    else {
        $past := PAST::Op.new( :pasttype('list') );
    }
    $past.name('&circumfix:<[ ]>');
    make $past;
}

method circumfix:sym<ang>($/) { make $<quote_EXPR>.ast; }
method circumfix:sym<« »>($/) { make $<quote_EXPR>.ast; }

method circumfix:sym<{ }>($/) {
    my $past := +$<pblock><blockoid><statementlist><statement> > 0
                ?? $<pblock>.ast
                !! vivitype('%');
    $past<bareblock> := 1;
    make $past;
}

method circumfix:sym<sigil>($/) {
    my $name := ~$<sigil> eq '@' ?? 'list' !!
                ~$<sigil> eq '%' ?? 'hash' !!
                                    'item';
    make PAST::Op.new( :pasttype('callmethod'), :name($name), $<semilist>.ast );
}

method semilist($/) { make $<statement>.ast }

method postcircumfix:sym<[ ]>($/) {
    make PAST::Var.new( $<EXPR>.ast , :scope('keyed_int'),
                        :viviself(vivitype('$')),
                        :vivibase(vivitype('@')) );
}

method postcircumfix:sym<{ }>($/) {
    make PAST::Var.new( $<EXPR>.ast , :scope('keyed'),
                        :viviself(vivitype('$')),
                        :vivibase(vivitype('%')) );
}

method postcircumfix:sym<ang>($/) {
    make PAST::Var.new( $<quote_EXPR>.ast, :scope('keyed'),
                        :viviself(vivitype('$')),
                        :vivibase(vivitype('%')) );
}

method postcircumfix:sym<( )>($/) {
    make $<arglist>.ast;
}

method value($/) {
    make $<quote> ?? $<quote>.ast !! $<number>.ast;
}

method number($/) {
    my $value := $<dec_number> ?? $<dec_number>.ast !! $<integer>.ast;
    if ~$<sign> eq '-' { $value := -$value; }
    make PAST::Val.new( :value($value) );
}

# XXX Overridden from HLL::Actions because it relies on PIR concat.
method quote_delimited($/) {
    my @parts;
    my $lastlit := '';
    for $<quote_atom> {
        my $ast := $_.ast;
        if !PAST::Node.ACCEPTS($ast) {
            $lastlit := $lastlit ~ $ast;
        }
        elsif $ast.isa(PAST::Val) {
            $lastlit := $lastlit ~ $ast.value;
        }
        else {
            if $lastlit gt '' { @parts.push($lastlit); }
            @parts.push($ast);
            $lastlit := '';
        }
    }
    if $lastlit gt '' { @parts.push($lastlit); }
    my $past := @parts ?? @parts.shift !! '';
    while @parts {
        $past := PAST::Op.new( :pasttype('call'), :name('&infix:<~>'), $past, @parts.shift );
    }
    make $past;
}

method quote:sym<apos>($/) { make $<quote_EXPR>.ast; }
method quote:sym<dblq>($/) { make $<quote_EXPR>.ast; }
method quote:sym<qq>($/)   { make $<quote_EXPR>.ast; }
method quote:sym<q>($/)    { make $<quote_EXPR>.ast; }
method quote:sym<Q>($/)    { make $<quote_EXPR>.ast; }
method quote:sym<Q:PIR>($/) {
    make PAST::Op.new( :inline( $<quote_EXPR>.ast.value ),
                       :pasttype('inline'),
                       :node($/) );
}

method quote:sym</ />($/, $key?) {
    if $key eq 'open' {
        Q:PIR {
            null $P0
            set_hll_global ['Regex';'P6Regex';'Actions'], '$REGEXNAME', $P0
        };
        @BLOCK[0].symbol('$¢', :scope('lexical'));
        @BLOCK[0].symbol('$/', :scope('lexical'));
        return 0;
    }
    my $regex := buildsub($<p6regex>.ast, @BLOCK.shift);
    my $past := 
        PAST::Op.new(
            :pasttype<callmethod>, :name<new>,
            PAST::Var.new( :name('Regex'), :namespace(['Regex']), :scope<package> ),
            $regex
        );
    # In sink context, we don't need the Regex::Regex object.
    $past<sink> := $regex;
    make $past;
}

sub buildsub($rpast, $block = PAST::Block.new() ) {
    my %capnames := capnames($rpast, 0);
    %capnames{''} := 0;
    $rpast := PAST::Regex.new(
        PAST::Regex.new( :pasttype('scan') ),
        $rpast,
        PAST::Regex.new( :pasttype('pass'),
                         # XXX :backtrack(@MODIFIERS[0]<r> ?? 'r' !! 'g') ),
                         :backtrack('g') ),
        :pasttype('concat'),
        :capnames(%capnames)
    );
    unless $block.symbol('$¢') { $block.symbol('$¢', :scope<lexical>); }
    unless $block.symbol('$/') { $block.symbol('$/', :scope<lexical>); }
    $block.push($rpast);
    $block.blocktype('declaration');
    $block.unshift(PAST::Var.new( :name('self'), :scope('parameter') ));
    $block;
}

sub capnames($ast, $count) {
    my %capnames;
    my $pasttype := $ast.pasttype;
    if $pasttype eq 'alt' {
        my $max := $count;
        for $ast.list {
            my %x := capnames($_, $count);
            for %x {
                %capnames{$_} := +%capnames{$_} < 2 && %x{$_} == 1
                                 ?? 1
                                 !! 2;
            }
            if %x{''} > $max { $max := %x{''}; }
        }
        $count := $max;
    }
    elsif $pasttype eq 'concat' {
        for $ast.list {
            my %x := capnames($_, $count);
            for %x {
                %capnames{$_} := +%capnames{$_} + %x{$_};
            }
            $count := %x{''};
        }
    }
    elsif $pasttype eq 'subrule' && $ast.subtype eq 'capture' {
        my $name := $ast.name;
        if $name eq '' { $name := $count; $ast.name($name); }
        my @names := Q:PIR {
            $P0 = find_lex '$name'
            $S0 = $P0
            %r = split '=', $S0
        };
        for @names {
            if $_ eq '0' || $_ > 0 { $count := $_ + 1; }
            %capnames{$_} := 1;
        }
    }
    elsif $pasttype eq 'subcapture' {
        my $name := $ast.name;
        my @names := Q:PIR {
            $P0 = find_lex '$name'
            $S0 = $P0
            %r = split '=', $S0
        };
        for @names {
            if $_ eq '0' || $_ > 0 { $count := $_ + 1; }
            %capnames{$_} := 1;
        }
        my %x := capnames($ast[0], $count);
        for %x {
            %capnames{$_} := +%capnames{$_} + %x{$_};
        }
        $count := %x{''};
    }
    elsif $pasttype eq 'quant' {
        my %astcap := capnames($ast[0], $count);
        for %astcap {
            %capnames{$_} := 2;
        }
        $count := %astcap{''};
    }
    %capnames{''} := $count;
    %capnames;
}
method quote_escape:sym<$>($/) { make $<variable>.ast; }
method quote_escape:sym<{ }>($/) {
    make PAST::Op.new(
        :pasttype('callmethod'), :name('Stringy'), block_immediate($<block>.ast), :node($/)
    );
}
method quote_escape:sym<esc>($/) { make "\c[27]"; }

## Operators

method postfix:sym<.>($/) { make $<dotty>.ast; }

method prefix:sym<make>($/) {
    make PAST::Op.new(
             PAST::Var.new( :name('$/'), :scope('contextual') ),
             :pasttype('callmethod'),
             :name('!make'),
             :node($/)
    );
}

sub control($/, $type) {
    make PAST::Op.new(
        :node($/),
        :pirop('die__vii'),
        0,
        PAST::Val.new( :value($type), :returns<!except_types> )
    );
}

method term:sym<next>($/) { control($/, 'CONTROL_LOOP_NEXT') }
method term:sym<last>($/) { control($/, 'CONTROL_LOOP_LAST') }
method term:sym<redo>($/) { control($/, 'CONTROL_LOOP_REDO') }

method infix:sym<~~>($/) {
    make PAST::Op.new( :pasttype<callmethod>, :name<ACCEPTS>, :node($/) );
}


class NQP::RegexActions is Regex::P6Regex::Actions {

    method metachar:sym<:my>($/) {
        my $past := $<statement>.ast;
        make PAST::Regex.new( $past, :pasttype('pastnode'),
                              :subtype('declarative'), :node($/) );
    }

    method metachar:sym<{ }>($/) { 
        make PAST::Regex.new( $<codeblock>.ast, 
                              :pasttype<pastnode>, :node($/) );
    }

    method metachar:sym<nqpvar>($/) {
        make PAST::Regex.new( '!INTERPOLATE', $<var>.ast, 
                              :pasttype<subrule>, :subtype<method>, :node($/));
    }

    method assertion:sym<{ }>($/) { 
        make PAST::Regex.new( '!INTERPOLATE_REGEX', $<codeblock>.ast, 
                              :pasttype<subrule>, :subtype<method>, :node($/));
    }

    method assertion:sym<?{ }>($/) { 
        make PAST::Regex.new( $<codeblock>.ast, 
                              :subtype<zerowidth>, :negate( $<zw> eq '!' ),
                              :pasttype<pastnode>, :node($/) );
    }

    method assertion:sym<var>($/) {
        make PAST::Regex.new( '!INTERPOLATE_REGEX', $<var>.ast, 
                              :pasttype<subrule>, :subtype<method>, :node($/));
    }

    method codeblock($/) {
        my $block := $<block>.ast;
        $block.blocktype('immediate');
        my $past :=
            PAST::Stmts.new(
                PAST::Op.new(
                    PAST::Var.new( :name('$/') ),
                    PAST::Op.new(
                        PAST::Var.new( :name('$¢') ),
                        :name('MATCH'),
                        :pasttype('callmethod')
                    ),
                    :pasttype('bind')
                ),
                $block
            );
        make $past;
    }
}
