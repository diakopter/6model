function Ops.equal_nums(TC, x, y)
    return x == y and 1 or 0;
end
Ops[13] = Ops.equal_nums;

function Ops.equal_ints(TC, x, y)
    return x == y and 1 or 0;
end
Ops[14] = Ops.equal_ints;

function Ops.equal_strs(TC, x, y)
    return x == y and 1 or 0;
end
Ops[15] = Ops.equal_strs;

function Ops.equal_refs(TC, x, y)
    return Ops.box_int(TC, x == y and 1 or 0, TC.DefaultBoolBoxType);
end
Ops[16] = Ops.equal_refs;

function Ops.less_than_nums(TC, x, y)
    return Ops.box_int(TC, Ops.unbox_num(TC, x) < Ops.unbox_num(TC, y) and 1 or 0, TC.DefaultBoolBoxType);
end
Ops[17] = Ops.less_than_nums;

function Ops.less_than_ints(TC, x, y)
    return Ops.box_int(TC, Ops.unbox_int(TC, x) < Ops.unbox_int(TC, y) and 1 or 0, TC.DefaultBoolBoxType);
end
Ops[18] = Ops.less_than_ints;

function Ops.less_than_or_equal_nums(TC, x, y)
    return Ops.box_int(TC, Ops.unbox_num(TC, x) <= Ops.unbox_num(TC, y) and 1 or 0, TC.DefaultBoolBoxType);
end
Ops[19] = Ops.less_than_or_equal_nums;

function Ops.less_than_or_equal_ints(TC, x, y)
    return Ops.box_int(TC, Ops.unbox_int(TC, x) <= Ops.unbox_int(TC, y) and 1 or 0, TC.DefaultBoolBoxType);
end
Ops[20] = Ops.less_than_or_equal_ints;

function Ops.greater_than_nums(TC, x, y)
    return Ops.box_int(TC, Ops.unbox_num(TC, x) > Ops.unbox_num(TC, y) and 1 or 0, TC.DefaultBoolBoxType);
end
Ops[21] = Ops.greater_than_nums;

function Ops.greater_than_ints(TC, x, y)
    return Ops.box_int(TC, Ops.unbox_int(TC, x) > Ops.unbox_int(TC, y) and 1 or 0, TC.DefaultBoolBoxType);
end
Ops[22] = Ops.greater_than_ints;

function Ops.greater_than_or_equal_nums(TC, x, y)
    return Ops.box_int(TC, Ops.unbox_num(TC, x) >= Ops.unbox_num(TC, y) and 1 or 0, TC.DefaultBoolBoxType);
end
Ops[23] = Ops.greater_than_or_equal_nums;

function Ops.greater_than_or_equal_ints(TC, x, y)
    return Ops.box_int(TC, Ops.unbox_int(TC, x) >= Ops.unbox_int(TC, y) and 1 or 0, TC.DefaultBoolBoxType);
end
Ops[24] = Ops.greater_than_or_equal_ints;

function Ops.less_than_strs(TC, x, y)
    return Ops.box_int(TC, Ops.unbox_str(TC, x) < Ops.unbox_str(TC, y) and 1 or 0, TC.DefaultBoolBoxType);
end
Ops[25] = Ops.less_than_strs;

function Ops.less_than_or_equal_strs(TC, x, y)
    return Ops.box_int(TC, Ops.unbox_str(TC, x) <= Ops.unbox_str(TC, y) and 1 or 0, TC.DefaultBoolBoxType);
end
Ops[26] = Ops.less_than_or_equal_strs;

function Ops.greater_than_strs(TC, x, y)
    return Ops.box_int(TC, Ops.unbox_str(TC, x) > Ops.unbox_str(TC, y) and 1 or 0, TC.DefaultBoolBoxType);
end
Ops[27] = Ops.greater_than_strs;

function Ops.greater_than_or_equal_strs(TC, x, y)
    return Ops.box_int(TC, Ops.unbox_str(TC, x) >= Ops.unbox_str(TC, y) and 1 or 0, TC.DefaultBoolBoxType);
end
Ops[28] = Ops.greater_than_or_equal_strs;

