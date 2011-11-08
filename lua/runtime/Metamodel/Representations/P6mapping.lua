
function makeP6mapping ()
    local P6mapping = { ["class"] = "P6mappingREPR" };
    local mt = { __index = P6mapping };
    
    local makeInstance = function ()
        local Instance = { ["class"] = "P6mapping" };
        local mt = { __index = Instance };
        function Instance.new (STable)
            local this = {};
            this.STable = STable;
            return this;
            --return setmetatable(this, mt);
        end
        Instance[1] = Instance.new;
        return Instance;
    end
    local Instance = makeInstance();
    function P6mapping.new ()
        return setmetatable({}, mt);
    end
    P6mapping[1] = P6mapping.new;
    function P6mapping:type_object_for (TC, MetaPackage)
        local STable = SharedTable.new();
        STable.HOW = MetaPackage;
        STable.REPR = self;
        STable.WHAT = Instance.new(STable);
        return STable.WHAT;
    end
    P6mapping[2] = P6mapping.type_object_for;
    function P6mapping:instance_of (TC, WHAT)
        local Object = Instance.new(WHAT.STable);
        Object.Storage = {};
        return Object;
    end
    P6mapping[3] = P6mapping.instance_of;
    function P6mapping:defined (TC, Obj)
        return Obj.Storage ~= nil;
    end
    P6mapping[4] = P6mapping.defined;
    function P6mapping:hint_for (TC, ClassHandle, Name)
        return Hints.NO_Hint;
    end
    P6mapping[5] = P6mapping.hint_for;
    return P6mapping;
end
P6mapping = makeP6mapping();
