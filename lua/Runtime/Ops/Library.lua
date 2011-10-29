function Ops.load_module(TC, Path)
    local module = dofile(Ops.unbox_str(TC, Path));
    -- This remains to be done correctly..
    return module.Load(TC, TC.Domain.Setting);
end

