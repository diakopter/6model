
function makeRakudoCodeRef ()
    local RakudoCodeRef = {};
    local mt = { __index = RakudoCodeRef };
    
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
    RakudoCodeRef.Instance = Instance;
    
    function RakudoCodeRef.new()
        return setmetatable({}, mt);
    end
    function RakudoCodeRef:type_object_for(TC, MetaPackage)
        local STable = SharedTable.new();
        STable.HOW = MetaPackage;
        STable.REPR = self;
        STable.WHAT = Instance.new(STable);
        STable.SpecialInvoke = function (TCi, Obj, Cap)
            Obj.Body(TCi, Obj, Cap);
        end;
        return STable.WHAT;
    end
    function RakudoCodeRef:instance_of(TC, WHAT)
        return Instance.new(WHAT.STable);
    end
    function RakudoCodeRef:defined(TC, Obj)
        if (Obj.Body ~= nil) then
            return true;
        else
            return false;
        end
    end
    function RakudoCodeRef:hint_for(TC, ClassHandle, Name)
        return Hints.NO_Hint;
    end
    return RakudoCodeRef;
end
RakudoCodeRef = makeRakudoCodeRef();
