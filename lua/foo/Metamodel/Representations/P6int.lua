
function makeP6int ()
    local P6int = {};
    local mt = { __index = P6int };
    
    -- inner class
    local makeInstance = function ()
        local Instance = {};
        local mt = { __index = Instance };
        function Instance.new(STable)
            local instance = {};
            instance.STable = STable;
            instance.Undefined = false;
            instance.Value = 0;
            return setmetatable(instance, mt);
        end
    end
    local Instance = makeInstance();
    
    function P6int.new()
        return setmetatable({}, mt);
    end
    function P6int:type_object_for(TC, MetaPackage)
        local STable = SharedTable.new();
        STable.HOW = MetaPackage;
        STable.REPR = self;
        local WHAT = Instance.new(STable);
        STable.WHAT = WHAT;
        WHAT.Undefined = true;
        return STable.WHAT;
    end
    function P6int:instance_of(TC, WHAT)
        return Instance.new(WHAT.STable);
    end
    function P6int:defined(TC, O)
        return not O.Undefined;
    end
    function P6int:hint_for(TC, ClassHandle, Name)
        return Hints.NO_HINT;
    end
    function P6int:set_int(TC, Object, Value)
        Object.Value = Value;
    end
    function P6int:get_int(TC, Object)
        return Object.Value;
    end
    return P6int;
end
P6int = makeP6int();
