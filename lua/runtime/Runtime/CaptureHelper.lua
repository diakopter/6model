CaptureHelper = {};
CaptureHelper.FLATTEN_NONE = 0;
CaptureHelper.FLATTEN_POS = 1;
CaptureHelper.FLATTEN_NAMED = 2;

function CaptureHelper.FormWith (PosArgs, NamedArgs, FlattenSpec)
    local REPR = CaptureHelper.CaptureTypeObject.STable.REPR;
    local C = REPR.instance_of(REPR, nil, CaptureHelper.CaptureTypeObject);
    if PosArgs ~= nil then
        C.Positionals = List.new();
        for k,v in ipairs(PosArgs) do
            List.Add(C.Positionals, v);
        end
    end;
    if NamedArgs ~= nil then C.Nameds = NamedArgs end;
    if FlattenSpec ~= nil then C.FlattenSpec = FlattenSpec; end;
    return C;
end

function CaptureHelper.GetPositional (Capture, Pos)
    return Capture.Positionals[Pos];
end

function CaptureHelper.NumPositionals (Capture)
    local Possies = Capture.Positionals;
    if (Possies ~= nil) then
        -- can use # here since it's always initialized using a literal
        --   even in generated code, I think.
        return #Possies;
    else
        return 0;
    end
end

function CaptureHelper.GetNamed (Capture, Name)
    return Capture.Nameds and Capture.Nameds[Name] or nil;
end

function CaptureHelper.GetPositionalAsString (Capture, Pos)
    return Ops.unbox_str(nil, CaptureHelper.GetPositional(Capture, Pos));
end

-- only slightly less horrible.
function CaptureHelper.Nil (TC)
    local REPR = TC.DefaultListType.STable.REPR;
    return REPR.instance_of(REPR, TC, TC.DefaultListType);
end
