function makeList ()
    local List = {};
    local mt = { __index = List };
    function List.new()
        local list = {};
        list.Count = 0;
        return setmetatable(list, mt);
    end
    function List:Add(item)
        -- stupid one-indexing
        self[self.Count + 1] = item;
        self.Count = self.Count + 1;
    end
    return List;
end
List = makeList();


