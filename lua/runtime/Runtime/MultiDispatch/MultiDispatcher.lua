

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
            this.EdgesOut = 0;
            return setmetatable(this, mt);
        end
        return CandidateGraphNode;
    end
    local CandidateGraphNode = makeCandidateGraphNode();
    
    local EDGE_REMOVAL_TODO = -1;
    local EDGE_REMOVED = -2;
    
    function MultiDispatcher.FindBestCandidate(TC, DispatchRoutine, Capture)
        local NativeCapture = Capture;
        
        if (DispatchRoutine.MultiDispatchCache ~= nil and NativeCapture.Nameds == nil) then
            local CacheResult = DispatchRoutine.MultiDispatchCache:Lookup(NativeCapture.Positionals);
            if (CacheResult ~= nil) then
                return CacheResult;
            end
        end
        
        local SortedCandidates = MultiDispatcher.Sort(TC, DispatchRoutine.Dispatchees);
        
        local PossiblesList = List.new();
        
        local continuing = false;
        
        for j = 1, SortedCandidates.Count do
            local Candidate = SortedCandidates[j];
            continuing = false;
            if (Candidate == nil) then
                if (PossiblesList.Count == 1) then
                    if (NativeCapture.Nameds == nil) then
                        if (DispatchRoutine.MultiDispatchCache == nil) then
                            DispatchRoutine.MultiDispatchCache = DispatchCache.new();
                        end
                        DispatchRoutine.MultiDispatchCache:Add(NativeCapture.Positionals, PossiblesList[1]);
                    end
                    return PossiblesList[1];
                elseif (PossiblesList.Count > 1) then
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
                local REPR = Type and Type.STable or nil;
                if (Type ~= nil and Ops.unbox_int(TC, REPR.TypeCheck(REPR, TC, Arg.STable.WHAT, Type)) == 0) then
                    TypeMismatch = true;
                    i = TypeCheckCount + 1; -- fake breaking
                end
                if (not TypeMismatch) then
                
                local Definedness = Candidate.Sig.Parameters[i].Definedness;
                if (Definedness ~= DefinednessConstraint.None) then
                    REPR = Arg.STable.REPR;
                    local ArgDefined = REPR.defined(REPR, null, Arg);
                    if (Definedness == DefinednessConstraint.DefinedOnly and not ArgDefined or
                            Definedness == DefinednessConstraint.UndefinedOnly and ArgDefined) then
                        TypeMismatch = true;
                        i = TypeCheckCount + 1; -- fake breaking
                    end
                end
                end -- breaking 
            end
            if (not TypeMismatch) then
                List.Add(PossiblesList, Candidate);
            end
        end
        end end -- continuings
        error("No candidates found to dispatch to");
    end
    
    function MultiDispatcher.Sort(TC, Unsorted)
        local NumCandidates = #Unsorted;
        
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
                if (Graph[i].EdgesIn == 0) then
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
    
    function MultiDispatcher.IsNarrower(TC, a, b)
        local Narrower = 0;
        local Tied = 0;
        local i, TypesToCheck;
        
        if (a.Sig.NumPositionals == b.Sig.NumPositionals) then
            TypesToCheck = a.Sig.NumPositionals;
        elseif (a.Sig.NumRequiredPositionals == b.Sig.NumRequiredPositionals) then
            TypesToCheck = math.min(a.Sig.NumPositionals, b.Sig.NumPositionals);
        else
            return 0;
        end
        
        for i = 1, TypesToCheck do
            local TypeObjA = a.Sig.Parameters[i].Type;
            local TypeObjB = b.Sig.Parameters[i].Type;
            if (TypeObjA == TypeObjB) then
                Tied = Tied + 1;
            else
                if (MultiDispatcher.IsNarrowerType(TC, TypeObjA, TypeObjB)) then
                    Narrower = Narrower + 1;
                elseif (not MultiDispatcher.IsNarrowerType(TC, TypeObjB, TypeObjA)) then
                    Tied = Tied + 1;
                end
            end
        end
        
        if (Narrower >= 1 and Narrower + Tied == TypesToCheck) then
            return 1;
        elseif (Tied ~= TypesToCheck) then
            return 0;
        end
        
        return not a.Sig:HasSlurpyPositional() and b.Sig:HasSlurpyPositional() and 1 or 0;
    end
    
    function MultiDispatcher.IsNarrowerType(TC, A, B)
        if (B == nil and A ~= nil) then
            return true;
        elseif (A == nil or B == nil) then
            return false;
        end
        
        return Ops.unbox_int(TC, Ops.type_check(TC, A, B)) ~= 0;
    end
    return MultiDispatcher;
end
MultiDispatch = {};
MultiDispatcher = makeMultiDispatcher();
MultiDispatch.MultiDispatcher = MultiDispatcher;