
function makeSharedTable ()
    local SharedTable = {};
    --local mt = { __index = SharedTable };
    local TypeCacheIDSource = 4;
    local FindMethod = function (self, TC, Obj, Name, Hint)
        local CachedMethod;

        -- Does this s-table have a special overridden finder?
        if (self.SpecialFindMethod ~= nil) then
            return self.SpecialFindMethod (TC, Obj, Name, Hint);
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
            local STable = HOW.STable;
            if (Meth == nil) then
                Meth = STable.FindMethod(STable, 
                    TC, HOW, "find_method", Hints.NO_HINT);
                Obj.STable.CachedFindMethod = Meth;
            end

            -- Call it.
            local Cap = CaptureHelper.FormWith({ HOW, Obj, Ops.box_str(TC, Name, TC.DefaultStrBoxType) });
            STable = Meth.STable;
            return STable.Invoke(STable, TC, Meth, Cap);
        end
    end
    --SharedTable.FindMethod = FindMethod
    --SharedTable[2] = FindMethod;
    local Invoke = function (self, TC, Obj, Cap)
        local specialInvoke = self.SpecialInvoke;
        if (specialInvoke ~= nil) then
            return specialInvoke(TC, Obj, Cap);
        end
        local STable = Obj.STable;
        local CachedInvoke = STable.CachedInvoke;
        if (CachedInvoke == nil) then
            CachedInvoke = STable.FindMethod(STable, TC, Obj, "postcircumfix:<( )>", Hints.NO_HINT);
            STable.CachedInvoke = CachedInvoke;
        end
        STable = CachedInvoke.STable;
        return STable.Invoke(STable, TC, Obj, Cap);
    end
    --SharedTable.Invoke = Invoke;
    --SharedTable[3] = Invoke;
    local TypeCheck = function (self, TC, Obj, Checkee)
        if (self.TypeCheckCache ~= nil) then
            for i = 1, self.TypeCheckCache.Count do
                if (self.TypeCheckCache[i] == Checkee) then
                    return Ops.box_int(TC, 1, TC.DefaultBoolBoxType);
                end
            end
            return Ops.box_int(TC, 0, TC.DefaultBoolBoxType);
        else
            local STable = self.HOW.STable;
            local Checker = STable.FindMethod(STable, TC, self.HOW, "type_check", Hints.NO_HINT);
            local Cap = CaptureHelper.FormWith({ self.HOW, Obj, Checkee });
            STable = Checker.STable;
            return STable.Invoke(STable, TC, Checker, Cap);
        end
    end
    --SharedTable.TypeCheck = TypeCheck;
    --SharedTable[4] = TypeCheck;
    function SharedTable.new ()
        TypeCacheIDSource = TypeCacheIDSource + 4;
        return { nil, FindMethod, Invoke, TypeCheck, nil, nil, nil, nil, nil, nil, nil, TypeCacheIDSource };
    end
    SharedTable[1] = SharedTable.new;
    return SharedTable;
end
SharedTable = makeSharedTable();
