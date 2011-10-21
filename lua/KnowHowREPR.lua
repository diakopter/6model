
function makeKnowHowREPR ()
    local KnowHowREPR = {};
    local mt = { __index = KnowHowREPR };
    
    local makeInstance = function ()
        local Instance = {};
        local mt = { __index = Instance };
        function Instance.new(STable)
            local instance = {};
            instance.STable = STable;
            return setmetatable(instance, mt);
        end
    end
    local Instance = makeInstance();
    
    function KnowHowREPR.new()
        return setmetatable({}, mt);
    end
    function KnowHowREPR:type_object_for(TC, MetaPackage)
        local STable = SharedTable.new();
        STable.HOW = MetaPackage;
        STable.REPR = self;
        STable.WHAT = Instance.new(STable);
        return STable.WHAT;
    end
    function KnowHowREPR:instance_of(TC, WHAT)
        local Object = Instance.new(WHAT.STable);
        Object.Methods = {};
        Object.Attributes = List.new();
        return Object;
    end
    function KnowHowREPR:defined(TC, Obj)
        if (Obj.Methods ~= nil) then
            return true;
        else
            return false;
        end
    end
    function KnowHowREPR:hint_for(TC, ClassHandle, Name)
        return Hints.NO_Hint;
    end
    return KnowHowREPR;
end
KnowHowREPR = makeKnowHowREPR();
