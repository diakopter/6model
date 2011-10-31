function Ops.get_caller_sub(TC, Level)
    local ToLevel = Ops.unbox_int(TC, Level);
    local Context = TC.CurrentContext;
    while (ToLevel >= 0) do
        Context = Context.Caller;
        if (Context == nil) then
            error("Tried to get look too many levels down for a caller");
        end
        ToLevel = ToLevel - 1;
    end
    return Context.StaticCodeObject;
end

function Ops.get_outer_sub(TC, Level)
    local ToLevel = Ops.unbox_int(TC, Level);
    local Context = TC.CurrentContext;
    while (ToLevel >= 0) do
        Context = Context.Outer;
        if (Context == nil) then
            error("Tried to get look too many levels down for an outer");
        end
        ToLevel = ToLevel - 1;
    end
    return Context.StaticCodeObject;
end
