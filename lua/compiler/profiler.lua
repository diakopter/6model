local Counters = {}
local Names = {}

local function hook ()
    local f = debug.getinfo(2, "f").func
    if Counters[f] == nil then
        Counters[f] = 1
        Names[f] = debug.getinfo(2, "Sn")
    else
        Counters[f] = Counters[f] + 1
    end
end

local f = assert(loadfile(arg[1]))
debug.sethook(hook, "c")
f()
debug.sethook()

function getname (func)
    local n = Names[func]
    if n.what == "C" then
        return n.names
    end
    local lc = string.format("%s:%s", n.short_src, n.linedefined)
    if n.namewhat ~= "" then
        return string.format("%s:%s", lc, n.name)
    else
        return lc
    end
end

function strsplit(delimiter, text)
  local list = {}
  local pos = 1
  if string.find("", delimiter, 1) then -- this would result in endless loops
    error("delimiter matches empty string!")
  end
  while 1 do
    local first, last = string.find(text, delimiter, pos)
    if first then -- found?
      table.insert(list, string.sub(text, pos, first-1))
      pos = last+1
    else
      table.insert(list, string.sub(text, pos))
      break
    end
  end
  return list
end

local Results = {}
for func, count in pairs(Counters) do
    local name = getname(func)
    if name ~= nil then
        if Results[name] == nil then
            Results[name] = 0
        end
        Results[name] = Results[name] + count
    end
end

local files = {}
function getline (filename, lineno)
    if files[filename] == nil then
        local lines = {}
        local index = 1
        for line in io.lines(filename) do
            lines[index] = line
            index = index + 1
        end
        files[filename] = lines;
    end
    return files[filename][lineno]
end
local SortedResults = {}
local index = 1
for marker, count in pairs(Results) do
    local splitted = strsplit(":", marker)
    local filename = splitted[1]
    local lineno = 0 + splitted[2]
    local line = getline(filename, lineno)
    if line ~= nil and string.match(line, "function %(") and lineno > 1 then
        line = getline(filename, lineno - 1) .. "\n" .. line
    end
    if count > 100 then
        SortedResults[index] = { marker, count, line }
        index = index + 1
    end
end

table.sort(SortedResults, function (l, r)
    return l[2] > r[2]
end)

for _,v in ipairs(SortedResults) do
    print(v[1], v[2], "\n", v[3], "\n")
    --print(v[1], v[2], "\n")
end