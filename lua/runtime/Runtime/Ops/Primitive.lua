function Ops.logical_not_int(TC, x)
    return x == 0 and 1 or 0;
end

function Ops.add_int(TC, x, y)
    return x + y;
end

function Ops.sub_int(TC, x, y)
    return x - y;
end

function Ops.mul_int(TC, x, y)
    return x * y;
end

function Ops.div_int(TC, x, y)
    return x / y;
end

function Ops.mod_int(TC, x, y)
    return x % y;
end

function Ops.add_num(TC, x, y)
    return Ops.box_num(TC, Ops.unbox_num(TC, x) + Ops.unbox_num(TC, y), TC.DefaultNumBoxType);
end

function Ops.sub_num(TC, x, y)
    return Ops.box_num(TC, Ops.unbox_num(TC, x) - Ops.unbox_num(TC, y), TC.DefaultNumBoxType);
end

function Ops.mul_num(TC, x, y)
    return Ops.box_num(TC, Ops.unbox_num(TC, x) * Ops.unbox_num(TC, y), TC.DefaultNumBoxType);
end

function Ops.div_num(TC, x, y)
    return Ops.box_num(TC, Ops.unbox_num(TC, x) / Ops.unbox_num(TC, y), TC.DefaultNumBoxType);
end

function Ops.bitwise_or_int(TC, x, y)
    return Ops.box_int(TC, bit.bor(Ops.unbox_int(TC, x), Ops.unbox_int(TC, y)), TC.DefaultIntBoxType);
end

function Ops.bitwise_and_int(TC, x, y)
    return Ops.box_int(TC, bit.band(Ops.unbox_int(TC, x), Ops.unbox_int(TC, y)), TC.DefaultIntBoxType);
end

-- skip num bitwise

function Ops.substr(TC, x, y, z)
    local str;
    if (z ~= nil and z.STable.REPR:define(TC, z)) then
        str = Ops.unbox_str(TC, x):sub(Ops.unbox_int(TC, y) + 1, Ops.unbox_int(TC, z) + 1);
    else
        str = Ops.unbox_str(TC, x):sub(Ops.unbox_int(TC, y) + 1);
    end
    return Ops.box_str(TC, str, TC.DefaultStrBoxType);
end

-- skip format_str

function Ops.index_str(TC, x, y)
    return Ops.box_int(TC, Ops.unbox_str(TC, x).find(Ops.unbox_str(TC, y)) - 1);
end

local split = function(string, pattern)
    local vals = {};
    local valindex = 0;
    local word = "";
    local cha;
	-- need to add a trailing separator to catch the last value.
	str = str .. patt;
	for i = 1, string.len(str) do
		cha = string.sub(str, i, i)
		if cha ~= patt then
			word = word .. cha
		else
			if word ~= nil then
				vals[valindex] = word
				valindex = valindex + 1
				word = ""
			else
				-- in case we get a line with no data.
				break
			end
		end 
		
	end	
	return vals
end

function Ops.split_str(TC, x, y)
    local list = Ops.instance_of(TC, Ops.get_lex(TC, "NQPList"));
    local store = list.Storage;
    local splitted = split(Ops.unbox_str(TC, x), Ops.unbox_str(TC, y));
    for i,v in ipairs(splitted) do
        store[i] = Ops.box_str(TC, v, TC.DefaultStrBoxType);
    end
    return list;
end

