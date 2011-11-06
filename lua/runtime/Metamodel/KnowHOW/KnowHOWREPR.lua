
function makeKnowHOWREPR ()
    local KnowHOWREPR = { ["class"] = "KnowHOWREPR" };
    local mt = { __index = KnowHOWREPR };
    
    local makeInstance = function ()
        local Instance = { ["class"] = "KnowHOW" };
        local mt = { __index = Instance };
        function Instance.new(STable)
            local this = {};
            this.STable = STable;
            return setmetatable(this, mt);
        end
        return Instance;
    end
    local Instance = makeInstance();
    function KnowHOWREPR.new()
        return setmetatable({}, mt);
    end
    KnowHOWREPR[1] = KnowHOWREPR.new;
    function KnowHOWREPR:type_object_for(TC, MetaPackage)
		local STable = SharedTable.new();
        STable.HOW = MetaPackage;
        STable.REPR = self;
        STable.WHAT = Instance.new(STable);
        return STable.WHAT;
    end
    KnowHOWREPR[2] = KnowHOWREPR.type_object_for;
    function KnowHOWREPR:instance_of(TC, WHAT)
        local Object = Instance.new(WHAT.STable);
        Object.Methods = {};
        Object.Attributes = List.new();
        return Object;
    end
    KnowHOWREPR[3] = KnowHOWREPR.instance_of;
    function KnowHOWREPR:defined(TC, Obj)
        return Obj.Methods ~= nil;
    end
    KnowHOWREPR[4] = KnowHOWREPR.defined;
    function KnowHOWREPR:hint_for(TC, ClassHandle, Name)
        return Hints.NO_Hint;
    end
    KnowHOWREPR[5] = KnowHOWREPR.hint_for;
    return KnowHOWREPR;
end
KnowHOWREPR = makeKnowHOWREPR();
