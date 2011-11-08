function Ops.type_object_for (TC, HOW, REPRName)
    local REPRNameStr = Ops.unbox_str(TC, REPRName);
    local REPR = REPRRegistry.get_REPR_by_name(REPRNameStr);
    return REPR.type_object_for(REPR, TC, HOW);
end
Ops[43] = Ops.type_object_for;

function Ops.instance_of (TC, WHAT)
    local REPR = WHAT.STable.REPR;
    return REPR.instance_of(REPR, TC, WHAT);
end
Ops[44] = Ops.instance_of;

function Ops.repr_defined (TC, Obj)
    local REPR = Obj.STable.REPR;
    return Ops.box_int(TC, REPR.defined(REPR, TC, Obj) and 1 or 0, TC.DefaultBoolBoxType);
end
Ops[45] = Ops.repr_defined;

function Ops.get_attr (TC, Object, Class, Name)
    if (Name.Value ~= nil) then
        Name = Ops.unbox_str(TC, Name);
    end
    local REPR = Object.STable.REPR;
    return REPR.get_attribute(REPR, TC, Object, Class, Name);
end
Ops[46] = Ops.get_attr;

function get_attr_with_hint (TC, Object, Class, name, Hint)
    local REPR = Object.STable.REPR;
    return REPR.get_attribute_with_hint(REPR, TC, Object, Class, Name, Hint);
end
Ops[47] = Ops.get_attr_with_hint;

function Ops.bind_attr (TC, Object, Class, Name, Value)
    if (Name.Value ~= nil) then
        Name = Ops.unbox_str(TC, Name);
    end
    local REPR = Object.STable.REPR;
    REPR.bind_attribute(REPR, TC, Object, Class, Name, Value);
    return Value;
end
Ops[48] = Ops.bind_attr;

function Ops.bind_attr_with_hint (TC, Object, Class, Name, Value, Hint)
    if (Name.Value ~= nil) then
        Name = Ops.unbox_str(TC, Name);
    end
    local REPR = Object.STable.REPR;
    REPR.bind_attribute_with_hint(REPR, TC, Object, Class, Name, Hint, Value);
    return Value;
end
Ops[49] = Ops.bind_attr_with_hint;

function Ops.find_method (TC, Object, Name)
    local STable = Object.STable;
    return STable.FindMethod(STable, TC, Object, Name, Hints.NO_HINT);
end
Ops[50] = Ops.find_method;

function Ops.find_method_with_hint (TC, Object, Name, Hint)
    local STable = Object.STable;
    return STable.FindMethod(STable, TC, Object, Name, Hint);
end
Ops[51] = Ops.find_method_with_hint;

function Ops.invoke (TC, Invokee, Capture)
    local STable = Invokee.STable;
    return STable.Invoke(STable, TC, Invokee, Capture);
end
Ops[52] = Ops.invoke;

function Ops.get_how (TC, Obj)
    return Obj.STable.HOW;
end
Ops[53] = Ops.get_how;

function Ops.get_what (TC, Obj)
    return Obj.STable.WHAT;
end
Ops[54] = Ops.get_what;

function Ops.type_check (TC, ToCheck, WantedType)
    local STable = ToCheck.STable;
    return STable.TypeCheck(STable, TC, ToCheck, WantedType);
end
Ops[55] = Ops.type_check;

function Ops.publish_type_check_cache (TC, WHAT, TypeList)
    WHAT.STable.TypeCheckCache = TypeList.Storage:Clone();
end
Ops[56] = Ops.publish_type_check_cache;

function Ops.publish_method_cache (TC, WHAT, MethodCacheHash)
    WHAT.STable.MethodCache = MethodCacheHash.Storage;
    return MethodCacheHash;
end
Ops[57] = Ops.publish_method_cache;
