function Ops.get_lex(TC, Name)
    local CurContext = TC.CurrentContext;
    while (CurContext ~= nil) do
        local Index;
        if (CurContext.LexPad.SlotMapping[Name] ~= nil) then
            return CurContext.LexPad.Storage[CurContext.LexPad.SlotMapping[Name]];
        end
        CurContext = CurContext.Outer;
    end
    error("No variable " .. Name .. " found in the lexical scope");
end
Ops[90] = Ops.get_lex;

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
Ops[91] = Ops.get_lex_skip_current;

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
Ops[92] = Ops.bind_lex;

function Ops.get_dynamic(TC, Name)
    local CurContext = TC.CurrentContext;
    while (CurContext ~= nil) do
        local Index;
        if (CurContext.LexPad.SlotMapping[Name] ~= nil) then
            return CurContext.LexPad.Storage[CurContext.LexPad.SlotMapping[Name]];
        end
        CurContext = CurContext.Caller;
    end
    error("No variable " .. Name .. " found in the dynamic scope");
end
Ops[93] = Ops.get_dynamic;

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
Ops[94] = Ops.bind_dynamic;
