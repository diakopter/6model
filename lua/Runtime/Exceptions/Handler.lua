function makeHandler ()
    local Handler = {};
    local mt = { __index = Handler };
    function Handler.new(Type, HandleBlock)
        local Handler = {};
        Handler.Type = Type;
        Handler.HandleBlock = HandleBlock;
        return setmetatable(Handler, mt);
    end
    return Handler;
end
Exceptions.Handler = makeHandler();


