

function makeMultiDispatcher ()
    local MultiDispatcher = {};
    
    local makeCandidateGraphNode = function ()
        local CandidateGraphNode = {};
        local mt = { __index = CandidateGraphNode };
        function CandidateGraphNode.new(Candidate, Edges)
            local this = {};
            this.Candidate = Candidate;
            this.Edges = Edges;
            this.EdgesIn = 0;
            this.Edges.Out = 0;
            return setmetatable(this, mt);
        end
    end
    local CandidateGraphNode = makeCandidateGraphNode();
    
    local EDGE_REMOVAL_TODO = -1;
    local EDGE_REMOVED = -2;
    
    function MultiDispatcher.FindBestCandidate(TC, DispatchRoutine, Capture)
        local NativeCapture = Capture;
        
        -- skip caching for now!
        
        local SortedCandidates = MultiDispatcher.Sort(TC, DispatchRoutine.Dispatchees);
        
        local PossiblesList = List.new();
        
        local continuing = false;
        
        for unused,Candidate in ipairs(SortedCandidates) do
            continuing = false;
            if (Candidate == nil) then
                if (PossiblesList.Count == 1) then
                    return PossiblesList[1];
                end
            elseif (PossiblesList.Count > 1) then
                -- skip caching.
                error("Ambiguous dispatch: more than one candidate matches");
            else
                continuing = true;
            end
        end
        if (not continuing) then
        
        local NumArgs = NativeCapture.Positionals.Count;
        if (NumArgs < Candidate.Sig.NumRequiredPositionals or NumArgs > Candidate.Sig.NumPositionals) then
            continuing = true;
        end
        if (not continuing) then
        
        local TypeCheckCount = math.min(NumArgs, Candidate.Sig.NumPositionals);
        local TypeMismatch = false;
        for i = 1, TypeCheckCount do
            local Arg = NativeCapture.Positionals[i];
            local Type = Candidate.Sig.Parameters[i].Type;
            if (Type ~= nil and Ops.unbox_int(TC, Type.STable:TypeCheck(TC, Arg.STable.WHAT, Type)) == 0) then
                TypeMismatch = true;
                i = TypeCheckCount + 1; -- fake breaking
            end
            if (not TypeMismatch) then
            
            local Definedness = Candidate.Sig.Parameters[i].Definedness;
            if (Definedness ~= DefinednessConstraint.None) then
                local ArgDefined = Arg.STable.REPR:defined(null, Arg);
                if (Definedness == DefinednessConstraint.DefinedOnly and not ArgDefined or
                        Definedness == DefinednessConstraint.UndefinedOnly and ArgDefined) then
                    TypeMismatch = true;
                    i = TypeCheckCount + 1; -- fake breaking
                end
            end
            end -- breaking 
        end
        if (not TypeMismatch) then
            PossiblesList.Add(Candidate);
        end
        end end -- continuings
        error("No candidates found to dispatch to");
    end
    
    function MultiDispatcher.Sort(TC, Unsorted)
        local NumCandidates = Unsorted.Count;
        local Result = List.new(2 * NumCandidates + 1);
        
        local Graph = List.new(NumCandidates);
        
        for i = 1, NumCandidates do
            Graph[i] = CandidateGraphNode.new(
                Unsorted[i],
                List.new(NumCandidates)
            );
        end
        
        for i = 1, NumCandidates do
            for j = 1, NumCandidates do
                if (i ~= j) then
                    if (MultiDispatcher.IsNarrower(TC, Graph[i].Candidate, Graph[j].Candidate) ~= 0) then
                        Graph[i].Edges[Graph[i].EdgesOut + 1] = Graph[j];
                        Graph[i].EdgesOut = Graph[i].EdgesOut + 1;
                        Graph[j].EdgesIn = Graph[j].EdgesIn + 1;
                    end
                end
            end
        end
        
        local CandidatesToSort = NumCandidates;
        local ResultPos = 1;
        
        while (CandidatesToSort > 0) do
            local StartPoint = ResultPos;
            
            for i = 1, NumCandidates do
                if (Graph[i].EdgesIn == 0) {
                    Result[ResultPos] = Graph[i].Candidate;
                    Graph[i].Candidate = nil;
                    ResultPos = ResultPos + 1;
                    CandidatesToSort = CandidatesToSort - 1;
                    Graph[i].EdgesIn = EDGE_REMOVAL_TODO;
                end
            end
            if (StartPoint == ResultPos) then
                error("Circularity detected in multi sub types.");
            end
            
            for i = 1, NumCandidates do
                if (Graph[i].EdgesIn == EDGE_REMOVAL_TODO) then
                    for j = 1, Graph[i].EdgesOut do
                        Graph[i].Edges[j].EdgesIn = Graph[i].Edges[j].EdgesIn - 1;
                    end
                    Graph[i].EdgesIn = EDGE_REMOVED;
                end
            end
            
            ResultPos = ResultPos + 1;
        end
        
        return Result;
    end
end

MultiDispatcher = makeMultiDispatcher();