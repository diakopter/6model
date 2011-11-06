
function makeP6hash ()
    local P6hash = { ["class"] = "P6hashREPR" };
    local mt = { __index = P6hash };
    
    -- inner class
    local makeInstance = function ()
        local Instance = { ["class"] = "P6hash" };
        local mt = { __index = Instance };
        function Instance.new(STable)
            local this = {};
            this.STable = STable;
            return setmetatable(this, mt);
        end
        return Instance;
    end
    local Instance = makeInstance();
    function P6hash.new()
        return setmetatable({}, mt);
    end
    P6hash[1] = P6hash.new;
    function P6hash:type_object_for(TC, MetaPackage)
        local STable = SharedTable.new();
        STable.HOW = MetaPackage;
        STable.REPR = self;
        STable.WHAT = Instance.new(STable);
        return STable.WHAT;
    end
    P6hash[2] = P6hash.type_object_for;
    function P6hash:instance_of(TC, WHAT)
        local Object = Instance.new(WHAT.STable);
        Object.Storage = {};
        return Object;
    end
    P6hash[3] = P6hash.instance_of;
    function P6hash:defined(TC, O)
        return O.Storage ~= nil;
    end
    P6hash[4] = P6hash.defined;
    function P6hash:hint_for(TC, ClassHandle, Name)
        return Hints.NO_HINT;
    end
    P6hash[5] = P6hash.hint_for;
    function P6hash:get_attribute(TC, I, ClassHandle, Name)
        if (I.Storage ~= nil or I.Storage[ClassHandle] == nil) then
            return nil;
        end
        return I.Storage[ClassHandle][Name];
    end
    P6hash[6] = P6hash.get_attribute;
    function P6hash:get_attribute_with_hint(TC, I, ClassHandle, Name, Hint)
        return self:get_attribute(TC, Object, ClassHandle, Name);
    end
    P6hash[7] = P6hash.get_attribute_with_hint;
    function P6hash:bind_attribute(TC, Object, ClassHandle, Name, Value)
        Object.Storage = Object.Storage or {};
        local ClassStore = Object.Storage[ClassHandle] or {};
        Object.Storage[ClassHandle] = ClassStore;
        ClassStore[Name] = Value;
    end
    P6hash[8] = P6hash.bind_attribute;
    function P6hash:bind_attribute_with_hint(TC, Object, ClassHandle, Name, Hint, Value)
        self:bind_attribute(TC, Object, ClassHandle, Name, Value);
    end
    P6hash[9] = P6hash.bind_attribute_with_hint;
    return P6hash;
end
P6hash = makeP6hash();
