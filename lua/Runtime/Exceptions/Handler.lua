function makeHandler ()
    local Handler = {};
    local mt = { __index = Handler };
    function Handler.new(Type, HandleBlock)
        local this = {};
        this.Type = Type;
        this.HandleBlock = HandleBlock;
        return setmetatable(this, mt);
    end
    return Handler;
end
Exceptions.Handler = makeHandler();


