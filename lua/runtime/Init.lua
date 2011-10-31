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

    return Init;
end
Init = makeInit();

