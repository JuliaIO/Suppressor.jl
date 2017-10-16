using Suppressor
using Base.Test

output = @capture_out begin
    println("should get captured, not printed")
end
@test output == "should get captured, not printed\n"

# test both with and without color
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

@test @suppress begin
    println("This string doesn't get printed!")
    warn("This warning is ignored.")
    42
end == 42

@test @suppress_out begin
    println("This string doesn't get printed!")
    warn("This warning is important")
    42
end == 42
# WARNING: This warning is important

@test @suppress_err begin
    println("This string gets printed!")
    warn("This warning is unimportant")
    42
end == 42

# This string gets printed!

@test_throws ErrorException @suppress begin
    println("This string doesn't get printed!")
    warn("This warning is ignored.")
    error("Remember that errors are still printed!")
end
#=
------------------------------------------------------------------------------------------
ErrorException                                          Stacktrace (most recent call last)
[#2] — anonymous
       ⌙ at <missing>:?

[#1] — macro expansion;
       ⌙ at Suppressor.jl:16 [inlined]

Remember that errors are still printed!
=#

# test that the macros work inside a function
function f1()
    @suppress println("should not get printed")
    42
end

@test f1() == 42

function f2()
    @suppress_out println("should not get printed")
    42
end

@test f2() == 42

function f3()
    @suppress_err println("should not get printed")
    42
end

@test f3() == 42

function f4()
    @capture_out println("should not get printed")
    42
end

@test f4() == 42

function f5()
    @capture_err println("should not get printed")
    42
end

@test f5() == 42