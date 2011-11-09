function makeContext ()
    local Context = { ["class"] = "Context" };
    local mt = { __index = Context };
    function Context.new (StaticCodeObject, Caller, Capture)
        local this = {};
        this.StaticCodeObject = StaticCodeObject;
        this.Caller = Caller;
        this.Capture = Capture;
        
        StaticCodeObject.CurrentContext = this;
        
        local lexpad = Lexpad.new({});
        this.LexPad  = lexpad;
        local staticCodeObject = StaticCodeObject.StaticLexPad;
        lexpad.SlotMapping = staticCodeObject.SlotMapping;
        lexpad.Storage = table_clone(staticCodeObject.Storage);
        
        local outer = StaticCodeObject.OuterForNextInvocation;
        if (outer ~= nil) then
            this.Outer = outer;
        else
            local cur = StaticCodeObject.OuterBlock.CurrentContext;
            if (cur ~= nil) then
                this.Outer = cur;
            else
                local CurContext = this;
                local OuterBlock = StaticCodeObject.OuterBlock;
                while (OuterBlock ~= nil) do
                    if (OuterBlock.CurrentContext ~= nil) then
                        CurContext.Outer = OuterBlock.CurrentContext;
                        break;
                    end
                    
                    local OuterContext = Context.newplain();
                    OuterContext.StaticCodeObject = OuterBlock;
                    OuterContext.LexPad = OuterBlock.StaticLexPad;
                    CurContext.Outer = OuterContext;
                    CurContext = OuterContext;
                    OuterBlock = OuterBlock.OuterBlock;
                end
            end
        end
        return setmetatable(this, mt);
    end
    Context[1] = Context.new;
    function Context.newplain ()
        return setmetatable({}, mt);
    end
    Context[2] = Context.newplain;
    return Context;
end
Context = makeContext();

