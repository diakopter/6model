function Ops.box_int (TC, Value, To)
    if To ~= nil then
        local REPR = To.STable.REPR;
        local Result = REPR:instance_of(TC, To);
        REPR.set_int(TC, Result, Value);
        return Result;
    else
        local Result = TC.DefaultIntBoxType.STable.REPR:instance_of(TC, TC.DefaultIntBoxType);
        TC.DefaultIntBoxType.STable.REPR:set_int(TC, Result, Value);
        return Result;
    end
end

function Ops.box_num (TC, Value, To)
    if To ~= nil then
        local REPR = To.STable.REPR;
        local Result = REPR:instance_of(TC, To);
        REPR.set_num(TC, Result, Value);
        return Result;
    else
        local Result = TC.DefaultNumBoxType.STable.REPR:instance_of(TC, TC.DefaultNumBoxType);
        TC.DefaultNumBoxType.STable.REPR:set_num(TC, Result, Value);
        return Result;
    end
end


function Ops.box_num (TC, Value, To)
    if To ~= nil then
        local REPR = To.STable.REPR;
        local Result = REPR:instance_of(TC, To);
        REPR.set_str(TC, Result, Value);
        return Result;
    else
        local Result = TC.DefaultStrBoxType.STable.REPR:instance_of(TC, TC.DefaultStrBoxType);
        TC.DefaultStrBoxType.STable.REPR:set_str(TC, Result, Value);
        return Result;
    end
end

function Ops.unbox_int(TC, Boxed)
    return Boxed.STable.REPR:get_int(TC, Boxed);
end

function Ops.unbox_num(TC, Boxed)
    return Boxed.STable.REPR:get_num(TC, Boxed);
end

function Ops.unbox_str(TC, Boxed)
    return Boxed.STable.REPR:get_str(TC, Boxed);
end
