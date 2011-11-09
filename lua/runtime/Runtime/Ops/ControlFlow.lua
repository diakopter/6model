function Ops.vivify(TC, Check, VivifyWith)
    if Check ~= nil then return Check end
    return VivifyWith;
end
Ops[29] = Ops.vivify;

function Ops.leave_block (TC, Block, ReturnValue)
    error(Exceptions.LeaveStackUnwinderException.new(Block, ReturnValue));
end
Ops[30] = Ops.leave_block;

function Ops.throw_dynamic (TC, ExceptionObject, ExceptionType)
    local WantType = Ops.unbox_int(TC, ExceptionType);
    local CurContext = TC.CurrentContext;
    while (CurContext ~= nil) do
        if (CurContext.StaticCodeObject ~= nil) then
            local Handlers = CurContext.StaticCodeObject.Handlers;
            if (Handlers ~= nil) then
                for i = 1, Handlers.Count or #Handlers do
                    if (Handlers[i].Type == WantType) then
                        return Exceptions.ExceptionDispatcher.CallHandler(TC,
                            Handlers[i].HandleBlock, ExceptionObject);
                    end
                end
            end
        end
        CurContext = CurContext.Caller;
    end
    Exceptions.ExceptionDispatcher.DieFromUnhandledException(TC, ExceptionObject);
    return nil; -- Unreachable; above call exits always.
end
Ops[31] = Ops.throw_dynamic;

function Ops.throw_lexical (TC, ExceptionObject, ExceptionType)
    local WantType = Ops.unbox_int(TC, ExceptionType);
    local CurContext = TC.CurrentContext;
    while (CurContext ~= nil) do
        if (CurContext.StaticCodeObject ~= nil) then
            local Handlers = CurContext.StaticCodeObject.Handlers;
            if (Handlers ~= nil) then
                for i = 1, Handlers.Count or #Handlers do
                    if (Handlers[i].Type == WantType) then
                        return Exceptions.ExceptionDispatcher.CallHandler(TC,
                            Handlers[i].HandleBlock, ExceptionObject);
                    end
                end
            end
        end
        CurContext = CurContext.Outer;
    end
    Exceptions.ExceptionDispatcher.DieFromUnhandledException(TC, ExceptionObject);
    return nil; -- Unreachable; above call exits always.
end
Ops[32] = Ops.throw_lexical;

function Ops.capture_outer (TC, Block)
    Block.OuterForNextInvocation = TC.CurrentContext;
    return Block;
end
Ops[33] = Ops.capture_outer;

function Ops.new_closure (TC, Block)
    local NewBlock = RakudoCodeRef.Instance.new(Block.STable);
    NewBlock.Body = Block.Body;
    NewBlock.CurrentContext = Block.CurrentContext;
    NewBlock.Dispatchees = Block.Dispatchees;
    NewBlock.Handlers = Block.Handlers;
    NewBlock.OuterBlock = Block.OuterBlock;
    NewBlock.Sig = Block.Sig;
    NewBlock.StaticLexPad = Block.StaticLexPad;

    -- Set the outer for next invocation and return the cloned block.
    NewBlock.OuterForNextInvocation = TC.CurrentContext;
    return NewBlock;
end
Ops[34] = Ops.new_closure;
