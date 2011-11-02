
function makeP6str ()
    local P6str = {};
    local mt = { __index = P6str };
    
    -- inner class
    local makeInstance = function ()
        local Instance = {};
        local mt = { __index = Instance };
        function Instance.new(STable)
            local instance = {};
            instance.STable = STable;
            instance.class = "P6str";
            return setmetatable(instance, mt);
        end
        return Instance;
    end
    local Instance = makeInstance();
    
    function P6str.new()
        return setmetatable({}, mt);
    end
    function P6str:type_object_for(TC, MetaPackage)
        local STable = SharedTable.new();
        STable.HOW = MetaPackage;
        STable.REPR = self;
        local WHAT = Instance.new(STable);
        STable.WHAT = WHAT;
        WHAT.Undefined = true;
        return STable.WHAT;
    end
    function P6str:instance_of(TC, WHAT)
        local instance = Instance.new(WHAT.STable);
        instance.Value = "";
        return instance;
    end
    function P6str:defined(TC, O)
        return O.Value ~= nil;
    end
    function P6str:hint_for(TC, ClassHandle, Name)
        return Hstrs.NO_Hstr;
    end
    function P6str:set_str(TC, Object, Value)
        Object.Value = Value;
    end
    function P6str:get_str(TC, Object)
        return Object.Value;
    end
    return P6str;
end
P6str = makeP6str();
