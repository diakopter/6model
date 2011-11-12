function makeLexpad ()
    local Lexpad = { ["class"] = "Lexpad" };
    local mt = { __index = Lexpad };
    function Lexpad.new (SlotNames)
        local this = {};
        local mapping = {};
        this.SlotMapping = mapping;
        for k,v in ipairs(SlotNames) do
            mapping[v] = k;
        end
        --local count = #SlotNames;
        --this.SlotCount = count;
        this.Storage = {};
        return setmetatable(this, mt);
    end
    Lexpad[1] = Lexpad.new;
    function Lexpad:GetByName (Name)
        return self.Storage[self.SlotMapping[Name]];
    end
    Lexpad[2] = Lexpad.GetByName;
    function Lexpad:SetByName (Name, Value)
        self.Storage[self.SlotMapping[Name]] = Value;
    end
    Lexpad[3] = Lexpad.SetByName;
    function Lexpad:Extend (Names)
        local SlotMapping = {};
        for k,v in pairs(self.SlotMapping) do
            SlotMapping[k] = v;
        end
        local SlotCount = #self.Storage;
        for k,v in ipairs(Names) do
            SlotMapping[v] = SlotCount + k;
        end
        self.SlotMapping = SlotMapping;
        local newSlotCount = SlotCount + #Names;
        local NewStorage = { Count = newSlotCount };
        for i = 1, SlotCount do
            NewStorage[i] = self.Storage[i];
        end
        --self.SlotCount = newSlotCount;
        self.Storage = NewStorage;
    end
    Lexpad[4] = Lexpad.Extend;
    return Lexpad;
end
Lexpad = makeLexpad();
