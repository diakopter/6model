KnowHOWBootstrapper = {};

function KnowHOWBootstrapper.Bootstrap ()
    local REPR = REPRRegistry.get_REPR_by_name("KnowHOWREPR");
    local KnowHOW = REPR.type_object_for(REPR, nil, nil);
    
    local KnowHOWMeths = {};
    KnowHOWMeths.new_type = CodeObjectUtility.WrapNativeMethod(
        function (TC, Ignored, Cap)
            local KnowHOWTypeObj = CaptureHelper.GetPositional(Cap, 1);
            local REPR = KnowHOWTypeObj.STable.REPR;
            local HOW = REPR.instance_of(REPR, TC, KnowHOWTypeObj.STable.WHAT);
            
            local TypeName = CaptureHelper.GetNamed(Cap, "name");
            HOW.Name = TypeName or Ops.box_str(TC, "<anon>");
            
            local REPRName = CaptureHelper.GetNamed(Cap, "repr");
            if (REPRName ~= nil) then
                REPR = REPRRegistry.get_REPR_by_name(Ops.unbox_str(nil, REPRName));
                return REPR.type_object_for(REPR, nil, HOW);
            else
                REPR = REPRRegistry.get_REPR_by_name("P6opaque");
                return REPR.type_object_for(REPR, TC, HOW);
            end
        end);
    KnowHOWMeths.add_attribute = CodeObjectUtility.WrapNativeMethod(
        function (TC, Ignored, Cap)
            local HOW = CaptureHelper.GetPositional(Cap, 1);
            local Attr = CaptureHelper.GetPositional(Cap, 3);
            List.Add(HOW.Attributes, Attr);
            return CaptureHelper.Nil(TC);
        end);
    KnowHOWMeths.add_method = CodeObjectUtility.WrapNativeMethod(
        function (TC, Ignored, Cap)
            local HOW = CaptureHelper.GetPositional(Cap, 1);
            local Name = CaptureHelper.GetPositionalAsString(Cap, 3);
            local Method = CaptureHelper.GetPositional(Cap, 4);
            HOW.Methods[Name] = Method;
            return CaptureHelper.Nil(TC);
        end);
    KnowHOWMeths.find_method = CodeObjectUtility.WrapNativeMethod(
        function (TC, Ignored, Cap)
            local Positionals = Cap.Positionals;
            local HOW = Positionals[1];
            local name = Ops.unbox_str(TC, Positionals[3]);
            if (HOW.Methods[name] ~= nil) then
                return HOW.Methods[name];
            else
                local knowhowName;
                if (type(HOW.Name) == "table") then
                    knowhowName = Ops.unbox_str(TC, HOW.Name);
                else
                    knowhowName = HOW.Name or "(no name available)";
                end
                error("No method '"..name.."' found in knowhow '"..knowhowName.."'");
            end
        end);
    KnowHOWMeths.compose = CodeObjectUtility.WrapNativeMethod(
        function (TC, Ignored, Cap)
            local HOW = CaptureHelper.GetPositional(Cap, 1);
            local Obj = CaptureHelper.GetPositional(Cap, 2);
            Obj.STable.MethodCache = HOW.Methods;
            return Obj;
        end);
    KnowHOWMeths.attributes = CodeObjectUtility.WrapNativeMethod(
        function (TC, Ignored, Cap)
            local HOW = CaptureHelper.GetPositional(Cap, 1);
            local ListType = KnowHOWBootstrapper.MostDefinedListType(TC);
            local REPR = ListType.STable.REPR;
            local Result = REPR.instance_of(REPR, TC, ListType);
            Result.Storage = HOW.Attributes;
            return Result;
        end);
    KnowHOWMeths.methods = CodeObjectUtility.WrapNativeMethod(
        function (TC, Ignored, Cap)
            local HOW = CaptureHelper.GetPositional(Cap, 1);
            local ListType = KnowHOWBootstrapper.MostDefinedListType(TC);
            local REPR = ListType.STable.REPR;
            local Result = REPR.instance_of(REPR, TC, ListType);
            local store = Result.Storage;
            for key, value in pairs(HOW.Methods) do
                List.Add(store, value);
            end
            return Result;
        end);
    KnowHOWMeths.parents = CodeObjectUtility.WrapNativeMethod(
        function (TC, Ignored, Cap)
            local ListType = KnowHOWBootstrapper.MostDefinedListType(TC);
            local REPR = ListType.STable.REPR;
            return REPR.instance_of(REPR, TC, ListType);
        end);
    KnowHOWMeths.type_check = CodeObjectUtility.WrapNativeMethod(
        function (TC, Ignored, Cap)
            local self = CaptureHelper.GetPositional(Cap, 2);
            local check = CaptureHelper.GetPositional(Cap, 3);
            return Ops.box_int(TC, self.STable.WHAT == check.STable.WHAT and 1 or 0, TC.DefaultBoolBoxType);
        end);
    
    local KnowHOWHOW = REPR.instance_of(REPR, nil, KnowHOW);
    for key, value in pairs(KnowHOWMeths) do
        KnowHOWHOW.Methods[key] = value;
    end
    
    local STableCopy = SharedTable.new();
    STableCopy.HOW = KnowHOWHOW;
    STableCopy.WHAT = KnowHOW.STable.WHAT;
    STableCopy.REPR = KnowHOW.STable.REPR;
    KnowHOWHOW.STable = STableCopy;
    
    KnowHOWHOW.STable.SpecialFindMethod = function (TC, Obj, Name, Hint)
        local MTable = Obj.Methods;
        if (MTable[Name] ~= null) then
            return MTable[Name];
        end
        error("No such method "..Name);
    end
    
    KnowHOW.STable.HOW = KnowHOWHOW;
    
    return KnowHOW;
end

function KnowHOWBootstrapper.SetupKnowHOWAttribute (KnowHOW)
    local REPR = KnowHOW.STable.REPR;
    local HOW = REPR.instance_of(REPR, nil, KnowHOW);

    REPR = REPRRegistry.get_REPR_by_name("P6str");
    local KnowHOWAttribute = REPR.type_object_for(REPR, null, HOW);

    HOW.Methods.new = CodeObjectUtility.WrapNativeMethod(
        function (TC, Code, Cap)
            local WHAT = CaptureHelper.GetPositional(Cap, 1).STable.WHAT;
            local Name = Ops.unbox_str(TC, CaptureHelper.GetNamed(Cap, "name"));
            return Ops.box_str(TC, Name, WHAT);
        end);
    HOW.Methods.name = CodeObjectUtility.WrapNativeMethod(
        function (TC, Code, Cap)
            local self = CaptureHelper.GetPositional(Cap, 1);
            return Ops.box_str(TC, Ops.unbox_str(TC, self), TC.DefaultStrBoxType);
        end);

    return KnowHOWAttribute;
end

function KnowHOWBootstrapper.MostDefinedListType (TC)
    if (TC.DefaultListType.STable.HOW ~= nil) then
        return TC.DefaultListType;
    end
    
    TC.DefaultListType = Ops.get_lex(TC, "NQPList");
    return TC.DefaultListType;
end






