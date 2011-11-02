
function makeSharedTable ()
    local SharedTable = {};
    local mt = { __index = SharedTable };
    local TypeCacheIDSource = 4;
    function SharedTable.new()
        local sharedTable = {};
        TypeCacheIDSource = TypeCacheIDSource + 4;
        sharedTable.TypeCacheID = TypeCacheIDSource;
        return setmetatable(sharedTable, mt);
    end
    function SharedTable:FindMethod(TC, Obj, Name, Hint)
        local CachedMethod;

        -- Does this s-table have a special overridden finder?
        if (self.SpecialFindMethod ~= nil) then
            return self.SpecialFindMethod(TC, Obj, Name, Hint);
        end

        -- See if we can find it by hint.
        if (Hint ~= Hints.NO_HINT and Obj.STable.VTable ~= nil and Hint < Obj.STable.VTable.Length) then
            -- Yes, just grab it from the v-table.
            return Obj.STable.VTable[Hint];
        
        -- Otherwise, try method cache.
        elseif (self.MethodCache ~= nil and self.MethodCache[Name] ~= nil) then
            return self.MethodCache[Name];

        -- Otherwise, go ask the meta-object.
        else
            -- Find the find_method method.
            local HOW = Obj.STable.HOW;
            local Meth = Obj.STable.CachedFindMethod;
            if (Meth ~= nil) then
                Meth = self.HOW.STable.FindMethod(
                    TC, HOW, "find_method", Hints.NO_HINT);
                Obj.STable.CachedFindMethod = Meth;
            end

            -- Call it.
            local Cap = CaptureHelper.FormWith({ HOW, Obj, Ops.box_str(TC, Name, TC.DefaultStrBoxType) });
            return Meth.STable.Invoke(TC, Meth, Cap);
        end
    end
    return SharedTable;
end
SharedTable = makeSharedTable();
