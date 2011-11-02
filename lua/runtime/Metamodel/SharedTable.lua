
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
            if (Meth == nil) then
                Meth = self.HOW.STable:FindMethod(
                    TC, HOW, "find_method", Hints.NO_HINT);
                Obj.STable.CachedFindMethod = Meth;
            end

            -- Call it.
            local Cap = CaptureHelper.FormWith({ HOW, Obj, Ops.box_str(TC, Name, TC.DefaultStrBoxType) });
            return Meth.STable:Invoke(TC, Meth, Cap);
        end
    end
    
    function SharedTable:Invoke(TC, Obj, Cap)
        if (self.SpecialInvoke ~= nil) then
            return self.SpecialInvoke(TC, Obj, Cap);
        end
        local STable = Obj.STable;
        if (STable.CachedInvoke == nil) then
            STable.CachedInvoke = Obj.STable:FindMethod(TC, Obj, "postcircumfix:<( )>", Hints.NO_HINT);
        end
        STable.CachedInvoke.STable:Invoke(TC, Obj, Cap);
    end
    
    function SharedTable:TypeCheck(TC, Obj, Checkee)
        if (self.TypeCheckCache ~= nil) then
            for i = 1, self.TypeCheckCache.Count do
                if (self.TypeCheckCache[i] == Checkee) then
                    return Ops.box_int(TC, 1, TC.DefaultBoolBoxType);
                end
            end
            return Ops.box_int(TC, 0, TC.DefaultBoolBoxType);
        else
            local Checker = HOW.STable:FindMethod(TC, HOW, "type_check", Hints.NO_HINT);
            local Cap = CaptureHelper.FormWith({ HOW, Obj, Checkee });
            return Checker.STable:Invoke(TC, Checker, Cap);
        end
    end
    
    return SharedTable;
end
SharedTable = makeSharedTable();
