Exceptions = {};
Exceptions.ExceptionDispatcher = {};

function Exceptions.ExceptionDispatcher.CallHandler(TC, Handler, ExceptionObject)
    local STable = Handler.STable;
    local Returned = STable.Invoke(STable, TC, Handler, CaptureHelper.FormWith({ ExceptionObject }));
    
    STable = Returned.STable;
    local ResumableMeth = STable.FindMethod(STable, TC, Returned, "resumable", Hints.NO_HINT);
    STable = ResumableMeth.STable;
    local Resumable = STable.Invoke(STable, TC, ResumableMeth, CaptureHelper.FormWith({ Returned }));
    if (Ops.unbox_int(TC, Resumable) ~= 0) then
        return Returned;
    else
        error(Exceptions.LeaveStackUnwinderException.new(Handler.OuterBlock, Returned));
    end
end

function Exceptions.ExceptionDispatcher.DieFromUnhandledException(TC, Exception)
    try {
        function ()
            local STable = Exception.STable;
            local StrMeth = STable.FindMethod(STable, TC, Exception, "Str", Hints.NO_HINT);
            local Stringified = STable.Invoke(STable, TC, StrMeth, CaptureHelper.FormWith({ Exception }));
            print(Ops.unbox_str(TC, Stringified));
        end
    }.except(){ -- catch GenericError (any error)
        function (_, exceptions, detail)
            print("error detail: " .. detail);
            print("Died from an exception, and died trying to stringify it too.");
        end
    };
    
    os.exit(1);
end

