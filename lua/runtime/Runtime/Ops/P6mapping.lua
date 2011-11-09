function Ops.llmapping_get_at_key (TC, LLMapping, Key)
    --if (LLMapping.class == "P6mapping") then
        local Storage = LLMapping.Storage;
        local StrKey = Ops.unbox_str(TC, Key);
        return Storage[StrKey];
    --else
    --    error("Cannot use llmapping_get_at_key if representation is not P6mapping");
    --end
end
Ops[70] = Ops.llmapping_get_at_key;

function Ops.llmapping_bind_at_key (TC, LLMapping, Key, Value)
    --if (LLMapping.class == "P6mapping") then
        local Storage = LLMapping.Storage;
        local StrKey = Ops.unbox_str(TC, Key);
        Storage[StrKey] = Value;
        return Value;
    --else
    --    error("Cannot use llmapping_bind_at_key if representation is not P6mapping");
    --end
end
Ops[71] = Ops.llmapping_bind_at_key;

function Ops.llmapping_elems (TC, LLMapping)
    --if (LLMapping.class == "P6mapping") then
        return Ops.box_int(TC, LLMapping.Storage.Count, TC.DefaultIntBoxType);
    --else
    --    error("Cannot use llmapping_elems if representation is not P6mapping");
    --end
end
Ops[72] = Ops.llmapping_elems;
