function makeLeaveStackUnwinderException ()
    local LeaveStackUnwinderException = { ["class"] = "LeaveStackUnwinderException" };
    local mt = { __index = LeaveStackUnwinderException };
    function LeaveStackUnwinderException.new (TargetBlock, PayLoad)
        local this = {};
        this.TargetBlock = TargetBlock;
        this.PayLoad = PayLoad;
        return setmetatable(this, mt);
    end
    LeaveStackUnwinderException[1] = LeaveStackUnwinderException.new;
    return LeaveStackUnwinderException;
end
Exceptions.LeaveStackUnwinderException = makeLeaveStackUnwinderException();

__exceptions["LeaveStackUnwinderException"] = {
	E.LeaveStackUnwinderException,
};
