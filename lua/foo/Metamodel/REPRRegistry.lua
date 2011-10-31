
dofile('Metamodel/Representations/P6capture.lua');
dofile('Metamodel/Representations/P6hash.lua');
dofile('Metamodel/Representations/P6int.lua');
dofile('Metamodel/Representations/P6list.lua');
dofile('Metamodel/Representations/P6mapping.lua');
dofile('Metamodel/Representations/P6num.lua');
dofile('Metamodel/Representations/P6opaque.lua');
dofile('Metamodel/Representations/P6str.lua');
dofile('Metamodel/Representations/RakudoCodeRef.lua');
dofile('Metamodel/KnowHOW/KnowHOWREPR.lua');

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
        local ID = Registry.Count + 1;
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
