
function makeP6capture ()
    local P6capture = { ["class"] = "P6captureREPR" };
    local mt = { __index = P6capture };
    
    local makeInstance = function ()
        local Instance = { ["class"] = "P6capture"};
        local mt = { __index = Instance };
        function Instance.new (STable)
            return { STable, nil, nil };
        end
        Instance[1] = Instance.new;
        return Instance;
    end
    local Instance = makeInstance();
    function P6capture.new ()
        local this = {};
        return setmetatable(this, mt);
    end
    P6capture[1] = P6capture.new;
    function P6capture:type_object_for (TC, MetaPackage)
        local STable = SharedTable.new();
        STable.HOW = MetaPackage;
        STable.REPR = self;
        STable.WHAT = Instance.new(STable);
        return STable.WHAT;
    end
    P6capture[2] = P6capture.type_object_for;
    function P6capture:instance_of (TC, WHAT)
        return { WHAT.STable, nil, nil };
    end
    P6capture[3] = P6capture.instance_of;
    function P6capture:defined (TC, Obj)
        return Obj.Positionals ~= nil or Obj.Nameds ~= nil;
    end
    P6capture[4] = P6capture.defined;
    function P6capture:hint_for (TC, ClassHandle, Name)
        return Hints.NO_HINT;
    end
    P6capture[5] = P6capture.hint_for;
    return P6capture;
end
P6capture = makeP6capture();
