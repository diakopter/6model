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

function try_catch_finally(try, exception_class, catch, finally)
    local ok, exception = pcall(try)
    local caught = false
    if catch ~= nil and exception ~= nil then
        local exps = E.resolve(exception)
        if exps[exception_class] then
            caught = true
			catch(exception_class, exps, exception)
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
