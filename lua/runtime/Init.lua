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
        CaptureHelper.CaptureTypeObject = SettingContext.LexPad:GetByName("capture");
        CodeObjectUtility.LLCodeTypeObject = SettingContext.LexPad:GetByName("NQPCode");

        -- Create an execution domain and a thread context for it.
        local ExecDom = ExecutionDomain.new();
        ExecDom.Setting = SettingContext;
        local Thread = ThreadContext.new();
        Thread.Domain = ExecDom;
        Thread.CurrentContext = SettingContext;
        Thread.DefaultBoolBoxType = SettingContext.LexPad:GetByName("NQPInt");
        Thread.DefaultIntBoxType = SettingContext.LexPad:GetByName("NQPInt");
        Thread.DefaultNumBoxType = SettingContext.LexPad:GetByName("NQPNum");
        Thread.DefaultStrBoxType = SettingContext.LexPad:GetByName("NQPStr");
        Thread.DefaultListType = SettingContext.LexPad:GetByName("NQPList");
        Thread.DefaultArrayType = SettingContext.LexPad:GetByName("NQPArray");
        Thread.DefaultHashType = SettingContext.LexPad:GetByName("NQPHash");

        return Thread;
    end
    
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
    
    function Init.BootstrapSetting(KnowHOW, KnowHOWAttribute)
        local SettingContext = Context.newplain();
        SettingContext.LexPad = Lexpad.new(
            { "KnowHOW", "KnowHOWAttribute", "capture", "NQPInt", "NQPNum", "NQPStr", "NQPList", "NQPCode", "list", "NQPArray", "NQPHash" });
        SettingContext.LexPad.Storage = 
            {
                KnowHOW,
                KnowHOWAttribute,
                REPRRegistry.get_REPR_by_name("P6capture"):type_object_for(nil, nil),
                REPRRegistry.get_REPR_by_name("P6int"):type_object_for(nil, nil),
                REPRRegistry.get_REPR_by_name("P6num"):type_object_for(nil, nil),
                REPRRegistry.get_REPR_by_name("P6str"):type_object_for(nil, nil),
                REPRRegistry.get_REPR_by_name("P6list"):type_object_for(nil, nil),
                REPRRegistry.get_REPR_by_name("RakudoCodeRef"):type_object_for(nil, KnowHOW.STable.REPR:instance_of(nil, KnowHOW)),
                CodeObjectUtility.WrapNativeMethod(function (TC, self, C)
                    local NQPList = Ops.get_lex(TC, "NQPList");
                    local List = NQPList.STable.REPR:instance_of(TC, NQPList);
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
    
    function Init.LoadSetting(Name, KnowHOW, KnowHOWAttribute)
        local success, SettingContext;
        --success, SettingContext = pcall(function ()
        --    dofile(Name .. '.lbc')
        --end);
        if not success then
            SettingContext = dofile(Name .. '.lua');
        end
        SettingContext.LexPad:Extend(
            { "KnowHOW", "KnowHOWAttribute", "print", "say", "capture" });
        SettingContext.LexPad:SetByName("KnowHOW", KnowHOW);
        SettingContext.LexPad:SetByName("KnowHOWAttribute", KnowHOWAttribute);
        SettingContext.LexPad:SetByName("print",
        CodeObjectUtility.WrapNativeMethod(function (TC, self, C)
                for i = 1, CaptureHelper.NumPositionals(C) do
                    local Value = CaptureHelper.GetPositional(C, i);
                    local StrMeth = self.STable:FindMethod(TC, Value, "Str", 0);
                    local StrVal = StrMeth.STable:Invoke(TC, StrMeth,
                        CaptureHelper.FormWith( { Value }));
                    io.write(Ops.unbox_str(nil, StrVal));
                end
                return CaptureHelper.Nil();
            end));
        SettingContext.LexPad:SetByName("say",
        CodeObjectUtility.WrapNativeMethod(function (TC, self, C)
                for i = 1, CaptureHelper.NumPositionals(C) do
                    local Value = CaptureHelper.GetPositional(C, i);
                    local StrMeth = self.STable:FindMethod(TC, Value, "Str", 0);
                    local StrVal = StrMeth.STable:Invoke(TC, StrMeth,
                        CaptureHelper.FormWith( { Value }));
                    io.write(Ops.unbox_str(nil, StrVal), "\n");
                end
                return CaptureHelper.Nil();
            end));
        SettingContext.LexPad:SetByName("capture", REPRRegistry.get_REPR_by_name("P6capture"):type_object_for(nil, nil));
        
        return SettingContext;
    end
    
    return Init;
end
Init = makeInit();

