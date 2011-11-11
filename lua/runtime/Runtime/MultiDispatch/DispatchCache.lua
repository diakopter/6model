
function makeDispatchCache ()
    local DispatchCache = { ["class"] = "DispatchCache" };
    local mt = { __index = DispatchCache };
    local MAX_ARITY = 3;
    local MAX_ENTRIES = 15;
    
    local makeArityCache = function ()
        local ArityCache = { ["class"] = "ArityCache" };
        local mt = { __index = ArityCache };
        function ArityCache.new (STable)
            local this = {};
            this.NumEntries = 0;
            return setmetatable(this, mt);
        end
        ArityCache[1] = ArityCache.new;
        return ArityCache;
    end
    local ArityCache = makeArityCache();
    function DispatchCache.new ()
        local this = {};
        this.ArityCaches = List.create(MAX_ARITY + 1);
        return setmetatable(this, mt);
    end
    local PositionalsToTypeCacheIDs;
    DispatchCache[1] = DispatchCache.new;
    function DispatchCache:Lookup (Positionals)
        if (Positionals.Count <= MAX_ARITY) then
            local Cache = self.ArityCaches[Positionals.Count];
            if (Cache ~= nil and Cache.NumEntries ~= 0) then
                local Seeking = PositionalsToTypeCacheIDs(Positionals);
                
                local ci = 1;
                for ri = 1, Cache.NumEntries do
                    local Matched = true;
                    for j = 1, Positionals.Count do
                        if (Seeking[j] ~= Cache.TypeIDs[ci]) then
                            Matched = false;
                            break;
                        end
                        ci = ci + 1;
                    end
                    if (Matched) then
                        return Cache.Results[ri];
                    end
                end
            end
        end
        return nil;
    end
    DispatchCache[2] = DispatchCache.Lookup;
    function DispatchCache:Add (Positionals, Result)
        if (Positionals.Count <= MAX_ARITY) then
            local ToAdd = PositionalsToTypeCacheIDs(Positionals);
            local ToAddCount = ToAdd.Count;
            
            local Previous = self.ArityCaches[Positionals.Count];
            
            local New = ArityCache.new();
            if (Previous == nil) then
                New.NumEntries = 1;
                New.Results = List.create(MAX_ENTRIES + 1);
                New.TypeIDs = List.create(MAX_ENTRIES * Positionals.Count);
                for i = 1, ToAdd.Count do
                    New.TypeIDs[i] = ToAdd[i];
                end
                New.Results[1] = Result;
            else
                New.NumEntries = Previous.NumEntries;
                New.TypeIDs = List.Clone(Previous.TypeIDs);
                New.Results = List.Clone(Previous.Results);
                
                if (New.NumEntries <= MAX_ENTRIES) then
                    local i = 1;
                    local j = New.NumEntries * ToAdd.Count;
                    while (i <= ToAddCount) do
                        New.TypeIDs[j] = ToAdd[i];
                        i = i + 1;
                        j = j + 1;
                    end
                    New.Results[New.NumEntries] = Result;
                    New.NumEntries = New.NumEntries + 1;
                else
                    local Evictee = math.random(MAX_ENTRIES + 1);
                    local i = 1;
                    local j = Evictee * ToAddCount;
                    while (i <= ToAddCount) do
                        New.TypeIDs[j] = ToAdd[i];
                        i = i + 1;
                        j = j + 1;
                    end
                    New.Results[Evictee] = Result;
                end
            end
            
            if (self.ArityCaches[ToAddCount] == Previous) then
                self.ArityCaches[ToAddCount] = New;
            end
        end
    end
    PositionalsToTypeCacheIDs = function (Positionals)
        local Result = List.create(Positionals.Count);
        for i = 1, Positionals.Count do
            local STable = Positionals[i].STable;
            local REPR = STable.REPR;
            Result[i] = bit.bor(STable.TypeCacheID, REPR.defined(REPR, nil, Positionals[i]) and 1 or 0);
        end
        return Result;
    end
    return DispatchCache;
end
DispatchCache = makeDispatchCache();
