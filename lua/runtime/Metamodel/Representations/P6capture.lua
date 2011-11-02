
function makeP6capture ()
    local P6capture = {};
    local mt = { __index = P6capture };
    
    local makeInstance = function ()
        local Instance = {};
        local mt = { __index = Instance };
        function Instance.new(STable)
            local instance = {};
            instance.STable = STable;
            instance.class = "P6capture";
            return setmetatable(instance, mt);
        end
        return Instance;
    end
    local Instance = makeInstance();
    
    function P6capture.new()
        return setmetatable({}, mt);
    end
    function P6capture:type_object_for(TC, MetaPackage)
        local STable = SharedTable.new();
        STable.HOW = MetaPackage;
        STable.REPR = self;
        STable.WHAT = Instance.new(STable);
        return STable.WHAT;
    end
    function P6capture:instance_of(TC, WHAT)
        return Instance.new(WHAT.STable);
    end
    function P6capture:defined(TC, Obj)
        if (Obj.Positionals ~= nil or Obj.Nameds ~= nil) then
            return true;
        else
            return false;
        end
    end
    function P6capture:hint_for(TC, ClassHandle, Name)
        return Hints.NO_HINT;
    end
    return P6capture;
end
P6capture = makeP6capture();
