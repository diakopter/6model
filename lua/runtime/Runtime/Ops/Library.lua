function Ops.load_module (TC, Path)
    local Name = Ops.unbox_str(TC, Path);
    local success;
    --success = pcall(function ()
    --    dofile(Name .. '.lbc')
    --end);
    if not success then
        dofile(Name .. '.lua');
    end
    return LastLoad(TC, TC.Domain.Setting);
end
Ops[42] = Ops.load_module;
