# This compiles a .Net Syntax Tree down to C#.
class LST2LuaCompiler;

method compile(LST::Node $node) {
    #my $*CUR_ID := 0;
    return cs_for($node);
}

# Quick hack so we can get unique (for this compilation) IDs.
sub get_unique_id($prefix) {
    $*CUR_ID := $*CUR_ID + 1;
    #pir::say("--  " ~ $prefix ~ "  " ~ $*CUR_ID);
    if ($prefix ne 'block') {
        return 'l[' ~ $*CUR_ID ~ ']';
    }
    return 'blocks[' ~ $*CUR_ID ~ ']';
}

our multi sub cs_for(LST::CompilationUnit $node) {
    my @*USINGS;
    my $main := '';
    for @($node) {
        $main := $main ~ cs_for($_);
    }
    my $code := '';
    #for @*USINGS {
    #    $code := $code ~ $_;
    #}
    return $code ~ $main;
}

our multi sub cs_for(LST::Using $using) {
    @*USINGS.push("using " ~ $using.namespace ~ ";\n");
    return '';
}

our multi sub cs_for(LST::Class $class) {
    my $code := "LastLoadSetting, LastMain, LastLoad = (function ()\n";
    for @($class) {
        $code := $code ~ cs_for($_);
    }
    $code := $code ~ "return LoadSetting, Main, Load;\nend)();\n";
    #if $class.namespace {
    #    $code := $code ~ "}\n";
    #}
    return $code;
}

our multi sub cs_for(LST::Attribute $attr) {
    return '    local ' ~ $attr.name ~ ";\n";
}

# yanked from nqp setting
sub match ($text, $regex, :$global?) {
    my $match := $text ~~ $regex;
    if $global {
        my @matches;
        while $match {
            @matches.push($match);
            $match := $match.CURSOR.parse($text, :rule($regex), :c($match.to));
        }
        @matches;
    }
    else {
        $match;
    }
}

sub subst ($text, $regex, $repl, :$global?) {
    my @matches := $global ?? match($text, $regex, :global)
                           !! [ $text ~~ $regex ];
    my $is_code := pir::isa($repl, 'Sub');
    my $offset  := 0;
    my $result  := pir::new__Ps('StringBuilder');

    for @matches -> $match {
        if $match {
            pir::push($result, pir::substr($text, $offset, $match.from - $offset))
                if $match.from > $offset;
            pir::push($result, $is_code ?? $repl($match) !! $repl);
            $offset := $match.to;
        }
    }

    my $chars := pir::length($text);
    pir::push($result, pir::substr($text, $offset, $chars))
        if $chars > $offset;

    ~$result;
}

our multi sub cs_for(LST::Method $meth) {
    my $*LAST_TEMP := '';

    # Method header.
    my $code := '    ' ~ ($meth.name ~~ /\[/ ?? "" !! "local ") ~ $meth.name ~ ' = function (' ~
        pir::join(', ', $meth.params) ~
        ")\n           local l = \{\};\n";
    
    my $body := "";

    # Emit everything in the method.
    for @($meth) {
        $body := $body ~ cs_for($_);
    }
    
    $code := $code ~ $body;
    
    # Return statement if needed, and block ending.
    unless $meth.return_type eq 'void' {
        $code := $code ~ "        return $*LAST_TEMP;\n";
    }
    $code := $code ~ "    end;\n\n";
    return $code;
}

our multi sub cs_for(LST::Stmts $stmts) {
    my $code := '';
    for @($stmts) {
        $code := $code ~ cs_for($_);
    }
    return $code;
}

our multi sub cs_for(LST::TryFinally $tf) {
    unless +@($tf) == 2 { pir::die('LST::TryFinally nodes must have 2 children') }
    my $try_result := get_unique_id('try_result');
    my $code := "        try\{\n" ~
                "            function ()\n" ~
                cs_for((@($tf))[0]);
    $code := $code ~
                "        $try_result = $*LAST_TEMP;\n" ~
                "            end\n" ~
                "        }.finally()\{\n" ~
                "            function (catchClass, exceptions, exc)\n" ~
                cs_for((@($tf))[1]) ~
                "            end\n" ~
                "        }\n";
    $*LAST_TEMP := $try_result;
    return $code;
}

our multi sub cs_for(LST::TryCatch $tc) {
    unless +@($tc) == 2 { pir::die('LST::TryCatch nodes must have 2 children') }
    my $try_result := get_unique_id('try_result');
    my $code := "        try\{\n" ~
                "            function ()\n" ~
                cs_for((@($tc))[0]);
    $code := $code ~
                "        $try_result = $*LAST_TEMP;\n" ~
                "            end\n" ~
                "        }.except(\"" ~ $tc.exception_type ~ "\")\{\n" ~
                "            function (catchClass, exceptions, exc)\n" ~
                cs_for((@($tc))[1]) ~
                "        $try_result = $*LAST_TEMP;\n" ~
                "            end\n" ~
                "        }\n";
    $*LAST_TEMP := $try_result;
    return $code;
}

our multi sub cs_for(LST::MethodCall $mc) {
    # Code generate all the arguments.
    my @arg_names;
    my $code := '';
    for @($mc) {
        $code := $code ~ cs_for($_);
        @arg_names.push($*LAST_TEMP);
    }

    # What're we calling it on?
    my $invocant := $mc.on || @arg_names.shift;

    # Code-gen the call.
    $code := $code ~ '        ';
    unless $mc.void {
        my $ret_type := $mc.type;
        $*LAST_TEMP := get_unique_id('result');
        my $method_name := $invocant ~ '.' ~ $mc.name;
        $code := $code ~ "$*LAST_TEMP = ";
    }
    $code := $code ~ "$invocant" ~ ($mc.name ~~ /\[/ ?? "" !! (($mc.name ~~ /":"/ || $invocant eq "Ops" || $invocant eq "SignatureBinder" || $invocant eq "CaptureHelper" || $invocant eq "CodeObjectUtility" || $invocant eq "Init") ?? "." !! ":")) ~ $mc.name ~
        "(" ~ pir::join(', ', @arg_names) ~ ");\n";
    return $code;
}

our multi sub cs_for(LST::Call $mc) {
    # Code generate all the arguments.
    my @arg_names;
    my $code := '';
    for @($mc) {
        $code := $code ~ cs_for($_);
        @arg_names.push($*LAST_TEMP);
    }

    # Code-gen the call.
    $code := $code ~ '        ';
    unless $mc.void {
        $*LAST_TEMP := get_unique_id('result');
        $code := $code ~ "$*LAST_TEMP = ";
    }
    $code := $code ~ $mc.name ~
        "(" ~ pir::join(', ', @arg_names) ~ ");\n";

    return $code;
}

our multi sub cs_for(LST::New $new) {
    # Code generate all the arguments.
    my @arg_names;
    my $code := '';
    for @($new) {
        $code := $code ~ cs_for($_);
        @arg_names.push($*LAST_TEMP);
    }

    # Code-gen the constructor call.
    $*LAST_TEMP := get_unique_id('new');
    $code := $code ~ "        $*LAST_TEMP = " ~
        $new.type ~ ".new(" ~ pir::join(', ', @arg_names) ~ ");\n";

    return $code;
}

our multi sub cs_for(LST::If $if) {
    unless +@($if) >= 2 { pir::die('A LST::If node must have at least 2 children') }

    # Need a variable to put the final result in.
    my $if_result := get_unique_id('if_result') if $if.result;

    # Get the conditional and emit if.
    my $code := cs_for((@($if))[0]);
    $code := $code ~
             "        $if_result = nil;\n" if $if.result;
    $code := $code ~
             "        if ($*LAST_TEMP" ~ ($if.bool ?? "" !! " ~= 0") ~ ") then\n";

    # Compile branch(es).
    $*LAST_TEMP := 'nil';
    $code := $code ~ cs_for((@($if))[1]);
    $code := $code ~ "        $if_result = $*LAST_TEMP;\n" if $if.result;
    if +@($if) == 3 {
        $*LAST_TEMP := 'nil';
        $code := $code ~ "        else \n";
        $code := $code ~ cs_for((@($if))[2]);
        $code := $code ~ "        $if_result = $*LAST_TEMP;\n" if $if.result;
    }
    $code := $code ~ "        end\n";

    $*LAST_TEMP := $if_result if $if.result;
    return $code;
}

our multi sub cs_for(LST::While $while) {
    unless +@($while) == 3 { pir::die('A LST::While node must have 3 children') }

    # Need a variable to put the final result in.
    my $while_result := get_unique_id('while_result') if $while.result;

    # Get the conditional and emit while.
    my $cond_code := cs_for((@($while))[0]) ~ cs_for((@($while))[1]);
    # $*LAST_TEMP is set by the condition result cs_for regardless of 
    #   whether the condition code is emitted at the beginning of the loop
    
    my $code := $while.repeat ?? "" !! $cond_code;
    
    $code := $code ~
             "        $while_result = nil;\n" if $while.result;
    if ($while.repeat) {
        $code := $code ~
             "        $*LAST_TEMP = " ~ ($while.bool ?? "true" !! 1) ~ ";\n";
    }
    $code := $code ~
             "        while ($*LAST_TEMP" ~ ($while.bool ?? "" !! " ~= 0") ~ ") do\n";

    # Compile branch.
    $*LAST_TEMP := 'nil';
    $code := $code ~ cs_for((@($while))[2]);
    $code := $code ~ "        $while_result = $*LAST_TEMP;\n" if $while.result;
    $code := $code ~ $cond_code;
    $code := $code ~ "        end\n";

    $*LAST_TEMP := $while_result if $while.result;
    return $code;
}

our multi sub cs_for(LST::Return $ret) {
    return cs_for($ret.target) ~ "        return " ~ $*LAST_TEMP ~ ";\n";
}

our multi sub cs_for(LST::Label $lab) {
    return "";
    return "      " ~ $lab.name ~ ":\n";
}

our multi sub cs_for(LST::Goto $gt) {
    return "";
    return "        goto " ~ $gt.label ~ ";\n";
}

our multi sub cs_for(LST::Bind $bind) {
    unless +@($bind) == 2 { pir::die('LST::Bind nodes must have 2 children') }
    my $code := cs_for((@($bind))[0]);
    my $lhs := $*LAST_TEMP;
    $code := $code ~ cs_for((@($bind))[1]);
    my $rhs := $*LAST_TEMP;
    $code := $code ~ "        $lhs = $rhs;\n";
    $*LAST_TEMP := $lhs;
    return $code;
}

our multi sub cs_for(LST::Literal $lit) {
    $*LAST_TEMP := $lit.escape ??
        ('"' ~ pir::join__ssp('\\n', pir::split__pss("\n", pir::join__ssp('\\"', pir::split__pss('"', ~$lit.value)))) ~ '"') !!
        $lit.value;
    return '';
}

our multi sub cs_for(LST::Null $null) {
    $*LAST_TEMP := 'nil';
    return '';
}

our multi sub cs_for(LST::Local $loc) {
    my $code := '';
    if $loc.isdecl {
        unless +@($loc) == 1 {
            pir::die('A LST::Local with isdecl set must have exactly one child')
        }
        unless $loc.type {
            pir::die('LST::Local with isdecl requires type');
        }
        $code := cs_for((@($loc))[0]);
        $code := $code ~ '        ' ~ ($loc.name eq 'type_obj' || $loc.name eq 'TC' ?? 'local ' ~ $loc.name !! $loc.name) ~ " = $*LAST_TEMP;\n";
    } elsif +@($loc) != 0 {
        pir::die('A LST::Local without isdecl set must have no children')
    }
    $*LAST_TEMP := $loc.name;
    return $code;
}

our multi sub cs_for(LST::JumpTable $jt) {
    my $reg := $jt.register;
    my $skip_label := LST::Label.new(:name('skip_jumptable_for_' ~ $reg.name));
    my $code := cs_for(LST::Goto.new(:label($skip_label.name)));
    $code := $code ~ cs_for($jt.label);
    $code := $code ~ '        switch( ' ~ $reg.name ~ " ) \{\n";
    my $i := 0;
    for @($jt) {
        $code := $code ~ "          case $i : goto " ~ $_.name ~ ";\n";
        $i := $i + 1;
    }
    $code := $code ~ "        }\n" ~ cs_for($skip_label);
    return $code;
}

sub lhs_rhs_op(@ops, $op) {
    my $code := cs_for(@ops[0]);
    my $lhs := $*LAST_TEMP;
    $code := $code ~ cs_for(@ops[1]);
    my $rhs := $*LAST_TEMP;
    $*LAST_TEMP := get_unique_id('expr_result');
    # @ops[2] is the type
    return "$code        $*LAST_TEMP = $lhs $op $rhs;\n";
}

sub lhs_rhs_call(@ops, $op) {
    my $code := cs_for(@ops[0]);
    my $lhs := $*LAST_TEMP;
    $code := $code ~ cs_for(@ops[1]);
    my $rhs := $*LAST_TEMP;
    $*LAST_TEMP := get_unique_id('expr_result');
    # @ops[2] is the type
    return "$code        $*LAST_TEMP = $op($lhs, $rhs);\n";
}

our multi sub cs_for(LST::Add $ops) {
    lhs_rhs_op(@($ops), '+')
}

our multi sub cs_for(LST::Subtract $ops) {
    lhs_rhs_op(@($ops), '-')
}

our multi sub cs_for(LST::GT $ops) {
    lhs_rhs_op(@($ops), '>')
}

our multi sub cs_for(LST::LT $ops) {
    lhs_rhs_op(@($ops), '<')
}

our multi sub cs_for(LST::GE $ops) {
    lhs_rhs_op(@($ops), '>=')
}

our multi sub cs_for(LST::LE $ops) {
    lhs_rhs_op(@($ops), '<=')
}

our multi sub cs_for(LST::EQ $ops) {
    lhs_rhs_op(@($ops), '==')
}

our multi sub cs_for(LST::NE $ops) {
    lhs_rhs_op(@($ops), '~=')
}

our multi sub cs_for(LST::OR $ops) {
    lhs_rhs_op(@($ops), 'or')
}

our multi sub cs_for(LST::AND $ops) {
    lhs_rhs_op(@($ops), 'and')
}

our multi sub cs_for(LST::BOR $ops) {
    lhs_rhs_call(@($ops), 'bor')
}

our multi sub cs_for(LST::BAND $ops) {
    lhs_rhs_call(@($ops), 'band')
}

our multi sub cs_for(LST::BXOR $ops) {
    lhs_rhs_call(@($ops), 'bxor')
}

our multi sub cs_for(LST::NOT $ops) {
    my $code := cs_for((@($ops))[0]);
    my $lhs := $*LAST_TEMP;
    $*LAST_TEMP := get_unique_id('expr_result_negated');
    return "$code        $*LAST_TEMP = not $lhs;\n";
}

our multi sub cs_for(LST::XOR $ops) {
    my $code := cs_for((@($ops))[0]);
    my $lhs := $*LAST_TEMP;
    $code := $code ~ cs_for((@($ops))[1]);
    my $rhs := $*LAST_TEMP;
    $*LAST_TEMP := get_unique_id('expr_result');
    return "$code        $*LAST_TEMP = $lhs and not $rhs or $rhs and not $lhs;\n";
}

our multi sub cs_for(LST::Throw $throw) {
    $*LAST_TEMP := 'nil';
    return "        error(exc);\n";
}

our multi sub cs_for(String $s) {
    $*LAST_TEMP := $s;
    return '';
}

our multi sub cs_for(LST::ArrayLiteral $al) {
    # Code-gen all the things to go in the array.
    my @item_names;
    my $code := '';
    for @($al) {
        $code := $code ~ cs_for($_);
        @item_names.push($*LAST_TEMP);
    }

    # Code-gen the array.
    $*LAST_TEMP := '{' ~ pir::join(',', @item_names) ~ '}';
    return $code;
}

our multi sub cs_for(LST::DictionaryLiteral $dl) {
    # Code-gen all the pieces that will go into the dictionary. The
    # list is key,value,key,value.
    my @items;
    my $code := '';
    for @($dl) -> $k, $v {
        $code := $code ~ cs_for($k);
        my $key := $*LAST_TEMP;
        $code := $code ~ cs_for($v);
        my $value := $*LAST_TEMP;
        @items.push(' [' ~ $key ~ ']=' ~ $value);
    }

    # Code-gen the dictionary.
    $*LAST_TEMP := '{ ' ~
        pir::join(',', @items) ~ ' }';
    return $code;
}

our multi sub cs_for($any) {
    pir::die("LST to Lua compiler doesn't know how to compile a " ~ pir::typeof__SP($any));
}
