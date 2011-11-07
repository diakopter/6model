function makeHandler ()
    local Handler = { ["class"] = "Handler" };
    local mt = { __index = Handler };
    function Handler.new (Type, HandleBlock)
        local this = {};
        this.Type = Type;
        this.HandleBlock = HandleBlock;
        return setmetatable(this, mt);
    end
    Handler[1] = Handler.new;
    return Handler;
end
Exceptions.Handler = makeHandler();


