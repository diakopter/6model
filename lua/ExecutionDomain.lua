function makeExecutionDomain ()
    local ExecutionDomain = {};
    local mt = { __index = ExecutionDomain };
    function ExecutionDomain.new()
        local this = {};
        return setmetatable(this, mt);
    end
    return ExecutionDomain;
end
ExecutionDomain = makeExecutionDomain();