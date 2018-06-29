# Suppressor

[![Travis](https://travis-ci.org/JuliaIO/Suppressor.jl.svg?branch=master)](https://travis-ci.org/JuliaIO/Suppressor.jl) [![Build status](https://ci.appveyor.com/api/projects/status/e3uuqon84kt97402/branch/master?svg=true)](https://ci.appveyor.com/project/SalchiPapa/suppressor-jl/branch/master) [![CoverAlls](https://coveralls.io/repos/github/JuliaIO/Suppressor.jl/badge.svg?branch=master)](https://coveralls.io/github/JuliaIO/Suppressor.jl?branch=master) [![CodeCov](https://codecov.io/gh/JuliaIO/Suppressor.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaIO/Suppressor.jl)

Julia macros for suppressing and/or capturing output (`stdout`), warnings (`stderr`) or both streams at the same time.

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

julia> output == (Base.have_color ? "\e[1m\e[33mWARNING: \e[39m\e[22m\e[33mshould get captured, not printed\e[39m\n" :
                                    "WARNING: should get captured, not printed\n")
true

```

Often when capturing output for test purposes it's useful to control whether
color is enabled or not, so that you can compare with or without the color
escape characters regardless of whether the julia process has colors enabled or
disabled globally. You can use the `@color_output` macro for this:

```julia
@color_output false begin
    output = @capture_err begin
        warn("should get captured, not printed")
    end
end
@test output == "WARNING: should get captured, not printed\n"

@color_output true begin
    output = @capture_err begin
        warn("should get captured, not printed")
    end
end
@test output == "\e[1m\e[33mWARNING: \e[39m\e[22m\e[33mshould get captured, not printed\e[39m\n"
```
