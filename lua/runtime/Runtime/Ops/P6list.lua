-- translate the zero-index to one-indexed.. <sigh>
function Ops.lllist_get_at_pos(TC, LLList, Index)
    if (Index.Value ~= nil) then Index = Index.Value end
    return LLList.Storage[Index + 1];
end

function Ops.lllist_bind_at_pos(TC, LLList, IndexObj, Value)
    local ix = Ops.unbox_int(TC, IndexObj) + 1;
    if ix == LLList.Storage.Count + 1 then
        -- the compiler likes to generate code to bind outside the range of
        -- lists hoping to extend.. <double sigh>
        LLList.Storage:Push(Value);
    else
        LLList.Storage[ix] = Value;
    end
    return Value;
end

function Ops.lllist_elems(TC, LLList)
    return Ops.box_int(TC, LLList.Storage.Count, TC.DefaultIntBoxType);
end

function Ops.lllist_push(TC, LLList, item)
    LLList.Storage:Push(item);
end

function Ops.lllist_pop(TC, LLList)
    return LLList.Storage:Pop();
end

function Ops.lllist_truncate_to(TC, LLList, Length)
    LLList.Storage:Truncate(Ops.unbox_int(TC, Length));
    return LLList;
end

function Ops.lllist_shift(TC, LLList)
    return LLList.Storage:Shift();
end

function Ops.lllist_unshift(TC, LLList, item)
    return LLList.Storage:Unshift(item);
end
