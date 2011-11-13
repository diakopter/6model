bit = require("bit"); -- in LuaJit only (yay)
icu = require("icu"); -- requires icu4lua (and the icu library)
icu.collator = require('icu.collator');
icu.idna = require('icu.idna');
icu.normalizer = require('icu.normalizer');
icu.regex = require('icu.regex');
icu.stringprep = require('icu.stringprep');
icu.ufile = require('icu.ufile');
icu.ustring = require('icu.ustring');
icu.utf8 = require('icu.utf8');

function table_clone (target)
    local dest = {};
    for k,v in pairs(target) do
        dest[k] = v;
    end
    return dest;
end

-- say debug_get("l") in the repl to find the innermost "l" variable
function debug_get (var)
    local i = 1
    while true do
        local j = 1
        while true do
            local k, v = debug.getlocal(i, j)
            if k == nil then break end
            if k == var then return v end
            j = j + 1;
        end
        i = i + 1
    end
end

function debug_flat (obj)
    local out = {}
    for k, v in pairs(obj) do
        -- flatten Storage info into the result
        if k == "Storage" then
            for ks, vs in pairs(v) do
                -- for P6opaque, merge all per-class attribute lists together
                if type(ks) == "table" then
                    for kss, vss in pairs(vs) do
                        out[kss] = vss
                    end
                else
                    out[ks] = vs
                end
            end
        else
            out[k] = v
        end
    end
    return out
end

function table_desc (target)
    if (type(target) == "nil") then
        print("table_desc target was nil");
    elseif (type(target) ~= "table") then
        print("table_desc target wasn't a table; it was a " .. type(target));
    else
        print("table_desc : " .. tostring(target));
        keys = {}
        for k,_ in pairs(target) do table.insert(keys, k) end
        table.sort(keys, function (k1, k2) return tostring(k1) < tostring(k2) end)
        for _,k in ipairs(keys) do print("   " .. tostring(k) .. " : " .. tostring(target[k])) end
    end
end

function makeInit ()
    local Init = {};
    -- mimic behavior of private static.
    local REPRS_Registered = false;
    
    function Init.Initialize(SettingName)
        Init.RegisterRepresentations();
        local KnowHOW = KnowHOWBootstrapper.Bootstrap();
        local KnowHOWAttribute = KnowHOWBootstrapper.SetupKnowHOWAttribute(KnowHOW);

        -- See if we're to load a setting or use the fake bootstrapping one.
        local SettingContext;
        if (SettingName == nil) then
            SettingContext = Init.BootstrapSetting(KnowHOW, KnowHOWAttribute);
        else
            SettingContext = Init.LoadSetting(SettingName, KnowHOW, KnowHOWAttribute);
        end
        

        -- Cache native capture and LLCode type object.
        local lexpad = SettingContext.LexPad;
        CaptureHelper.CaptureTypeObject = lexpad.GetByName(lexpad, "capture");
        CodeObjectUtility.LLCodeTypeObject = lexpad.GetByName(lexpad, "NQPCode");

        -- Create an execution domain and a thread context for it.
        local ExecDom = ExecutionDomain.new();
        ExecDom.Setting = SettingContext;
        local Thread = ThreadContext.new();
        Thread.Domain = ExecDom;
        Thread.CurrentContext = SettingContext;
        Thread.DefaultBoolBoxType = lexpad.GetByName(lexpad, "NQPInt");
        Thread.DefaultIntBoxType = lexpad.GetByName(lexpad, "NQPInt");
        Thread.DefaultNumBoxType = lexpad.GetByName(lexpad, "NQPNum");
        Thread.DefaultStrBoxType = lexpad.GetByName(lexpad, "NQPStr");
        Thread.DefaultListType = lexpad.GetByName(lexpad, "NQPList");
        Thread.DefaultArrayType = lexpad.GetByName(lexpad, "NQPArray");
        Thread.DefaultHashType = lexpad.GetByName(lexpad, "NQPHash");

        return Thread;
    end
    Init[1] = Init.Initialize;
    
    function Init.RegisterRepresentations()
    if not REPRS_Registered then
        REPRRegistry.register_REPR("KnowHOWREPR", KnowHOWREPR.new());
        REPRRegistry.register_REPR("P6opaque", P6opaque.new());
        REPRRegistry.register_REPR("P6hash", P6hash.new());
        REPRRegistry.register_REPR("P6int", P6int.new());
        REPRRegistry.register_REPR("P6num", P6num.new());
        REPRRegistry.register_REPR("P6str", P6str.new());
        REPRRegistry.register_REPR("P6capture", P6capture.new());
        REPRRegistry.register_REPR("RakudoCodeRef", RakudoCodeRef.new());
        REPRRegistry.register_REPR("P6list", P6list.new());
        REPRRegistry.register_REPR("P6mapping", P6mapping.new());
        REPRS_Registered = true;
        end
    end
    Init[2] = Init.RegisterRepresentations;
    
    function Init.BootstrapSetting(KnowHOW, KnowHOWAttribute)
        local SettingContext = Context.newplain();
        local P6capture = REPRRegistry.get_REPR_by_name("P6capture");
        local P6int = REPRRegistry.get_REPR_by_name("P6int");
        local P6num = REPRRegistry.get_REPR_by_name("P6num");
        local P6str = REPRRegistry.get_REPR_by_name("P6str");
        local P6list = REPRRegistry.get_REPR_by_name("P6list");
        local RakudoCodeRef = REPRRegistry.get_REPR_by_name("RakudoCodeRef");
        local tmp1 = KnowHOW.STable.REPR;
        SettingContext.LexPad = Lexpad.new(
            { "KnowHOW", "KnowHOWAttribute", "capture", "NQPInt", "NQPNum", "NQPStr", "NQPList", "NQPCode", "list", "NQPArray", "NQPHash" });
        SettingContext.LexPad.Storage = 
            {
                KnowHOW,
                KnowHOWAttribute,
                P6capture.type_object_for(P6capture, nil, nil),
                P6int.type_object_for(P6int, nil, nil),
                P6num.type_object_for(P6num, nil, nil),
                P6str.type_object_for(P6str, nil, nil),
                P6list.type_object_for(P6list, nil, nil),
                RakudoCodeRef.type_object_for(RakudoCodeRef, nil, tmp1.instance_of(tmp1, nil, KnowHOW)),
                CodeObjectUtility.WrapNativeMethod(function (TC, self, C)
                    local NQPList = Ops.get_lex(TC, "NQPList");
                    local tmp1 = NQPList.STable.REPR;
                    local List = tmp1.instance_of(tmp1, TC, NQPList);
                    local NativeCapture = C;
                    for unused, Obj in ipairs(NativeCapture.Positionals) do
                        List.Storage:Add(Obj);
                    end
                    return List;
                end),
                nil,
                nil
            };
        return SettingContext;
    end
    Init[3] = Init.BootstrapSetting;
    
    function Init.LoadSetting(Name, KnowHOW, KnowHOWAttribute)
        local success, SettingContext;
        --success = pcall(function ()
        --    dofile(Name .. '.lbc')
        --end);
        if not success then
            dofile(Name .. '.lua');
        end
        SettingContext = LastLoadSetting();
        local lexpad = SettingContext.LexPad;
        lexpad.Extend(lexpad,
            { "KnowHOW", "KnowHOWAttribute", "print", "say", "capture" });
        lexpad.SetByName(lexpad, "KnowHOW", KnowHOW);
        lexpad.SetByName(lexpad, "KnowHOWAttribute", KnowHOWAttribute);
        lexpad.SetByName(lexpad, "print",
        CodeObjectUtility.WrapNativeMethod(function (TC, self, C)
                for i = 1, CaptureHelper.NumPositionals(C) do
                    local Value = CaptureHelper.GetPositional(C, i);
                    local STable = self.STable;
                    local StrMeth = STable.FindMethod(STable, TC, Value, "Str", 0);
                    STable = StrMeth.STable;
                    local StrVal = STable.Invoke(STable, TC, StrMeth,
                        CaptureHelper.FormWith( { Value }));
                    io.write(Ops.unbox_str(nil, StrVal));
                end
                return CaptureHelper.Nil(TC);
            end));
        lexpad.SetByName(lexpad, "say",
        CodeObjectUtility.WrapNativeMethod(function (TC, self, C)
                for i = 1, CaptureHelper.NumPositionals(C) do
                    local Value = CaptureHelper.GetPositional(C, i);
                    local STable = self.STable;
                    local StrMeth = STable.FindMethod(STable, TC, Value, "Str", 0);
                    STable = StrMeth.STable;
                    local StrVal = STable.Invoke(STable, TC, StrMeth,
                        CaptureHelper.FormWith( { Value }));
                    io.write(Ops.unbox_str(nil, StrVal), "\n");
                end
                return CaptureHelper.Nil(TC);
            end));
        local REPR = REPRRegistry.get_REPR_by_name("P6capture");
        lexpad.SetByName(lexpad, "capture", REPR.type_object_for(REPR, nil, nil));
        
        return SettingContext;
    end
    Init[4] = Init.LoadSetting;
    
    return Init;
end
Init = makeInit();

