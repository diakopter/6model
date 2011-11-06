
function makeP6str ()
    local P6str = { ["class"] = "P6strREPR" };
    local mt = { __index = P6str };
    
    local makeInstance = function ()
        local Instance = { ["class"] = "P6str" };
        local mt = { __index = Instance };
        function Instance.new(STable)
            local this = {};
            this.STable = STable;
            return setmetatable(this, mt);
        end
        return Instance;
    end
    local Instance = makeInstance();
    function P6str.new()
        return setmetatable({}, mt);
    end
    P6str[1] = P6str.new;
    function P6str:type_object_for(TC, MetaPackage)
        local STable = SharedTable.new();
        STable.HOW = MetaPackage;
        STable.REPR = self;
        local WHAT = Instance.new(STable);
        STable.WHAT = WHAT;
        WHAT.Undefined = true;
        return STable.WHAT;
    end
    P6str[2] = P6str.type_object_for;
    function P6str:instance_of(TC, WHAT)
        local instance = Instance.new(WHAT.STable);
        instance.Value = "";
        return instance;
    end
    P6str[3] = P6str.instance_of;
    function P6str:defined(TC, O)
        return O.Value ~= nil;
    end
    P6str[4] = P6str.defined;
    function P6str:hint_for(TC, ClassHandle, Name)
        return Hints.NO_HINT;
    end
    P6str[5] = P6str.hint_for;
    function P6str:set_str(TC, Object, Value)
        Object.Value = Value;
    end
    P6str[14] = P6str.set_str;
    function P6str:get_str(TC, Object)
        return Object.Value;
    end
    P6str[15] = P6str.get_str;
    return P6str;
end
P6str = makeP6str();
