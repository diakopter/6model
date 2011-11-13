function makeThreadContext ()
    local ThreadContext = { ["class"] = "ThreadContext" };
    local mt = { __index = ThreadContext };
    function ThreadContext.new()
        return setmetatable({}, mt);
    end
    ThreadContext[1] = ThreadContext.new;
    return ThreadContext;
end
ThreadContext = makeThreadContext();