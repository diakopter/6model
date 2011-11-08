
function makeP6int ()
    local P6int = { ["class"] = "P6intREPR" };
    local mt = { __index = P6int };
    
    -- inner class
    local makeInstance = function ()
        local Instance = { ["class"] = "P6int" };
        local mt = { __index = Instance };
        function Instance.new (STable)
            local this = {};
            this.STable = STable;
            this.Undefined = false;
            this.Value = 0;
            return this;
            --return setmetatable(this, mt);
        end
        Instance[1] = Instance.new;
        return Instance;
    end
    local Instance = makeInstance();
    function P6int.new ()
        return setmetatable({}, mt);
    end
    P6int[1] = P6int.new;
    function P6int:type_object_for (TC, MetaPackage)
        local STable = SharedTable.new();
        STable.HOW = MetaPackage;
        STable.REPR = self;
        local WHAT = Instance.new(STable);
        STable.WHAT = WHAT;
        WHAT.Undefined = true;
        return STable.WHAT;
    end
    P6int[2] = P6int.type_object_for;
    function P6int:instance_of (TC, WHAT)
        return Instance.new(WHAT.STable);
    end
    P6int[3] = P6int.instance_of;
    function P6int:defined (TC, O)
        return not O.Undefined;
    end
    P6int[4] = P6int.new;
    function P6int:hint_for (TC, ClassHandle, Name)
        return Hints.NO_HINT;
    end
    P6int[5] = P6int.hint_for;
    function P6int:set_int (TC, Object, Value)
        Object.Value = Value;
    end
    P6int[10] = P6int.set_hint;
    function P6int:get_int (TC, Object)
        return Object.Value;
    end
    P6int[11] = P6int.set_hint;
    return P6int;
end
P6int = makeP6int();
