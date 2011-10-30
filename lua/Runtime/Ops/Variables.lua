function Ops.get_lex(TC, Name)
    local CurContext = TC.CurrentContext;
    while (CurContext ~= nil) do
        local Index;
        if (CurContext.LexPad.SlotMapping[Name] ~= nil) then
            return CurContext.LexPad.Storage(CurContext.LexPad.SlotMapping[Name]);
        end
        CurContext = CurContext.Outer;
    end
    error("No variable " .. Name .. " found in the lexical scope");
end

function Ops.get_lex_skip_current(TC, Name)
    local CurContext = TC.CurrentContext.Outer;
    while (CurContext ~= nil) do
        local Index;
        if (CurContext.LexPad.SlotMapping[Name] ~= nil) then
            return CurContext.LexPad.Storage[CurContext.LexPad.SlotMapping[Name]];
        end
        CurContext = CurContext.Outer;
    end
    error("No variable " .. Name .. " found in the lexical scope");
end

function Ops.bind_lex(TC, Name, Value)
    local CurContext = TC.CurrentContext;
    while (CurContext ~= nil) do
        local Index;
        if (CurContext.LexPad.SlotMapping[Name] ~= nil) then
            CurContext.LexPad.Storage[CurContext.LexPad.SlotMapping[Name]] = Value;
            return Value;
        end
        CurContext = CurContext.Outer;
    end
    error("No variable " .. Name .. " found in the lexical scope");
end

function Ops.get_dynamic(TC, Name)
    local CurContext = TC.CurrentContext;
    while (CurContext ~= nil) do
        local Index;
        if (CurContext.LexPad.SlotMapping[Name] ~= nil) then
            return CurContext.LexPad.Storage(CurContext.LexPad.SlotMapping[Name]);
        end
        CurContext = CurContext.Caller;
    end
    error("No variable " .. Name .. " found in the dynamic scope");
end

function Ops.bind_dynamic(TC, Name, Value)
    local CurContext = TC.CurrentContext;
    while (CurContext ~= nil) do
        local Index;
        if (CurContext.LexPad.SlotMapping[Name] ~= nil) then
            CurContext.LexPad.Storage[CurContext.LexPad.SlotMapping[Name]] = Value;
            return Value;
        end
        CurContext = CurContext.Caller;
    end
    error("No variable " .. Name .. " found in the dynamic scope");
end
