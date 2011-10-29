function Ops.multi_dispatch_over_lexical_candidates(ThreadContext TC)
    local CurOuter = TC.CurrentContext;
    while (CurOuter ~= nil) do
        local CodeObj = CurOuter.StaticCodeObject;
        if (CodeObj.Dispatchees ~= nil) then
            local Candidate = MultiDispatch.MultiDispatcher.FindBestCandidate(TC,
                CodeObj, CurOuter.Capture);
            return Candidate.STable:Invoke(TC, Candidate, CurOuter.Capture);
        end
        CurOuter = CurOuter.Outer;
    end
    error("Could not find dispatchee list!");
end