#!/bin/sh
# this version of try for use with Mono 2.4 on Linux
cp ../runtime/bin/Debug/RakudoRuntime.dll .
make
rm ./RakudoOutput.exe 2> /dev/null
parrot compile.pir $1 > RakudoOutput.cs
gmcs -nowarn:162,168,219 RakudoOutput.cs /reference:RakudoRuntime.dll
echo ---
mono ./RakudoOutput.exe
