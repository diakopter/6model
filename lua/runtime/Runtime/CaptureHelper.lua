CaptureHelper = {};
CaptureHelper.FLATTEN_NONE = 0;
CaptureHelper.FLATTEN_POS = 1;
CaptureHelper.FLATTEN_NAMED = 2;

function CaptureHelper.FormWith (PosArgs, NamedArgs, FlattenSpec)
    --local REPR = CaptureHelper.CaptureTypeObject.STable.REPR;
    --local C = REPR.instance_of(REPR, nil, CaptureHelper.CaptureTypeObject);
    local C = { CaptureHelper.CaptureTypeObject.STable, nil, nil }
    if PosArgs ~= nil then
        C.Positionals = List.createFrom(PosArgs);
    end;
    C.Nameds = NamedArgs;
    C.FlattenSpec = FlattenSpec;
    return C;
end
CaptureHelper[1] = CaptureHelper.FormWith;

function CaptureHelper.GetPositional (Capture, Pos)
    return Capture.Positionals[Pos];
end
CaptureHelper[2] = CaptureHelper.GetPositional;

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
CaptureHelper[3] = CaptureHelper.NumPositionals;

function CaptureHelper.GetNamed (Capture, Name)
    return Capture.Nameds and Capture.Nameds[Name] or nil;
end
CaptureHelper[4] = CaptureHelper.GetNamed;

function CaptureHelper.GetPositionalAsString (Capture, Pos)
    return Ops.unbox_str(nil, CaptureHelper.GetPositional(Capture, Pos));
end
CaptureHelper[5] = CaptureHelper.GetPositionalAsString;

-- only slightly less horrible.
function CaptureHelper.Nil (TC)
    local REPR = TC.DefaultListType.STable.REPR;
    return REPR.instance_of(REPR, TC, TC.DefaultListType);
end
CaptureHelper[6] = CaptureHelper.Nil;
