
function makeP6int ()
    local P6int = { ["class"] = "P6intREPR" };
    local mt = { __index = P6int };
    
    -- inner class
    local makeInstance = function ()
        local Instance = { ["class"] = "P6int" };
        local mt = { __index = Instance };
        function Instance.new (STable)
            return { STable, 0, false };
        end
        Instance[1] = Instance.new;
        return Instance;
    end
    local Instance = makeInstance();
    local type_object_for = function (self, TC, MetaPackage)
        local STable = SharedTable.new();
        STable.HOW = MetaPackage;
        STable.REPR = self;
        local WHAT = { STable, nil };
        STable.WHAT = WHAT;
        WHAT.Undefined = true;
        return STable.WHAT;
    end
    P6int[2] = type_object_for;
    local instance_of = function (self, TC, WHAT)
        return { WHAT.STable, nil };
    end
    P6int[3] = instance_of;
    local defined = function (self, TC, O)
        return O.Value ~= nil;
    end
    P6int[4] = defined;
    local hint_for = function (self, TC, ClassHandle, Name)
        return Hints.NO_HINT;
    end
    P6int[5] = hint_for;
    local set_int = function (self, TC, Object, Value)
        Object.Value = Value;
    end
    P6int[10] = set_int;
    local get_int = function (self, TC, Object)
        return Object.Value;
    end
    P6int[11] = get_int;
    function P6int.new ()
        return { nil, type_object_for, instance_of, defined, hint_for, nil, nil, nil, nil, set_int, get_int };
    end
    P6int[1] = P6int.new;
    return P6int;
end
P6int = makeP6int();
