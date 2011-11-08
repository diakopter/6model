
function makeP6opaque ()
    local P6opaque = { ["class"] = "P6opaqueREPR" };
    local mt = { __index = P6opaque };
    
    local makeInstance = function ()
        local Instance = { ["class"] = "P6opaque" };
        local mt = { __index = Instance };
        function Instance.new (STable)
            local this = {};
            this.STable = STable;
            return this;
            --return setmetatable(this, mt);
        end
        Instance[1] = Instance.new;
        return Instance;
    end
    local Instance = makeInstance();
    function P6opaque.new ()
        return setmetatable({}, mt);
    end
    P6opaque[1] = P6opaque.new;
    function P6opaque:type_object_for (TC, MetaPackage)
        local STable = SharedTable.new();
        STable.HOW = MetaPackage;
        STable.REPR = self;
        STable.WHAT = Instance.new(STable);
        return STable.WHAT;
    end
    P6opaque[2] = P6opaque.type_object_for;
    function P6opaque:instance_of (TC, WHAT)
        local Object = Instance.new(WHAT.STable);
        Object.Storage = {};
        return Object;
    end
    P6opaque[3] = P6opaque.instance_of;
    function P6opaque:defined (TC, O)
        return O.Storage ~= nil;
    end
    P6opaque[4] = P6opaque.defined;
    function P6opaque:hint_for (TC, ClassHandle, Name)
        return Hints.NO_HINT;
    end
    P6opaque[5] = P6opaque.hint_for;
    function P6opaque:get_attribute (TC, I, ClassHandle, Name)
        if (I.Storage == nil or I.Storage[ClassHandle] == nil) then
            return nil;
        end
        return I.Storage[ClassHandle][Name];
    end
    P6opaque[6] = P6opaque.get_attribute;
    function P6opaque:get_attribute_with_hint (TC, I, ClassHandle, Name, Hint)
        return self.get_attribute(self, TC, Object, ClassHandle, Name);
    end
    P6opaque[7] = P6opaque.get_attribute_with_hint;
    function P6opaque:bind_attribute (TC, Object, ClassHandle, Name, Value)
        Object.Storage = Object.Storage or {};
        local ClassStore = Object.Storage[ClassHandle] or {};
        Object.Storage[ClassHandle] = ClassStore;
        ClassStore[Name] = Value;
    end
    P6opaque[8] = P6opaque.bind_attribute;
    function P6opaque:bind_attribute_with_hint (TC, Object, ClassHandle, Name, Hint, Value)
        self.bind_attribute(self, TC, Object, ClassHandle, Name, Value);
    end
    P6opaque[9] = P6opaque.bind_attribute_with_hint;
    return P6opaque;
end
P6opaque = makeP6opaque();
