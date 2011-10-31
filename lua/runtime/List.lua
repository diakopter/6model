function makeList ()
    local List = {};
    local mt = { __index = List };
    function List.new(count)
        local list = {};
        list.Count = count ~= nil and count or 0;
        return setmetatable(list, mt);
    end
    function List:Add(item)
        -- stupid one-indexing
        self[self.Count + 1] = item;
        self.Count = self.Count + 1;
    end
    List.Push = List.Add;
    function List:Pop()
        local idx = self.Count;
        if (idx < 1) then
            error("Cannot pop from an empty list");
        end
        local item = self[idx];
        self[idx] = nil;
        self.Count = self.Count - 1;
        return item;
    end
    function List:Truncate(length)
        local count = self.Count;
        if (length < count) then
            for i = length + 1, count do
                self[i] = nil;
            end
        end
        self.Count = length;
        return self;
    end
    
    function List:Shift()
        local idx = self.Count;
        if (idx < 1) then
            error("Cannot shift from an empty list");
        end
        local item = self[1];
        for i = 2, idx do
            self[i - 1] = self[i];
        end
        self[idx] = nil;
        return item;
    end

    function List:Unshift(item)
        for i = self.Count, 1, -1 do
            store[i + 1] = store[i];
        end
        store[1] = item;
        return item;
    end
    return List;
end
List = makeList();


