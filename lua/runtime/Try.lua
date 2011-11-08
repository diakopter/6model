-- originally from http://failboat.me/2010/lua-exception-handling/

local _mtg = {}
local _orig = getmetatable(_G)
function _mtg.__index(self, k)
	return rawget(self,k.."___macro")
end

E = {}
setmetatable(E, {__index = function(self,k) return k end})
E.resolve = function(exception)
	local exceptions = {GenericError = true}
	if not exception then return {} end
    if type(exception) == "table" then exception = exception.class end
	for pat, ks in pairs(__exceptions) do
		if exception:gfind(pat)() then
			for _,k in ipairs(ks) do
				exceptions[k] = true
			end
		end
	end
	return exceptions
end

local getlocals = function(func)
     local n = 1
     local locals = {}
     func = (type(func) == "number") and func + 1 or func
     while true do
          local lname, lvalue = debug.getlocal(func, n)
          if lname == nil then break end
          if lvalue == nil then lvalue = mynil end
          locals[lname] = lvalue
          n = n + 1
     end
     return locals
end

function try_catch_finally(try, exception_class, catch, finally)
    local ok = {pcall(fn)}
    local exception = nil
    if not ok[1] then
        exception = ok[2]
    end
    if catch ~= nil and exception ~= nil then
        local exps = E.resolve(exception)
        if exps[exception_class] then
			catch(exception_class, exps, exception)
		else
            error(exception)
        end
    end
    if finally ~= nil then
        finally()
    end
end

function try(fn, ...)
	local real_args = {...}
    fn = fn[1]
	--if type(fn) == "table" then fn = fn[1] end
	--if type(fn) == "string" then fn = loadstring(fn) end
	--if type(fn) ~= "function" then return nil end
	--local locals = getlocals(2)

	--for _,obj in pairs(locals) do rawset(_G,_.."___macro",obj) end
	--setmetatable(_G,_mtg)

	--local ok = {pcall(function() return fn(unpack(real_args)) end)}
	local ok = {pcall(fn)}
	--local ok = {true, fn(unpack(real_args))}

	--setmetatable(_G,_orig)
	--for k,__ in pairs(locals) do rawset(_G,k.."___macro",nil) end

	local returns = {}
	local exception = nil
	if ok[1] then
		table.remove(ok, 1)
		returns.values = ok
	else
		exception = ok[2]
	end
	returns.except = function(catch, _fn)
		if not catch then return returns.except("GenericError") end
		if type(catch) == "string" and not _fn then return function(fn) return returns.except(catch, fn) end end
		if type(catch) == "table" then _fn = catch[1]; catch = "GenericError" end
		if type(catch) == "function" then _fn = catch end
		if type(_fn) == "table" then _fn = _fn[1] end
		if not (_fn and type(_fn) == "function") then return end
		local exps = E.resolve(exception)
		--setmetatable(exps, {__tostring = function(self)
		--					local _r = "{";
		--					for k,_ in pairs(exps) do
		--						_r = _r .. k .. ", "
		--					end;
		--					return _r:sub(0,#_r-2).."}";
		--				end})
		if exps[catch] or (type(catch) ~= "string" and exception) then
			return _fn(catch, exps, exception)
		elseif exception then
			error(exception)
		else
			return unpack(returns.values)
		end
		if returns.values then
			return unpack(returns.values)
		end
	end
	returns.finally = function(catch, _fn)
		if not catch then return returns.finally("GenericError") end
		if type(catch) == "string" and not _fn then return function(fn) return returns.finally(catch, fn) end end
		if type(catch) == "table" then _fn = catch[1]; catch = "GenericError" end
		if type(catch) == "function" then _fn = catch end
		if type(_fn) == "table" then _fn = _fn[1] end
		if not (_fn and type(_fn) == "function") then return end
		local exps = E.resolve(exception)
		--setmetatable(exps, {__tostring = function(self)
		--					local _r = "{";
		--					for k,_ in pairs(exps) do
		--						_r = _r .. k .. ", "
		--					end;
		--					return _r:sub(0,#_r-2).."}";
		--				end})
		_fn(catch, exps, exception)
		if exception then
			error(exception)
		else
			return unpack(returns.values)
		end
		if returns.values then
			return unpack(returns.values)
		end
	end
	setmetatable(returns, {__call = function(self) return self.values end})
	return returns
end

__exceptions = {
	["attempt to concatenate .+"] = {
			E.ConcatenationError,
		},
	["attempt to perform arithmetic .+"] = {
			E.ArithmeticError,
	},
	["attempt to call .+"] = {
			E.FunctionError,
			E.TypeError,
	},
	["bad argument .+"] = {
			E.ParameterError,
	},
	["(.+ generator)"] = {
			E.GeneratorError,
	},
	["(a .+ value)"] = {
			E.TypeError,
			E._ValueError,
	},
	["(a function value)"] = {
			E.FunctionError,
	},
	["(a nil value)"] = {
			E.NilError,
	},
	["(a table value)"] = {
			E.TableError,
	},
	["(a number value)"] = {
			E.NumberError,
			E.ArithmeticError,
	},
	["(a string value)"] = {
			E.StringError,
	},
	[".+ local .+"] = {
			E.LocalError,
	},
	[".+ global .+"] = {
			E.GlobalError,
	},
	["assertion"] = {
			E.AssertionError,
			E._ValueError,
	},
	["no function environment"] = {
			E.EnvironmentError,
	},
	["attempt to compare .+"] = {
			E.ComparisonError,
	},
}
