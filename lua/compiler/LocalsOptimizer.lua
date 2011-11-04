
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

local_decl = "local l = {};";
infile = io.open(arg[1]);
input = infile:read("*a");
io.close(infile);
maxlocals = 53;

for section, text in ipairs(strsplit(local_decl, input)) do
    header = "";
    if (section == 1) then
        io.write(text);
    else
        scan = 0;
        replace = 0;
        while (scan < 12000) do
            look = "l%[" .. scan .. "%]";
            if (string.find(text, look)) then
                replace = replace + 1;
                if (replace <= maxlocals) then
                    text = string.gsub(text, look, "l" .. replace);
                else
                    text = string.gsub(text, look, "l[" .. (replace - maxlocals + 1) .. "]");
                end
                if (replace == 1) then
                    header = "\n        local l1";
                elseif (replace <= maxlocals) then
                    header = header .. ",l" .. replace;
                end
            end
            scan = scan + 1;
        end
        if (replace > maxlocals) then io.write(local_decl) end
        io.write(header .. ";" .. text);
    end
end