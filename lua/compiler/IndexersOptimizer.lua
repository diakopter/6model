local rep = {};

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

local splitted;
for line in io.lines(arg[1]) do
    splitted = strsplit(" ", line);
    rep[splitted[1]] = splitted[2];
end

local infile = io.open(arg[2]);
local input = infile:read("*a");
infile:close();

for key, value in pairs(rep) do
    input = string.gsub(input, key, value);
end

local outfile = io.open(arg[3], "w")
outfile:write(input);
outfile:flush();
outfile:close();
