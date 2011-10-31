function makeSignature ()
    local Signature = {};
    local mt = { __index = Signature };
    function Signature.new(Parameters)
        local this = {};
        this.Parameters = Parameters;
        this.NumRequiredPositionals = 0;
        this.NumPositionals = 0;
        
        for i = 1, Parameters.Count do
            if (Parameters[i].Flags == Parameter.POS_FLAG) then
                this.NumRequiredPositionals = this.NumRequiredPositionals + 1;
                this.NumPositionals = this.NumPositionals + 1;
            elseif (Parameters[i].Flags == Parameter.OPTIONAL_FLAG) then
                this.NumPositionals = this.NumPositionals + 1;
            else
                i = Parameters.Count + 1; -- fake break
            end
        end
        return setmetatable(this, mt);
    end
    
    function Signature:HasSlurpyPositional()
        for i = 1, self.Parameters.Count do
            if (self.Parameters[i].Flags == Parameter.POS_SLURPY_FLAG) then
                return true;
            end
        end
        return false;
    end
    return Signature;
end
Signature = makeSignature();


