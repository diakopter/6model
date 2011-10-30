Exceptions = {};
dofile('Runtime/Exceptions/ExceptionType.lua');
dofile('Runtime/Exceptions/Handler.lua');
dofile('Runtime/Exceptions/LeaveStackUnwinderException.lua');


function Exceptions.CallHandler(TC, Handler, ExceptionObject)
    local Returned = Handler.STable:Invoke(TC, Handler, CaptureHelper.FormWith({ ExceptionObject }));
    
    local ResumableMeth = Returned.STable:FindMethod(TC, Returned, "resumable", Hints.NO_HINT);
    local Resumable = ResumableMeth.STable:Invoke(TC, ResumableMeth, CaptureHelper.FormWith({ Returned }));
    if (Ops.unbox_int(TC, Resumable) ~= 0) then
        return Returned;
    else
        error(Exceptions.LeaveStackUnwinderException.new(Handler.OuterBlock, Returned));
    end
end

function Exceptions.DieFromUnhandledException(TC, Exception)
    try {
        function ()
            local StrMeth = Exception.STable:FindMethod(TC, Exception, "Str", Hints.NO_HINT);
            local Stringified = StrMeth.STable:Invoke(TC, StrMeth, CaptureHelper.FormWith({ Exception }));
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

