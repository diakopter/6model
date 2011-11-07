
function makeP6list ()
    local P6list = { ["class"] = "P6listREPR" };
    local mt = { __index = P6list };
    
    local makeInstance = function ()
        local Instance = { ["class"] = "P6list" };
        local mt = { __index = Instance };
        function Instance.new (STable)
            local this = {};
            this.STable = STable;
            return setmetatable(this, mt);
        end
        Instance[1] = Instance.new;
        return Instance;
    end
    local Instance = makeInstance();
    function P6list.new ()
        return setmetatable({}, mt);
    end
    P6list[1] = P6list.new;
    function P6list:type_object_for (TC, MetaPackage)
        local STable = SharedTable.new();
        STable.HOW = MetaPackage;
        STable.REPR = self;
        STable.WHAT = Instance.new(STable);
        return STable.WHAT;
    end
    P6list[2] = P6list.type_object_for;
    function P6list:instance_of (TC, WHAT)
        local Object = Instance.new(WHAT.STable);
        Object.Storage = List.create();
        return Object;
    end
    P6list[3] = P6list.instance_of;
    function P6list:defined (TC, Obj)
        return Obj.Storage ~= nil;
    end
    P6list[4] = P6list.defined;
    return P6list;
end
P6list = makeP6list();
