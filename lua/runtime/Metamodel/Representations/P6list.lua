
function makeP6list ()
    local P6list = {};
    local mt = { __index = P6list };
    
    local makeInstance = function ()
        local Instance = {};
        local mt = { __index = Instance };
        function Instance.new(STable)
            local instance = {};
            instance.STable = STable;
            instance.class = "P6list";
            return setmetatable(instance, mt);
        end
        return Instance;
    end
    local Instance = makeInstance();
    
    function P6list.new()
        local this = {};
        this.class = "P6listREPR";
        return setmetatable(this, mt);
    end
    function P6list:type_object_for(TC, MetaPackage)
        local STable = SharedTable.new();
        STable.HOW = MetaPackage;
        STable.REPR = self;
        STable.WHAT = Instance.new(STable);
        return STable.WHAT;
    end
    function P6list:instance_of(TC, WHAT)
        local Object = Instance.new(WHAT.STable);
        Object.Storage = List.new();
        return Object;
    end
    function P6list:defined(TC, Obj)
        if (Obj.Storage ~= nil) then
            return true;
        else
            return false;
        end
    end
    return P6list;
end
P6list = makeP6list();
