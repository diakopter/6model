function makeDictionary ()
    local Dictionary = {};
    local mt = {};
    function Dictionary.new()
        return setmetatable({}, mt);
    end
    function Dictionary:Add(key, value)
        self[key] = value;
    end
    return Dictionary;
end
Dictionary = makeDictionary();
