CodeObjectUtility = {};

function CodeObjectUtility.WrapNativeMethod (Code)
    local REPR = REPRRegistry.get_REPR_by_name("KnowHOWREPR");
    local Wrapper = REPR.type_object_for(REPR, nil, nil);
    Wrapper.STable.SpecialInvoke = Code;
    return Wrapper;
end

function CodeObjectUtility.BuildStaticBlockInfo (Code, Outer, LexNames, BlockName)
    local REPR = CodeObjectUtility.LLCodeTypeObject.STable.REPR;
    local Result = REPR.instance_of(REPR, nil, CodeObjectUtility.LLCodeTypeObject);
    Result.Body = Code; -- 1
    Result.OuterBlock = Outer; -- 2
    Result.BlockName = BlockName; -- 3
    Result.StaticLexPad = Lexpad.new(LexNames); -- 4
    return Result;
end
