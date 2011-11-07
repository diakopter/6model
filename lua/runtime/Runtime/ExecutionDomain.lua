function makeExecutionDomain ()
    local ExecutionDomain = { ["class"] = "ExecutionDomain" };
    local mt = { __index = ExecutionDomain };
    function ExecutionDomain.new ()
        local this = {};
        return setmetatable(this, mt);
    end
    ExecutionDomain[1] = ExecutionDomain.new;
    return ExecutionDomain;
end
ExecutionDomain = makeExecutionDomain();