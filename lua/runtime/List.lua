function makeList ()
    local List = {};
    local mt = { __index = List };
    function List.new(count)
        local list = {};
        list.Count = count ~= nil and count or 0;
        return setmetatable(list, mt);
    end
    function List:Add(item)
        self.Count = self.Count + 1;
        self[self.Count] = item;
    end
    function List:Push(item)
        self.Count = self.Count + 1;
        self[self.Count] = item;
    end
    function List:Pop()
        local idx = self.Count;
        if (idx < 1) then
            error("Cannot pop from an empty list");
        end
        self.Count = self.Count - 1;
        return table.remove(self, idx);
    end
    function List:Peek()
        local idx = self.Count;
        if (idx < 1) then
            error("Cannot peek into an empty list");
        end
        return self[idx];
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
        self.Count = self.Count - 1;
        if (idx < 1) then
            error("Cannot shift from an empty list");
        end
        local item = self[1];
        for i = 2, idx do
            self[i - 1] = self[i];
        end
        table.remove(self, idx);
        return item;
    end
    function List:Unshift(item)
        if (self.Count > 0) then
            for i = self.Count, 1, -1 do
                self[i + 1] = self[i];
            end
        end
        self[1] = item;
        self.Count = self.Count + 1;
        return item;
    end
    return List;
end
List = makeList();


