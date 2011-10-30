function makeLeaveStackUnwinderException ()
    local LeaveStackUnwinderException = {};
    local mt = { __index = LeaveStackUnwinderException };
    function LeaveStackUnwinderException.new(TargetBlock, PayLoad)
        local LeaveStackUnwinderException = {};
        LeaveStackUnwinderException.TargetBlock = TargetBlock;
        LeaveStackUnwinderException.HandleBlock = PayLoad;
        return setmetatable(LeaveStackUnwinderException, mt);
    end
    return LeaveStackUnwinderException;
end
Exceptions.LeaveStackUnwinderException = makeLeaveStackUnwinderException();


