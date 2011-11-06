function makeLeaveStackUnwinderException ()
    local LeaveStackUnwinderException = {};
    local mt = { __index = LeaveStackUnwinderException };
    function LeaveStackUnwinderException.new(TargetBlock, PayLoad)
        local this = {};
        this.TargetBlock = TargetBlock;
        this.PayLoad = PayLoad;
        this.class = "LeaveStackUnwinderException";
        return setmetatable(this, mt);
    end
    return LeaveStackUnwinderException;
end
Exceptions.LeaveStackUnwinderException = makeLeaveStackUnwinderException();

__exceptions["LeaveStackUnwinderException"] = {
	E.LeaveStackUnwinderException,
};
