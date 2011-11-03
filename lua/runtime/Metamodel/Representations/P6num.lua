
function makeP6num ()
    local P6num = {};
    local mt = { __index = P6num };
    
    -- inner class
    local makeInstance = function ()
        local Instance = {};
        local mt = { __index = Instance };
        function Instance.new(STable)
            local instance = {};
            instance.STable = STable;
            instance.Undefined = false;
            instance.Value = 0.0;
            instance.class = "P6num";
            return setmetatable(instance, mt);
        end
        return Instance;
    end
    local Instance = makeInstance();
    
    function P6num.new()
        local this = {};
        this.class = "P6numREPR";
        return setmetatable(this, mt);
    end
    function P6num:type_object_for(TC, MetaPackage)
        local STable = SharedTable.new();
        STable.HOW = MetaPackage;
        STable.REPR = self;
        local WHAT = Instance.new(STable);
        STable.WHAT = WHAT;
        WHAT.Undefined = true;
        return STable.WHAT;
    end
    function P6num:instance_of(TC, WHAT)
        return Instance.new(WHAT.STable);
    end
    function P6num:defined(TC, O)
        return not O.Undefined;
    end
    function P6num:hint_for(TC, ClassHandle, Name)
        return Hints.NO_Hint;
    end
    function P6num:set_num(TC, Object, Value)
        Object.Value = Value;
    end
    function P6num:get_num(TC, Object)
        return Object.Value;
    end
    return P6num;
end
P6num = makeP6num();
