
function makeREPRRegistry ()
    local REPRRegistry = {};
    local mt = { __index = REPRRegistry };
    local Registry = List.create();
    local NamedToIDMapper = {};
    function REPRRegistry.new ()
        return setmetatable({}, mt);
    end
    REPRRegistry[1] = REPRRegistry.new;
    function REPRRegistry.register_REPR (Name, REPR)
        List.Add(Registry, REPR);
        REPR.Name = Name;
        local ID = Registry.Count;
        NamedToIDMapper[Name] = ID;
        return ID;
    end
    REPRRegistry[2] = REPRRegistry.register_REPR;
    function REPRRegistry.get_REPR_by_id (ID)
        return Registry[ID];
    end
    REPRRegistry[3] = REPRRegistry.get_REPR_by_id;
    function REPRRegistry.get_REPR_by_name (Name)
        return Registry[NamedToIDMapper[Name]];
    end
    REPRRegistry[4] = REPRRegistry.get_REPR_by_name;
    return REPRRegistry;
end
REPRRegistry = makeREPRRegistry();
Hints = {};
Hints.NO_HINT = -1;
