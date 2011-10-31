function Ops.type_object_for(TC, HOW, REPRName)
    local REPRNameStr = Ops.unbox_str(TC, REPRName);
    return REPRRegistry.get_REPR_by_name(REPRNameStr):type_object_for(TC, HOW);
end

function Ops.instance_of(TC, WHAT)
    return WHAT.STable.REPR:instance_of(TC, WHAT);
end

function Ops.repr_defined(TC, Obj)
    return Ops.box_int(TC, Obj.STable.REPR:defined(TC, Obj) and 1 or 0, TC.DefaultBoolBoxType);
end

function Ops.get_attr(TC, Object, Class, Name)
    if (Name.Value ~= nil) then
        Name = Ops.unbox_str(TC, Name);
    end
    return Object.STable.REPR:get_attribute(TC, Object, Class, Name);
end

function get_attr_with_hint(TC, Object, Class, name, Hint)
    return Object.STable.REPR:get_attribute_with_hint(TC, Object, Class, Name, Hint);
end

function Ops.bind_attr(TC, Object, Class, Name, Value)
    if (Name.Value ~= nil) then
        Name = Ops.unbox_str(TC, Name);
    end
    Object.STable.REPR:bind_attribute(TC, Object, Class, Name, Value);
    return Value;
end


function Ops.bind_attr_with_hint(TC, Object, Class, Name, Value, Hint)
    if (Name.Value ~= nil) then
        Name = Ops.unbox_str(TC, Name);
    end
    Object.STable.REPR:bind_attribute_with_hint(TC, Object, Class, Name, Value);
    return Value;
end

function Ops.find_method(TC, Object, Name)
    return Object.STable:FindMethod(TC, Object, Name, Hints.NO_HINT);
end

function Ops.find_method_with_hint(TC, Object, Name, Hint)
    return Object.STable:FindMethod(TC, Object, Name, Hint);
end

function Ops.invoke(TC, Invokee, Capture)
    return Invokee.STable.Invoke(TC, Invokee, Capture);
end

function Ops.get_how(TC, Obj)
    return Obj.STable.HOW;
end

function Ops.get_what(TC, Obj)
    return Obj.STable.WHAT;
end

function Ops.type_check(TC, ToCheck, WantedType)
    return ToCheck.STable:TypeCheck(TC, ToCheck, WantedType);
end

function Ops.publish_type_check_cache(TC, WHAT, TypeList)
    WHAT.STable.TypeCheckCache = TypeList.Storage;
end

function Ops.publish_method_cache(TC, WHAT, MethodCacheHash)
    WHAT.STable.MethodCache = MethodCacheHash.Storage;
    return MethodCacheHash;
end
