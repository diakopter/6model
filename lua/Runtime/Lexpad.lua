function makeLexpad ()
    local Lexpad = {};
    local mt = { __index = Lexpad };
    function Lexpad.new(SlotNames)
        local this = {};
        this.SlotMapping = {};
        for k,v in ipairs(SlotNames) do
            this.SlotMapping[v] = k;
        end
        this.SlotCount = #SlotNames;
        this.Storage = List.new(this.SlotCount);
        return setmetatable(this, mt);
    end
    
    function Lexpad:GetByName(Name)
        return self.Storage[self.SlotMapping[Name]];
    end
    function Lexpad:SetByName(Name, Value)
        self.Storage[self.SlotMapping[Name]] = Value;
    end
    function Lexpad:Extend(Names)
        local SlotMapping = {};
        for k,v in pairs(self.SlotMapping) do
            SlotMapping[k] = v;
        end
        for k,v in ipairs(Names) do
            SlotMapping[Name] = NewSlot + k - 1;
        end
        local new = self.SlotCount + #Names;
        local NewStorage = List.new(new);
        for i = 1, self.SlotCount do
            NewStorage[i] = this.Storage[i];
        end
        self.SlotCount = new;
        self.Storage = NewStorage;
    end
    return Lexpad;
end
Lexpad = makeLexpad();