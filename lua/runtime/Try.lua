-- originally from http://failboat.me/2010/lua-exception-handling/

E = {}
setmetatable(E, {__index = function(self,k) return k end})

function try_catch_finally(try, exception_class, catch, finally)
    local ok, exception = pcall(try)
    local caught = false
    if catch ~= nil and not ok then
        local is_table = type(exception) == "table"
        if is_table and exception.class == exception_class or not is_table then
            caught = true
            catch(exception_class, nil, exception)
		end
    end
    if finally ~= nil then
        finally()
    end
    if exception ~= nil and not caught then
        error(exception)
    end
end

__exceptions = {
}
