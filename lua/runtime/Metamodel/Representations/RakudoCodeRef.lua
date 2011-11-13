
function makeRakudoCodeRef ()
    local RakudoCodeRef = { ["class"] = "RakudoCodeRefREPR" };
    local mt = { __index = RakudoCodeRef };
    
    local makeInstance = function ()
        local Instance = { ["class"] = "RakudoCodeRef" };
        local mt = { __index = Instance };
        function Instance.new(STable)
            local instance = {};
            instance.STable = STable;
            return setmetatable(instance, mt);
        end
        return Instance;
    end
    local Instance = makeInstance();
    RakudoCodeRef.Instance = Instance;
    function RakudoCodeRef.new()
        return setmetatable({}, mt);
    end
    RakudoCodeRef[1] = RakudoCodeRef.new;
    function RakudoCodeRef:type_object_for(TC, MetaPackage)
        local STable = SharedTable.new();
        STable.HOW = MetaPackage;
        STable.REPR = self;
        STable.WHAT = Instance.new(STable);
        STable.SpecialInvoke = function (TCi, Obj, Cap)
            return Obj.Body(TCi, Obj, Cap);
        end;
        return STable.WHAT;
    end
    RakudoCodeRef[2] = RakudoCodeRef.type_object_for;
    function RakudoCodeRef:instance_of(TC, WHAT)
        return Instance.new(WHAT.STable);
    end
    RakudoCodeRef[3] = RakudoCodeRef.instance_of;
    function RakudoCodeRef:defined(TC, Obj)
        return Obj.Body ~= nil;
    end
    RakudoCodeRef[4] = RakudoCodeRef.defined;
    function RakudoCodeRef:hint_for(TC, ClassHandle, Name)
        return Hints.NO_Hint;
    end
    RakudoCodeRef[5] = RakudoCodeRef.hint_for;
    return RakudoCodeRef;
end
RakudoCodeRef = makeRakudoCodeRef();
