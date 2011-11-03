
function makeP6mapping ()
    local P6mapping = {};
    local mt = { __index = P6mapping };
    
    local makeInstance = function ()
        local Instance = {};
        local mt = { __index = Instance };
        function Instance.new(STable)
            local instance = {};
            instance.STable = STable;
            instance.class = "P6mapping";
            return setmetatable(instance, mt);
        end
        return Instance;
    end
    local Instance = makeInstance();
    
    function P6mapping.new()
        local this = {};
        this.class = "P6mappingREPR";
        return setmetatable(this, mt);
    end
    function P6mapping:type_object_for(TC, MetaPackage)
        local STable = SharedTable.new();
        STable.HOW = MetaPackage;
        STable.REPR = self;
        STable.WHAT = Instance.new(STable);
        return STable.WHAT;
    end
    function P6mapping:instance_of(TC, WHAT)
        local Object = Instance.new(WHAT.STable);
        Object.Storage = {};
        return Object;
    end
    function P6mapping:defined(TC, Obj)
        if (Obj.Storage ~= nil) then
            return true;
        else
            return false;
        end
    end
    function P6mapping:hint_for(TC, ClassHandle, Name)
        return Hints.NO_Hint;
    end
    return P6mapping;
end
P6mapping = makeP6mapping();
