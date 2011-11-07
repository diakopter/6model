function Ops.multi_dispatch_over_lexical_candidates(TC)
    local CurOuter = TC.CurrentContext;
    while (CurOuter ~= nil) do
        local CodeObj = CurOuter.StaticCodeObject;
        if (CodeObj.Dispatchees ~= nil) then
            local Candidate = MultiDispatch.MultiDispatcher.FindBestCandidate(TC,
                CodeObj, CurOuter.Capture);
            local STable = Candidate.STable;
            return STable.Invoke(STable, TC, Candidate, CurOuter.Capture);
        end
        CurOuter = CurOuter.Outer;
    end
    error("Could not find dispatchee list!");
end
Ops[35] = Ops.multi_dispatch_over_lexical_candidates;

function Ops.set_dispatchees(TC, CodeObject, Dispatchees)
    CodeObject.Dispatchees = Dispatchees.Storage;
    return CodeObject;
end
Ops[36] = Ops.set_dispatchees;

function Ops.create_dispatch_and_add_candidates(TC, ToInstantiate, ExtraDispatchees)
    -- Make sure we got the right things.
    local Source = ToInstantiate;
    local AdditionalDispatchList = ExtraDispatchees;
    
    -- Clone all but SC (since it's a new object and doesn't live in any
    -- SC yet) and dispatchees (which we want to munge).
    local NewDispatch = RakudoCodeRef.Instance.new(Source.STable);
    NewDispatch.Body = Source.Body;
    NewDispatch.CurrentContext = Source.CurrentContext;
    NewDispatch.Handlers = Source.Handlers;
    NewDispatch.OuterBlock = Source.OuterBlock;
    NewDispatch.OuterForNextInvocation = Source.OuterForNextInvocation;
    NewDispatch.Sig = Source.Sig;
    NewDispatch.StaticLexPad = Source.StaticLexPad;

    -- Take existing candidates and add new ones.
    NewDispatch.Dispatchees = List.new(Source.Dispatchees.Count);
    local i = 1;
    for j = 1, Source.Dispatchees.Count do
        NewDispatch.Dispatchees[i] = Source.Dispatchees[j];
        i = i + 1;
    end
    for j = 1, AdditionalDispatchList.Storage.Count do
        NewDispatch.Dispatchees[i] = AdditionalDispatchList.Storage[j];
        i = i + 1;
    end
    return NewDispatch;
end
Ops[37] = Ops.create_dispatch_and_add_candidates;

function Ops.push_dispatchee(TC, Dispatcher, Dispatchee)
    local Target = Dispatcher;
    if (Target.Dispatchees == nil) then
        error("push_dispatchee passed something that is not a dispatcher");
    end
    List.Add(Target.Dispatchees, Dispatchee);
    
    return Target;
end
Ops[38] = Ops.push_dispatchee;

function Ops.is_dispatcher(TC, Check)
    local Checkee = Check;
    if (Checkee ~= nil and Checkee.Dispatchees ~= nil) then
        return Ops.box_int(TC, 1, TC.DefaultBoolBoxType);
    else
        return Ops.box_int(TC, 0, TC.DefaultBoolBoxType);
    end
end
Ops[39] = Ops.is_dispatcher;
