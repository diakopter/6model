function makeContext ()
    local Context = {};
    local mt = { __index = Context };
    function Context.new(StaticCodeObject, Caller, Capture)
        local this = {};
        this.StaticCodeObject = StaticCodeObject;
        this.Caller = Caller;
        this.Capture = Capture;
        
        StaticCodeObject.CurrentContext = this;
        
        this.LexPad = Lexpad.new();
        this.LexPad.SlotMapping = StaticCodeObject.StaticLexPad.SlotMapping;
        this.LexPad.Storage = table_clone(StaticCodeObject.StaticLexPad.Storage);
        
        if (StaticCodeObject.OuterForNextInvocation ~= nil) then
            this.Outer = StaticCodeObject.OuterForNextInvocation;
        elseif (StaticCodeObject.OuterBlock.CurrentContext ~= nil) then
            this.Outer = StaticCodeObject.OuterBlock.CurrentContext;
        else
            local CurContext = this;
            local OuterBlock = StaticCodeObject.OuterBlock;
            while (OuterBlock ~= nil) do
                if (OuterBlock.CurrentContext ~= nil) then
                    CurContext.Outer = OuterBlock.CurrentContext;
                    break;
                end
                
                local OuterContext = Context.new();
                OuterContext.StaticCodeObject = OuterBlock;
                OuterContext.LexPad = OuterBlock.StaticLexPad;
                CurContext.Outer = OuterContext;
                CurContext = OuterContext;
                OuterBlock = OuterBlock.OuterBlock;
            end
        end
        return setmetatable(this, mt);
    end
    return Context;
end
Context = makeContext();

