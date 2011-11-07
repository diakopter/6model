function makeSignature ()
    local Signature = { ["class"] = "Signature" };
    local mt = { __index = Signature };
    function Signature.new(Parameters)
        local this = {};
        this.Parameters = List.new();
        for k,v in ipairs(Parameters) do
            this.Parameters:Add(v);
        end
        this.NumRequiredPositionals = 0;
        this.NumPositionals = 0;
        
        for i = 1, this.Parameters.Count do
            if (this.Parameters[i].Flags == Parameter.POS_FLAG) then
                this.NumRequiredPositionals = this.NumRequiredPositionals + 1;
                this.NumPositionals = this.NumPositionals + 1;
            elseif (Parameters[i].Flags == Parameter.OPTIONAL_FLAG) then
                this.NumPositionals = this.NumPositionals + 1;
            else
                i = this.Parameters.Count + 1; -- fake break
            end
        end
        return setmetatable(this, mt);
    end
    Signature[1] = Signature.new;
    
    function Signature:HasSlurpyPositional()
        for i = 1, self.Parameters.Count do
            if (self.Parameters[i].Flags == Parameter.POS_SLURPY_FLAG) then
                return true;
            end
        end
        return false;
    end
    Signature[2] = Signature.HasSlurpyPositional;
    return Signature;
end
Signature = makeSignature();


