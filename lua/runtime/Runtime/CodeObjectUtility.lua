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
    Result.Body = Code;
    Result.OuterBlock = Outer;
    Result.BlockName = BlockName;
    Result.StaticLexPad = Lexpad.new(LexNames);
    return Result;
end
