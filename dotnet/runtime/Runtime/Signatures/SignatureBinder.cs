﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Rakudo.Metamodel;
using Rakudo.Metamodel.Representations;

namespace Rakudo.Runtime
{
    /// <summary>
    /// Simple signature binder implementation.
    /// </summary>
    public static class SignatureBinder
    {
        /// <summary>
        /// Singleton empty positionals array.
        /// </summary>
        private static RakudoObject[] EmptyPos = new RakudoObject[0];

        /// <summary>
        /// Single empty nameds hash.
        /// </summary>
        private static Dictionary<string, RakudoObject> EmptyNamed = new Dictionary<string, RakudoObject>();

        /// <summary>
        /// Binds the capture against the given signature and stores the
        /// bound values into variables in the lexpad.
        /// 
        /// XXX No type-checking is available just yet. :-(
        /// 
        /// XXX No proper handling of optionals and defaults yet.
        /// 
        /// XXX No support for nameds mapping to positionals yet either.
        /// 
        /// (In other words, this kinda sucks...)
        /// </summary>
        /// <param name="C"></param>
        /// <param name="Capture"></param>
        public static void Bind(Context C, RakudoObject Capture)
        {
            // Make sure the object is really a low level capture (don't handle
            // otherwise yet) and grab the pieces.
            var NativeCapture = Capture as P6capture.Instance;
            if (NativeCapture == null)
                throw new NotImplementedException("Can only deal with native captures at the moment");
            var Positionals = NativeCapture.Positionals ?? EmptyPos;
            var Nameds = NativeCapture.Nameds ?? EmptyNamed;

            // If we have no signature, that's same as an empty signature.
            var Sig = C.StaticCodeObject.Sig;
            if (Sig == null)
                return;

            // Current positional.
            var CurPositional = 0;

            // Iterate over the parameters.
            var Params = Sig.Parameters;
            var NumParams = Params.Length;
            for (int i = 0; i < NumParams; i++)
            {
                var Param = Params[i];

                // Positional required?
                if (Param.Flags == Parameter.POS_FLAG)
                {
                    if (CurPositional < Positionals.Length)
                    {
                        // We have an argument, just bind it.
                        C.LexPad.Storage[Param.VariableLexpadPosition] = Positionals[CurPositional];
                    }
                    else
                    {
                        throw new Exception("Not enough positional parameters; got " +
                            CurPositional.ToString() + " but needed " +
                            NumRequiredPositionals(C.StaticCodeObject.Sig).ToString());
                    }

                    // Increment positional counter.
                    CurPositional++;
                }

                // Positonal optional?
                else if (Param.Flags == Parameter.OPTIONAL_FLAG)
                {
                    if (CurPositional < Positionals.Length)
                    {
                        // We have an argument, just bind it.
                        C.LexPad.Storage[Param.VariableLexpadPosition] = Positionals[CurPositional];
                        CurPositional++;
                    }
                    else
                    {
                        // XXX Default value, vivification.
                    }
                }

                // Named slurpy?
                else if ((Param.Flags & Parameter.NAMED_SLURPY_FLAG) != 0)
                {
                    throw new Exception("Named slurpy parameters are not yet implemented.");
                }

                // Named positional?
                else if ((Param.Flags & Parameter.POS_SLURPY_FLAG) != 0)
                {
                    throw new Exception("Positional slurpy parameters are not yet implemented.");
                }

                // Named?
                else if (Param.Name != null)
                {
                    // Yes, try and get argument.
                    RakudoObject Value;
                    if (Nameds.TryGetValue(Param.Name, out Value))
                    {
                        // We have an argument, just bind it.
                        C.LexPad.Storage[Param.VariableLexpadPosition] = Value;
                    }
                    else
                    {
                        // Optional?
                        if ((Param.Flags & Parameter.OPTIONAL_FLAG) == 0)
                        {
                            throw new Exception("Required named parameter " + Param.Name + " missing");
                        }
                        else
                        {
                            // XXX Default value, vivification.
                        }
                    }
                }

                // Otherwise, WTF?
                else
                {

                }
            }

            // Ensure we had enough positionals.
            var PossiesInCapture = Positionals.Length;
            if (CurPositional != PossiesInCapture)
                throw new Exception("Too many positional arguments passed; expected " +
                    NumRequiredPositionals(C.StaticCodeObject.Sig).ToString() +
                    " but got " + PossiesInCapture.ToString());

            // XXX TODO; Ensure we don't have leftover nameds.
        }

        /// <summary>
        /// The number of positionals we require.
        /// </summary>
        /// <param name="Sig"></param>
        /// <returns></returns>
        private static int NumRequiredPositionals(Signature Sig)
        {
            int Num = 0;
            foreach (var Param in Sig.Parameters)
                if (Param.Flags != 0 || Param.Name != null)
                    break;
                else
                    Num++;
            return Num;
        }
    }
}
