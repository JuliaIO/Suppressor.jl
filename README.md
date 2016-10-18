# Suppressor

[![Travis](https://travis-ci.org/Ismael-VC/Suppressor.jl.svg?branch=master)](https://travis-ci.org/Ismael-VC/Suppressor.jl) [![AppVeyor](https://ci.appveyor.com/api/projects/status/e93wedour6lrdpj7/branch/master?svg=true)](https://ci.appveyor.com/project/Ismael-VC/suppressor-jl/branch/master) [![Coveralls](https://coveralls.io/repos/github/Ismael-VC/Suppressor.jl/badge.svg?branch=master)](https://coveralls.io/github/Ismael-VC/Suppressor.jl?branch=master) [![Codecov](http://codecov.io/github/Ismael-VC/Suppressor.jl/coverage.svg?branch=master)](http://codecov.io/github/Ismael-VC/Suppressor.jl?branch=master)

Julia macros for suppressing and/or capturing output (STDOUT), warnings (STDERR) or both streams at the same time.

## Installation

```julia
julia> Pkg.add("Suppressor")
```

## Usage

```julia
julia> using Suppressor

julia> @suppress begin
           println("This string doesn't get printed!")
           warn("This warning is ignored.")
       end

julia> @suppress_out begin
           println("This string doesn't get printed!")
           warn("This warning is important")
       end
WARNING: This warning is important

julia> @suppress_err begin
           println("This string gets printed!")
           warn("This warning is unimportant")
       end
This string gets printed!

julia> @suppress begin
           println("This string doesn't get printed!")
           warn("This warning is ignored.")
           error("Remember that errors are still printed!")
       end
------------------------------------------------------------------------------------------
ErrorException                                          Stacktrace (most recent call last)
[#2] — anonymous
       ⌙ at <missing>:?

[#1] — macro expansion;
       ⌙ at Suppressor.jl:16 [inlined]

Remember that errors are still printed!

```

The `suppress` macros return whatever the given expression returns, but Suppressor also provides `@capture_out` and `@capture_err` macros that work similiarly to their `@suppress_` cousins except they return any output as a string:

```julia
julia> output = @capture_out begin
    println("should get captured, not printed")
end;

julia> output == "should get captured, not printed\n"
true

julia> output = @capture_err begin
    warn("should get captured, not printed")
end;

julia> output == Base.have_color ? "\e[1m\e[31mWARNING: should get captured, not printed\e[0m\n" :
                                   "WARNING: should get captured, not printed\n"
true

```

Note that in this case the warning is printed with the escape characters to set the color because color is enabled at the REPL.
