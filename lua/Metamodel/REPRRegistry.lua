
dofile('P6capture.lua');
dofile('P6hash.lua');
dofile('P6int.lua');
dofile('P6list.lua');
dofile('P6mapping.lua');
dofile('P6num.lua');
dofile('P6opaque.lua');
dofile('P6str.lua');
dofile('RakudoCodeRef.lua');
dofile('KnowHowREPR.lua');

function makeREPRRegistry ()
    local REPRRegistry = {};
    local mt = { __index = REPRRegistry };
    local Registry = List.new();
    local NamedToIDMapper = Dictionary.new();
    function REPRRegistry.new()
        return setmetatable({}, mt);
    end
    function REPRRegistry.register_REPR(Name, REPR)
        Registry.Add(REPR);
        local ID = Registry.Count; -- took out the - 1
        NamedToIDMapper.Add(Name, ID);
        return ID;
    end
    function get_REPR_by_id(ID)
        return Registry[ID];
    end
    function get_REPR_by_name(Name)
        return Registry[NamedToIDMapper[Name]];
    end
    return REPRRegistry;
end
REPRRegistry = makeREPRRegistry();
Hints = {};
Hints.NO_HINT = -1;
