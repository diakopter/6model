
function makeP6hash ()
    local P6hash = {};
    local mt = { __index = P6hash };
    
    -- inner class
    local makeInstance = function ()
        local Instance = {};
        local mt = { __index = Instance };
        function Instance.new(STable)
            local instance = {};
            instance.STable = STable;
            instance.class = "P6hash";
            return setmetatable(instance, mt);
        end
        return Instance;
    end
    local Instance = makeInstance();
    
    function P6hash.new()
        local this = {};
        this.class = "P6hashREPR";
        return setmetatable(this, mt);
    end
    function P6hash:type_object_for(TC, MetaPackage)
        local STable = SharedTable.new();
        STable.HOW = MetaPackage;
        STable.REPR = self;
        STable.WHAT = Instance.new(STable);
        return STable.WHAT;
    end
    function P6hash:instance_of(TC, WHAT)
        local Object = Instance.new(WHAT.STable);
        Object.Storage = {};
        return Object;
    end
    function P6hash:defined(TC, O)
        if (Obj.Storage ~= nil) then
            return true;
        else
            return false;
        end
    end
    function P6hash:get_attribute(TC, I, ClassHandle, Name)
        if (I.Storage ~= nil or I.Storage[ClassHandle] == nil) then
            return nil;
        end
        return I.Storage[ClassHandle][Name];
    end
    function P6hash:get_attribute_with_hint(TC, I, ClassHandle, Name, Hint)
        return self:get_attribute(TC, Object, ClassHandle, Name);
    end
    function P6hash:bind_attribute(TC, Object, ClassHandle, Name, Value)
        Object.Storage = Object.Storage or {};
        local ClassStore = Object.Storage[ClassHandle] or {};
        Object.Storage[ClassHandle] = ClassStore;
        ClassStore[Name] = Value;
    end
    function P6hash:bind_attribute_with_hint(TC, Object, ClassHandle, Name, Hint, Value)
        self:bind_attribute(TC, Object, ClassHandle, Name, Value);
    end
    function P6hash:hint_for(TC, ClassHandle, Name)
        return Hints.NO_HINT;
    end
    return P6hash;
end
P6hash = makeP6hash();
