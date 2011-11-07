function makeDictionary ()
    local Dictionary = {};
    local mt = { __index = Dictionary };
    function Dictionary.new ()
        return setmetatable({}, mt);
    end
    Dictionary[1] = Dictionary.new;
    function Dictionary:Add (key, value)
        self[key] = value;
    end
    Dictionary[2] = Dictionary.Add;
    return Dictionary;
end
Dictionary = makeDictionary();
