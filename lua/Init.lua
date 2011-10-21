dofile('List.lua');
dofile('Dictionary.lua');
dofile('REPRRegistry.lua');
dofile('SharedTable.lua');
dofile('KnowHOWBootstrapper.lua');
bit = require("bit");

function makeInit ()
    local Init = {};
    local mt = {};
    local REPRS_Registered = false;
    function Init.new()
        return setmetatable({}, mt);
    end
    function Init.Initialize(SettingName)
        Init.RegisterRepresentations();
        local KnowHOW = KnowHOWBootstrapper.Bootstrap();
        local KnowHOWAttribute = KnowHOWBootstrapper.SetupKnowHOWAttribute(KnowHOW);

        -- See if we're to load a setting or use the fake bootstrapping one.
        local SettingContext;
        if (SettingName == nil) then
            SettingContext = BootstrapSetting(KnowHOW, KnowHOWAttribute);
        else
            SettingContext = LoadSetting(SettingName, KnowHOW, KnowHOWAttribute);
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
    if not REPRS_Registered then do
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
        end end
    end
    return Init;
end
Init = makeInit();

