function makeSignatureBinder()
    local SignatureBinder = {};
    
    local EmptyPos = List.new(0);
    local EmptyNamed = {};
    
    function SignatureBinder.Bind(TC, C, Capture)
        local NativeCapture = Capture;
        if (NativeCapture == nil) then
            error("Can only deal with native captures at the moment");
        end
        local Positionals = NativeCapture.Positionals and NativeCapture.Positionals or EmptyPos;
        local Nameds = NativeCapture.Nameds and NativeCapture.Nameds or EmptyNamed;
        local SeenNames = nil;
        
        if (NativeCapture.FlattenSpec ~= nil) then
            Positionals, Nameds = SignatureBinder.Flatten(NativeCapture.FlattenSpec, Positionals, Nameds)
        end
        
        local Sig = C.StaticCodeObject.Sig;
        if (Sig == nil) then
            return;
        end
        
        local CurPositional = 1;
        
        local Params = Sig.Parameters;
        local NumParams = Params.Count;
        for i = 1, NumParams do
            local Param = Params[i];
            
            if (Param.Flags == Parameter.POS_FLAG) then
                if (CurPositional <= Positionals.Count) then
                    C.LexPad.Storage[Param.VariableLexpadPosition] = Positionals[CurPositional];
                else
                    error("Not enough positional parameters; got " ..
                        CurPositional .. " but needed " ..
                        SignatureBinder.NumRequiredPositionals(C.StaticCodeObject.Sig));
                end
                
                CurPositional = CurPositional + 1;
            elseif (Param.Flags == Parameter.OPTIONAL_FLAG) then
                if (CurPositional <= Positionals.Count) then
                    C.LexPad.Storage[Param.VariableLexpadPosition] = Positionals[CurPositional];
                else
                    C.LexPad.Storage[Param.VariableLexpadPosition] = Param.DefaultValue.STable:Invoke(TC, Param.DefaultValue, Capture);
                end
            elseif (band(Param.Flags, Parameter.NAMED_SLURPY_FLAG) ~= 0) then
                local SlurpyHolder = TC.DefaultHashType.STable.REPR:instance_of(TC, TC.DefaultHashType);
                C.LexPad.Storage[Param.VariableLexpadPosition] = SlurpyHolder;
                for Name, unused in pairs(Nameds) do
                    if (SeenNames == nil or SeenNames[Name] == nil) then
                        Ops.llmapping_bind_at_key(TC, SlurpyHolder,
                            Ops.box_str(TC, Name, TC.DefaultStrBoxType),
                            Nameds[Name]);
                    end
                end
            elseif (band(Param.Flags, Parameter.POS_SLURPY_FLAG) ~= 0) then
                local SlurpyHolder = TC.DefaultArrayType.STable.REPR:instance_of(TC, TC.DefaultArrayType);
                C.LexPad.Storage[Param.VariableLexpadPosition] = SlurpyHolder;
                -- pretty sure this might be off-by-one. ;)
                for j = CurPositional, Positionals.Length - 1 do
                    Ops.lllist_push(TC, SlurpyHolder, Positionals[j]);
                end
                CurPositional = j;
            elseif (Param.Name ~= nil) then
                local Value;
                if (Nameds[Param.Name] ~= nil) then
                    C.LexPad.Storage[Param.VariableLexpadPosition] = Nameds[Param.Name];
                    if (SeenNames == nil) then
                        SeenNames = {};
                    end
                    SeenNames[Param.Name] = true;
                else
                    if (band(Param.Flags, Parameter.OPTIONAL_FLAG) == 0) then
                        error("Required named parameter " .. Param.Name .. " missing");
                    else
                        C.LexPad.Storage[Param.VariableLexpadPosition] = Param.DefaultValue.STable:Invoke(TC, Param.DefaultValue, Capture);
                    end
                end
            else
                -- error("wtf");
            end
        end
        
        local PossiesInCapture = Positionals.Count;
        if (CurPositional > PossiesInCapture + 1) then
            error("Too many positional arguments passed; expected " ..
                NumRequiredPositionals(C.StaticCodeObject.Sig) ..
                " but got " + PossiesInCapture);
        end
    end
    
    function SignatureBinder.NumRequiredPositionals(Sig)
        local Num = 0;
        local breaking = false;
        for unused, Param in ipairs(Sig.Parameters) do
            if (not breaking) then
            if (Param.Flags ~= 0 or Param.Name ~= nil) then
                breaking = true;
            else
                Num = Num + 1;
            end
            end -- breaking
        end
        return Num;
    end
    
    function SignatureBinder.Flatten(FlattenSpec, Positionals, Nameds)
        local NewPositionals = List.new();
        local NewNameds = {};
        
        for i = 1, Positionals.Count do
            if (FlattenSpec[i] == CaptureHelper.FLATTEN_NONE) then
                NewPositionals.Add(Positionals[i]);
            elseif (FlattenSpec[i] == CaptureHelper.FLATTEN_POS) then
                local Flattenee = Positionals[i];
                for unused, Pos in ipairs(Flattenee.Storage) do
                    NewPositionals.Add(Pos);
                end
            elseif (FlattenSpec[i] == CaptureHelper.FLATTEN_NAMED) then
                local Flattenee = Positionals[i];
                for k, v in pairs(Flattenee.Storage) do
                    NewNameds[k] = v;
                end
            end
        end
        return NewPositionals, NewNameds;
    end
    
    return SignatureBinder;
end
SignatureBinder = makeSignatureBinder();