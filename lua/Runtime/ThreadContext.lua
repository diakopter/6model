function makeThreadContext ()
    local ThreadContext = {};
    local mt = { __index = ThreadContext };
    function ThreadContext.new()
        local this = {};
        return setmetatable(this, mt);
    end
    return ThreadContext;
end
ThreadContext = makeThreadContext();