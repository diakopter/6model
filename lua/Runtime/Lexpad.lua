function makeLexpad ()
    local Lexpad = {};
    local mt = { __index = Lexpad };
    function Lexpad.new(SlotNames)
        local this = {};
        this.SlotMapping = {};
        for k,v in ipairs(SlotNames) do
            this.SlotMapping[v] = k - 1;
        end
        this.SlotCount = #SlotNames;
        this.Storage = {}; -- zero-indexed...!
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
        local NewSlot = this.SlotCount;
        for k,v in ipairs(Names) do
            SlotMapping[Name] = NewSlot + k - 1;
        end
        local NewStorage = {};
        for i = 0, this.SlotCount - 1 do
            NewStorage[i] = this.Storage[i];
        end
        Storage = NewStorage;
    end
    return Lexpad;
end
Lexpad = makeLexpad();