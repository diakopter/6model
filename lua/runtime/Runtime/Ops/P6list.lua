function Ops.lllist_get_at_pos(TC, LLList, Index)
    if (Index.Value ~= nil) then Index = Index.Value end
    return LLList.Storage[Index + 1];
end
Ops[62] = Ops.lllist_get_at_pos;

function Ops.lllist_bind_at_pos(TC, LLList, IndexObj, Value)
    local ix = Ops.unbox_int(TC, IndexObj) + 1;
    if ix == LLList.Storage.Count + 1 then
        -- the compiler likes to generate code to bind outside the range of
        -- lists hoping to extend.. <double sigh>
        List.Push(LLList.Storage, Value);
    else
        LLList.Storage[ix] = Value;
    end
    return Value;
end
Ops[63] = Ops.lllist_bind_at_pos;

function Ops.lllist_elems(TC, LLList)
    return Ops.box_int(TC, LLList.Storage.Count, TC.DefaultIntBoxType);
end
Ops[64] = Ops.lllist_elems;

function Ops.lllist_push(TC, LLList, item)
    LLList.Storage:Push(item);
end
Ops[65] = Ops.lllist_push;

function Ops.lllist_pop(TC, LLList)
    return LLList.Storage:Pop();
end
Ops[66] = Ops.lllist_pop;

function Ops.lllist_truncate_to(TC, LLList, Length)
    LLList.Storage:Truncate(Ops.unbox_int(TC, Length));
    return LLList;
end
Ops[67] = Ops.lllist_truncate_to;

function Ops.lllist_shift(TC, LLList)
    return LLList.Storage:Shift();
end
Ops[68] = Ops.lllist_shift;

function Ops.lllist_unshift(TC, LLList, item)
    return LLList.Storage:Unshift(item);
end
Ops[69] = Ops.lllist_unshift;
