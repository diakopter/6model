
function makeP6num ()
    local P6num = { ["class"] = "P6numREPR" };
    local mt = { __index = P6num };
    
    local makeInstance = function ()
        local Instance = { ["class"] = "P6num" };
        local mt = { __index = Instance };
        function Instance.new (STable)
            local this = {};
            this.STable = STable;
            this.Undefined = false;
            this.Value = 0.0;
            return setmetatable(this, mt);
        end
        Instance[1] = Instance.new;
        return Instance;
    end
    local Instance = makeInstance();
    function P6num.new ()
        return setmetatable({}, mt);
    end
    P6num[1] = P6num.new;
    function P6num:type_object_for (TC, MetaPackage)
        local STable = SharedTable.new();
        STable.HOW = MetaPackage;
        STable.REPR = self;
        local WHAT = Instance.new(STable);
        STable.WHAT = WHAT;
        WHAT.Undefined = true;
        return STable.WHAT;
    end
    P6num[2] = P6num.type_object_for;
    function P6num:instance_of (TC, WHAT)
        return Instance.new(WHAT.STable);
    end
    P6num[3] = P6num.instance_of;
    function P6num:defined (TC, O)
        return not O.Undefined;
    end
    P6num[4] = P6num.defined;
    function P6num:hint_for (TC, ClassHandle, Name)
        return Hints.NO_Hint;
    end
    P6num[5] = P6num.hint_for;
    function P6num:set_num (TC, Object, Value)
        Object.Value = Value;
    end
    P6num[12] = P6num.set_num;
    function P6num:get_num (TC, Object)
        return Object.Value;
    end
    P6num[13] = P6num.set_num;
    return P6num;
end
P6num = makeP6num();
