CodeObjectUtility = {};

function CodeObjectUtility.WrapNativeMethod (Code)
    local Wrapper = REPRRegistry.get_REPR_by_name("KnowHOWREPR"):type_object_for(nil, nil);
    Wrapper.STable.SpecialInvoke = Code;
    return Wrapper;
end

function CodeObjectUtility.BuildStaticBlockInfo (Code, Outer, LexNames)
    local Result = CodeObjectUtility.LLCodeTypeObject.STable.REPR:instance_of(nil, CodeObjectUtility.LLCodeTypeObject);
    Result.Body = Code;
    Result.OuterBlock = Outer;
    Result.StaticLexPad = Lexpad.new(LexNames);
    return Result;
end
