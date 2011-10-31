function Ops.equal_nums(TC, x, y)
    return x == y and 1 or 0;
end

function Ops.equal_ints(TC, x, y)
    return x == y and 1 or 0;
end

function Ops.equal_strs(TC, x, y)
    return x == y and 1 or 0;
end


function Ops.equal_refs(TC, x, y)
    return Ops.box_int(TC, x == y and 1 or 0, TC.DefaultBoolBoxType);
end

function Ops.less_than_nums(TC, x, y)
    return Ops.box_int(TC, Ops.unbox_num(TC, x) < Ops.unbox_num(TC, y) and 1 or 0, TC.DefaultBoolBoxType);
end

function Ops.less_than_ints(TC, x, y)
    return Ops.box_int(TC, Ops.unbox_int(TC, x) < Ops.unbox_int(TC, y) and 1 or 0, TC.DefaultBoolBoxType);
end

function Ops.less_than_or_equal_nums(TC, x, y)
    return Ops.box_int(TC, Ops.unbox_num(TC, x) <= Ops.unbox_num(TC, y) and 1 or 0, TC.DefaultBoolBoxType);
end

function Ops.less_than_or_equal_ints(TC, x, y)
    return Ops.box_int(TC, Ops.unbox_int(TC, x) <= Ops.unbox_int(TC, y) and 1 or 0, TC.DefaultBoolBoxType);
end

function Ops.greater_than_nums(TC, x, y)
    return Ops.box_int(TC, Ops.unbox_num(TC, x) > Ops.unbox_num(TC, y) and 1 or 0, TC.DefaultBoolBoxType);
end

function Ops.greater_than_ints(TC, x, y)
    return Ops.box_int(TC, Ops.unbox_int(TC, x) > Ops.unbox_int(TC, y) and 1 or 0, TC.DefaultBoolBoxType);
end

function Ops.greater_than_or_equal_nums(TC, x, y)
    return Ops.box_int(TC, Ops.unbox_num(TC, x) >= Ops.unbox_num(TC, y) and 1 or 0, TC.DefaultBoolBoxType);
end

function Ops.greater_than_or_equal_ints(TC, x, y)
    return Ops.box_int(TC, Ops.unbox_int(TC, x) >= Ops.unbox_int(TC, y) and 1 or 0, TC.DefaultBoolBoxType);
end

function Ops.less_than_strs(TC, x, y)
    return Ops.box_int(TC, Ops.unbox_str(TC, x) < Ops.unbox_str(TC, y) and 1 or 0, TC.DefaultBoolBoxType);
end

function Ops.less_than_or_equal_strs(TC, x, y)
    return Ops.box_int(TC, Ops.unbox_str(TC, x) <= Ops.unbox_str(TC, y) and 1 or 0, TC.DefaultBoolBoxType);
end

function Ops.greater_than_strs(TC, x, y)
    return Ops.box_int(TC, Ops.unbox_str(TC, x) > Ops.unbox_str(TC, y) and 1 or 0, TC.DefaultBoolBoxType);
end

function Ops.greater_than_or_equal_strs(TC, x, y)
    return Ops.box_int(TC, Ops.unbox_str(TC, x) >= Ops.unbox_str(TC, y) and 1 or 0, TC.DefaultBoolBoxType);
end


