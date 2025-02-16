function Ops.coerce_int_to_str(TC, Int, TargetType)
    return Ops.box_str(TC, "".. Ops.unbox_int(TC, Int), TargetType);
end
Ops[7] = Ops.coerce_int_to_str;

function Ops.coerce_num_to_str(TC, Int, TargetType)
    return Ops.box_str(TC, "".. Ops.unbox_num(TC, Int), TargetType);
end
Ops[8] = Ops.coerce_num_to_str;

function Ops.coerce_int_to_num(TC, Int, TargetType)
    return Ops.box_num(TC, Ops.unbox_int(TC, Int), TargetType);
end
Ops[9] = Ops.coerce_int_to_num;

function Ops.coerce_num_to_int(TC, Num, TargetType)
    return Ops.box_int(TC, Ops.unbox_num(TC, Int), TargetType);
end
Ops[10] = Ops.coerce_num_to_int;

function Ops.coerce_str_to_int(TC, Str, TargetType)
    return Ops.box_int(TC, 0 + Ops.unbox_str(TC, Str), TargetType);
end
Ops[11] = Ops.coerce_str_to_int;

function Ops.coerce_str_to_num(TC, Str, TargetType)
    return Ops.box_num(TC, 0 + Ops.unbox_str(TC, Str), TargetType);
end
Ops[12] = Ops.coerce_str_to_num;
