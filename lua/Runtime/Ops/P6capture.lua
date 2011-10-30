function Ops.llcap_get_at_pos(TC, Capture, Index)
    local Cap = Capture;
    if (Cap.Positionals == nil) then
        Cap.Positionals = {};
        return Ops.get_lex(TC, "Mu");
    end
    local result = Cap.Positionals[Ops.unbox_int(TC, Index)];
    if (result ~= nil) then return result end
    return Ops.get_lex(TC, "Mu");
end

function Ops.llcap_bind_at_pos(TC, Capture, IndexObj, Value)
    local Cap = Capture;
    local Storage = Cap.Positionals;
    local Index = Ops.unbox_int(TC, IndexObj);
    if (Storage == nil) then
        Cap.Positionals = {};
        Storage = Cap.Positionals;
    end
    Storage[Index] = Value;
    return Value;
end

function Ops.llcap_get_at_key(TC, Capture, Key)
    local Storage = Capture.Nameds;
    if (Storage == nil) then
        Capture.Nameds = {};
        Storage = Capture.Nameds;
    end
    local StrKey = Ops.unbox_str(TC, Key);
    if (Storage[StrKey] ~= nil) then
        return Storage[StrKey];
    else
        return Ops.get_lex(TC, "Mu");
    end
end

function Ops.llcap_bind_at_key(TC, Capture, Key, Value)
    local Storage = Capture.Nameds;
    if (Storage == nil) then
        Capture.Nameds = {};
        Storage = Capture.Nameds;
    end
    local StrKey = Ops.unbox_str(TC, Key);
    Storage[StrKey] = Value;
    return Value;
end

