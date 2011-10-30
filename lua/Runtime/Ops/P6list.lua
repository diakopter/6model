function Ops.lllist_get_at_pos(TC, LLList, Index)
    if (Index.Value ~= nil) then Index = Index.Value end
    return LLList.Storage[Index + 1];
end

function Ops.lllist_bind_at_pos(TC, LLList, IndexObj, Value)
    LLList.Storage[Ops.unbox_int(TC, IndexObj) + 1] = Value;
    return Value;
end

function Ops.lllist_elems(TC, LLList)
    return Ops.box_int(TC, #LLList.Storage, TC.DefaultIntBoxType);
end

function Ops.lllist_push(TC, LLList, item)
    LLList.Storage[#LLList.Storage + 1] = item;
end

function Ops.lllist_pop(TC, LLList)
    local store = LLList.Storage;
    local idx = #store;
    if (idx < 1) then
        error("Cannot pop from an empty list");
    end
    local item = store[idx];
    store[idx] = nil;
    return item;
end

function Ops.lllist_truncate_to(TC, LLList, Length)
    local store = LLList.Storage;
    local count = #store;
    local length = Ops.unbox_int(TC, Length);
    if (length < count) then
        for i = length + 1, count do
            store[i] = nil;
        end
    end
    return LLList;
end

function Ops.lllist_shift(TC, LLList)
    local store = LLList.Storage;
    local idx = #store;
    if (idx < 1) then
        error("Cannot shift from an empty list");
    end
    local item = store[1];
    for i = 2, idx do
        store[i - 1] = store[i];
    end
    store[idx] = nil;
    return item;
end

function Ops.lllist_unshift(TC, LLList, item)
    local store = LLList.Storage;
    for i = #store, 1, -1 do
        store[i + 1] = store[i];
    end
    store[1] = item;
    return item;
end
