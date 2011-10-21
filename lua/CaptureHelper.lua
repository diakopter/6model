CaptureHelper = {};
CaptureHelper.FLATTEN_NONE = 0;
CaptureHelper.FLATTEN_POS = 1;
CaptureHelper.FLATTEN_NAMED = 2;

function CaptureHelper.FormWith (PosArgs, NamedArgs, FlattenSpec)
    local C = CaptureHelper.CaptureTypeObject.STable.REPR:instance_of(nil, CaptureHelper.CaptureTypeObject);
    if PosArgs ~= nil then C.Positionals = PosArgs end;
    if NamedArgs ~= nil then C.Nameds = NamedArgs end;
    if FlattenSpec ~= nil then C.FlattenSpec = FlattenSpec; end;
    return C;
end

function CaptureHelper.GetPositional (Capture, Pos)
    local Possies = Capture.Positionals;
    if (Possies ~= nil and Pos < Possies.Length) then
        return Possies[Pos];
    else
        return nil;
    end
end

function CaptureHelper.NumPositionals (Capture)
    local Possies = Capture.Positionals;
    if (Possies ~= nil) then
        return Possies.Length;
    else
        return 0;
    end
end

function CaptureHelper.GetNamed (Capture, Name)
    local Nameds = Capture.Nameds;
    if (Nameds ~= nil and Nameds[Name] ~= nil) then
        return Nameds[Name];
    else
        return nil;
    end
end

function CaptureHelper.GetPositionalAsString (Capture, Pos)
    return Ops.unbox_str(nil, CaptureHelper.GetPositional(Capture, Pos));
end

function CaptureHelper.Nil ()
    return nil;
end
