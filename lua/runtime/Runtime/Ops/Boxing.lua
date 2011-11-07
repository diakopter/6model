function Ops.box_int (TC, Value, To)
    local REPR;
    if To ~= nil then
        REPR = To.STable.REPR;
        local Result = REPR.instance_of(REPR, TC, To);
        REPR.set_int(REPR, TC, Result, Value);
        return Result;
    else
        REPR = TC.DefaultIntBoxType.STable.REPR;
        local Result = REPR.instance_of(REPR, TC, TC.DefaultIntBoxType);
        REPR = TC.DefaultIntBoxType.STable.REPR;
        REPR.set_int(REPR, TC, Result, Value);
        return Result;
    end
end
Ops[1] = Ops.box_int;

function Ops.box_num (TC, Value, To)
    local REPR;
    if To ~= nil then
        REPR = To.STable.REPR;
        local Result = REPR.instance_of(REPR, TC, To);
        REPR.set_num(REPR, TC, Result, Value);
        return Result;
    else
        REPR = TC.DefaultNumBoxType.STable.REPR;
        local Result = REPR.instance_of(REPR, TC, TC.DefaultNumBoxType);
        REPR = TC.DefaultNumBoxType.STable.REPR;
        REPR.set_num(REPR, TC, Result, Value);
        return Result;
    end
end
Ops[2] = Ops.box_num;

function Ops.box_str (TC, Value, To)
    local REPR;
    if To ~= nil then
        REPR = To.STable.REPR;
        local Result = REPR.instance_of(REPR, TC, To);
        REPR.set_str(REPR, TC, Result, Value);
        return Result;
    else
        REPR = TC.DefaultStrBoxType.STable.REPR;
        local Result = REPR.instance_of(REPR, TC, TC.DefaultStrBoxType);
        REPR = TC.DefaultStrBoxType.STable.REPR;
        REPR.set_str(REPR, TC, Result, Value);
        return Result;
    end
end
Ops[3] = Ops.box_str;

function Ops.unbox_int (TC, Boxed)
    local REPR = Boxed.STable.REPR;
    return REPR.get_int(REPR, TC, Boxed);
end
Ops[4] = Ops.unbox_int;

function Ops.unbox_num (TC, Boxed)
    local REPR = Boxed.STable.REPR;
    return REPR.get_num(REPR, TC, Boxed);
end
Ops[5] = Ops.unbox_num;

function Ops.unbox_str (TC, Boxed)
    local REPR = Boxed.STable.REPR;
    return REPR.get_str(REPR, TC, Boxed);
end
Ops[6] = Ops.unbox_str;
