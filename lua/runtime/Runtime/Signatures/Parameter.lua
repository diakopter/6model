function makeParameter ()
    local Parameter = {};
    local mt = { __index = Parameter };
    function Parameter.new(Type, VariableName, VariableLexpadPosition, Name, Flags, Definedness, DefaultValue)
        local this = {};
        this.Type = Type;
        this.VariableName = VariableName;
        this.VariableLexpadPosition = VariableLexpadPosition;
        this.Name = Name;
        this.DefaultValue = DefaultValue;
        this.Flags = Flags;
        this.Definedness = Definedness;
        return setmetatable(this, mt);
    end
    
    Parameter.POS_FLAG = 0;
    Parameter.OPTIONAL_FLAG = 1;
    Parameter.POS_SLURPY_FLAG = 2;
    Parameter.NAMED_SLURPY_FLAG = 4;
    Parameter.NAMED_FLAG = 8;
    
    function Parameter:HasSlurpyPositional()
        for i = 1, self.Parameters.Count do
            if (self.Parameters[i].Flags == Parameter.POS_SLURPY_FLAG) then
                return true;
            end
        end
        return false;
    end
    return Parameter;
end
Parameter = makeParameter();


