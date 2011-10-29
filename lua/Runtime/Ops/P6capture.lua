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
    if (Index >= #Storage) then
        local newStorage = {};
    -- XXX unfinished
    end
end
