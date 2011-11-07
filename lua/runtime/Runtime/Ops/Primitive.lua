function Ops.logical_not_int(TC, x)
    return x == 0 and 1 or 0;
end
Ops[73] = Ops.logical_not_int;

function Ops.add_int(TC, x, y)
    return x + y;
end
Ops[74] = Ops.add_int;

function Ops.sub_int(TC, x, y)
    return x - y;
end
Ops[75] = Ops.sub_int;

function Ops.mul_int(TC, x, y)
    return x * y;
end
Ops[76] = Ops.mul_int;

function Ops.div_int(TC, x, y)
    return x / y;
end
Ops[77] = Ops.div_int;

function Ops.mod_int(TC, x, y)
    return x % y;
end
Ops[78] = Ops.mod_int;

function Ops.add_num(TC, x, y)
    return Ops.box_num(TC, Ops.unbox_num(TC, x) + Ops.unbox_num(TC, y), TC.DefaultNumBoxType);
end
Ops[79] = Ops.add_num;

function Ops.sub_num(TC, x, y)
    return Ops.box_num(TC, Ops.unbox_num(TC, x) - Ops.unbox_num(TC, y), TC.DefaultNumBoxType);
end
Ops[80] = Ops.sub_num;

function Ops.mul_num(TC, x, y)
    return Ops.box_num(TC, Ops.unbox_num(TC, x) * Ops.unbox_num(TC, y), TC.DefaultNumBoxType);
end
Ops[81] = Ops.mul_num;

function Ops.div_num(TC, x, y)
    return Ops.box_num(TC, Ops.unbox_num(TC, x) / Ops.unbox_num(TC, y), TC.DefaultNumBoxType);
end
Ops[82] = Ops.div_num;

function Ops.bitwise_or_int(TC, x, y)
    return Ops.box_int(TC, bit.bor(Ops.unbox_int(TC, x), Ops.unbox_int(TC, y)), TC.DefaultIntBoxType);
end
Ops[83] = Ops.bitwise_or_int;

function Ops.bitwise_and_int(TC, x, y)
    return Ops.box_int(TC, bit.band(Ops.unbox_int(TC, x), Ops.unbox_int(TC, y)), TC.DefaultIntBoxType);
end
Ops[84] = Ops.bitwise_and_int;

function Ops.bitwise_xor_int(TC, x, y)
    return Ops.box_int(TC, bit.bxor(Ops.unbox_int(TC, x), Ops.unbox_int(TC, y)), TC.DefaultIntBoxType);
end
Ops[85] = Ops.bitwise_xor_int;

function Ops.concat(TC, x, y)
    return Ops.box_str(TC, Ops.unbox_str(TC, x) .. Ops.unbox_str(TC, y), TC.DefaultStrBoxType);
end
Ops[86] = Ops.concat;

-- skip num bitwise

function Ops.substr(TC, x, y, z)
    local str;
    local REPR = z.STable.REPR;
    if (z ~= nil and REPR.defined(REPR, TC, z)) then
        str = Ops.unbox_str(TC, x):sub(Ops.unbox_int(TC, y) + 1, Ops.unbox_int(TC, z) + 1);
    else
        str = Ops.unbox_str(TC, x):sub(Ops.unbox_int(TC, y) + 1);
    end
    return Ops.box_str(TC, str, TC.DefaultStrBoxType);
end
Ops[87] = Ops.substr;
-- skip format_str

function Ops.index_str(TC, x, y)
    return Ops.box_int(TC, Ops.unbox_str(TC, x).find(Ops.unbox_str(TC, y)) - 1);
end
Ops[88] = Ops.index_str;

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
        List.Add(Store, Ops.box_str(TC, v, TC.DefaultStrBoxType));
    end
    return list;
end
Ops[89] = Ops.split_str;
