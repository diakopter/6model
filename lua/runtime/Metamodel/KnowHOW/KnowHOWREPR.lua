
function makeKnowHOWREPR ()
    local KnowHOWREPR = {};
    local mt = { __index = KnowHOWREPR };
    
    local makeInstance = function ()
        local Instance = {};
        local mt = { __index = Instance };
        function Instance.new(STable)
            local instance = {};
            instance.STable = STable;
            instance.class = "KnowHOWREPR";
            return setmetatable(instance, mt);
        end
        return Instance;
    end
    local Instance = makeInstance();
    
    function KnowHOWREPR.new()
        return setmetatable({}, mt);
    end
    function KnowHOWREPR:type_object_for(TC, MetaPackage)
        local STable = SharedTable.new();
        STable.HOW = MetaPackage;
        STable.REPR = self;
        STable.WHAT = Instance.new(STable);
        return STable.WHAT;
    end
    function KnowHOWREPR:instance_of(TC, WHAT)
        local Object = Instance.new(WHAT.STable);
        Object.Methods = {};
        Object.Attributes = List.new();
        return Object;
    end
    function KnowHOWREPR:defined(TC, Obj)
        if (Obj.Methods ~= nil) then
            return true;
        else
            return false;
        end
    end
    function KnowHOWREPR:hint_for(TC, ClassHandle, Name)
        return Hints.NO_Hint;
    end
    return KnowHOWREPR;
end
KnowHOWREPR = makeKnowHOWREPR();
