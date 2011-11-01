# This compiles a .Net Syntax Tree down to C#.
class LST2LuaCompiler;

method compile(LST::Node $node) {
    my $*CUR_ID := 0;
    return cs_for($node);
}

# Quick hack so we can get unique (for this compilation) IDs.
sub get_unique_id($prefix) {
    $*CUR_ID := $*CUR_ID + 1;
    return $prefix ~ '_' ~ $*CUR_ID;
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
    my $code := '';
    #if $class.namespace {
    #    $code := $code ~ 'namespace ' ~ $class.namespace ~ " \{\n";
    #}
    $code := $code ~ $class.name ~ "= (function ()\n";
    for @($class) {
        $code := $code ~ cs_for($_);
    }
    $code := $code ~ "return Main or LoadSetting;\nend)();\n";
    #if $class.namespace {
    #    $code := $code ~ "}\n";
    #}
    return $code;
}

our multi sub cs_for(LST::Attribute $attr) {
    return '    local ' ~ $attr.name ~ ";\n";
}

our multi sub cs_for(LST::Method $meth) {
    my $*LAST_TEMP := '';

    # Method header.
    my $code := '    function ' ~
        #$meth.return_type ~ ' ' ~ 
        $meth.name ~ '(' ~
        pir::join(', ', $meth.params) ~
        ") \n          local locals = {};\n";

    # Emit everything in the method.
    for @($meth) {
        $code := $code ~ cs_for($_);
    }

    # Return statement if needed, and block ending.
    unless $meth.return_type eq 'void' {
        $code := $code ~ "        return $*LAST_TEMP;\n";
    }
    return $code ~ "    end\n\n";
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
    my $code := "        local $try_result;\n" ~
                "        try\{\n" ~
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
    my $code := "        local $try_result;\n" ~
                "        try \{\n" ~
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
        $code := $code ~ "local $*LAST_TEMP = ";
    }
    $code := $code ~ "$invocant" ~ (($mc.name ~~ /":"/ || $invocant eq "Ops" || $invocant eq "SignatureBinder" || $invocant eq "CaptureHelper" || $invocant eq "CodeObjectUtility" || $invocant eq "Init" || $invocant eq "SignatureBinder" || $invocant eq "SignatureBinder" || $invocant eq "SignatureBinder" || $invocant eq "SignatureBinder" || $invocant eq "SignatureBinder" || $invocant eq "SignatureBinder" || $invocant eq "SignatureBinder") ?? "." !! ":") ~ $mc.name ~
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
        $code := $code ~ "local $*LAST_TEMP = ";
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
    $code := $code ~ "        local $*LAST_TEMP = " ~
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
             "        local $if_result = nil;\n" if $if.result;
    $code := $code ~
             "        if ($*LAST_TEMP" ~ ($if.bool ?? "" !! " != 0") ~ ") then\n";

    # Compile branch(es).
    $*LAST_TEMP := 'nil';
    $code := $code ~ cs_for((@($if))[1]);
    $code := $code ~ "        $if_result = $*LAST_TEMP;\n" if $if.result;
    $code := $code ~ "        end\n";
    if +@($if) == 3 {
        $*LAST_TEMP := 'nil';
        $code := $code ~ "        else \n";
        $code := $code ~ cs_for((@($if))[2]);
        $code := $code ~ "        $if_result = $*LAST_TEMP;\n" if $if.result;
        $code := $code ~ "        end\n";
    }

    $*LAST_TEMP := $if_result if $if.result;
    return $code;
}

our multi sub cs_for(LST::Return $ret) {
    return cs_for($ret.target) ~ "        return " ~ $*LAST_TEMP ~ ";\n";
}

our multi sub cs_for(LST::Label $lab) {
    return "      " ~ $lab.name ~ ":\n";
}

our multi sub cs_for(LST::Goto $gt) {
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
        ('"' ~ pir::join__ssp('""', pir::split__pss('"', ~$lit.value)) ~ '"') !!
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
        $code := $code ~ '        locals[' ~ $loc.name ~ "] = $*LAST_TEMP;\n";
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
    return "$code        " ~ @ops[2] ~ " $*LAST_TEMP = $lhs $op $rhs;\n";
}

sub lhs_rhs_call(@ops, $op) {
    my $code := cs_for(@ops[0]);
    my $lhs := $*LAST_TEMP;
    $code := $code ~ cs_for(@ops[1]);
    my $rhs := $*LAST_TEMP;
    $*LAST_TEMP := get_unique_id('expr_result');
    # @ops[2] is the type
    return "$code        " ~ @ops[2] ~ " $*LAST_TEMP = $op($lhs, $rhs);\n";
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
    return "$code        local $*LAST_TEMP = not $lhs;\n";
}

our multi sub cs_for(LST::XOR $ops) {
    my $code := cs_for((@($ops))[0]);
    my $lhs := $*LAST_TEMP;
    $code := $code ~ cs_for((@($ops))[1]);
    my $rhs := $*LAST_TEMP;
    $*LAST_TEMP := get_unique_id('expr_result');
    return "$code        local $*LAST_TEMP = $lhs and not $rhs or $rhs and not $lhs;\n";
}

our multi sub cs_for(LST::Throw $throw) {
    $*LAST_TEMP := 'nil';
    return '        error(exc);';
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
        @items.push(' ["' ~ $key ~ '"]=' ~ $value);
    }

    # Code-gen the dictionary.
    $*LAST_TEMP := '{ ' ~
        pir::join(',', @items) ~ ' }';
    return $code;
}

our multi sub cs_for($any) {
    pir::die("LST to Lua compiler doesn't know how to compile a " ~ pir::typeof__SP($any));
}
